package POE::Component::dns::monitor::analysis::plugin::zone::discovery;

use strict;
use warnings;
use POE;
use DateTime;
use DateTime::Format::Pg;
use YAML;

sub spawn {
    my $self = shift;
    my %args = @_;

    die "Bad Config" if ref $args{Config} ne 'HASH';
    die "Bad DBH" unless ref $args{DBH};
    die "No Alias" unless length $args{Alias};

    my $sess = POE::Session->create( inline_states => {
        _start  => sub { $poe_kernel->yield( 'zone_discovery_start', \%args ); },
        _stop   => sub { },
        zone_discovery_start => \&zone_discovery_start,
        analyze => \&analyze,
        zone_questions => \&zone_questions,
        zone_answers => \&zone_answers,
        notify => \&notify,
    });

    return $sess->ID;
}

sub zone_discovery_start {
    my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

    $kernel->alias_set( $args->{Alias} );

    # Store stuff in the heap
    $heap->{log} = $args->{LogSID};
    $heap->{dbh} = $args->{DBH};
    $heap->{interval} = $args->{Config}{interval} || 3600;

    # Schedule the Analysis
    $kernel->delay_add('analyze' => 5);
}

# Discover Authorized and Unauthorized servers
sub analyze {
    my ( $kernel,$heap ) = @_[KERNEL,HEAP];

    $kernel->call( $heap->{log} => debug => "zone::discovery running analysis" );

    $kernel->yield( 'zone_questions' );
    $kernel->yield( 'zone_answers' );

    # Schedule the Analysis
    $kernel->delay_add( analyze => $heap->{interval} );
}

sub zone_questions {
    my ( $kernel,$heap ) = @_[KERNEL,HEAP];

    my %STH = ();
    my %SQL = (
        check => q{
                select q.* from packet_record_question q
                    left join zone_question z on q.id = z.question_id
                where
                    q.class = 'IN'
                    and q.type in ( 'A', 'AAAA', 'PTR', 'MX', 'SOA', 'NS' )
                    and z.question_id is null
                order by first_ts asc
        },
        zone_id => q{select get_zone_id( ?, ?, ?, ? )},
        link_zone_question => q{
            select link_zone_question( ?, ? )
        },
    );
    foreach my $s (keys %SQL) {
        $STH{$s} = $heap->{dbh}->run( fixup => sub {
                my $sth = $_->prepare($SQL{$s});
                $sth;
            }
        );
    }

    $STH{check}->execute();

    my $updates = 0;
    while( my $q = $STH{check}->fetchrow_hashref ) {
        my ($name,$zone) = split( /\./, $q->{name}, 2 );
        if (! defined $zone ) {
            $kernel->call($heap->{log} => debug =>  "error parsing zone for $q->{id} $q->{class} $q->{type} $q->{name}");
            next;
        }
        my @path = split( /\./, $zone );
        my $path = join('.', reverse @path);
        $path =~ s/\-/_/g;
        $STH{zone_id}->execute( $zone, $path, $q->{first_ts}, $q->{last_ts} );
        my ($zone_id) = $STH{zone_id}->fetchrow_array;
        next unless defined $zone_id and $zone_id > 0;
        $STH{link_zone_question}->execute( $zone_id, $q->{id} );
    }

}

sub zone_answers {
    my ( $kernel,$heap ) = @_[KERNEL,HEAP];

    my %STH = ();
    my %SQL = (
        check => q{
                select a.* from packet_record_answer a
                    left join zone_answer z on a.id = z.answer_id
                where
                    a.class = 'IN'
                    and a.type in ( 'A', 'AAAA', 'PTR', 'MX', 'SOA', 'NS' )
                    and z.answer_id is null
                order by first_ts asc
        },
        zone_id => q{select get_zone_id( ?, ?, ?, ? )},
        link_zone_answer => q{
            select link_zone_answer( ?, ? )
        },
    );
    foreach my $s (keys %SQL) {
        $STH{$s} = $heap->{dbh}->run( fixup => sub {
                my $sth = $_->prepare($SQL{$s});
                $sth;
            }
        );
    }

    $STH{check}->execute();

    my $updates = 0;
    while( my $q = $STH{check}->fetchrow_hashref ) {
        foreach my $field ( qw( name value ) ) {
            next if $q->{$field} =~ /(\d{1,3}\.){3}\d{1,3}/;
            my ($name,$zone) = map { lc } split( /\./, $q->{$field}, 2 );
            if (! defined $zone || ! length $zone ) {
                $kernel->call($heap->{log} => debug =>  "error parsing zone for $q->{id} $q->{class} $q->{type} $q->{name}");
                next;
            }
            my @path = split( /\./, $zone );
            my $path = join('.', reverse @path );
            $path =~ s/\-/_/g;
            $STH{zone_id}->execute( $zone, $path, $q->{first_ts}, $q->{last_ts} );
            my ($zone_id) = $STH{zone_id}->fetchrow_array;
            next unless defined $zone_id and $zone_id > 0;
            $STH{link_zone_answer}->execute( $zone_id, $q->{id} );
        }
    }

}

# Notification of Unauthorized Servers
sub notify {
    my ($kernel,$heap,$cli) = @_[KERNEL,HEAP,ARG0];
}

# Return True
1;
