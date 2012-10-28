package POE::Component::dns::monitor::sniffer::plugin::server::stats;

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
        _start  => sub { $poe_kernel->yield( 'server_stats_start', \%args ); },
        _stop   => sub { },
        server_stats_start => \&server_stats_start,
        process => \&process,
    });

    return $sess->ID;
}

sub server_stats_start {
    my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

    $kernel->alias_set( $args->{Alias} );

    # Store stuff in the heap
    $heap->{log} = $args->{LogSID};

    # Check to see if stats is enabled
    $heap->{enabled} = $kernel->call( sniffer => check_feature => 'stats' );

    if( !$heap->{enabled} ) {
        $kernel->post( $heap->{log} => 'error' => q{server::stats requires feature 'stats', but is not being provided, noop results.} );

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
    $kernel->post( stats => incr => "servers.$info->{client}.$metric.count" );
    $kernel->post( stats => add  => "servers.$info->{client}.$metric.bytes", length $dnsp );

}

# Return True
1;
