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

	$c->forward( '/client/overview' );
}

=head2 overview

Display Client Overview

=cut
 
sub overview :Path('overview') :Args(0) {
	my ($self,$c) = @_;

	my $sth = $c->dbconn->run( fixup => sub {
		my $lsh = $_->prepare(q{
			select
				CAST(regexp_replace( CAST( ip | inet '0.0.0.255' as TEXT), '255/32$', '0') || '/24' as inet) as network,
				count(1) as clients,
				to_char(min(first_ts), 'YYYY-MM-DD HH24:MI') as first_ts,
				to_char(max(last_ts), 'YYYY-MM-DD HH24:MI') as last_ts,
				bool_or(is_local) as is_local
			from client
			group by ip | inet '0.0.0.255'
		});
		$lsh;
	});
	$sth->execute();

	my @networks = ();
	my $total_clients = 0;
	while( my $row = $sth->fetchrow_hashref ) {
		push @networks, $row;
		$total_clients += $row->{clients};
	}

	$c->stash->{template} = '/client/overview.mas';
	$c->stash->{networks} = \@networks;
	$c->stash->{total_clients} = $total_clients;
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
