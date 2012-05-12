package POE::Component::dns::monitor::feature::graphite;

use POE;

# All features have to tell me what they provide!
sub provides { return 'stats'; }

sub spawn {
    return $$;
}


1;
