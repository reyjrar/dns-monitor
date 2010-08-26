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

# Add local lib path
use lib "$FindBin::Bin/../lib";

# File name processing
use File::Spec;
use File::Basename;
# Config Parsing
use YAML::Syck;
$YAML::Syck::ImplicitTyping = 1;
# POE Environment
sub POE::Kernel::ASSERT_DEFAULT () { 1 } 
use EV;
use POE qw(
	Loop::EV
	Component::Daemon
	Component::Logger
	Component::dns::monitor::sniffer
);

# DBIx::Class
use dns::monitor::Schema;

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
my $CFG = LoadFile( $configFile ) or die "unable to load $configFile: $!\n";

# Connect to the Database:
my $schema = dns::monitor::Schema->connect( $CFG->{db}{dsn}, $CFG->{db}{user}, $CFG->{db}{pass} );

#------------------------------------------------------------------------#
# POE Environment Setup
#------------------------------------------------------------------------#
#POE::Component::Daemon->spawn( detach => 1, babysit => 600, max_children => 5 );

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
	DBICSchema => $schema,
	Plugins => $CFG->{plugins},
	PcapOpts => $CFG->{pcap},
);

#------------------------------------------------------------------------#
# Run the POE Sessions
#------------------------------------------------------------------------#
POE::Kernel->run;

#------------------------------------------------------------------------#
exit 0;
