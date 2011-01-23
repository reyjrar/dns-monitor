use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'dns::monitor' }
BEGIN { use_ok 'dns::monitor::Controller::query' }

ok( request('/query')->is_success, 'Request should succeed' );
done_testing();
