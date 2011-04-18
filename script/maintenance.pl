#!/usr/bin/env perl
#
# Call the plugin cleanup() routines
#
# Code by Brad Lhotsky <brad@divisionbyzero.net>
#
$|++;
use strict;
use warnings;
use FindBin;
use DBI;
use DBD::Pg qw(:async);
use Try::Tiny;
use Getopt::Std;

# File name processing
use File::Spec;
use File::Basename;
# Config Parsing
use YAML;
# POE Environment
use lib "$FindBin::Bin/../lib";

# Option Handling
my %OPT = ();
getopts( 'q', \%OPT );

#------------------------------------------------------------------------#
# Locate all the necessary directories
my @BasePath = File::Spec->splitdir( $FindBin::Bin );
pop @BasePath;
my %DIRS = (
	'base'	=> File::Spec->catdir( @BasePath ),
	'lib'	=> File::Spec->catdir( @BasePath, 'lib' ),
	'etc'	=> File::Spec->catdir( @BasePath, 'conf' ),
	'cache'	=> File::Spec->catdir( @BasePath, 'cache' ),
);

#------------------------------------------------------------------------#
# Load Configuration
my $configFile = File::Spec->catfile( $DIRS{base}, 'dns_monitor.yml' );
my $CFG = YAML::LoadFile( $configFile ) or die "unable to load $configFile: $!\n";

# Connect to the Database:
my $dbh = DBI->connect( $CFG->{db}{dsn}, $CFG->{db}{user}, $CFG->{db}{pass} );

# Find all the plugins with keep_for set
foreach my $plugin (sort keys %{ $CFG->{plugins} } ) {
	print "checking $plugin .. " unless $OPT{q};
	my $pluginConf = $CFG->{plugins}{$plugin};
	my $prefix = $plugin;
	$prefix =~ s/\:\:/\_/g;

	my $keep_for = exists $pluginConf->{keep_for} ? $pluginConf->{keep_for} : undef;

	if( !defined $keep_for ) {
		print "no keep_for set, skipping.\n" unless $OPT{q};
		next;
	}

	if( $keep_for =~  /[^a-z0-9 ]+/ ) {
		# Invalid
		print "invalid interval ($keep_for), skipping.\n" unless $OPT{q};
		next;
	}

	# Prepare the Clean Up
	my $sql = qq{ select ${prefix}_cleanup( ? ) };
	print "preparing '$sql' with arg '$keep_for' .." unless $OPT{q};
	my $sth = $dbh->prepare( $sql, {pg_async => PG_ASYNC} );

	try { 
		$sth->execute( $keep_for );
	} catch {
		print "error cleaning up: ($_)" unless $OPT{q};
	};

	while ( ! $sth->pg_ready() ) {
		sleep 2;
		print '.';
	}

	print " done.\n" unless $OPT{q};
}
