package POE::Component::dns::monitor::sniffer::plugin::client::stats;

use strict;
use warnings;
use POE;
use DateTime;
use Try::Tiny;

sub spawn {
    my $self = shift;
    my %args = @_;

    die "Bad Config" if ref $args{Config} ne 'HASH';
    die "No Alias" unless length $args{Alias};

    my $sess = POE::Session->create( inline_states => {
        _start  => sub { $poe_kernel->yield( 'client_stats_start', \%args ); },
        _stop   => sub { },
        client_stats_start => \&client_stats_start,
        process => \&process,
    });

    return $sess->ID;
}

sub client_stats_start {
    my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

    $kernel->alias_set( $args->{Alias} );

    # Store stuff in the heap
    $heap->{log} = $args->{LogSID};

    # Check to see if stats is enabled
    $heap->{enabled} = $kernel->call( sniffer => check_feature => 'stats' );

    if( !$heap->{enabled} ) {
        $kernel->post( $heap->{log} => 'error' => q{client::stats requires feature 'stats', but is not being provided, noop results.} );

    }
}

sub process {
    my ( $kernel,$heap,$dnsp,$info ) = @_[KERNEL,HEAP,ARG0,ARG1];

    return unless $heap->{enabled};

    # Check for query/response
    my $metric = '';
    if( $dnsp->header->qr ) {
        if ( $dnsp->header->rcode eq 'NOERROR' ) {
            $metric='answer';
        }
        elsif( $dnsp->header->rcode eq 'NXDOMAIN' ) {
            $metric='nx';
        }
        else {
            $metric='error';
        }
    }
    else {
       $metric='query';
    }
    $kernel->post( stats => incr => "clients.$info->{client}.$metric.count" );
    $kernel->post( stats => add  => "clients.$info->{client}.$metric.bytes", length $dnsp );
}

# Return True
1;
