package POE::Component::dns::monitor::analysis::plugin::packet::timing;

use strict;
use warnings;
use POE;

sub spawn {
	my $self = shift;
	my %args = @_;

	die "Bad Config" if ref $args{Config} ne 'HASH';
	die "Bad DBH" unless ref $args{DBH};
	die "No Alias" unless length $args{Alias};

	my $sess = POE::Session->create( inline_states => {
		_start	=> sub { $poe_kernel->yield( 'packet_timing_start', \%args ); },
		_stop 	=> sub { },
		packet_timing_start => \&packet_timing_start,
		analyze => \&analyze,
	});

	return $sess->ID;
}

sub packet_timing_start {
	my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

	$kernel->alias_set( $args->{Alias} );
	
	# Store stuff in the heap
	$heap->{log} = $args->{LogSID};
	$heap->{dbh} = $args->{DBH};
	$heap->{interval} = $args->{Config}{interval} || 3600;

	# Schedule the Analysis
	$kernel->yield('analyze');
}

# Add timing data to the database
sub analyze {
	my ( $kernel,$heap ) = @_[KERNEL,HEAP];

	$kernel->call( $heap->{log} => debug => "packet::timing running analysis" );

	my %SQL = (
		check => q{select
					 q.id as query_id, q.conversation_id, qr.response_id, r.capture_time - q.capture_time as difference
						from packet_query q
							inner join packet_meta_query_response qr on q.id = qr.query_id
							left join packet_timing t on q.id = t.query_id and t.query_id is null
							inner join packet_response r on qr.response_id = r.id and r.capture_time is not null
						where q.capture_time is not null
							and q.query_ts > NOW() - interval '2 hours'
		},
		insert => q{insert into packet_timing ( conversation_id, query_id, response_id, difference )
						values ( ?, ?, ?, ? ) 
		},
	);
	my %STH = ();
	foreach my $s ( keys %SQL ) {
		$STH{$s} = $heap->{dbh}->run( fixup => sub {
				my $sth = $_->prepare( $SQL{$s} );
				$sth;
		});
	}

	$STH{check}->execute();

	my $updates = 0;
	while( my $ent = $STH{check}->fetchrow_hashref ) {
		$STH{insert}->execute( $ent->{conversation_id}, $ent->{query_id}, $ent->{response_id}, $ent->{difference} );
		$updates++;
	}
	$kernel->post( $heap->{log} => debug => "packet::timing posted $updates updates");

	# Schedule the Analysis
	$kernel->delay_add( analyze => $heap->{interval} );
}

# Return True
1;
