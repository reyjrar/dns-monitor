package dns::monitor::Controller::RRD;
use Moose;
use namespace::autoclean;
use File::Spec;
use File::Basename;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

dns::monitor::Controller::RRD - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

my %_spans = (
    halfday => { start => 3600*12, step => 1 },
    day     => { start => 3600*24, step => 60 },
    week    => { start => 3600*24*7, step => 60 },
    month   => { start => 3600*24*30, step => 60 },
);

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched dns::monitor::Controller::RRD in RRD.');
}

sub rrd_base :Chained('/') :PathPart('rrd') :CaptureArgs(1) { 
    my ($self,$c,$span) = @_;

    if( !exists $_spans{$span} ) {
        die "sniffer_base($span): unknown time span";
    }

    my $time = time;
    $c->stash->{graphopts} = {
        start   => $time - $_spans{$span}->{start},
        end     => $time,
        step    => $_spans{$span}->{step},
    };

}

sub sniffer_graph :Chained('rrd_base') :PathPart('sniffer') :Args(1) {
    my ($self,$c,$type) = @_;

    my $rrd_base = File::Spec->catdir( $c->stash->{rrd_base}, 'sniffer' );

    # Type Definition
    my %_defs = (
        dispatch => {
            title => 'dispatches vs packets'
        },
        network => {
            title => 'layer 4 breakdown',
        },
        dns => {
            title => 'dns breakdown',
        },
    );
    if( !exists $_defs{$type} ) {
        die "sniffer_base($type): non-existant type";
    }

    my %opts = %{ $_defs{$type} };

    my @def = ();
    my @art = ();
    if( $type eq 'dispatch' ) {
        push @def, q{DEF:dispatch=} . File::Spec->catfile( $rrd_base, 'dispatch.rrd' ) . ':count:AVERAGE';
        push @def, q{DEF:packet=} . File::Spec->catfile( $rrd_base, 'packet.rrd' ) . ':count:AVERAGE';
        push @art, q{AREA:packet#FFD873:packets processed};
        push @art, q{LINE:dispatch#6977E8:events dispatched};
    
    }
    elsif( $type eq 'network' ) {
        push @def, q{DEF:tcp=} . File::Spec->catfile( $rrd_base, 'tcp.rrd' ) . ':count:AVERAGE';
        push @def, q{DEF:udp=} . File::Spec->catfile( $rrd_base, 'udp.rrd' ) . ':count:AVERAGE';
        push @art, q{AREA:tcp#FFAAAA:tcp packets};
        push @art, q{AREA:udp#AAFFAA:udp packets:STACK};
    }
    elsif( $type eq 'dns' ) {
        push @def, q{DEF:questions=} . File::Spec->catfile( $rrd_base, 'question.rrd' ) . ':count:AVERAGE';
        push @def, q{DEF:answers=} . File::Spec->catfile( $rrd_base, 'answer.rrd' ) . ':count:AVERAGE';
        push @def, q{CDEF:invq=questions,-1,*};
        push @art, q{AREA:invq#41A7E5:questions};
        push @art, q{AREA:answers#79CE83:answers};
    }

    
    # Set the options
    foreach my $option (keys %opts) {
        $c->stash->{graphopts}{$option} = $opts{$option};
    }
    # Add the definitions:
    $c->stash->{graphopts}{defs} = \@def;
    # Add the artifacts:
    $c->stash->{graphopts}{artifacts} = \@art;

    # Display this graph
    $c->detach( '/rrd/display_graph' );
}

sub sniffer_plugins :Chained('rrd_base') :PathPart('plugin') :Args {
    my ( $self, $c, @path ) = @_;

    my $name = join('::', @path);
    my $label = join('_', @path);
    my $rrd_base = File::Spec->catdir( $c->stash->{rrd_base}, 'sniffer' );
    my $file = pop @path;
    $file .= '.rrd';
    my $plugin_rrd = File::Spec->catfile( $rrd_base, 'plugin', @path, $file );
    my $packet_rrd = File::Spec->catfile( $rrd_base, 'packet.rrd' );
    
    if( !-f $plugin_rrd ) {
        die "sniffer_plugins($plugin_rrd) file not found";
    }

    my %opts = ( title => "$name vs packets");
    my @def = ();
    my @art = ();

    push @def, qq{DEF:plugin=$plugin_rrd:count:AVERAGE};
    push @def, qq{DEF:packet=$packet_rrd:count:AVERAGE};
    push @def, qq{CDEF:difference=plugin,packet,-};
    #push @art, qq{AREA:plugin#FFD873:$label processed};
    #push @art, q{LINE:packet#6977E8:packets in};
    push @art, q{AREA:difference#FFAAAA:packets in minus processed};
    
    
    # Set the options
    foreach my $option (keys %opts) {
        $c->stash->{graphopts}{$option} = $opts{$option};
    }
    # Add the definitions:
    $c->stash->{graphopts}{defs} = \@def;
    # Add the artifacts:
    $c->stash->{graphopts}{artifacts} = \@art;

    # Display this graph
    $c->detach( '/rrd/display_graph' );
}

=head2 display_graph

    Renders the image based on the data assembled in the chains.
    
    Usage: $c->detach( '/rrd/display_graph' );

=cut

sub display_graph :Private {
    my ( $self, $c ) = @_;

    my $opts = $c->stash->{graphopts};
    $c->stash->{graph} = [
            '--color' => 'BACK#FFFFFF',
            '--color' => 'CANVAS#FAFEF4',
            '--color' => 'GRID#CCCCCC',
            '--color' => 'MGRID#CCCCCC',
            '--color' => 'FONT#000000',
            '--color' => 'ARROW#FF0000',
            '--color' => 'FRAME#000000',
            '--title' => $opts->{title},
            '--vertical-label' => $opts->{'vertical-label'},
            '--start' => $opts->{start},
            '--step' => $opts->{step},
            @{ $opts->{defs} },
            @{ $opts->{artifacts} },
            "HRULE:0#0000FF"
    ];
}

=head2 auto

Setup Defaults for the RRD Graphing

=cut

sub auto :Private {
    my ( $self, $c) = @_;

    $c->stash->{current_view} = 'RRDGraph';
    my $rrd_base = $c->config->{rrd}{dir};
    if( ! File::Spec->file_name_is_absolute( $rrd_base ) ) {
        $rrd_base = $c->path_to( $rrd_base )->absolute->stringify;
    }
    $c->stash->{rrd_base} = $rrd_base;
    if( ! -d $c->stash->{rrd_base} ) {
        die "rrd/dir not defined in config!";
    }
    return 1;
}


=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
