package POE::Component::dns::monitor::feature::graphite;

use POE;
use IO::Socket::INET;
use Try::Tiny;

# All features have to tell me what they provide!
sub provides { return 'stats'; }

# Spawn our graphite session
sub spawn {
    my $self = shift;
    my %args = @_;

    die "Bad Config" if ref $args{Config} ne 'HASH';

    my $sess = POE::Session->create( inline_states => {
        _start  => sub { $poe_kernel->yield( 'graphite_start', \%args ); },
        _stop   => sub { },
        add     => \&graphite_add,
        incr    => \&graphite_add,
        value   => \&graphite_raw_value,
        graphite_start => \&graphite_start,
        graphite_send  => \&graphite_send,
    });

    return $sess->ID;
}
sub graphite_start {
    my ($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

    # Set the alias to our "provides"
    $kernel->alias_set( __PACKAGE__->provides() );

    # Parse configuration
    my %cfg = (
        interval        => 60,
        prefix          => 'dns',
        carbon_host     => 'localhost',
        carbon_port     => 2003,
        carbon_proto    => 'tcp',
        %{ $args->{Config} },
    );
    # Set configuration
    $heap->{_cfg} = \%cfg;

    # Initialize some stuff
    $heap->{log} = $args->{LogSID};
    $heap->{_store} = {};
    $heap->{_cached} = [];

    # Install the repeating event
    $kernel->delay_add( 'graphite_send', $heap->{_cfg}{interval} );
}
sub graphite_add {
    my ($kernel,$heap,$metric,$value) = @_[KERNEL,HEAP,ARG0];

    my $m=clean_metric( $heap->{_cfg}{prefix}, $metric );
    my $v=clean_value( $value );
    return unless defined $m and length $m;
    # Default to Increment
    $v=1 unless defined $v;

    $heap->{_store}{counters}{$m} = 0 if !exists $heap->{_store}{counters}{$m};
    $heap->{_store}{counters}{$m} += $v;
}
sub graphite_raw_value {
    my ($kernel,$heap,$metric,$value) = @_[KERNEL,HEAP,ARG0,ARG1];

    # Tidy up
    my $t=time;
    my $m=clean_metric( $heap->{_cfg}{prefix}, $metric );
    my $v=clean_value( $value );

    return unless defined $m and length $m;
    return unless defined $v;

    $heap->{_store}{raw} = \qw() if !exists $heap->{_store}{raw};
    push @{ $heap->{_store}{raw} }, "$m $v $t";
}
sub graphite_send {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $counters   = delete $heap->{_store}{counters} if exists $heap->{_store}{counters};
    my $raw_values = delete $heap->{_store}{raw}      if exists $heap->{_store}{raw};

    my $socket;
    try {
        $socket = IO::Socket::INET->new(
                PeerAddr    => $heap->{_cfg}{carbon_server},
                PeerPort    => $heap->{_cfg}{carbon_port},
                PeerProto   => $heap->{_cfg}{carbon_proto},
        );
    };

    my @updates = ();
    # Grab Raw Updates
    push @updates, @{ $raw_values }
        if defined $raw_values;
    # Add counters
    my $t=time;
    push @updates, map { "$_ $counters->{$_} $t" }
        keys %{ $counters } if defined $counters;

    # Send or cache the updates
    if( defined $socket && $socket->connected ) {
        $socket->send( join '', map { "$_\n" } @updates );
    }
    else {
        push @{ $heap->{_cached} }, \@updates;
        $kernel->post( $heap->{log} => notice => "graphite server unavailable, cached writes" );
    }
    $kernel->delay_add( 'graphite_send' => $heap->{_cfg}{interval} );
}
sub clean_metric {
    my ($prefix,$name) = @_;
    return undef unless defined $prefix and length $name > 2;
    return undef unless defined $name and length $name > 2;
    # Prepend the prefix;
    $name = join('.', $prefix,$name);
    # Replace anything strange with a .
    $name =~ s/[^a-z0-9\-\_\.]+/./g;
    # Replace multiple dots with one!
    $name =~ s/\.{2,}/\./g;
    return $name;
}
sub clean_value {
    my $value = shift;
    return undef unless defined $value;

    # Math it.
    return $value + 0;
}
1;
