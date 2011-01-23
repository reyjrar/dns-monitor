package dns::monitor::rrd;


use RRDs;
use File::Spec;
use File::Basename;
use Carp;

use strict;
use warnings;

=head1 NAME
	dns::monitor::rrd = encapsulate RRD functions

=head1 SYNOPSIS

	my $rrd = dns::monitor::rrd->new( 'packet::query',
		RootDir => '/var/rrd'
		Variables => {
			types => {
				names => [qw(A CNAME MX PTR SRV TXT other)],
				data => {	
					packets => [qw(GAUGE 600 0 U)],
					bytes => [qw(GAUGE 600 0 U)],
				},
			},
			opcodes => {
				names => [qw(QUERY UPDATE other)],
				data => {	
					packets => [qw(GAUGE 600 0 U)],
					bytes => [qw(GAUGE 600 0 U)],
				},
			},
		}
		Archives => [qw(
			RRA:AVERAGE:0.5:1:576	
			RRA:AVERAGE:0.5:8:576	
			RRA:AVERAGE:0.5:32:576	
			RRA:AVERAGE:0.5:372:576	
		)]
	);

	$rrd->update( types => {
		A => { packets => 1, bytes => 512 },
		CNAME => { packets => 2, bytes => 1024 },
		...
	});

	$rrd->graph( types => {
		data => 'packets',
	});

=cut

sub new {
	my ( $meta, $class, %opts ) = @_;
	my $self = bless {}, ref $meta ? ref $meta : $meta;

	my %Config = (
		Archives => [qw(
			RRA:AVERAGE:0.5:1:576	
			RRA:AVERAGE:0.5:8:576	
			RRA:AVERAGE:0.5:32:576	
			RRA:AVERAGE:0.5:372:576	
		)],
		%opts
	); 

	die "Variables not properly initialized." unless _config_check_variables( \%Config );
	die "RootDir not set." unless exists $Config{RootDir} && length $Config{RootDir};

	mkdir( $Config{RootDir}, 0755 ) unless -d $Config{RootDir};

	# Build the RRD Path
	my @rrdpath = split('\:\:', $class);
	my $dir = $Config{RootDir};
	foreach my $sub (@rrdpath) {
		$dir = File::Spec->catdir( $dir, $sub );
		mkdir( $dir, 0755 ) unless -d $dir;
	}

	# Store the base directory
	$self->{_rrd_base} = $dir;
	$self->{_variables} = $Config{Variables};

	$self->setup_rrd( @{ $Config{Archives} } );
}

sub setup_rrd {
	my ( $self, @archives ) = @_;

	while( my ($var,$info) = each %{ $self->{_variables} } ) {
		my $dir = File::Spec->catdir( $self->{_rrd_base}, $var );
		mkdir( $dir, 0755 ) unless -d $dir;
		foreach my $name (@{ $info->{names} }) {
			my $rrd = File::Spec->catfile( $dir, $name . '.rrd' );
			$self->{_rrds}->{$var}{$name} = $rrd;
			next if -e $rrd;
			# Build out the RRD
			my @opts = qw(--step 60);
			while( my ($field,$ds_opts) = each %{ $info->{data} } ) {
				push @opts, qq{DS:$field:} . join(':', @{ $ds_opts } );
			}
			push @opts, @{ $self->{_archives} };
			RRDs::create $rrd, @opts;
			my $err = RRDs::error;
			if( $err ) {
				carp "error creating rrd ($rrd): $err";
			}
		}
	}
}

sub step {
	my ($self, $data) = @_;
}

sub _config_check_variables {
	my $href = shift;

	return 0 unless defined $href;
	return 0 unless exists $href->{Variables};
	return 0 unless ref $href->{Variables} eq 'HASH';
	foreach my $name ( keys %{ $href->{Variables} } ) {
		my $var_ref = $href->{Variables}{$name};
		return 0 unless ref $var_ref eq 'HASH';
		return 0 unless exists $var_ref->{names} && ref $var_ref->{names} eq 'ARRAY';
		return 0 unless exists $var_ref->{data} && ref $var_ref->{data} eq 'HASH';
		while( my ( $name, $aref ) = each %{ %$var_ref->{data} } ) {
			return 0 if scalar @{ $aref } != 4;
		}
	}
}


# Return True;
1;
