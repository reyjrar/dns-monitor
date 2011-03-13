#!/usr/bin/env perl 

use strict;
use warnings;
use FindBin;

# Add local lib path
use lib "$FindBin::Bin/../lib";

use File::Spec;
use File::Basename;
use File::Slurp qw( slurp );
use YAML;
use DBIx::Connector;
use Try::Tiny;

#------------------------------------------------------------------------#
# Grab Mode
my %MODES = (
	install => \&install,
);
my $MODE = shift @ARGV;
$MODE //= 'install';

if( !exists $MODES{$MODE} ) {
	die "usage: $0 [mode: " . join(',', keys %MODES) . "]\n";
}


#------------------------------------------------------------------------#
# Locate all the necessary directories
my @BasePath = File::Spec->splitdir( $FindBin::Bin );
pop @BasePath;

#------------------------------------------------------------------------#
# Load Configuration
my $configFile = File::Spec->catfile( @BasePath, 'dns_monitor.yml' );
my $CFG = YAML::LoadFile( $configFile ) or die "unable to load $configFile: $!\n";


#------------------------------------------------------------------------#
# Load Schema YAML
my $deployFile = File::Spec->catfile( @BasePath, 'devel', 'schema', 'deploy.yml' );
my $SCHEMA = YAML::LoadFile( $deployFile ) or die "unable to load $deployFile: $!\n";

# Connect to the Database:
my $dbConn = DBIx::Connector->new( $CFG->{db}{dsn}, $CFG->{db}{user}, $CFG->{db}{pass},
	{PrintError => 0, RaiseError => 1 } );

exit $MODES{$MODE}->( $SCHEMA->{$MODE} );

sub install {
	my $schema = shift;

	# Install Base
	foreach my $entity (@{ $schema->{base} } ) {
		my $srcFile = File::Spec->catfile( @BasePath, qw(devel schema install base), "$entity.sql" );
		die "$srcFile does not exist!\n" unless -f $srcFile;
		my $error = undef;

		my $sql = slurp( $srcFile );
		$dbConn->run( fixup => sub {
			$_->do( $sql );
		}, catch { $error = $_ } );	
		die " - applying base $entity failed with error: $error\n" if $error;
		print " - applied base $entity!\n";
	}

	# Install Plugins
	foreach my $plugin (sort { $schema->{plugins}{$a}{level} <=> $schema->{plugins}{$b}{level} } keys %{ $schema->{plugins} } ) {
		my $plugin_pathpart = $plugin;
		$plugin_pathpart =~ s/\:\:/_/g;
		my @path = ( @BasePath, qw( devel schema install plugins ), $plugin_pathpart );
		print "+ Processing plugin $plugin:\n";
		foreach my $entity ( @{ $schema->{plugins}{$plugin}{entities} } ) {
			my $srcFile = File::Spec->catfile( @path, "$entity.sql" );
			die "$srcFile does not exist!\n" unless -f $srcFile;
			my $error = undef;
	
			my $sql = slurp( $srcFile );
			$dbConn->run( fixup => sub {
				$_->do( $sql );
			}, catch { $error = $_ } );	
	
			die " - applying plugin($plugin) $entity failed with error: $error\n" if $error;
			print " - applied plugin($plugin) $entity!\n";
	
		}
	}
	
}
