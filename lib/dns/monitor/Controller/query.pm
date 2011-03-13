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

	my $from = DateTime->now(time_zone => $c->config->{time_zone})->subtract( days => 1 );
	
	$c->stash->{new_rs} = $c->model('DB::packet::record::question')->search(
		{ first_ts => { '>', $from }, reference_count => { '>' => 1}  },
		{
	#		order_by => { -desc=> 'first_ts' },
		},
	);

	$c->stash->{most_asked_rs} = $c->model('DB::packet::record::question')->search(
		{ last_ts => { '>', $from } },
		{
			order_by => { -desc=> 'reference_count' },
			rows => 500,
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
