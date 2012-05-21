package dns::monitor::core::sniffer;

use POE qw( Component::Pcap );

use MooseX::POE::SweetArgs;

extends qw(
    dns::monitor::core::logger
    dns::monitor::core::plugin::loader
    dns::monitor::core::stats::tracker
);

with qw(
    MooseX::POE::Aliased
);


=head1 NAME

  dns::monitor::core::sniffer - Passive DNS Sniffer

=head1 VERSION

Version 0.9

=cut

=head1 ATTRIBUTES

=cut

has name    => ( isa => 'String',   is => 'ro', default => 'sniffer' );
has config  => ( isa => 'HashRef',  is => 'rw', default => sub { {} } );

=head1 METHODS

=head2 log

Method to log data via POE::Component::Logger compatible session

=cut

sub log {
    my ($self,$level,@message) = @_;

    $self->post( $self->config->{LogSID}, $level, $_ ) for @message;
}

=head1 EVENTS

=head2 Initialization

Basic setup
 * Parse Configuraiton Hash
 * Load Plugins
 * Start Packet Capture

=cut

sub START {
    my $self = shift;
    my %args = (
        LogSID => 'log',
        @_
    );
    #########################################
    # liibpcap options parsing
    my %pcapOpts = ( dev => 'any', snaplen => 1518, filter => '(tcp or udp) and port 53', promisc => 0 );
    # Configure Defaults: PcapOpts
    foreach my $k ( keys %pcapOpts ) {
        if( ! exists $args{PcapOpts}->{$k} ) {
            $args{PcapOpts}->{$k} = $pcapOpts{$k};
        }
    }

    # Store Configuraiton
    $self->config( \%args );

    #########################################
    # Set Session ID
    $self->alias('sniffer');

    #########################################
    # Load all the plugins
    $self->yield( 'load_plugins' );

    #########################################
    # Configure the Pcap Session
    my $pcap_session_id = POE::Component::Pcap->spawn(
        Alias       => 'pcap',
        Device      => $args{PcapOpts}->{dev},
        Dispatch    => 'handle_packets',
        Session     => 'sniffer',
    );
    # Enable Packet Capture
    $self->yield( 'start_pcap' );
}


=head2 start_pcap

Begin capturing packets on the wire

=cut

event start_pcap => sub {
    my ($self) = @_;

    my $pcapOpts = $self->config->{pcapOpts};

    $self->log( debug => "opening pcap live" );
    $self->post( pcap => open_live => @{$pcapOpts}{qw(dev snaplen promisc timeout)} );
    $self->log( debug => "pcap::filter : $pcapOpts->{filter}" );
    $self->post( pcap => set_filter => $pcapOpts->{filter} )
        if exists $PcapOpts->{filter} && length $PcapOpts->{filter};
    $self->call( pcap => 'run' );
    $self->log( notice => 'packet capture started' );
};

=head2 start_pcap

Begin capturing packets on the wire

=cut

event handle_packets => sub {
};


no Moose;
__PACKAGE__->make_immutable;
