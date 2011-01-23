package dns::monitor::Controller::query;
use Moose;
use DateTime;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

dns::monitor::Controller::query - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

	my $from = DateTime->now()->subtract( days => 1 );
	
	$c->stash->{new_rs} = $c->model('DB::packet::record::question')->search(
		{ first_ts => { '>', $from } },
		{
	#		order_by => { -desc=> 'first_ts' },
		},
	);

	$c->stash->{most_asked_rs} = $c->model('DB::packet::record::question')->search(
		{ last_ts => { '>', $from } },
		{
	#		order_by => { -desc=> 'first_ts' },
		},
	);
	$c->stash->{template} = '/query/index.mas';
}



=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
