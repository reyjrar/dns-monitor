package POE::Component::dns::monitor::sniffer::plugin::packet::logger;

use strict;
use warnings;
use POE;
use DateTime;
use DateTime::Format::Pg;
use Digest::SHA qw( sha1_hex );
use YAML;
use Try::Tiny;
use Sys::Syslog;

my %_SECTION_CODE = (
	answer		=> 'ANS',
	additional	=> 'ADD',
	authority	=> 'AUTH',
);

sub spawn {
	my $self = shift;
	my %args = @_;

	die "Bad Config" if ref $args{Config} ne 'HASH';
	die "No Alias" unless length $args{Alias};

	my $sess = POE::Session->create( inline_states => {
		_start	=> sub { $poe_kernel->yield( 'packet_logger_start', \%args ); },
		_stop 	=> sub { },
		packet_logger_start => \&packet_logger_start,
		process => \&process,
		maintenance => \&packet_logger_maintenance,
		flush_entry => \&packet_logger_flush_entry,
	});

	return $sess->ID;
}

sub packet_logger_start {
	my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

	$kernel->alias_set( $args->{Alias} );
	
	# Store stuff in the heap
	$heap->{log} = $args->{LogSID};

	# Set the Config
	my %cfg = (
		facility => 'user',
		priority => 'notice',
		log_uuid => 0,
		%{ $args->{Config} },
	);
	$heap->{config} = \%cfg;

	# Caching
	$heap->{cache} = ();

	# Open the logger
	openlog( 'dnsmonitor', '', $heap->{config}->{facility} );

	# Trigger Maintenance
	$kernel->delay_add( 'maintenance', 60 );
}

sub process {
	my ( $kernel,$heap,$dnsp,$info ) = @_[KERNEL,HEAP,ARG0,ARG1];

	# UUID
	my $uuid = sha1_hex join(';', 
							$info->{server}, $info->{server_port},
							$info->{client}, $info->{client_port},
				$dnsp->header->id
	);

	# Check for query/response
	if( $dnsp->header->qr ) {

		# Grab entry from cache:
		my $entry = delete $heap->{cache}{$uuid};
		# If there isn't an entry, create one and set the the flushed flag
		$entry ||= { uuid => $uuid, flushed => 1 };

		# Answer Header
		$entry->{a} = {
			'time'	=> $info->{time},
			cli		=> join(':', $info->{client}, $info->{client_port} ),
			srv		=> join(':', $info->{server}, $info->{server_port} ),
			id		=> $dnsp->header->id,
			op		=> $dnsp->header->opcode,
			qcnt	=> $dnsp->header->qdcount,
			cd		=> $dnsp->header->cd,
			rd		=> $dnsp->header->rd,
			status	=> $dnsp->header->rcode,
			size	=> $dnsp->answersize,
			anscnt	=> $dnsp->header->ancount,
			addcnt	=> $dnsp->header->arcount,
			authcnt	=> $dnsp->header->nscount,
			authr	=> $dnsp->header->aa,
			authn	=> $dnsp->header->ad,
			ra		=> $dnsp->header->ra,
		};

		my @sets = ();
		
		foreach my $section (qw(answer additional authority)) {
			my @records = ();
			try {
				no strict;
				@records = $dnsp->$section();
			};
			if( @records ) {
				push @sets, { name => $_SECTION_CODE{$section}, rr => \@records };
			}
		}
		foreach my $set ( @sets ) {
			foreach my $pa ( @{ $set->{rr} } ) {
				my %data = _get_rr_data( $pa );
				
				next unless defined $data{value} && length $data{value};
				
				push @{ $entry->{ar} }, {
					sect	=> $set->{name},
					class	=> $pa->class,
					rtype	=> $pa->type,
					name	=> $pa->name,
					value	=> $data{value},
					opts	=> $data{opts},
					ttl		=> $pa->ttl,
				};
			}
		}

		$kernel->yield( 'flush_entry' => $entry );
	}
	else {
		# Query
		my %entry = (
			proc_time => time,
			uuid => $uuid,
		);
		$entry{q} = {
			'time'	=> $info->{time},
			cli		=> join(':', $info->{client}, $info->{client_port} ),
			srv		=> join(':', $info->{server}, $info->{server_port} ),
			id		=> $dnsp->header->id,
			op		=> $dnsp->header->opcode,
			qcnt	=> $dnsp->header->qdcount,
			rd		=> $dnsp->header->rd,
			cd		=> $dnsp->header->cd,
		};

		# Set Cache:
		foreach my $pq ( $dnsp->question ) {
			push @{ $entry{qr} }, {
				class	=> $pq->qclass,
				rtype	=> $pq->qtype,
				name	=> $pq->qname,
			};
		}

		# Store it in the cache
		$heap->{cache}{$uuid} = \%entry;
	}
}

sub packet_logger_flush_entry {
	my($kernel,$heap,$entry) = @_[KERNEL,HEAP,ARG0];

	foreach my $t (qw{ q qr a ar }) {
		my $rec = exists $entry->{$t} ? $entry->{$t} : undef;
		next unless defined $rec;

		my $line = qq{type=$t};
		$line .= qq{ uuid=$entry->{uuid}} if $heap->{config}{log_uuid};
		$line .= ' flushed=1' if( exists $entry->{flushed} && $entry->{flushed} );

		if( ref $rec eq 'ARRAY' ) {
			foreach my $item ( @{ $rec } ) {
				my $subline = $line;
				foreach my $field (qw(sect class rtype name value opts ttl)) {
					if( exists $item->{$field} ) {
						$subline .= qq{ $field=$item->{$field}};
					}
				}
				syslog( $heap->{config}{priority}, $subline ); 
			}

		}
		elsif( ref $rec eq 'HASH' ) {
			foreach my $field (qw(time srv cli id op status rd cd size qcnt anscnt addcnt authcnt ra authn authr ) ) {
				if( exists $rec->{$field} ) {
					# Handle flags gracefully
					my $value = $rec->{$field} ? $rec->{$field} : 0;
					$line .= qq{ $field=$value};
				}
			}
			syslog( $heap->{config}{priority}, $line ); 
		}
		else {
			$kernel->call('log' => 'notice' => "packet::logger->flush_entry handed invalid reference for UUID: $entry->{uuid}");
			next;
		}
	}
}

sub packet_logger_maintenance {
	my ($kernel,$heap) = @_[KERNEL,HEAP];

	# Expire after 20 seconds and now response
	my $expire = time - 20;

	# Purge the Query Cache
	foreach my $uuid (keys %{ $heap->{cache} }) {
		if( $heap->{cache}{$uuid}{proc_time} < $expire ) {
			my $entry = delete $heap->{cache}{$uuid};
			$entry->{flushed} = 1;

			$kernel->yield( flush_entry => $entry );
		}
	}

	my $entries = scalar keys %{ $heap->{cache} };
	$kernel->call( $heap->{log} => debug => "logger cache at $entries entries" );
	# Reschedule
	$kernel->delay_add( 'maintenance', 60 );
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


