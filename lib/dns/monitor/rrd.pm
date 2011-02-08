package dns::monitor::rrd;


use RRDs;
use File::Spec;
use File::Basename;
use Carp;

use dns::monitor::rrd::instance;

use strict;
use warnings;

=head1 NAME
	dns::monitor::rrd = encapsulate RRD functions

=head1 SYNOPSIS

	my $RRDNetwork = dns::monitor::rrd->new( 'network::traffic', 
		RootDir => '/var/rrd'
		DataSources => {	
				packets => q{GAUGE 600 0 U},
				bytes => q{GAUGE 600 0 U},
		},
		Step => 60,
		Archives => [qw(
			RRA:AVERAGE:0.5:1:576	
			RRA:AVERAGE:0.5:8:576	
			RRA:AVERAGE:0.5:32:576	
			RRA:AVERAGE:0.5:372:576	
		)]
	);

	my $instance = $RRDNetwork->find_or_create( [qw(hosts myhost tcp)] );

	$instance->update( packets => 1, bytes => 512 );

=cut

sub new {
	my ( $meta, $class, %Config ) = @_;
	my $self = bless {}, ref $meta ? ref $meta : $meta;

	die "RootDir not set." unless exists $Config{RootDir} && length $Config{RootDir};
	my $root = File::Spec->rel2abs( $Config{RootDir} );

	mkdir( $Config{RootDir}, 0755 ) unless -d $Config{RootDir};

	# Build the RRD Path
	my @rrdpath = split('\:\:', $class);
	my $dir = $root;
	foreach my $sub (@rrdpath) {
		$dir = File::Spec->catdir( $dir, $sub );
		mkdir( $dir, 0755 ) unless -d $dir;
	}

	# Store the base directory
	$self->{_rrd_base} = $dir;
	$self->{_data_sources} = $Config{DataSources};
	$self->{_archives} = $Config{Archives} if exists $Config{Archives};
	$self->{_step} = exists $Config{Step} && $Config{Step} > 0 ? $Config{Step} : 60;

	return $self;

}

sub find_or_create {
	my ($self,$path) = @_;
	
	my $file = pop @{ $path };
	my $rrdfile = File::Spec->catfile( $self->{_rrd_base}, @$path, "$file.rrd" );
	my $instance = undef;
	if( -f $rrdfile ) {
		$instance = dns::monitor::rrd::instance->from_file( $rrdfile );
	}
	else {
		my %opts = (
			File => $rrdfile,
			DataSources => $self->{_data_sources},
			Step => $self->{_step},
		);
		$opts{Archives} = $self->{_archives} if exists $self->{_archives};
		$instance = dns::monitor::rrd::instance->new( %opts );
	}
	return $instance;
}

# Return True;
1;
