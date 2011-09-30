package dns::monitor::core::plugin::db;

use Moose;

extends 'dns::monitor::core::plugin';

has dbconn => (
	isa => 'Object',
	is => 'ro',
	required => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable();
1;
