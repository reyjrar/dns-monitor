package dns::monitor::Controller::server;
use Moose;
use namespace::autoclean;
use DateTime;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

dns::monitor::Controller::server - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

}

=head2 stats

Display Statistics for the Date

=cut

sub stats_index :Path('stats') :Args(0) {
	my ($self,$c) = @_;
	
	my $day = DateTime->now->ymd;

	$c->forward( '/server/stats', $day );
	$c->detach;
}

sub stats :Path('stats') :Args(1) {
	my ( $self, $c, $day ) = @_;
	if( $day !~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/ ) {
		$day = DateTime->now->ymd;
	}

	# Don't need sorting, dataTables does that
	my $stats_rs = $c->model('DB::server::stats')->search(
		{ day => $day },
		{ prefetch => 'server' }
	);

	$c->stash->{date} = $day;
	$c->stash->{server_stats_rs} = $stats_rs;
	$c->stash->{template} = '/server/stats.mas';
}


=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
