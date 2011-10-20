package dns::monitor::Controller::search;
use Moose;
use namespace::autoclean;
use DateTime::Format::Pg;

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
		'zone-tree'			=> '/search/zone_tree',
	);

	my $params = $c->req->params();
	if( exists $params->{search_type} && exists $dispatch{$params->{search_type}} ) {
		$c->stash->{query} = $params->{search_value};
		$c->detach( $dispatch{$params->{search_type}})
			if exists $params->{search_value} && defined $params->{search_value};
	} 

	$c->flash->{notice} = 'invalid search parameters';
	$c->forward( '/index' );
}

sub clients_asking :Path('clients-asking') :Args(0) {
	my ($self,$c) = @_;

	my @parts = split /\s+/, $c->stash->{query};
	#my @parts = map { s/[^a-zA-Z0-9\_\-\.]//g; $_ } split /\s+/, $query;
	my %parameters = ();

	if( @parts == 3 ) {	
		%parameters = (
			class	=> uc $parts[0],
			type 	=> uc $parts[1],
			name	=> $parts[2],
		);
	}
	elsif( $parts[0] =~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ ) {
		%parameters = (
			class	=> 'IN',
			type	=> 'PTR',
			name	=> $parts[0],
		);
	}
	else {
		%parameters = (
			class	=> 'IN',
			type	=> 'A',
			name	=> $parts[0],
		);
	}
	my $question = $c->model('db::packet::record::question')->find(\%parameters);

	# Detach if nothing found
	$c->detach( '/search/nothing_found' ) unless defined $question;
	
	my $sth = $c->dbconn->run( fixup => sub {
		my $sth = $_->prepare(q{
			select
				ip as client, min(q.query_ts) as first, max(q.query_ts) as last, count(1) as count
			from
				packet_meta_question mq
				inner join packet_query q on mq.query_id = q.id
				inner join client c on q.client_id = c.id
			where
				mq.question_id = ?
			group by ip
		});
	});

	my @results = ();
	$sth->execute( $question->id );
	while( my $row = $sth->fetchrow_hashref ) {
		push @results, $row;
	}

	$c->stash->{template} = '/search/clients-asking.mas';
	$c->stash->{question} = $question;
	$c->stash->{results} = \@results;
}

sub query_asked :Path('query-asked') :Args(0) {
	my ($self,$c) = @_;

	my @parts = map { s/[^a-zA-Z0-9\_\-\.]//g; $_ } split /\s+/, $c->stash->{query};
	my %parameters = ();

	if( @parts == 3 ) {	
		%parameters = (
			class	=> uc $parts[0],
			type 	=> uc $parts[1],
			name	=> $parts[2],
		);
	}
	elsif( $parts[0] =~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ ) {
		%parameters = (
			class	=> 'IN',
			type	=> 'PTR',
			name	=> $parts[0],
		);
	}
	else {
		%parameters = (
			class	=> 'IN',
			type	=> 'A',
			name	=> $parts[0],
		);
	}
	my $question = $c->model('db::packet::record::question')->find(\%parameters);

	$c->stash->{template} = '/search/query-asked.mas';
}

sub zone_tree :Path('zone-tree') :Args(0) {
	my ($self,$c) = @_;

	$c->stash->{template} = '/search/zone-tree.mas';
}

sub nothing_found :Path('nothing') Args(0) {
	my ($self,$c) = @_;

	$c->stash->{template} = '/search/nothing.mas';
}

=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
