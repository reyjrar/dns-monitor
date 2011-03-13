#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'dns-monitor';
all_from 'lib/dns/monitor.pm';

requires 'Catalyst::Runtime' => '5.80023';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::View::Mason';
requires 'Catalyst::View::RRDGraph';
requires 'Catalyst::Model::DBIC::Schema';
requires 'DBIx::Connector';
requires 'DBIx::Class';
requires 'DBIx::Class::TimeStamp';
requires 'Moose';
requires 'namespace::autoclean';
requires 'YAML';
requires 'Try::Tiny';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
requires 'DateTime';
requires 'DateTime::Format::HTTP';
requires 'DateTime::Format::Pg';
requires 'DateTime::Format::Duration';
requires 'CHI';
requires 'EV';
requires 'POE';
requires 'POE::Component::Daemon';
requires 'POE::Component::Pcap';
requires 'POE::Component::Logger';
requires 'POE::Loop::EV';
requires 'Net::DNS';
requires 'Net::IP::Resolver';
requires 'NetPacket';
requires 'RRDs';
requires 'Module::Pluggable';
test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
