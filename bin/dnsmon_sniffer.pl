#!/usr/bin/env perl
#
# Use PoCo::Pcap to analyze DNS Packets for
# potential problems with the DNS infrastructure.
#
# Code by Brad Lhotsky <brad@divisionbyzero.net>
#

use strict;
use warnings;
use FindBin;
use Getopt::Std;

# Add local lib path
use lib "$FindBin::Bin/../lib";

# File name processing
use File::Spec;
use File::Basename;
# Config Parsing
use YAML;
# Other Essentials
use DBIx::Connector;
use Daemon::Daemonize qw( check_pidfile write_pidfile daemonize );
# POE Environment
sub POE::Kernel::ASSERT_DEFAULT () { 1 } 
use EV;
use POE qw(
	Component::Logger
	Component::dns::monitor::sniffer
);
#------------------------------------------------------------------------#
# Argument handling
my %OPTS=();
getopts('d',\%OPTS);


#------------------------------------------------------------------------#
# Locate all the necessary directories
my @BasePath = File::Spec->splitdir( $FindBin::Bin );
pop @BasePath;
my %DIRS = (
	'base'	=> File::Spec->catdir( @BasePath ),
	'lib'	=> File::Spec->catdir( @BasePath, 'lib' ),
	'etc'	=> File::Spec->catdir( @BasePath, 'conf' ),
	'cache'	=> File::Spec->catdir( @BasePath, 'cache' ),
	'db'	=> File::Spec->catdir( @BasePath, 'cache', 'db' ),
	'rrd'	=> File::Spec->catdir( @BasePath, 'cache', 'rrd' ),
);

#------------------------------------------------------------------------#
# Load Configuration
my $configFile = File::Spec->catfile( $DIRS{base}, 'dns_monitor.yml' );
my $CFG = YAML::LoadFile( $configFile ) or die "unable to load $configFile: $!\n";
$DIRS{state} = $CFG->{statedir};

#------------------------------------------------------------------------#
# Daemonize
if( !$OPTS{d} ) {
	my $base = basename $0;
	mkdir $DIRS{state}, 0755 unless -d $DIRS{state};
	my $PIDFILE = File::Spec->catfile( $DIRS{state}, $base . '.pid' );

	my $pid = check_pidfile( $PIDFILE );
	if( $pid > 0 ) {
		warn "$base - another process is currently running ($pid)\n";
		exit 1;
	}
	
	daemonize( chdir => $DIRS{base}, close => 'std' );
	write_pidfile( $PIDFILE );
	$poe_kernel->has_forked();
}

# Handle interrupts gracefully
$SIG{INT} = sub { exit };

# Connect to the Database:
my $dbConn = DBIx::Connector->new( $CFG->{db}{dsn}, $CFG->{db}{user}, $CFG->{db}{pass},
	{ RaiseError => 0 } );

#------------------------------------------------------------------------#
# POE Environment Setup

#
# Setup the Logger
POE::Component::Logger->spawn(
	Alias		=> 'log',
	ConfigFile	=> $CFG->{log_cfg},
);

#
# Start Packet Capturing
POE::Component::dns::monitor::sniffer->spawn(
	Config	=> $configFile,
	DBH => $dbConn,
	Plugins => $CFG->{plugins},
	PcapOpts => $CFG->{pcap},
	RRDOpts => $CFG->{rrd},
);

#------------------------------------------------------------------------#
# Run the POE Sessions
#------------------------------------------------------------------------#
POE::Kernel->run;

#------------------------------------------------------------------------#
exit 0;
