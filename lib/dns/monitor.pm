package dns::monitor;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;
use DBIx::Connector;
use Exception::Class::DBI;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    ConfigLoader
    Static::Simple
    StackTrace
    
    Session
    Session::Store::FastMmap
    Session::State::Cookie
/;

extends 'Catalyst';

our $VERSION = '0.02';
$VERSION = eval $VERSION;

# Configure the application.
#
# Note that settings in dns_monitor.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'dns::monitor',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    default_view => 'Mason',
    time_zone => 'America/New_York',
);

# Start the application
__PACKAGE__->setup();


has dbconn => ( is => 'ro', lazy => 1, default => sub {
        DBIx::Connector->new(
            __PACKAGE__->config->{db}{dsn},
            __PACKAGE__->config->{db}{user},
            __PACKAGE__->config->{db}{pass},
        {
            PrintError => 0,
            RaiseError => 0,
            HandleError => Exception::Class::DBI->handler,
            AutoCommit => 1,
            pg_enable_utf8 => 1,
        });
});

=head1 NAME

dns::monitor - Catalyst based application

=head1 SYNOPSIS

    script/dns_monitor_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<dns::monitor::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
