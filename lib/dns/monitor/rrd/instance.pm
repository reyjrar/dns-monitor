package dns::monitor::rrd::instance;

use strict;
use warnings;
use File::Spec;
use File::Basename;
use RRDs;
use Carp;

sub new {
    my ($meta,%opts) = @_;
    my $self = bless {}, ref $meta ? ref $meta : $meta;

    # Defaults
    my %Config = (
        # Assumes 60 second steps
        Archives => [
            q{RRA:AVERAGE:0.5:2:750},       # 25 Hours (every 2 minutes)
            q{RRA:AVERAGE:0.5:15:768},      # 8 Days (every 15 minutes)
            q{RRA:AVERAGE:0.5:60:768},      # 32 days (every hour)
            q{RRA:AVERAGE:0.5:480:1116},    # 372 days (every 8 hours)
        ],
        %opts
    );
    croak "Step required but invalid" unless defined $Config{Step} && $Config{Step} > 0;
    croak "File required but null" unless defined $Config{File} && length $Config{File};
    croak "DataSources required but null" unless defined $Config{DataSources} && ref $Config{DataSources} eq 'HASH';

    $self->{_file} = $Config{File};
    $self->{_data_sources} = [ sort keys %{ $Config{DataSources} } ];
    $self->{_step} = $Config{Step};

    return $self->_build_rrd( \%Config );
}

sub from_file {
    my ($meta,$file) = @_;
    my $self = bless {}, ref $meta ? ref $meta : $meta;

    croak "file not found: $file $!" unless -f $file;

    # Retrieve information from file
    my ($start,$step,$names,$vals) = RRDs::fetch $file, 'AVERAGE';
    my $hash = RRDs::info $file;
    
    $self->{_file} = $file;
    $self->{_data_sources} = $names;
    $self->{_step} = $hash->{step};

    return $self;
}

sub data_sources {
    my ($self) = @_;

    # Copy
    my @ds = @{ $self->{_data_sources} };

    # return
    return wantarray ? @ds : \@ds;
}

sub step {
    my ($self) = @_;
    return $self->{_step};
}

sub update {
    my ($self,$updates) = @_;
    
    my @data = ( time );
    foreach my $field ( @{ $self->{_data_sources} } ) {
        push @data, $updates->{$field} || 0;
    }
    my $update = join( ':', @data );

    RRDs::update $self->{_file}, $update;
    my $err = RRDs::error;
    if( $err ) {
        carp "error updating $self->{_file}  : $err";
    }
}


# RRD Creation
sub _build_rrd {
    my ($self, $config) = @_;

    return $self if -f $self->{_file};

    # Build the Directory Path
    my $basefile = fileparse( $self->{_file} );
    my @dirs = File::Spec->splitdir( dirname( $self->{_file} ) );
    my $currDir = undef;
    foreach my $dir ( @dirs ) {
        $currDir = defined $currDir ? File::Spec->catdir( $currDir, $dir ) : $dir;
        mkdir( $currDir, 0755 ) unless -d $currDir;
    }

    my @opts = ( q{--step}, $self->{_step} );
    foreach my $field ( sort keys %{ $config->{DataSources} } ) {
        my $def = join( ':', split /\s+/, $config->{DataSources}{$field} );
        push @opts, qq{DS:$field:$def};
    }
    push @opts, @{ $config->{Archives} };
    
    RRDs::create $self->{_file}, @opts;
    my $err = RRDs::error;
    if( $err ) {
        croak "error creating rrd($self->{_file}): $err";
    }

    return $self;
}

# Return True
1;
