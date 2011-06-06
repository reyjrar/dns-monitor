package POE::Component::dns::monitor::analysis::plugin::server::authorized;

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
		_start	=> sub { $poe_kernel->yield( 'server_authorized_start', \%args ); },
		_stop 	=> sub { },
		server_authorized_start => \&server_authorized_start,
		analyze => \&analyze,
		notify => \&notify,
	});

	return $sess->ID;
}

sub server_authorized_start {
	my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

	$kernel->alias_set( $args->{Alias} );
	
	# Store stuff in the heap
	$heap->{log} = $args->{LogSID};
	$heap->{dbh} = $args->{DBH};
	$heap->{interval} = $args->{Config}{interval} || 3600;
	$heap->{authorized} = $args->{Config}{authorized} || [];

	# Schedule the Analysis
	$kernel->yield('analyze');
}

# Discover Authorized and Unauthorized servers
sub analyze {
	my ( $kernel,$heap ) = @_[KERNEL,HEAP];

	$kernel->call( $heap->{log} => debug => "server::authorized running analysis" );

	my %SQL = (
		check => 'select * from server',
		update => 'update server set is_authorized = ? where id = ?',
	);
	my %STH = ();
	foreach my $s (keys %SQL) {
		$STH{$s} = $heap->{dbh}->run( fixup => sub {
				my $sth = $_->prepare( $SQL{$s} );
				$sth;
			}
		);
	}

	my $check_ts = DateTime->now()->subtract( seconds => $heap->{interval} );
	$STH{check}->execute();

	my $updates = 0;
	while( my $ent = $STH{check}->fetchrow_hashref ) {
		my $doUpdate = 0;
		my $value = undef;
		if( grep { $ent->{ip} eq $_ } @{ $heap->{authorized} } ) {
			if( ! $ent->{is_authorized} ) {
				$value = 1;
				$doUpdate = 1;
			}
		}
		else {
			if( $ent->{is_authorized} ) {
				$value = 0;
				$doUpdate = 1;
			}
		}
		if( $doUpdate ) {
			$STH{update}->execute( $value, $ent->{id} );
			my $first_ts = DateTime::Format::Pg->parse_datetime( $ent->{first_ts} );
			if( $first_ts > $check_ts ) {
				$kernel->yield( 'notify' => $ent );
			}
		}
		$updates += $doUpdate;
	}
	$kernel->post( $heap->{log} => debug => "server::authorized posted $updates updates.");

	# Schedule the Analysis
	$kernel->delay_add( analyze => $heap->{interval} );
}

# Notification of Unauthorized Servers
sub notify {
	my ($kernel,$heap,$srv) = @_[KERNEL,HEAP,ARG0];
}

# Return True
1;
