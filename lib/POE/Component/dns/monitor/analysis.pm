package POE::Component::dns::monitor::analysis;

use strict;
use warnings;

# DateTime Handling
use DateTime;
use DateTime::Format::Duration;
# Caching
use CHI;
# Handle Loading Plugins
use Module::Pluggable require => 1, search_path => [ 'POE::Component::dns::monitor::analysis::plugin' ];
use YAML;
use Try::Tiny;

# POE
use POE;

=head1 NAME

POE::Component::dns::monitor::analysis - Passive Analysis on Packets Logged

=cut

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use POE::Component::dns::monitor::analysis;

    my $snif_sess_id = POE::Component::dns::monitor::analysis->spawn(
            Config      => $configFile,         # Required
            DBH         => $dbh,                # Required
            LogSID      => 'log',               # Default
            Plugins     => \%pluginConfig,      # See below for details
    );

=head1 EXPORT

POE::Component::dns::monitor::analysis does not export any symbols

=head1 FUNCTIONS

=head2 spawn

Creates the POE::Session for the dns::monitor::analysis.

Parameters:

    B<Config> is a filename to a YAML Config File.

    B<DBH> is a DBIx::Connector object that's connected.

    B<LogSID> is the Session ID of a POE::Component::Logger session or your custom logging
    session capable of handling standard log level events.

    B<Plugins> is a hash ref for plugin options
        Defaults to:
        {
            'query::response'       => { enable => 1 },
        }
=cut

sub spawn {
    my $self = shift;

    # Process Arguments
    my %args = (
        DBH             => undef,
        LogSID          => 'log',
        @_
    );
    # Defaults
    my %pluginConfig = (
        'query::response'       => { enable => 1 },
    );
    # Hashify
    foreach my $hashOpt(qw( Plugins ) ) {
        $args{$hashOpt} = ref $args{$hashOpt} eq 'HASH' ? $args{$hashOpt} : {};
    }
    # Configure Defaults: Plugins
    foreach my $k ( keys %pluginConfig ) {
        if( ! exists $args{Plugins}->{$k} ) {
            $args{Plugins}->{$k} = $pluginConfig{$k};
        }
    }

    # Configure the analysis Session
    my $session_id = POE::Session->create(
        inline_states => {
            _start  => sub { $poe_kernel->yield( 'analysis_start' => \%args ) },
            _stop   => sub {} ,
            _child  => \&analysis_handle_sigchld,
            analysis_start          => \&analysis_start,
            analysis_load_plugins   => \&analysis_load_plugins,
        },
    );

    return $session_id;
}

#------------------------------------------------------------------------#
# analysis_start
#  Just load all the plugins, this session barely does anything.
sub analysis_start {
    my ($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

    # Store the Args in the Heap
    $heap->{_config} = $args->{Config};
    $heap->{dbh} = $args->{DBH};
    $heap->{log} = $args->{LogSID};
    $heap->{_plugins} = $args->{Plugins};

    # Set the Alias
    $kernel->alias_set( 'analysis' );

    # Load the Plugins
    $kernel->yield( 'analysis_load_plugins' );
}

#------------------------------------------------------------------------#
# Load all the plugins
sub analysis_load_plugins {
    my ($self,$kernel,$heap) = @_[OBJECT,KERNEL,HEAP];

    my %loadedPlugins = ();
    my $charsToStrip = length('POE::Component::dns::monitor::analysis::plugin::');
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

        if( !$plugin->can('spawn') || !$plugin->can('analyze') ) {
            $kernel->post( $heap->{log} => notice => "plugin::$name : API Failure, skipping" );
            next;
        }
        $kernel->post( $heap->{log} => debug => "plugin::$name : attempting to bootstrap" );
        
        try {
            $loadedPlugins{$name} = $plugin->spawn(
                Alias => $name,
                Config => $pluginConf,
                DBH => $heap->{dbh},
                LogSID => $heap->{log},
            );
        } catch {
            $kernel->post( $heap->{log} => warning => "plugin::$name : unable to spawn: $_" );
            delete $loadedPlugins{$name};
        };
    }
    $heap->{_loaded_plugins} = \%loadedPlugins;
    $kernel->post( $heap->{log} => notice => "plugins loaded: " . join(', ', sort keys %loadedPlugins) );
}


#------------------------------------------------------------------------#
sub analysis_handle_sigchld {
    my ($kernel,$heap,$child,$exit_code) = @_[KERNEL,HEAP,ARG1,ARG2];
    my $child_pid = $child->ID;
    $exit_code ||= 0;
    my $exit_status = $exit_code >>8;
    return unless $exit_code != 0;
    $kernel->post( $heap->{log} => notice => "Received SIGCHLD from $child_pid ($exit_status)" );
}

# RETURN TRUE;
1;
