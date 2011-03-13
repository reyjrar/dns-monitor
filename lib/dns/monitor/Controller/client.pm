package dns::monitor::Controller::client;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

dns::monitor::Controller::client - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched dns::monitor::Controller::client in client.');
}

=head2 stats

Display Statistics for the Date

=cut

sub stats_index :Path('stats') :Args(0) {
	my ($self,$c) = @_;
	
	my $day = DateTime->now('time_zone' => $c->config->{time_zone})->ymd;

	$c->forward( '/client/stats', $day );
	$c->detach;
}

sub stats :Path('stats') :Args(1) {
	my ( $self, $c, $day ) = @_;
	if( $day !~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/ ) {
		$day = DateTime->now( time_zone => $c->config->{time_zone})->ymd;
	}

	# Don't need sorting, dataTables does that
	my $stats_rs = $c->model('DB::client::stats')->search(
		{ day => $day },
		{ prefetch => 'client' }
	);

	$c->stash->{date} = $day;
	$c->stash->{client_stats_rs} = $stats_rs;
	$c->stash->{template} = '/client/stats.mas';
}

=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
