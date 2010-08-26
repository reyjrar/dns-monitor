package dns::monitor::Schema::server;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw(PK::Auto TimeStamp InflateColumn::DateTime));
__PACKAGE__->table( 'server' );
__PACKAGE__->add_columns(
	id => {
		data_type => 'integer',
		size => 16,
		is_auto_increment => 1,
	},
	ip => {
		data_type => 'text',
		size => 15,
	},
	hostname => {
		data_type => 'text',
		size => 255,
		is_nullable => 1,
	},
	first_ts => {
		data_type => 'datetime',
		size => 20,
		inflate_datetime => 1,
		set_on_create => 1,
	},
	last_ts => {
		data_type => 'datetime',
		size => 20,
		inflate_datetime => 1,
		set_on_create => 1, set_on_update => 1,
	},
	is_authorized => {
		data_type => 'bool',
		default_value => 'false',
	},
);
__PACKAGE__->set_primary_key( 'id' );

1;
