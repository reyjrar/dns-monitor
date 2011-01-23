package POE::Component::dns::monitor::analysis::plugin::server::authorized;

use strict;
use warnings;
use POE;
use DateTime;
use YAML;

sub spawn {
	my $self = shift;
	my %args = @_;

	die "Bad Config" if ref $args{Config} ne 'HASH';
	die "Bad Model" unless ref $args{DBICSchema};
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
	$heap->{model} = $args->{DBICSchema};
	$heap->{interval} = $args->{Config}{interval} || 3600;
	$heap->{authorized} = $args->{Config}{authorized} || [];

	# Schedule the Analysis
	$kernel->yield('analyze');
}

# Discover Authorized and Unauthorized servers
sub analyze {
	my ( $kernel,$heap ) = @_[KERNEL,HEAP];

	$kernel->post( $heap->{log} => debug => "server::authorized running analysis" );

	my $check_ts = DateTime->now()->subtract( seconds => $heap->{interval} );
	my $srv_rs = $heap->{model}->resultset('server')->search;

	my $updates = 0;
	while( my $srv = $srv_rs->next ) {
		my $doUpdate = 0;
		if( grep { $srv->ip eq $_ } @{ $heap->{authorized} } ) {
			if( ! $srv->is_authorized ) {
				$srv->is_authorized( 1 );
				$doUpdate = 1;
			}
		}
		else {
			if( $srv->is_authorized ) {
				$srv->is_authorized( 0 );
				$doUpdate = 1;
			}
		}
		if( $doUpdate ) {
			$srv->update;
			if( $srv->first_ts > $check_ts ) {
				$kernel->yield( 'notify' => $srv );
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



1;


