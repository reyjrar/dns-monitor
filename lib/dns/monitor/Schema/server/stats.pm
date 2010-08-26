package dns::monitor::Schema::server::stats;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw(PK::Auto TimeStamp InflateColumn::DateTime));
__PACKAGE__->table( 'server_stats' );
__PACKAGE__->add_columns(
	server_id => {
		data_type => 'integer',
		size => 32,
	},
	day => {
		data_type => 'character varying',
		size => 15,
		inflate_datetime => 1,
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
	questions => {
		data_type => 'integer',
		size => 32,
		default_value => 0,
	},
	answers => {
		data_type => 'integer',
		size => 32,
		default_value => 0,
	},
);
__PACKAGE__->set_primary_key(qw(server_id day));

# Relationships
__PACKAGE__->belongs_to( 'server' => 'dns::monitor::Schema::server' =>
	{ 'foreign.id' => 'self.server_id' }
);

1;

