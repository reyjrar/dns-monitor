package POE::Component::dns::monitor::analysis::plugin::query::response;

use strict;
use warnings;
use POE;
use DateTime;
use DateTime::Format::Pg;
use YAML;

sub spawn {
	my $self = shift;
	my %args = @_;

	die "Bad Config" if ref $args{Config} ne 'HASH';
	die "Bad DBH" unless ref $args{DBH};
	die "No Alias" unless length $args{Alias};

	my $sess = POE::Session->create( inline_states => {
		_start	=> sub { $poe_kernel->yield( 'query_response_start', \%args ); },
		_stop 	=> sub { },
		query_response_start => \&query_response_start,
		analyze => \&analyze,
		notify => \&notify,
		reset_id => \&reset_id,
	});

	return $sess->ID;
}

sub query_response_start {
	my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

	$kernel->alias_set( $args->{Alias} );

	# Store stuff in the heap
	$heap->{log} = $args->{LogSID};
	$heap->{dbh} = $args->{DBH};
	$heap->{interval} = $args->{Config}{interval} || 900;

	# Schedule the Analysis
	$kernel->delay_add('analyze' => 10);
	$kernel->yield('reset_id');
}

sub reset_id {
	my ($kernel,$heap) = @_[KERNEL,HEAP];

	$heap->{last_id} = 0;
	$kernel->delay_add( reset_id => 3600*12 );
}

# Link Query and Response
sub analyze {
	my ( $kernel,$heap ) = @_[KERNEL,HEAP];

	$kernel->call( $heap->{log} => debug => "query::reponse running analysis" );

	# Select Null response_id
	my $check_ts = DateTime->now()->subtract( hours => 12 );

	my %STH = ();
	my %SQL = (
		null_response => q{
				select q.* from packet_query q
					left join packet_meta_query_response m on q.id = m.query_id
						where m.response_id is null
						and q.query_ts > ?
						and q.id > ?
						order by q.query_ts limit 2000
		},
		find_response => q{
			select id from packet_response
				where conversation_id = ?
					and query_serial = ?
					and response_ts between ? and ?
		},
		set_response => q{
			select link_query_response( ?, ? )
		},
	);
	foreach my $s (keys %SQL) {
		$STH{$s} = $heap->{dbh}->run( fixup => sub {
				my $sth = $_->prepare($SQL{$s});
				$sth;
			}
		);
	}

	$STH{null_response}->execute( $check_ts->datetime, $heap->{last_id} );

	my $updates = 0;
	my $id = 0;
	while( my $q = $STH{null_response}->fetchrow_hashref ) {
		my $qt = DateTime::Format::Pg->parse_datetime( $q->{query_ts} );
		# Find the response
		$STH{find_response}->execute( $q->{conversation_id}, $q->{query_serial},
			$qt->clone->datetime,
			$qt->clone()->add( seconds => 5 )->datetime
		);
		# If we found 1, do something!
		if( $STH{find_response}->rows == 1 ) {
			my($response_id) = $STH{find_response}->fetchrow_array;
			$STH{set_response}->execute( $q->{id}, $response_id );
			$updates++;
		}
		$id = $q->{id};
	}
	$heap->{last_id} = $id;

	$kernel->post( $heap->{log} => debug => "query::response posted $updates updates");

	# Schedule the Analysis
	$kernel->delay_add( analyze => $heap->{interval} );
}

# Notification
sub notify {
	my ($kernel,$heap) = @_[KERNEL,HEAP];
}

# Return True
1;
