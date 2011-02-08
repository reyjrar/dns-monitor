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
		packet_logger_query_response => \&packet_logger_query_response,
		packet_logger_client_is_server => \&packet_logger_client_is_server,
	});

	return $sess->ID;
}

sub packet_logger_start {
	my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

	$kernel->alias_set( $args->{Alias} );
	
	# Store stuff in the heap
	$heap->{log} = $args->{LogSID};
	$heap->{dbh} = $args->{DBH};

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

	$kernel->yield('packet_logger_query_response');
	#$kernel->yield('packet_logger_client_is_server');

	# Reschedule
	$kernel->delay_add( 'maintenance', 600 );
}

sub packet_logger_query_response {
	my ($kernel,$heap) = @_[KERNEL,HEAP];

	# Select Null response_id
	my $check_ts = DateTime->now()->subtract( days => 2 );
	my %STH = ();
	my %SQL = (
		null_response => q{
				select * from packet_query where response_id is null
					and query_ts > ?
					order by query_ts limit 1000
		},
		find_response => q{
			select id from packet_response
				where conversation_id = ?
					and query_serial = ?
					and response_ts between ? and ?
		},
		set_response => q{
			update packet_query set response_id = ? where id = ?
		},
	);
	foreach my $s (keys %SQL) {
		$STH{$s} = $heap->{dbh}->run( fixup => sub {
				my $sth = $_->prepare($SQL{$s});
				$sth;
			}
		);
	}

	$STH{null_response}->execute( $check_ts->datetime );

	my $updates = 0;
	while( my $q = $STH{null_response}->fetchrow_hashref ) {
		my $qt = DateTime::Format::Pg->parse_datetime( $q->{query_ts} );
		# Find the response
		$STH{find_response}->execute( $q->{conversation_id}, $q->{query_serial},
			$qt->clone->subtract( seconds => 1)->datetime, 
			$qt->clone()->add( seconds => 10 )->datetime
		);
		# If we found 1, do something!
		if( $STH{find_response}->rows == 1 ) {
			my($response_id) = $STH{find_response}->fetchrow_array;
			$STH{set_response}->execute( $response_id, $q->{response_id} );
			$updates++;
		}
	}
	$kernel->post( $heap->{log} => debug => "packet::logger::query_response linked $updates stray queries" );
}

sub packet_logger_client_is_server {
	my ($kernel,$heap) = @_[KERNEL,HEAP];

	my $clients = $heap->{model}->resultset('client')->search(
		{ role_server_id => { '!=' => undef } },
	);
	
	my $updates = 0;
	while( my $cli = $clients->next ) {
		my $conversations = $heap->model('conversation')->search(
			{ 
				client_id => $cli->id,
				client_is_server => 0
			}
		);

		while ( my $conv = $conversations->next ) {
			$conv->client_is_server( 1 );
			$conv->update;
			$updates++;
		}
	}

	$kernel->post( $heap->{log} => debug => "packet::logger::client_is_server updated $updates conversations" );
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


