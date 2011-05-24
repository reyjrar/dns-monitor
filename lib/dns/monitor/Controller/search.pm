package dns::monitor::Controller::search;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

dns::monitor::Controller::search - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

	my %dispatch = (
		'clients-asking'	=> '/search/clients_asking',
		'query-asked'		=> '/search/query_asked',
	);

	my $params = $c->req->params();
	if( exists $params->{search_type} && exists $dispatch{$params->{search_type}} ) {
		$c->detach( $dispatch{$params->{search_type}}, $params->{search_value} )
			if exists $params->{search_value} && defined $params->{search_value};
	} 

	$c->flash->{notice} = 'invalid search parameters';
	$c->forward( '/index' );
}

sub clients_asking :Path('clients-asking') :Args(1) {
	my ($self,$c,$query) = @_;

	$c->stash->{template} = '/search/clients-asking.mas';
	$c->stash->{query} = $query;
}

sub query_asked :Path('query-asked') :Args(1) {
	my ($self,$c,$query) = @_;

	$c->stash->{template} = '/search/query-asked.mas';
	$c->stash->{query} = $query;
}

=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
