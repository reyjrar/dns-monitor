package dns::monitor::core::plugin;

use MooseX::POE;

with qw(MooseX::POE::Aliased);

has name => ( isa => 'Str', is => 'ro', default => sub { 'generic' } );
has config => ( isa => 'HashRef', is => 'ro', default => sub { {} } );
has log_alias => ( isa => 'HashRef', is => 'ro', default => sub { 'log' } );
has interval => ( isa => 'PositiveInt', is => 'ro', default => sub { 600 } );

sub START {
	my ($self) = @_[OBJECT];

	$self->alias( $self->name );
	$self->delay_add( maintenance => $self->interval );
}

event maintenance => sub {
	my ($self,$kernel) = @_[OBJECT,KERNEL];

	$kernel->post( $self->log_alias => debug => $self->name . "[maintenance] - invoked" );
	$self->delay_add( maintenance => $self->interval );
};

no MooseX::POE;
__PACKAGE__->meta->make_immutable();
1;
