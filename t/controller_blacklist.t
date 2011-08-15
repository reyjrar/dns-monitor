use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'dns::monitor' }
BEGIN { use_ok 'dns::monitor::Controller::blacklist' }

ok( request('/blacklist')->is_success, 'Request should succeed' );
done_testing();
