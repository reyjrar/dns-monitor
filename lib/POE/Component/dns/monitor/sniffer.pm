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
use Net::DNS::Packet;
# Handle Loading Plugins
use Module::Pluggable require => 1, search_path => [ 'POE::Component::dns::monitor::sniffer::plugin' ];
use YAML;
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
			Config		=> $configFile,			# Required
			DBICSchema	=> $model,				# Required
			LogSID		=> 'log',				# Default
			PcapOpts	=> \%pcapOpts,			# See below for details
			Plugins		=> \%pluginConfig,		# See below for details
	);

=head1 EXPORT

POE::Component::dns::monitor::sniffer does not export any symbols

=head1 FUNCTIONS

=head2 spawn

Creates the POE::Session for the dns::monitor::sniffer.

Parameters:

	B<Config> is a filename to a YAML Config File.

	B<DBICSchema> is a DBIx::Class::Schema object that's connected.

	B<LogSID> is the Session ID of a POE::Component::Logger session or your custom logging
	session capable of handling standard log level events.

	B<PcapOpts> is a hashref containing options to send to the Net::Pcap module
		Defaults to:
			{ dev => 'any', snaplen => 1518, filter => 'udp and port 53', promisc => 0 }
		You should really send something more interesting than that

	B<Plugins> is a hash ref for plugin options
		Defaults to:
		{
			'packet::logger'		=> { enable => 1, keep_for => '30 days' },
			'server::authorized'	=> { enable => 1 },
			'server::stats'			=> { enable => 1, rrd => 1 },
			'client::stats'			=> { enable => 1, rrd => 1 },
		}
=cut

sub spawn {
	my $self = shift;

	# Process Arguments
	my %args = (
		DBICSchema 		=> undef,
		LogSID			=> 'log',
		@_
	);
	# Defaults
	my %pcapOpts = ( dev => 'any', snaplen => 1518, filter => 'udp and port 53', promisc => 0 );
	my %pluginConfig = (
		'packet::logger'		=> { enable => 1, keep_for => '30 days' },
		'server::authorized'	=> { enable => 1 },
		'server::stats'			=> { enable => 1, rrd => 1 },
		'client::stats'			=> { enable => 1, rrd => 1 },
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
		Alias		=> 'pcap',
		Device		=> $args{PcapOpts}->{dev},
		Dispatch	=> 'handle_packet',
		Session		=> 'sniffer',
	);

	# Configure the Sniffer Session
	my $session_id = POE::Session->create( 
		inline_states => {
			_start	=> sub { $poe_kernel->yield( 'sniffer_start' => \%args ) },
			_stop	=> sub {} ,	
			sniffer_start 			=> \&sniffer_start,
			sniffer_load_plugins	=> \&sniffer_load_plugins,
			# Actually handle the packet
			handle_packet			=> \&sniffer_handle_packet,
		},
	);

	return $session_id;
}	

sub sniffer_start {
	my ($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

	# Store the Args in the Heap
	$heap->{_config} = $args->{Config};
	$heap->{model} = $args->{DBICSchema};
	$heap->{log} = $args->{LogSID};
	$heap->{_plugins} = $args->{Plugins};
	$heap->{_pcap} = $args->{PcapOpts};

	# Set the Alias
	$kernel->alias_set( 'sniffer' );

	# Load the Plugins
	$kernel->yield( 'sniffer_load_plugins' );

	# Configure the Pcap Handler
	$kernel->post( pcap => open_live => @{$args->{PcapOpts}}{qw(dev snaplen promisc timeout)} );
	$kernel->post( $heap->{log} => debug => "pcap::filter : $args->{PcapOpts}{filter}" );
	$kernel->post( pcap => set_filter => $args->{PcapOpts}{filter} )
		if exists $args->{PcapOpts}{filter} && length $args->{PcapOpts}{filter};
	$kernel->post( pcap => 'run' );
}

sub sniffer_load_plugins {
	my ($self,$kernel,$heap) = @_[OBJECT,KERNEL,HEAP];

	my %loadedPlugins = ();
	my $charsToStrip = length('POE::Component::dns::monitor::sniffer::plugin::');
	foreach my $plugin ( __PACKAGE__->plugins ) {
		my $name = substr($plugin, $charsToStrip );
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
			$loadedPlugins{$name} = $plugin->spawn(
				Alias => $name,
				Config => $pluginConf,
				DBICSchema => $heap->{model},
				LogSID => $heap->{log},
			);
		} catch {
			$kernel->post( $heap->{log} => warning => "plugin::$name : unable to spawn: $_" );
		};
	}
	$heap->{_loaded_plugins} = \%loadedPlugins;
	$kernel->post( $heap->{log} => notice => "plugins loaded: " . join(', ', sort keys %loadedPlugins) );
}

#------------------------------------------------------------------------#
# sniffer_handle_packet
#  - dispatch the packet to the parser
sub sniffer_handle_packet {
	my ($kernel,$heap,$packets) = @_[KERNEL,HEAP,ARG0];

	foreach my $inst ( @{ $packets } )  {
		my ($hdr, $pkt) = @{ $inst };
		next unless defined $hdr;
	
		#
		# Begin Decoding
		my $eth_pkt = NetPacket::Ethernet->decode( $pkt );
		my $ip_pkt  = NetPacket::IP->decode( eth_strip($pkt) );
	
		return unless defined $ip_pkt;
		return unless $ip_pkt->{proto};

		if( $ip_pkt->{proto} == IP_PROTO_UDP ) {
			dns_parse( $pkt, $ip_pkt, $heap );
		}
	}
}

#------------------------------------------------------------------------#
sub dns_parse {
	my ($orig, $ip, $heap) = @_;

	#
	# udp packet breakdown
	my $udp = NetPacket::UDP->decode( ip_strip( eth_strip($orig) ) );
	$poe_kernel->post( $heap->{log} => debug =>  "Packet $ip->{src_ip}:$udp->{src_port}" .
			" to $ip->{dest_ip}:$udp->{dest_port}"
	);
	#
	# Server Accounting.
	my %ip = ();
	if( $udp->{src_port} == 53 ) {
		$ip{server} = $ip->{src_ip};
		$ip{client} = $ip->{dest_ip};
	}
	elsif ( $udp->{dest_port} == 53 ) {
		$ip{server} = $ip->{dest_ip};
		$ip{client} = $ip->{src_ip};
	}

	return unless  $ip{client} and $ip{server};
	$poe_kernel->post( $heap->{log} => debug => "Server: $ip{server}, Client => $ip{client}");

	# Net::DNS Packet
	my $dnsp = Net::DNS::Packet->new( \$udp->{data} );
	if( defined $dnsp ) {
		# Client and Server Objects
		my $srv = $heap->{model}->resultset('server')->find_or_create( { ip => $ip{server} } );
		my $cli = $heap->{model}->resultset('client')->find_or_create( { ip => $ip{client} } );

		foreach my $plugin_name ( keys %{ $heap->{_loaded_plugins} } ) {
			$poe_kernel->post( $plugin_name => process => $dnsp, $srv, $cli );
		}
	}
}

# RETURN TRUE;
1;
