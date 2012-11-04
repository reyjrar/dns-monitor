#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use File::Basename;
use YAML;
use DBI;
use DateTime;
use DateTime::Format::HTTP;

# Application Stuff
use lib "$FindBin::Bin/../lib";

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
my $dbh = DBI->connect($CFG->{db}{dsn},$CFG->{db}{user},$CFG->{db}{pass},
	{ RaiseError => 1 });

my %SQL=(
    select => q{
        select m.*, r.response_ts - q.query_ts
            from packet_meta_query_response m
            inner join packet_query q on m.query_id = q.id
            inner join packet_response r on m.response_id = r.id
        where
         r.response_ts - q.query_ts > interval '10 seconds'

	},
    delete => q{
        delete from packet_meta_query_response where query_id = ? and response_id = ?
	},

);
my %STH=();
foreach my $s (keys %SQL) {
	$STH{$s} = $dbh->prepare( $SQL{$s} );
}

my %totals = ();

$STH{select}->execute();
while( my $row = $STH{select}->fetchrow_hashref ) {
	$STH{delete}->execute( $row->{query_id}, $row->{response_id} );
	$totals{deleted}++;
}

print Dump \%totals;
