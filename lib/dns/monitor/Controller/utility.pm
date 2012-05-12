package dns::monitor::Controller::utility;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

dns::monitor::Controller::utility - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = '/utility/index.mas';
}

=head2 reverse

Handle fake reverses

=cut 

sub reverse_blank :Path('reverse') :Args(0) {
    my ($self, $c ) = @_;


    my $params = $c->req->params;

    if( exists $params->{ip} && length $params->{ip} ) {
        $c->stash->{ip} = $params->{ip};
        $c->stash->{forwards} = $c->model('db::packet::record::answer')->search(
            {   class => 'IN', type => 'A', value => $params->{ip} },
        );
    }
    $c->stash->{template} = '/utility/reverse.mas';
}




=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
