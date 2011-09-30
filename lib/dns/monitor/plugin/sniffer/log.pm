package dns::monitor::plugin::sniffer::log;

use Digest::SHA qw( sha1_hex );
use MooseX::POE;

extends qw(dns::monitor::core::plugin);

with qw(
	dns::monitor::core::util
	dns::monitor::plugin::sniffer
);

has cache => ( isa => 'HashRef', is => 'rw', default => sub { {} } );

event process => sub {
	my ($self,$dnsp,$info) = @_[OBJECT,ARG0,ARG1];

	# Establish UUID
	my $uuid = sha1_hex join(';', 
							$info->{server}, $info->{server_port},
							$info->{client}, $info->{client_port},
							$dnsp->header->id
	); 
};

event flush_entry => sub {
	my ($self,$entry) = @_[OBJECT,ARG0];

	my $line = '';
	$self->write( $line );
};

before maintenance => sub {
	my ($self) = @_[OBJECT];
};

no MooseX::POE;
__PACKAGE__->make_immutable;
1;
