package dns::monitor::View::Mason;

use strict;
use warnings;

use parent 'Catalyst::View::Mason';
use dns::monitor;

__PACKAGE__->config(use_match => 0);
__PACKAGE__->config(comp_root => dns::monitor->path_to(qw(root))->absolute->stringify );
__PACKAGE__->config(data_dir => dns::monitor->path_to(qw(cache mason))->absolute->stringify );
=head1 NAME

dns::monitor::View::Mason - Mason View Component for dns::monitor

=head1 DESCRIPTION

Mason View Component for dns::monitor

=head1 SEE ALSO

L<dns::monitor>, L<HTML::Mason>

=head1 AUTHOR

Brad Lhotsky

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
