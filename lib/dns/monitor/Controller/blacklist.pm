package dns::monitor::Controller::blacklist;
use Moose;
use DateTime;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

dns::monitor::Controller::blacklist - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

	my $rs = $c->model('DB::blacklist')->search;
	$c->stash->{blacklist_rs} = $rs->count > 0 ? $rs : undef;
	$c->stash->{template} = '/blacklist/list.mas';
}

=head2 edit

Page to add a new blacklist

=cut

sub edit :Path('edit') :Args(1) {
	my ( $self,$c, $id) = @_;

	$c->stash->{blacklist} = $c->model('DB::blacklist')->find( $id );
	$c->stash->{template} = '/blacklist/edit.mas';
}

=head2 add

Page to add a new blacklist

=cut

sub add :Path('add') :Args(0) {
	my ( $self,$c ) = @_;

	$c->stash->{blacklist} = undef;
	$c->stash->{template} = '/blacklist/edit.mas';
}

=head2 save

saves a new/updated blacklist source

=cut

sub save :Path('save') :Args(0) {
	my ($self,$c) = @_;

	my %params = %{ $c->req->params() };
	my $blacklist = undef;
	if( exists $params{id} ) {
		# Editing
		$blacklist = $c->model('DB::blacklist')->find( $params{id} );
		$c->flash->{notice} = "Blacklist " . $blacklist->name . " updated.";
	}
	else {
		# Creating
		if( ! exists $params{name} || length $params{name} < 3 ) {
			push @{ $c->flash->{errors} }, 'invalid name parameter';
			$c->detach( '/blacklist/index' );
			return 0;
		}
		if( ! exists $params{type} || length $params{type} < 3 ) {
			push @{ $c->flash->{errors} }, 'invalid type parameter';
			$c->detach( '/blacklist/index' );
			return 0;
		}
		$blacklist = $c->model('DB::blacklist')->create( {
				name => $params{name},
				type => $params{type},
		});
		$c->flash->{notice} = "Blacklist " . $blacklist->name . " created.";
	}
	# Updates
	$blacklist->type( $params{type} );
	$blacklist->refresh_url( $params{refresh_url} );
	$blacklist->can_refresh( $params{can_refresh} );
	$blacklist->refresh_every( $params{refresh_every} ) if exists $params{refresh_every} && length $params{refresh_every};

	# Handle the file upload
	my $source = $c->req->upload('source_file');
	if( defined $source ) {
		$c->log->debug('got source_file');
		my $fh = $source->fh;
		$c->model('DB::blacklisted')->search({ blacklist_id => $blacklist->id })->update({ blacklist_refreshed => 0 });	
		while( my $line = <$fh> ) {
			$line =~ s/\#.*//;
			$line =~ s/\s+//g;	
			$c->log->debug(qq{attempting to add $line});
			next unless length $line > 3;
			my $zone = $line;
			my $path = join( '.', reverse map { s/\-//g; $_ } split /\./, $line);
			my $bd = $c->model('DB::blacklisted')->find_or_create({
				blacklist_id => $blacklist->id,
				zone => $zone,
				path => $path
			});
			$bd->blacklist_refreshed( 1 );
			$bd->last_ts( DateTime->now() );
			$bd->update;
		}
		$c->model('DB::blacklisted')->search({ blacklist_id => $blacklist->id, blacklist_refreshed => 0 })->delete;	
		$blacklist->refresh_last_ts( DateTime->now() );
	}
	# Do the update
	$blacklist->update;
	$c->forward('/blacklist/index');
}

sub delete :Path('delete') :Args(1) {
	my ($self,$c,$id) = @_;

	my $blacklist = $c->model('DB::blacklist')->find( $id );
	if( defined $blacklist ) {
		my $name = $blacklist->name();
		$blacklist->delete();
		$c->flash->{notice} = "Deleted Blacklist : $name";
	}

	$c->forward('/blacklist/index');
}


=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
