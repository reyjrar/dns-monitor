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
use LWP::Simple;
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

# SQL Statements
my %SQL = ( 
    list => q{select * from list where can_refresh is true
                and (refresh_last_ts < NOW() - refresh_every or refresh_last_ts is null)
    },
    clear_entry_refresh => q{update list_entry set refreshed = false where list_id = ?},

    check_entry => q{
        select id from list_entry where list_id = ? and zone = ?
    },
    update_entry => q{
        update list_entry set refreshed = true, last_ts = NOW() where id = ?
    },
    insert_entry => q{
        insert into list_entry ( list_id, "zone", path, refreshed ) values ( ?, ?, ?, true )
    },
    list_update_refresh => q{
        update list set refresh_last_ts = NOW() where id = ?
    },
    clear_stale_entries => q{
        delete from list_entry where list_id = ? and refreshed is false
    },
);

my %STH=();
foreach my $s (keys %SQL){
    $STH{$s} = $dbh->prepare($SQL{$s});
}
$STH{list}->execute();
while( my $list = $STH{list}->fetchrow_hashref ) { 
    # Fetch List Entries
    my $content;
    try {
        $content = get( $list->{refresh_url} ) or die "unable to retrieve $list->{refresh_url}";
    } catch {
        print "ERROR: $_\n" unless $OPT{q};
        next;
    }; 

    # Clear the list_entry.refreshed flag
    $STH{clear_entry_refresh}->execute( $list->{id} );
    
    # Add or Update the list
    foreach my $line (map { lc } split /\r*\n+/, $content) {
        # Assume first column is the zone
        my ($zone) = ($line =~ /^(\S+)/);

        # Insert or Update?
        $STH{check_entry}->execute( $list->{id}, $zone );

        if( $STH{check_entry}->rows > 0 ) {
            my ($eid) = $STH{check_entry}->fetchrow_array;
            $STH{update_entry}->execute( $eid );
        }
        else {
            my $path = join('.', reverse split /\./, $zone );
            $path =~ s/\-/_/g;
            $STH{insert_entry}->execute( $list->{id}, $zone, $path );
        }
    }

    # Clear Entries not refreshed
    $STH{clear_stale_entries}->execute( $list->{id} );
}
