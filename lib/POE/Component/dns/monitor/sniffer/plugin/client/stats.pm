package POE::Component::dns::monitor::sniffer::plugin::client::stats;

use strict;
use warnings;
use POE;
use DateTime;

sub spawn {
	my $self = shift;
	my %args = @_;

	die "Bad Config" if ref $args{Config} ne 'HASH';
	die "Bad Model" unless ref $args{DBICSchema};
	die "No Alias" unless length $args{Alias};

	my $sess = POE::Session->create( inline_states => {
		_start	=> sub { $poe_kernel->yield( 'client_stats_start', \%args ); },
		_stop 	=> sub { },
		client_stats_start => \&client_stats_start,
		process => \&process,
	});

	return $sess->ID;
}

sub client_stats_start {
	my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

	$kernel->alias_set( $args->{Alias} );
	
	# Store stuff in the heap
	$heap->{log} = $args->{LogSID};
	$heap->{model} = $args->{DBICSchema};
}

sub process {
	my ( $kernel,$heap,$dnsp,$srv,$cli ) = @_[KERNEL,HEAP,ARG0,ARG1,ARG2];

	my $dt = DateTime->now();
	my $stats = $heap->{model}->resultset('client::stats')->find_or_create(
		{
			client_id	=> $cli->id,
			day 		=> $dt->ymd,
		}
	);	
	# Check for query/response
	if( $dnsp->header->qr ) {
		if ( $dnsp->header->rcode eq 'NOERROR' ) {
			$stats->answers( $stats->answers + 1 );
		}
		elsif( $dnsp->header->rcode eq 'NXDOMAIN' ) {
			$stats->nx( $stats->nx + 1 );
		}
		else {
			$stats->errors( $stats->errors + 1 );
		}
	}
	else {
		$stats->queries( $stats->queries + 1 );
	}
	$stats->update;
}

# Return True
1;
