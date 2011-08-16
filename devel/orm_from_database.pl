#!/usr/bin/env perl

use strict;
use warnings;
use YAML;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;

if( !-d './lib') {
	die "must be run in the root dir of dns::monitor!\n";
}

my $CFG = YAML::LoadFile( 'dns_monitor.yml' ) or die "unable to source config file!\n";

make_schema_at(
	'dns::monitor::Schema',
	{
		dump_directory=> './lib',
		exclude		=> qr/(^pg_)|(^v_admin)|(^v_history)/,
		moniker_map	=> sub {
			my $table = shift;

			my %map = (
				client						=> 'client',
				conversation				=> 'conversation',
				server						=> 'server',
				# Stats Plugins
				client_stats				=> 'client::stats',
				server_stats				=> 'server::stats',
				# Packet Logger
				packet_query				=> 'packet::query',	
				packet_response				=> 'packet::response',
				packet_record_question		=> 'packet::record::question',
				packet_record_answer		=> 'packet::record::answer',
				packet_meta_question		=> 'packet::meta::question',
				packet_meta_answer			=> 'packet::meta::answer',
				packet_meta_query_response	=> 'packet::meta::query_response',
				packet_timing				=> 'packet::timing',
				# Zone Discovery
				zone						=> 'zone',
				zone_question				=> 'zone::meta::question',
				zone_answer					=> 'zone::meta::answer',
				# List Plugin
				list						=> 'list',
				list_type					=> 'list::type',
				list_entry					=> 'list::entry',
				list_meta_question			=> 'list::meta::question',
				list_meta_answer			=> 'list::meta::answer',
				list_tracking_client		=> 'list::tracking::client',
			);

			return $map{$table} if exists $map{$table};

			my $pre = '';
			if( $table =~ /^v_/ ) {
				$pre = 'view::';
				$table =~ s/^v_//;	
			}

			return $pre . join('', map ucfirst, split /[\W_]+/, lc $table);
		},
		skip_relationships => 1,
		components => [qw(InflateColumn::DateTime PK::Auto)],
	},
	[ $CFG->{db}{dsn}, $CFG->{db}{user}, $CFG->{db}{pass} ]

);
