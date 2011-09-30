package dns::monitor::plugin::sniffer::log::dest::file;

use Moose;

extends 'dns::monitor::plugin::sniffer::log';

with 'dns::monitor::plugin::sniffer::log::dest';

sub write {
	my ($self,$line) = @_;

	print $line,"\n";
}

no Moose;
__PACKAGE__->meta->make_immutable();
1;
