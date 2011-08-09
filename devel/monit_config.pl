#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use English;
use File::Spec;
use Scalar::Util qw( tainted );
use IO::Prompt;
use Carp;

use Template;
use Data::Dumper;


#------------------------------------------------------------------------#
# Locate all the necessary directories
my @BasePath = File::Spec->splitdir( $FindBin::Bin );
pop @BasePath;
my $TEMPLATE_DIR = File::Spec->catdir( @BasePath, 'devel', 'templates' );

#------------------------------------------------------------------------#
# Prompt for Information
my @Perls = ();
foreach my $possible ( RunCommand( 'locate', 'bin/perl' ) ) {
	push @Perls, $possible if $possible =~ /\/perl$/;
}
my %VARS = (
	baseDir => File::Spec->rel2abs( File::Spec->catdir( @BasePath ) ),
);

$VARS{perl} = prompt "Which perl should I use to run dns-monitor? ",
	-menu => \@Perls;

$VARS{analyzer} = prompt "Start Analyzer? [yn] ", -tyn1;

my $default = -d '/etc/monit.d' && -w '/etc/monit.d' ? '/etc/monit.d' : '/tmp';

$VARS{destination} = prompt "Destination: ", -d=>$default,
	-require => {
		"Destination must be a directory: [$default]" => sub { return -d $_; },
		"Destination must be writable: [$default]"	=> sub { return -w $_; },
	};

#------------------------------------------------------------------------#
# Generate Configuration using templates
print "Generating Configurations at $VARS{destination}\n";
my $tt = Template->new({
	INCLUDE_PATH	=> $TEMPLATE_DIR,
	OUTPUT_PATH		=> $VARS{destination},
	TRIM			=> 0,
});

$tt->process( 'monit.conf.tmpl', \%VARS, 'dnsmonitor.conf' )
	or croak "templating failed: " . $tt->error;

print "Templates generated successfully.\n\n";

#------------------------------------------------------------------------#
# ShellSafe
#  escapes a string so it's safe for the shell.
sub ShellSafe {
	my $str = shift;
	$str =~ s/[^\w\d\+\-_\/\.]//g;
	$str =~ s/[^\\]* /\\ /g;

	if( $str =~ /^(.*)$/) {
		$str = $1;
	}
	else {
		$str = '';
	}

	print "SHELL ESCAPE, $str still tainted" if tainted($str);

	return $str;
}

#------------------------------------------------------------------------#
# RunCommand
sub RunCommand {
	my ($cmd,@args) = @_;

	my %BIN = (
		'locate'	=> '/usr/bin/locate',
	);

	if( scalar @args == 0 ) {
		($cmd,@args) = split /\s+/, $cmd;
	}

	croak "unable to run command: $cmd, not in my dispatch"
		unless exists $BIN{$cmd};

	my @safe_args = map { tainted($_) ? ShellSafe($_) : $_;  } @args;

	local %ENV = ();

	for ($BIN{$cmd},@safe_args) {
		carp "$_ is tainted\n" if tainted($_); 
	}

	# Fork the Command
	my $pid = open(my $out, '-|');

	if( $pid ) {
		# Parent, read the file handle
		my @output = ();
		while( local $_ = <$out> ) {
			chomp;
			push @output, $_;
		}
		close $out;
	
		return wantarray ? @output : ( $CHILD_ERROR ? 0 : 1 );
	}
	else {
		# Child, write, ignore STDERR
		open( STDERR, '>' . File::Spec->devnull );
		exec $BIN{$cmd}, @safe_args;
	}
	
}
