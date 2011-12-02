package dns::monitor::core::logger;

use Moose;

sub log {
	my ($self,$level,@messages) = @_;
	$self->post( $self->config->{LogSID}, $level => join( ': ', $self->name $_ ) ) for @messages;
}
no Moose;
__PACKAGE__->make_immutable;
