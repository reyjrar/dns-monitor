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
	sel_query => q{
		select client_id, server_id, count(1) as queries, min(query_ts) as first_ts,
			max(query_ts) as last_ts
		from packet_query
		group by client_id, server_id
	},
	sel_response => q{
		select client_id, server_id, count(1) as responses, min(response_ts) as first_ts,
			max(response_ts) as last_ts
		from packet_response
		group by client_id, server_id
	},


	sel_check => q{
		select id, first_ts, last_ts, questions, answers from packet_meta_conversation where client_id = ? and server_id = ? 
	},

	ins_convo => q{
		insert into packet_meta_conversation ( client_id, server_id, first_ts, last_ts, questions, answers )
			values ( ?, ?, ?, ?, ?, ? )
	},
	upd_convo => q{
		update packet_meta_conversation set first_ts = ?, last_ts = ?, questions = ?, answers = ?
			where id = ?
	},

	upd_query => q{
		update packet_query set conversation_id = ? where client_id = ? and server_id = ?
	},
	upd_response => q{
		update packet_response set conversation_id = ? where client_id = ? and server_id = ?
	},

);
my %STH=();
foreach my $s (keys %SQL) {
	$STH{$s} = $dbh->prepare( $SQL{$s} );
}

my %totals = ();

$STH{sel_query}->execute();
while( my $row = $STH{sel_query}->fetchrow_hashref ) {
	$STH{sel_check}->execute( $row->{client_id}, $row->{server_id} );	

	my $conv_id = 0;

	# Updates
	if( $STH{sel_check}->rows == 1 ) {
		my $convRow = $STH{sel_check}->fetchrow_hashref;	
		$conv_id = $convRow->{id};
		my %ts = (
			first_ts => $row->{first_ts} gt $convRow->{first_ts} ? $convRow->{first_ts} : $row->{first_ts},
			last_ts => $row->{last_ts} lt $convRow->{last_ts} ? $convRow->{last_ts} : $row->{last_ts},
		);
		$STH{upd_convo}->execute( @ts{qw(first_ts last_ts)}, $row->{queries}, $convRow->{answers}, $conv_id );
		$totals{queries_updated}++;
	}
	else {
		$STH{ins_convo}->execute(
			$row->{client_id},
			$row->{server_id},
			$row->{first_ts},
			$row->{last_ts},
			$row->{queries},
			0
		);
		$STH{sel_check}->execute( $row->{client_id}, $row->{server_id} );
		($conv_id) = $STH{sel_check}->fetchrow_array;
		$totals{queries_created}++;
	}

	$STH{upd_query}->execute( $conv_id, $row->{client_id}, $row->{server_id} );

	$totals{queries_conversed}++;
}

$STH{sel_response}->execute();
while( my $row = $STH{sel_response}->fetchrow_hashref ) {
	$STH{sel_check}->execute( $row->{client_id}, $row->{server_id} );	

	my $conv_id = 0;

	# Updates
	if( $STH{sel_check}->rows == 1 ) {
		my $convRow = $STH{sel_check}->fetchrow_hashref;	
		$conv_id = $convRow->{id};
		my %ts = (
			first_ts => $row->{first_ts} gt $convRow->{first_ts} ? $convRow->{first_ts} : $row->{first_ts},
			last_ts => $row->{last_ts} lt $convRow->{last_ts} ? $convRow->{last_ts} : $row->{last_ts},
		);
		$STH{upd_convo}->execute( @ts{qw(first_ts last_ts)}, $convRow->{questions}, $row->{responses}, $conv_id );
		$totals{responses_updated}++;
	}
	else {
		$STH{ins_convo}->execute(
			$row->{client_id},
			$row->{server_id},
			$row->{first_ts},
			$row->{last_ts},
			0,
			$row->{responses}
		);
		$STH{sel_check}->execute( $row->{client_id}, $row->{server_id} );
		($conv_id) = $STH{sel_check}->fetchrow_array;
		$totals{responses_created}++;
	}

	$STH{upd_response}->execute( $conv_id, $row->{client_id}, $row->{server_id} );

	$totals{responses_conversed}++;
}

print Dump \%totals;
