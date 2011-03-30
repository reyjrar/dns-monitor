package POE::Component::dns::monitor::sniffer::plugin::packet::logger;

use strict;
use warnings;
use POE;
use DateTime;
use DateTime::Format::Pg;
use YAML;
use Try::Tiny;

sub spawn {
	my $self = shift;
	my %args = @_;

	die "Bad Config" if ref $args{Config} ne 'HASH';
	die "Bad DBH" unless ref $args{DBH};
	die "No Alias" unless length $args{Alias};

	my $sess = POE::Session->create( inline_states => {
		_start	=> sub { $poe_kernel->yield( 'packet_logger_start', \%args ); },
		_stop 	=> sub { },
		packet_logger_start => \&packet_logger_start,
		process => \&process,
		maintenance => \&packet_logger_maintenance,
		expire_records => \&expire_records,
	});

	return $sess->ID;
}

sub packet_logger_start {
	my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

	$kernel->alias_set( $args->{Alias} );
	
	# Store stuff in the heap
	$heap->{log} = $args->{LogSID};
	$heap->{dbh} = $args->{DBH};

	# Set the Config
	my %cfg = (
		keep_for => '8 days',
		%{ $args->{Config} },
	);
	$heap->{config} = \%cfg;

	# Caching
	my %_qcache = ();
	$heap->{qcache} = CHI->new( driver => 'Memory', datastore => \%_qcache, expires_in => 90 );
	$heap->{__qcache} = \%_qcache;

	# Statement Handle Caching
	my %SQL = (
		query => q{select add_query( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )},
		question => q{select find_or_create_question( ?, ?, ?, ? ) },
		response => q{select add_response( ?, ?, ?, ?, ?, ?, ?,
											?, ?, ?, ?, ?, ?, ?,
											?, ?, ?, ?, ? )},
		answer => q{select find_or_create_answer( ?, ?, ?, ?, ?, ?, ?, ? )},
		query_response => q{select link_query_response( ?, ? )},
	);
	foreach my $s (keys %SQL) {
		$heap->{sth}{$s} = $heap->{dbh}->run( fixup => sub {
				my $sth = $_->prepare( $SQL{$s} );
				$sth;
			}, catch {
				my $err = shift;
				$kernel->post( $heap->{log} => notice => qq|packet::logger STH: $s failed: $err| );
			}
		);
	}

	# Trigger Maintenance
	$kernel->delay_add( 'maintenance', 30 );
}

sub process {
	my ( $kernel,$heap,$dnsp,$info ) = @_[KERNEL,HEAP,ARG0,ARG1];

	# Packet ID
	my $packet_id = join(';', $info->{conversation_id}, $dnsp->header->id );

	# Check for query/response
	if( $dnsp->header->qr ) {
		# Grab Queriy id from cache:
		my $query_id = $heap->{qcache}->get( $packet_id );
		# Answer
		$heap->{sth}{response}->execute(
			$info->{conversation_id},
			$info->{client_id},
			$info->{client_port},
			$info->{server_id},
			$info->{server_port},
			$dnsp->header->id,
			$dnsp->header->opcode,
			$dnsp->header->rcode,
			$dnsp->answersize,
			$dnsp->header->ancount,
			$dnsp->header->arcount,
			$dnsp->header->nscount,
			$dnsp->header->qdcount,
			$dnsp->header->aa,
			$dnsp->header->ad,
			$dnsp->header->tc,
			$dnsp->header->cd,
			$dnsp->header->rd,
			$dnsp->header->ra,
		);

		my ($response_id) = $heap->{sth}{response}->fetchrow_array;
		return unless defined $response_id && $response_id > 0;

		# Link Query / Response
		if( defined $query_id ) {
			$heap->{sth}{query_response}->execute($query_id, $response_id);
		}

		my @sets = (
			{ name => 'answer', rr => [ $dnsp->answer ], },
			{ name => 'additional', rr => [ $dnsp->additional ], },
			{ name => 'authority', rr => [ $dnsp->authority ], },
		);
		foreach my $set ( @sets ) {
			foreach my $pa ( @{ $set->{rr} } ) {
				my %data = _get_rr_data( $pa );
				
				next unless defined $data{value} && length $data{value};
				
				$heap->{sth}{answer}->execute(
					$response_id,
					$set->{name},
					$pa->ttl,
					$pa->class,
					$pa->type,
					$pa->name,
					$data{value},
					$data{opts},
				);
			}
		}
	}
	else {
		# Query
		$heap->{sth}{query}->execute(
			$info->{conversation_id},
			$info->{client_id},
			$info->{client_port},
			$info->{server_id},
			$info->{server_port},
			$dnsp->header->id,
			$dnsp->header->opcode,
			$dnsp->header->qdcount,
			$dnsp->header->rd,
			$dnsp->header->tc,
			$dnsp->header->cd
		);

		my ($query_id) = $heap->{sth}{query}->fetchrow_array;
		return unless defined $query_id && $query_id > 0;

		# Set Cache:
		$heap->{qcache}->set( $packet_id, $query_id );
		foreach my $pq ( $dnsp->question ) {
			$heap->{sth}{question}->execute(
				$query_id,
				$pq->qclass,
				$pq->qtype,
				$pq->qname
			);
		}
	}
}

sub packet_logger_maintenance {
	my ($kernel,$heap) = @_[KERNEL,HEAP];

	# Purge the Query Cache
	$heap->{qcache}->purge();

	# Age Records in query/response tables
	$kernel->yield( 'expire_records' );

	# Reschedule
	$kernel->delay_add( 'maintenance', 600 );
}

sub expire_records {
	my ($kernel,$heap) = @_[KERNEL,HEAP];

	return 1 if $heap->{config}{keep_for} == 0;
	
	my $sth = $heap->{dbh}->run( fixup => sub {
			my $sth = $_->prepare( q{select packet_logger_cleanup( ? )} );
			$sth;
	});

	$sth->execute( $heap->{config}{keep_for} );
	$sth->finish;

	$kernel->call( $heap->{log} => notice => "expire_records completed.");

	return 1;
}

sub _get_rr_data {
	my ($pa) = shift;

	my %data = ( value => undef, opts => undef );

	if( $pa->type eq 'A' || $pa->type eq 'AAAA' ) {
		$data{value} = $pa->address;
	}
	elsif( $pa->type eq 'CNAME' ) {
		$data{value} = $pa->cname;
	}
	elsif( $pa->type eq 'DNAME' ) {
		$data{value} = $pa->dname;
	}
	elsif( $pa->type eq 'MX' ) {
		$data{value} = $pa->exchange;
		$data{opts} = $pa->preference;
	}
	elsif( $pa->type eq 'NS' ) {
		$data{value} = $pa->nsdname;
	}
	elsif( $pa->type eq 'PTR' ) {
		$data{value} = $pa->ptrdname;
	}
	elsif( $pa->type eq 'SRV' ) {
		$data{value} = $pa->target;
		$data{value} .= ':' . $pa->port if $pa->port;
		$data{opts} = $pa->priority;
		$data{opts} .= ';' . $pa->priority if defined $pa->weight;
	}
	elsif( $pa->type eq 'SPF' || $pa->type eq 'TXT' ) {
		$data{value} = $pa->txtdata;
	}
	
	return %data;
}

1;


