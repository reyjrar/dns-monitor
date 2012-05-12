package POE::Component::dns::monitor::sniffer;

use strict;
use warnings;

# DateTime Handling
use DateTime;
use DateTime::Format::Duration;
# Caching
use CHI;
# Packet Parsing
use NetPacket::Ethernet qw(:strip);
use NetPacket::IP qw(:strip :protos);
use NetPacket::UDP;
use NetPacket::TCP;
use Net::DNS::Packet;
# Handle Loading Plugins
use Module::Pluggable   require     => 1,
                        search_path => [qw(
                            POE::Component::dns::monitor::sniffer::plugin
                            POE::Component::dns::monitor::feature
                        )];
use Try::Tiny;

# POE
use POE qw( Component::Pcap );

=head1 NAME

POE::Component::dns::monitor::sniffer - Passive DNS Monitoring

=cut

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use POE::Component::dns::monitor::sniffer;

    my $snif_sess_id = POE::Component::dns::monitor::sniffer->spawn(
            Config      => $configFile,         # Required
            DBH         => $dbh,                # Required
            LogSID      => 'log',               # Default
            PcapOpts    => \%pcapOpts,          # See below for details
            Plugins     => \%pluginConfig,      # See below for details
            Features    => \%featureConfig,     # See below for details
    );

=head1 EXPORT

POE::Component::dns::monitor::sniffer does not export any symbols

=head1 FUNCTIONS

=head2 spawn

Creates the POE::Session for the dns::monitor::sniffer.

Parameters:

    B<Config> is a filename to a YAML Config File.

    B<DBH> is a DBI object that's connected.

    B<LogSID> is the Session ID of a POE::Component::Logger session or your custom logging
    session capable of handling standard log level events.

    B<PcapOpts> is a hashref containing options to send to the Net::Pcap module
        Defaults to:
            { dev => 'any', snaplen => 1518, filter => '(tcp or udp) and port 53', promisc => 0 }
        You should really send something more interesting than that

    B<Plugins> is a hash ref for plugin options
        Defaults to:
        {
            'packet::store'     => { enable => 1, keep_for => '30 days' },
        }

    B<Features> is a hash ref for feature configs, default is none

=cut

sub spawn {
    my $self = shift;

    # Process Arguments
    my %args = (
        DBH         => undef,
        LogSID          => 'log',
        @_
    );
    # Defaults
    my %pcapOpts = ( dev => 'any', snaplen => 1518, filter => '(tcp or udp) and port 53', promisc => 0 );
    my %pluginConfig = (
        'packet::store'     => { enable => 1, keep_for => '30 days' },
    );
    # Hashify
    foreach my $hashOpt(qw( Plugins PcapOpts ) ) {
        $args{$hashOpt} = ref $args{$hashOpt} eq 'HASH' ? $args{$hashOpt} : {};
    }
    # Configure Defaults: Plugins
    foreach my $k ( keys %pluginConfig ) {
        if( ! exists $args{Plugins}->{$k} ) {
            $args{Plugins}->{$k} = $pluginConfig{$k};
        }
    }
    # Configure Defaults: PcapOpts
    foreach my $k ( keys %pcapOpts ) {
        if( ! exists $args{PcapOpts}->{$k} ) {
            $args{PcapOpts}->{$k} = $pcapOpts{$k};
        }
    }

    # Configure the Pcap Session
    my $pcap_session_id = POE::Component::Pcap->spawn(
        Alias       => 'pcap',
        Device      => $args{PcapOpts}->{dev},
        Dispatch    => 'handle_packets',
        Session     => 'sniffer',
    );

    # Configure the Sniffer Session
    my $session_id = POE::Session->create(
        inline_states => {
            _start  => sub { $poe_kernel->yield( 'sniffer_start' => \%args ) },
            _stop   => sub {} ,
            _child  => \&sniffer_handle_sigchld,
            sniffer_start           => \&sniffer_start,
            sniffer_load_plugins    => \&sniffer_load_plugins,
            sniffer_stats           => \&sniffer_stats,
            # Actually handle the packets
            handle_packets          => \&sniffer_handle_packets,
            dns_parse               => \&sniffer_dns_parse,
        },
    );

    return $session_id;
}

sub sniffer_start {
    my ($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

    # Store the Args in the Heap
    $heap->{_config} = $args->{Config};
    $heap->{_features} = $args->{Features};
    $heap->{dbh} = $args->{DBH};
    $heap->{log} = $args->{LogSID};
    $heap->{_plugins} = $args->{Plugins};
    $heap->{_pcap} = $args->{PcapOpts};

    # Set the Alias
    $kernel->alias_set( 'sniffer' );

    # Load the Plugins
    $kernel->yield( 'sniffer_load_plugins' );

    # Configure the Pcap Handler
    $kernel->post( $heap->{log} => debug => "pcap::open_live : $args->{PcapOpts}{dev}" );
    $kernel->post( pcap => open_live => @{$args->{PcapOpts}}{qw(dev snaplen promisc timeout)} );
    $kernel->post( $heap->{log} => debug => "pcap::filter : $args->{PcapOpts}{filter}" );
    $kernel->post( pcap => set_filter => $args->{PcapOpts}{filter} )
        if exists $args->{PcapOpts}{filter} && length $args->{PcapOpts}{filter};
    $kernel->call( pcap => 'run' );

    # Initialize Statistics Engine
    $kernel->yield('sniffer_stats');
}

sub sniffer_load_plugins {
    my ($self,$kernel,$heap) = @_[OBJECT,KERNEL,HEAP];

    my %plugins=();
    my %features=();
    foreach my $plugin ( __PACKAGE__->plugins ) {
        my $name;
        if(($name) = ($plugin =~ /::plugin::(.*)$/) ) {
            $kernel->post( $heap->{log} => debug => "found plugin: $name" );
            # Check for plugin configuration
            if( !exists $heap->{_plugins}{$name} || ref $heap->{_plugins}{$name} ne 'HASH' ) {
                $kernel->post( $heap->{log} => notice => "plugin::$name : no configuration, skipping" );
                next;
            }
            # Store the config in a shorter variable
            my $pluginConf = $heap->{_plugins}{$name};

            # Check to ensure the plugin is enabled
            if( !exists $pluginConf->{enable} || $pluginConf->{enable} != 1 ) {
                $kernel->post( $heap->{log} => notice => "plugin::$name : disabled skipping" );
                next;
            }

            if( !$plugin->can('spawn') || !$plugin->can('process') ) {
                $kernel->post( $heap->{log} => notice => "plugin::$name : API Failure, skipping" );
                next;
            }
            $kernel->post( $heap->{log} => debug => "plugin::$name : attempting to bootstrap" );

            try {
                $plugins{$name} = $plugin->spawn(
                    Alias => $name,
                    Config => $pluginConf,
                    DBH => $heap->{dbh},
                    LogSID => $heap->{log},
                );
            } catch {
                $kernel->post( $heap->{log} => warning => "plugin::$name : unable to spawn: $_" );
            };
        }
        elsif(($name) = ($plugin =~ /::feature::(.*)$/) ) {
            # Load a feature
            $kernel->post( $heap->{log} => debug => "found feature: $name" );
            # Check for plugin configuration
            if( !exists $heap->{_features}{$name} || ref $heap->{_features}{$name} ne 'HASH' ) {
                $kernel->post( $heap->{log} => notice => "feature::$name : no configuration, skipping" );
                next;
            }
            # Store the config in a shorter variable
            my $featureConf = $heap->{_features}{$name};

            # Check to ensure the plugin is enabled
            if( !exists $featureConf->{enable} || $featureConf->{enable} != 1 ) {
                $kernel->post( $heap->{log} => notice => "feature::$name : disabled skipping" );
                next;
            }

            if( !$plugin->can('spawn') || !$plugin->can('provides') ) {
                $kernel->post( $heap->{log} => notice => "feature::$name : API Failure, skipping" );
                next;
            }
            $kernel->post( $heap->{log} => debug => "feature::$name : attempting to bootstrap" );

            my ($feature, $error);
            try {
                $feature = $plugin->provides;
                $features{$feature} = $plugin->spawn(
                    Config => $featureConf,
                    LogSID => $heap->{log},
                );
            } catch {
                $error++;
                $kernel->post( $heap->{log} => warning => "feature::$name : unable to spawn: $_" );
            };
            if( $error ) {
                delete $features{$feature} if defined $features{$feature};
                undef $feature;
            }
            else {
                $kernel->post( $heap->{log} => debug => "feature::$name providing $feature loaded" );
            }
        }
    }
    $heap->{_loaded_plugins} = \%plugins;
    my $totalPlugins = scalar keys %plugins;
    if( $totalPlugins < 1 ) {
        $kernel->call( $heap->{log} => error => "Did not load any plugins, so exiting!" );
        $kernel->yield('_stop');
        exit 1;
    }
    $kernel->post( $heap->{log} => notice => "plugins loaded: " . join(', ', sort keys %plugins) );
}

#------------------------------------------------------------------------#
# sniffer_handle_packet
#  - dispatch the packet to the parser
sub sniffer_handle_packets {
    my ($kernel,$heap,$packets) = @_[KERNEL,HEAP,ARG0];

    increment_stat( $heap, 'dispatch' );
    foreach my $inst ( @{ $packets } )  {
        my ($hdr, $pkt) = @{ $inst };
        next unless defined $hdr;
        increment_stat( $heap, 'packet' );

        #
        # Begin Decoding
        my $ip_pkt  = NetPacket::IP->decode( eth_strip($pkt) );

        return unless defined $ip_pkt;
        return unless $ip_pkt->{proto};

        # Handle UDP Packets
        if( $ip_pkt->{proto} == IP_PROTO_UDP ) {
            my $udp = NetPacket::UDP->decode( $ip_pkt->{data} );
            my %ip = (
                src_ip => $ip_pkt->{src_ip},
                src_port => $udp->{src_port},
                dest_ip => $ip_pkt->{dest_ip},
                dest_port => $udp->{dest_port},
                'time' => join('.', $hdr->{tv_sec}, sprintf("%0.6d", $hdr->{tv_usec}) ),
            );
            increment_stat( $heap, 'udp' );
            $kernel->yield( dns_parse => $udp, \%ip );
        }
        # Handle TCP Packets
        elsif ( $ip_pkt->{proto} == IP_PROTO_TCP ) {
            my $tcp = NetPacket::TCP->decode( $ip_pkt->{data} );
            my %ip = (
                src_ip => $ip_pkt->{src_ip},
                src_port => $tcp->{src_port},
                dest_ip => $ip_pkt->{dest_ip},
                dest_port => $tcp->{dest_port},
                'time' => join('.', $hdr->{tv_sec}, sprintf("%0.6d", $hdr->{tv_usec}) ),
            );
            increment_stat( $heap, 'tcp' );
            $kernel->yield( dns_parse => $tcp, \%ip );
        }
        else {
            increment_stat( $heap, 'invalid' );
        }
    }
}

#------------------------------------------------------------------------#
sub sniffer_handle_sigchld {
    my ($kernel,$heap,$child,$exit_code) = @_[KERNEL,HEAP,ARG1,ARG2];
    my $child_pid = $child->ID;
    $exit_code ||= 0;
    my $exit_status = $exit_code >>8;
    return unless $exit_code != 0;
    $kernel->post( $heap->{log} => notice => "Received SIGCHLD from $child_pid ($exit_status)" );
}
#------------------------------------------------------------------------#
sub sniffer_dns_parse {
    my ($kernel,$heap,$layer4,$ip) = @_[KERNEL,HEAP,ARG0,ARG1];

    # Parse DNS Packet
    my $dnsp = Net::DNS::Packet->new( \$layer4->{data} );
    return unless defined $dnsp;
    increment_stat( $heap, 'dns' );

    #
    # Server Accounting.
    my $qa = $dnsp->header->qr ? 'answer' : 'question';
    increment_stat( $heap, $qa );

    my %info = ( 'time' => $ip->{time} );
    if( $qa eq 'answer' ) {
        $info{server} = $ip->{src_ip};
        $info{server_port} = $ip->{src_port};
        $info{client} = $ip->{dest_ip}; 
        $info{client_port} = $ip->{dest_port};
    }
    else {
        $info{server} = $ip->{dest_ip};
        $info{server_port} = $ip->{dest_port};
        $info{client} = $ip->{src_ip};
        $info{client_port} = $ip->{src_port};
    }

    # Conversations
    my %ID = ();
    if( defined $heap->{dbh} && ref $heap->{dbh} eq 'DBIx::Connector' ) {
        my $dbError = undef;
        my $sth = $heap->{dbh}->run( fixup => sub {
                my $sth = $_->prepare('select * from find_or_create_conversation( ?, ? )');
                $sth->execute( $info{client}, $info{server} );
                $sth;
            }, catch {
                $dbError = "find_or_create_conversation failed: $_";
            }
        );
        if( $dbError || $sth->rows == 0 ) {
            $kernel->post( $heap->{log} => notice => qq|conversation tracking failed between $info{client} and $info{server}| );
            return;
        }
        my $convo = $sth->fetchrow_hashref;
        %ID = (
            client_id => $convo->{client_id},
            server_id => $convo->{server_id},
            conversation_id => $convo->{id},
        );
    }

    foreach my $plugin_name ( keys %{ $heap->{_loaded_plugins} } ) {
        $kernel->post( $plugin_name => process => $dnsp, { %info, %ID } );
        increment_stat( $heap, "plugin::$plugin_name" );
    }
}

sub sniffer_stats {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Delete the stats from the heap;
    my $stats = delete $heap->{stats};

    my @pairs = ();
    foreach my $k (qw( dispatch packet invalid udp tcp port53 dns question answer )) {
        if( exists $stats->{$k} ) {
            push @pairs, "$k=$stats->{$k}";
        }
    }
    foreach my $plugin ( sort grep /^plugin\:\:/, keys %{ $stats } ) {
        push @pairs, "$plugin=$stats->{$plugin}";
    }
    $kernel->post( log => 'debug' => 'STATS: ' . join(', ', @pairs) );

    # RRD Track these
    my @tracked = (qw(dispatch packet udp tcp question answer),
        map { join('::', 'plugin', $_ ) } keys %{ $heap->{_loaded_plugins} }
    );
    foreach my $stat ( @tracked ) {
        my @path = split /\:\:/, $stat;
        #$rrd->update( { count => exists $stats->{$stat} ? $stats->{$stat} : 0 } );
        # TODO: Replace this with graphite bindings
    }

    # Redo Stats Event
    $kernel->delay_add( 'sniffer_stats', 60 );
}

sub increment_stat {
    my ($heap,$key) = @_;

    # make sure the stat exists
    if( !exists $heap->{stats}  ) {
        $heap->{stats} = {};
    }
    if( !exists $heap->{stats}{$key} ) {
        $heap->{stats}{$key} = 0;
    }
    # increment stat
    $heap->{stats}{$key}++;
}

# RETURN TRUE;
1;
