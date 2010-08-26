#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use File::Basename;
use YAML;

# Application Stuff
use lib "$FindBin::Bin/../lib";
use dns::monitor::Schema;

# Locate Our Base Directory
my @BasePath = File::Spec->splitdir( $FindBin::Bin );
pop @BasePath;
my %DIRS = (
	'base'	=> File::Spec->catdir( @BasePath ),
	'lib'	=> File::Spec->catdir( @BasePath, 'lib' ),
	'cache'	=> File::Spec->catdir( @BasePath, 'cache' ),
	'db'	=> File::Spec->catdir( @BasePath, 'cache', 'db' ),
);

# Load Config
my $config = File::Spec->catfile( $DIRS{base}, 'dns_monitor.yml' );
my $CFG = YAML::LoadFile( $config );

# Make the Database Directory
mkdir( $DIRS{db}, 0755 ) unless -d $DIRS{db};

# Connect and Deploy, overwriting what's in the db now.
my $schema = dns::monitor::Schema->connect($CFG->{db}{dsn},$CFG->{db}{user},$CFG->{db}{user});
$schema->deploy({ add_drop_table => 1 });
