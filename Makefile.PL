#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;

name 'dns-monitor';
version '0.9';

requires 'DBIx::Connector';
requires 'DBIx::Class';
requires 'DBIx::Class::TimeStamp';
requires 'YAML';
requires 'Try::Tiny';
requires 'Daemon::Daemonize';
requires 'DateTime';
requires 'DateTime::Format::HTTP';
requires 'DateTime::Format::Pg';
requires 'DateTime::Format::Duration';
requires 'Digest::SHA';
requires 'File::Find::Rule';
requires 'Exception::Class::DBI';
requires 'CHI';
requires 'EV';
requires 'Log::Dispatch::FileRotate';
requires 'POE';
requires 'POE::Component::Daemon';
requires 'POE::Component::Pcap';
requires 'POE::Component::Logger';
requires 'POE::Loop::EV';
requires 'Net::DNS';
requires 'Net::IP::Resolver';
requires 'NetPacket';
requires 'Sys::Syslog';
requires 'WWW::Mechanize';
requires 'Module::Pluggable';
test_requires 'Test::More' => '0.88';

install_script glob('bin/*.pl');
auto_install;
WriteAll;
