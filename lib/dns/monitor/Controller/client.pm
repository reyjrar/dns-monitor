package dns::monitor::Controller::client;
use Moose;
use DateTime;
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
				regexp_replace( CAST( ip | inet '0.0.0.255' as TEXT), '255/32$', '0') as network_addr,
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

=head2 network

Display Client Network Overview

=cut
 
sub network :Path('network') :Args(1) {
	my ($self,$c,$rawnet) = @_;

	# Strip any non IPv4 / IPv6 Characters
	$rawnet =~ s/[^0-9A-F:\.]+//g;

	# By Client
	my $sth = $c->dbconn->run( fixup => sub {
		my $lsh = $_->prepare(qq{
			select
				c.ip,
				c.id,
				sum(s.answers) as answers,
				sum(s.queries) as queries,
				sum(s.errors) as errors,
				sum(s.nx) as nx,
				min(s.day) as first_day,
				max(s.day) as last_day,
				bool_or(c.is_local) as is_local
			from client_stats s
				inner join client c on s.client_id = c.id
				where c.ip << inet '$rawnet/24'
			group by c.id, c.ip
		});
		$lsh;
	});
	$sth->execute();

	my @ips = ();
	my $total_clients = 0;
	while( my $row = $sth->fetchrow_hashref ) {
		push @ips, $row;
		$total_clients++;
	}
	
	# Graph Data!
	my $gsth = $c->dbconn->run( fixup => sub {
		my $lsh = $_->prepare(qq{
			select
				s.day,
				sum(s.answers) as answers,
				sum(s.queries) as queries,
				sum(s.errors) as errors,
				sum(s.nx) as nx
			from client_stats s
				inner join client c on c.id = s.client_id
				where c.ip << inet '$rawnet/24'
			group by s.day
			order by s.day asc
		});
		$lsh;
	});
	$gsth->execute();
	my %graph_data = ();
	while( my $row = $gsth->fetchrow_hashref ) {
		my ($y,$m,$d) = split /\-/, $row->{day};
		my $dt = DateTime->new( year => $y, month => $m, day => $d );
		my $i = $dt->epoch * 1000;
		push @{ $graph_data{answers} }, qq{ [ $i, $row->{answers} ] };
		push @{ $graph_data{queries} }, qq{ [ $i, $row->{queries} ] };
		push @{ $graph_data{errors} }, qq{ [ $i, $row->{errors} ] };
		push @{ $graph_data{nx} }, qq{ [ $i, $row->{nx} ] };
	}

	$c->stash->{template} = '/client/network.mas';
	$c->stash->{ips} = \@ips;
	$c->stash->{total_clients} = $total_clients;
	$c->stash->{graph_data} = \%graph_data;
	$c->stash->{network} = $rawnet;
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

=head2 view 

View a Single Client Statistics

=cut

sub view :Path('view') :Args(1) {
	my ($self,$c,$id) = @_;

	my $client = $c->model('DB::client')->find( $id );

	if( !defined $client ) {
		$c->forward('/client/overview');
		$c->detach();
	}

	my $stats_rs = $c->model('DB::client::stats')->search(
		{ client_id => $id },
		{ order_by => { -asc => 'day' } }
	);

	if( !defined $stats_rs || $stats_rs->count < 1 ) {
		$c->forward('/client/overview');
		$c->detach;
	}

	my $query_rs = $c->model('DB::packet::meta::question')->search(
		{ 'query.client_id' => $id },
		{
			join => [qw(query question)],
			select => [
				'query.server_id',
				'me.question_id',
				{ count => 1, -as => 'queries' },
				{ min => 'query.query_ts', -as => 'first_ts' },
				{ max => 'query.query_ts', -as => 'last_ts' },
			],
			as => [qw(
				server_id question_id queries first_ts last_ts
			)],
			group_by => [qw(query.server_id me.question_id)],
			rows => 500,
		},
	);

	$c->stash->{template} = '/client/view.mas';
	$c->stash->{client} = $client;
	$c->stash->{stats_rs} = $stats_rs;
	$c->stash->{query_rs} = $query_rs;
}

=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
