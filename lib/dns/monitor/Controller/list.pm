package dns::monitor::Controller::list;
use Moose;
use DateTime;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

dns::monitor::Controller::list - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

	my $rs = $c->model('DB::list')->search;
	$c->stash->{list_rs} = $rs->count > 0 ? $rs : undef;
	$c->stash->{template} = '/list/list.mas';
}

=head2 edit

Page to add a new list

=cut

sub edit :Path('edit') :Args(1) {
	my ( $self,$c, $id) = @_;

	$c->stash->{list} = $c->model('DB::list')->find( $id );
	$c->stash->{types} = $c->model('DB::list::type')->search_rs;
	$c->stash->{template} = '/list/edit.mas';
}

=head2 add

Page to add a new list

=cut

sub add :Path('add') :Args(0) {
	my ( $self,$c ) = @_;

	$c->stash->{list} = undef;
	$c->stash->{types} = $c->model('DB::list::type')->search_rs;
	$c->stash->{template} = '/list/edit.mas';
}

=head2 save

saves a new/updated list source

=cut

sub save :Path('save') :Args(0) {
	my ($self,$c) = @_;

	my %params = %{ $c->req->params() };
	my $list = undef;
	if( exists $params{id} ) {
		# Editing
		$list = $c->model('DB::list')->find( $params{id} );
		$c->flash->{notice} = "list " . $list->name . " updated.";
	}
	else {
		# Creating
		if( ! exists $params{name} || length $params{name} < 3 ) {
			push @{ $c->flash->{errors} }, 'invalid name parameter';
			$c->detach( '/list/index' );
			return 0;
		}
		if( ! exists $params{list_type} || $params{list_type} <= 0 ) {
			push @{ $c->flash->{errors} }, 'invalid type parameter';
			$c->detach( '/list/index' );
			return 0;
		}
		$list = $c->model('DB::list')->create( {
				name => $params{name},
				type_id => $params{list_type},
		});
		$c->flash->{notice} = "list " . $list->name . " created.";
	}
	# Updates
	$list->type_id( $params{list_type} );
	$list->track( $params{track} );
	$list->can_refresh( $params{can_refresh} );
	$list->refresh_url( $params{refresh_url} );
	$list->refresh_every( $params{refresh_every} ) if exists $params{refresh_every} && length $params{refresh_every};

	# Handle the file upload
	my $source = $c->req->upload('source_file');
	if( defined $source ) {
		$c->log->debug('got source_file');
		my $fh = $source->fh;
		$c->model('DB::list::entry')->search({ list_id => $list->id })->update({ refreshed => 0 });	
		my $now = DateTime->now();
		while( my $line = <$fh> ) {
			$line =~ s/\#.*//;
			$line =~ s/\s+//g;	
			next unless length $line > 3;
			my $zone = $line;
			my $path = join( '.', reverse map { s/\-/_/g; $_ } split /\./, $line);
			my $ent = $c->model('DB::list::entry')->find_or_create({
				list_id => $list->id,
				zone => $zone,
				path => $path
			});
			$ent->refreshed( 1 );
			$ent->last_ts( $now );
			$ent->update;
		}
		$c->model('DB::list::entry')->search({ list_id => $list->id, refreshed => 0 })->delete;	
		$list->refresh_last_ts( $now );
	}
	# Do the update
	$list->update;
	$c->forward('/list/index');
}

sub delete :Path('delete') :Args(1) {
	my ($self,$c,$id) = @_;

	my $list = $c->model('DB::list')->find( $id );
	if( defined $list ) {
		my $name = $list->name();
		$list->delete();
		$c->flash->{notice} = "Deleted list : $name";
	}

	$c->forward('/list/index');
}


=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
