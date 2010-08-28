package dns::monitor::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

dns::monitor::Controller::Root - Root Controller for dns::monitor

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

	$c->stash->{template} = '/index.mas';
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'not yet implemented' );
    $c->response->status(404);
}

=head2 auto

Root Auto global settings

=cut

sub auto :Private {
	my ( $self, $c ) = @_;

	my $args = $c->req->params;

	if( exists $args->{debug} ) {
		if ( $args->{debug} eq 'enable' ) {
			$c->session->{debug} = 1;
		}
		else {
			$c->session->{debug} = 0;
		}
	}
	return 1;
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
