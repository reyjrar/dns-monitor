package POE::Component::dns::monitor::sniffer::plugin::packet::rrd;

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
		_start	=> sub { $poe_kernel->yield( 'rrd_start', \%args ); },
		_stop 	=> sub { },
		packet_logger_start => \&packet_logger_start,
		process => \&process,
	});

	return $sess->ID;
}

sub rrd_start {
	my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

	$kernel->alias_set( $args->{Alias} );
	
	# Store stuff in the heap
	$heap->{log} = $args->{LogSID};
	$heap->{model} = $args->{DBICSchema};
}

sub process {
	my ( $kernel,$heap,$dnsp,$ip,$srv,$cli ) = @_[KERNEL,HEAP,ARG0,ARG1,ARG2,ARG3];

	#my $stats = $heap->{model}->resultset('server::stats')->find_or_create(
	#	{
	#		server_id	=> $srv->id,
	#		day 		=> $dt->ymd,
	#	}
	#);	

	# Check for query/response
	if( $dnsp->header->qr ) { }
}

# Return true;
1;


