package POE::Component::dns::monitor::analysis::plugin::client::local;

use strict;
use warnings;
use POE;
use DateTime;
use YAML;
use Net::IP::Resolver;

sub spawn {
	my $self = shift;
	my %args = @_;

	die "Bad Config" if ref $args{Config} ne 'HASH';
	die "Bad Model" unless ref $args{DBICSchema};
	die "No Alias" unless length $args{Alias};

	my $sess = POE::Session->create( inline_states => {
		_start	=> sub { $poe_kernel->yield( 'client_local_start', \%args ); },
		_stop 	=> sub { },
		client_local_start => \&client_local_start,
		analyze => \&analyze,
		notify => \&notify,
	});

	return $sess->ID;
}

sub client_local_start {
	my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

	$kernel->alias_set( $args->{Alias} );
	
	# Store stuff in the heap
	$heap->{log} = $args->{LogSID};
	$heap->{model} = $args->{DBICSchema};
	$heap->{interval} = $args->{Config}{interval} || 3600;
	$heap->{resolver} = Net::IP::Resolver->new();
	my $networks = ref $args->{Config}{clients} eq 'ARRAY' ? $args->{Config}{clients} : undef;

	if( not defined $networks ) {
		$kernel->post( $heap->{log} => 'error' => "No Networks passed to client::local, skipping scheduling" );
	}
	else {
		$heap->{resolver}->add( 'local', @$networks );

		# Schedule the Analysis
		$kernel->yield('analyze');
	}
}

# Discover Authorized and Unauthorized servers
sub analyze {
	my ( $kernel,$heap ) = @_[KERNEL,HEAP];

	$kernel->post( $heap->{log} => debug => "client::local running analysis" );

	my $check_ts = DateTime->now()->subtract( seconds => $heap->{interval} );
	my $cli_rs = $heap->{model}->resultset('client')->search;

	my $updates = 0;
	while( my $cli = $cli_rs->next ) {
		my $doUpdate = 0;
		if( $heap->{resolver}->find_first( $cli->ip ) ) {
			if( ! $cli->is_local ) {
				$cli->is_local( 1 );
				$doUpdate = 1;
			}
		}
		else {
			if( $cli->is_local ) {
				$cli->is_local( 0 );
				$doUpdate = 1;
			}
		}
		if( $doUpdate ) {
			$cli->update;
			if( $cli->first_ts > $check_ts ) {
				$kernel->yield( 'notify' => $cli );
			}
		}
		$updates += $doUpdate;
	}
	$kernel->post( $heap->{log} => debug => "client::local posted $updates updates");

	# Schedule the Analysis
	$kernel->delay_add( analyze => $heap->{interval} );
}

# Notification of Unauthorized Servers
sub notify {
	my ($kernel,$heap,$cli) = @_[KERNEL,HEAP,ARG0];
}

# Return True
1;



1;


