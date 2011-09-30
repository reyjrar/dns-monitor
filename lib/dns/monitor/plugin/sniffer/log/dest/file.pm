package dns::monitor::plugin::sniffer::log::dest::file;

use Moose;

extends 'dns::monitor::plugin::sniffer::log';

sub write {
	my ($self,$line) = @_;

	print $line,"\n";
}

with 'dns::monitor::plugin::sniffer::log::dest';

no Moose;
__PACKAGE__->meta->make_immutable();
1;
