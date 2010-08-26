#!/usr/bin/env perl
#
# Use PoCo::Pcap to analyze DNS Packets for
# potential problems with the DNS infrastructure.
#
# Code by Brad Lhotsky <brad@divisionbyzero.net>
#

use strict;
use warnings;
use FindBin;

# Add local lib path
use lib "$FindBin::Bin/../lib";

# DateTime Handling
use DateTime;
use DateTime::Format::Duration;
# Packet Parsing
use NetPacket::Ethernet qw(:strip);
use NetPacket::IP qw(:strip :protos);
use NetPacket::UDP;
use Net::DNS::Packet;
# File name processing
use File::Spec;
use File::Basename;
# Config Parsing
use YAML::Syck;
$YAML::Syck::ImplicitTyping = 1;
# POE Environment
use EV;
use POE qw(
	Loop::EV
	Component::Daemon
	Component::Pcap
	Component::Logger
);

# DBIx::Class
use dns::monitor::Schema;

#------------------------------------------------------------------------#
# Locate all the necessary directories
my @BasePath = File::Spec->splitdir( $FindBin::Bin );
pop @BasePath;
my %DIRS = (
	'base'	=> File::Spec->catdir( @BasePath ),
	'lib'	=> File::Spec->catdir( @BasePath, 'lib' ),
	'etc'	=> File::Spec->catdir( @BasePath, 'conf' ),
	'cache'	=> File::Spec->catdir( @BasePath, 'cache' ),
	'db'	=> File::Spec->catdir( @BasePath, 'cache', 'db' ),
	'rrd'	=> File::Spec->catdir( @BasePath, 'cache', 'rrd' ),
);

#------------------------------------------------------------------------#
# Load Configuration
my $configFile = File::Spec->catfile( $DIRS{base}, 'dns_monitor.yml' );
my $CFG = LoadFile( $configFile ) or die "unable to load $configFile: $!\n";

#------------------------------------------------------------------------#
# POE Environment Setup
#------------------------------------------------------------------------#
#POE::Component::Daemon->spawn( detach => 1, babysit => 600, max_children => 5 );

#
# Setup the Logger
POE::Component::Logger->spawn(
	Alias		=> 'log',
	ConfigFile	=> $CFG->{log_cfg},
);

#
# Start Packet Capturing
POE::Component::Pcap->spawn(
	Alias		=> 'pcap',
	Device		=> $CFG->{pcap}{dev},
	Dispatch	=> 'handle_packet',
	Session		=> 'processor',
);

# Main Processor Session
POE::Session->create(
	inline_states	=> {
		_start			=> \&start_processor,
		_stop			=> \&stop_processor,
		handle_packet	=> \&handle_packet,
		report			=> \&show_report,
		connect_db		=> \&connect_db,
	},
);

#------------------------------------------------------------------------#
# Run the POE Sessions
#------------------------------------------------------------------------#
POE::Kernel->run;

#------------------------------------------------------------------------#
exit 0;
#------------------------------------------------------------------------#



#------------------------------------------------------------------------#
# Start the Processor
sub start_processor {
	my ($kernel,$heap) = @_[KERNEL,HEAP];

	$kernel->alias_set('processor');

	# Connect to the Database
	$kernel->yield( 'connect_db' );
	my %pcap_opts = %{ $CFG->{pcap} };

	# Setup the Packet Capture
	$kernel->post( pcap => open_live => @pcap_opts{qw(dev snaplen promisc timeout)} );
	$kernel->post( pcap => set_filter => $pcap_opts{filter} )
		if exists $pcap_opts{filter} && length $pcap_opts{filter};
	$kernel->post( pcap => 'run' );

	$kernel->post( log => debug => 'dns::monitor::sniffer started!' );
}
#------------------------------------------------------------------------#

#------------------------------------------------------------------------#
# stop the processor
sub stop_processor {
	my ($kernel,$heap) = @_[KERNEL,HEAP];
	
	# Stop pcap
	$kernel->post( 'pcap' => 'shutdown' );
}
#------------------------------------------------------------------------#


#------------------------------------------------------------------------#
# Check Connection to the database, re-establish if necessary.
sub connect_db {
	my ($kernel,$heap) = @_[KERNEL,HEAP];

	#
	# Skip if we're initialized
	if( defined $heap->{model} ) {
		return;
	}
	$heap->{model} = dns::monitor::Schema->connect( $CFG->{db}{dsn}, $CFG->{db}{user}, $CFG->{db}{pass} );

	# Reschedule Check
	$kernel->delay_add( 'connect_db', 1800 );
}

#------------------------------------------------------------------------#
sub handle_packet {
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


#------------------------------------------------------------------------#
sub dns_parse {
	my ($orig, $ip, $heap) = @_;

	#
	# udp packet breakdown
	my $udp = NetPacket::UDP->decode( ip_strip( eth_strip($orig) ) );
	$poe_kernel->post( log => debug =>  "Packet $ip->{src_ip}:$udp->{src_port}" .
			" to $ip->{dest_ip}:$udp->{dest_port}"
	);
	#
	# Server Accounting.
	my $srv = undef;
	my $cli = undef;
	if( $udp->{src_port} == 53 ) {
		$srv = $ip->{src_ip};
		$cli = $ip->{dest_ip};
	}
	elsif ( $udp->{dest_port} == 53 ) {
		$srv = $ip->{dest_ip};
		$cli = $ip->{src_ip};
	}
	$heap->{srv}{$srv}++;
			
	#
	# DNS Interpretation
	my $dnsp = Net::DNS::Packet->new( \$udp->{data} );
	if( defined $dnsp ) {
		#
		# Retrieve the Header
		my $hdr = $dnsp->header;
		return unless defined $hdr;
		#
		# Verify the packet is a response
		my $isResponse = $hdr->qr;
		return unless $isResponse;
		# Grab other flags
		my @flags = ();
		push @flags, 'rd' if $hdr->rd;
		push @flags, 'ra' if $hdr->ra;
		push @flags, 'tc' if $hdr->tc;
		push @flags, 'aa' if $hdr->aa;
		push @flags, 'ad' if $hdr->ad;
		push @flags, 'cd' if $hdr->cd;
		my $flags = join(' ', @flags);

		#
		# Retrieve the Data Section
		my $q = ($dnsp->question)[0];
		if( !defined $q ) {
			$poe_kernel->post( log => notice => "DNS Packet with no question section, flags: [ $flags ]: OP:" . $hdr->opcode );
			return;
		}

		# Make sure we're interested in this type:
		my $goodType = 0;
		my $qType = $q->qtype;
		foreach my $type ( @{ $CFG->{dns}{types} } ) {
			if( $qType eq $type ) {
				$goodType = 1;
				last;
			}
		}
		return unless $goodType;

		$poe_kernel->post( log => debug =>  "  [$flags]  Query: ", $q->qtype, " for ", $q->qname, ' (of ', $hdr->qdcount, ' questions)');
		$heap->{questions}{$srv}++;

		my @answers = $dnsp->answer;
		push @answers, $dnsp->authority;
		push @answers, $dnsp->additional;

		if( scalar @answers > 0 ) {
			$heap->{answered}{$srv}++;
		}
	
		foreach my $a ( @answers ) {
			my @params = (
				$a->class,
				$a->type,
				$a->ttl,
				$a->name
			);
			if( $a->type eq 'A' ) {
				push @params, $a->address, undef;
			}
			elsif( $a->type eq 'CNAME' ) {
				push @params, $a->cname, undef;
			}
			elsif( $a->type eq 'NS' ) {
				push @params, $a->nsdname, undef;
			}
			elsif( $a->type eq 'MX' ) {
				push @params, $a->exchange, $a->preference;
			}
			elsif( $a->type eq 'PTR' ) {
				push @params, $a->ptrdname, undef;
			}
			elsif( $a->type eq 'SOA' ) {
				# SKIP SOA!
				next;
			}
			else {
				# Catch all.
				push @params, $a->rdatastr, undef;
			}

			# dns_query_id, class, type, ttl, name, answer, additional_info
		}
	}
	else {
		$poe_kernel->post( log => notice =>  "Illegal DNS Packet $srv to $cli" );
	}

}
#------------------------------------------------------------------------#


#------------------------------------------------------------------------#
# Show a report of DNS Servers
sub show_report {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	print "\n*** DNS Server Report ***\n\n";

	foreach my $srv (sort { $heap->{srv}{$b} <=> $heap->{srv}{$a} } keys %{ $heap->{srv} } ) {
		print "\t\t\t\tDNS Server: $srv , $heap->{srv}{$srv} packets, $heap->{questions}{$srv} questioned, $heap->{answered}{$srv} answered.\n";
	}

	print "\n--- END REPORT---\n\n";
}
#------------------------------------------------------------------------#
