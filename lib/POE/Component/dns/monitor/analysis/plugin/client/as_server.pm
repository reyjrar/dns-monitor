package POE::Component::dns::monitor::analysis::plugin::client::as_server;

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
	$heap->{dbh} = $args->{DBH};
	$heap->{interval} = $args->{Config}{interval} || 3600;

	# Schedule the Analysis
	$kernel->yield('analyze');
}

# Discover Authorized and Unauthorized servers
sub analyze {
	my ( $kernel,$heap ) = @_[KERNEL,HEAP];

	$kernel->call( $heap->{log} => debug => "client::as_server running analysis" );

	my %SQL = (
		check => q{select client.id as client_id, server.id as server_id
					from client
						inner join server on client.ip = server.ip
					where client.role_server_id is null
		},
		update => q{update client set role_server_id = ? where id = ? },
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
		$STH{update}->execute( $ent->{server_id}, $ent->{client_id} );
		$updates++;
	}
	$kernel->post( $heap->{log} => debug => "client::as_server posted $updates updates");

	# Schedule the Analysis
	$kernel->delay_add( analyze => $heap->{interval} );
}

# Return True
1;
