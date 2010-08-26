#!/usr/bin/env perl
use strict;
use warnings;
use dns::monitor;

dns::monitor->setup_engine('PSGI');
my $app = sub { dns::monitor->run(@_) };

