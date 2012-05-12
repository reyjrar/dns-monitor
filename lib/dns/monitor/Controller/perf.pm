package dns::monitor::Controller::perf;
use Moose;
use namespace::autoclean;
use File::Spec;
use File::Find::Rule;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

dns::monitor::Controller::perf - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = '/perf/index.mas';
}

sub sniffer :Path('sniffer') :Args(0) {
    my ($self, $c) = @_;

    # Find Plugin Graphs
    my $rrd_base = $c->config->{rrd}{dir};
    if( ! File::Spec->file_name_is_absolute( $rrd_base ) ) {
        $rrd_base = $c->path_to( $rrd_base )->absolute->stringify;
    }
    my $plugin_dir = File::Spec->catdir( $rrd_base, qw(sniffer plugin) );
    my @plugins = ();

    foreach my $rrd ( File::Find::Rule->file()->name('*.rrd')->in( $plugin_dir ) ) {
        my ($name) = ($rrd =~ m|plugin/(.*)\.rrd|);
        push @plugins, $name;
    }
    $c->stash->{plugins} = \@plugins;
    $c->stash->{template} = '/perf/sniffer.mas';
}

sub sniffer_detail :Path('sniffer/details') :Args(1) {
    my ($self,$c,$type) = @_;

    my @types = qw(dispatch network dns);
    die "invalid sniffer detail type ($type)" unless $type ~~ @types;

    $c->stash->{type} = $type;
    $c->stash->{template} = '/perf/sniffer_detail.mas';
}

=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
