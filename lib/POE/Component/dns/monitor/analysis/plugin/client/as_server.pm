package POE::Component::dns::monitor::analysis::plugin::client::as_server;

use strict;
use warnings;
use POE;

sub spawn {
	my $self = shift;
	my %args = @_;

	die "Bad Config" if ref $args{Config} ne 'HASH';
	die "Bad Model" unless ref $args{DBICSchema};
	die "No Alias" unless length $args{Alias};

	my $sess = POE::Session->create( inline_states => {
		_start	=> sub { $poe_kernel->yield( 'client_as_server_start', \%args ); },
		_stop 	=> sub { },
		client_as_server_start => \&client_as_server_start,
		analyze => \&analyze,
	});

	return $sess->ID;
}

sub client_as_server_start {
	my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

	$kernel->alias_set( $args->{Alias} );
	
	# Store stuff in the heap
	$heap->{log} = $args->{LogSID};
	$heap->{model} = $args->{DBICSchema};
	$heap->{interval} = $args->{Config}{interval} || 3600;

	# Schedule the Analysis
	$kernel->yield('analyze');
}

# Discover Authorized and Unauthorized servers
sub analyze {
	my ( $kernel,$heap ) = @_[KERNEL,HEAP];

	$kernel->post( $heap->{log} => debug => "client::as_server running analysis" );

	my $cli_rs = $heap->{model}->resultset('client')->search(
		{ 'role_server_id' => { '!=' => undef } },
		{
			prefetch => 'server_by_ip',
		}
	);

	my $updates = 0;
	while( my $cli = $cli_rs->next ) {
		my $srv = $cli->server_by_ip;
		if( defined $srv ) {
			$cli->role_server_id( $srv->id );
			$cli->update;
			$updates++;
		}
	}
	$kernel->post( $heap->{log} => debug => "client::as_server posted $updates updates");

	# Schedule the Analysis
	$kernel->delay_add( analyze => $heap->{interval} );
}

# Return True
1;



1;


