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
    die "Bad DBH" unless ref $args{DBH};
    die "No Alias" unless length $args{Alias};

    my $sess = POE::Session->create( inline_states => {
        _start  => sub { $poe_kernel->yield( 'server_stats_start', \%args ); },
        _stop   => sub { },
        server_stats_start => \&server_stats_start,
        process => \&process,
        post_updates => \&post_updates,
    });

    return $sess->ID;
}

sub server_stats_start {
    my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

    $kernel->alias_set( $args->{Alias} );
    
    # Store stuff in the heap
    $heap->{log} = $args->{LogSID};
    $heap->{dbh} = $args->{DBH};
    $heap->{interval} = exists $args->{Config}{interval} ? $args->{Config}{interval} : 300;
    $heap->{updates} = {};

    $kernel->delay_add( 'post_updates', $heap->{interval} );
}

sub post_updates {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Grab the updates:
    my $updates = delete $heap->{updates};
    $heap->{updates} = {};

    # Statement Handle Caching
    my %SQL = (
        update => q{select server_stats_update( ?, ?, ?, ?, ? )},
    );
    my %STH = ();
    foreach my $s (keys %SQL) {
        $STH{$s} = $heap->{dbh}->run( fixup => sub {
                my $sth = $_->prepare( $SQL{$s} );
                $sth;
            }, catch {
                my $err = shift;
                $kernel->post( $heap->{log} => notice => qq|server::stats STH: $s failed: $err| );
            }
        );
    }

    foreach my $id ( keys %{ $updates } ) {
        my %info = %{ $updates->{$id} };

        $STH{update}->execute( $id, @info{qw( queries answers nx errors )} );
    }

    $kernel->delay_add( 'post_updates', $heap->{interval} );
}

sub process {
    my ( $kernel,$heap,$dnsp,$info ) = @_[KERNEL,HEAP,ARG0,ARG1];
    
    my $updates = $heap->{updates};
    my $id = $info->{server_id};

    if( ! exists $updates->{$id} ) {
        $updates->{$id} = {
            queries => 0,
            answers => 0,
            nx      => 0,
            errors  => 0,
        };
    }   

    # Check for query/response
    if( $dnsp->header->qr ) {
        if ( $dnsp->header->rcode eq 'NOERROR' ) {
            $updates->{$id}{answers}++;
        }
        elsif( $dnsp->header->rcode eq 'NXDOMAIN' ) {
            $updates->{$id}{nx}++;
        }
        else {
            $updates->{$id}{errors}++;
        }
    }
    else {
        $updates->{$id}{queries}++;
    }
}

# Return True
1;
