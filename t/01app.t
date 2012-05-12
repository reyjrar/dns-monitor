#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'POE::Component::dns::monitor::sniffer', 'dns::monitor::sniffer';
    use_ok 'POE::Component::dns::monitor::analysis', 'dns::monitor:analysis';
}


done_testing();
