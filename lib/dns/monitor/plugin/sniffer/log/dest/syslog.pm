package dns::monitor::plugin::sniffer::log::dest::syslog;

use Moose;
use Sys::Syslog;

extends 'dns::monitor::plugin::sniffer::log';

has facility => (
);

has priority => (
);


after START => sub {
	my ($self) = @_[OBJECT];

	openlog( 'dnsmonitor', '', $self->config->{facility} );
};

sub write {
	my ($self,$line) = @_;

	syslog( $self->config->{priority}, $line );
}

with 'dns::monitor::plugin::sniffer::log::dest';

no Moose;
__PACKAGE__->meta->make_immutable();
1;
