package dns::monitor::plugin::sniffer::log::dest::syslog;

use Moose;
use Sys::Syslog;

extends 'dns::monitor::plugin::sniffer::log';

has facility => (
);

has priority => (
);

sub write {
	my ($self,$line) = @_;

	print $line,"\n";
}

with 'dns::monitor::plugin::sniffer::log::dest';

no Moose;
__PACKAGE__->meta->make_immutable();
1;
