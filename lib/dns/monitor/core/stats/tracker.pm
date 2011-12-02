package dns::monitor::core::stats::tracker;

use dns::monitor::rrd;
use Moose;

=head1 NAME

=head1 VERSION

Version 0.1

=head1 SYNOPSIS

Provides stat tracking abilities to track basic statistics

=cut

sub BUILD {
	my ($self) = @_;

	my $rrdConfig = $self->config->{RRDOpts};
}

sub stat_increment {
	my ($self,$stat) = @_;
}

no Moose;
__PACKAGE__->make_immutable;
