package dns::monitor::Schema::client::stats;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw(PK::Auto TimeStamp InflateColumn::DateTime));
__PACKAGE__->table( 'client_stats' );
__PACKAGE__->add_columns(
	client_id => {
		data_type => 'integer',
		size => 32,
	},
	day => {
		data_type => 'date',
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
	queries => {
		data_type => 'integer',
		default_value => 0,
	},
	answers => {
		data_type => 'integer',
		default_value => 0,
	},
	nx => {
		data_type => 'integer',
		default_value => 0,
	},
	errors => {
		data_type => 'integer',
		default_value => 0,
	},
);
__PACKAGE__->set_primary_key( qw(client_id day) );

# Relationships
__PACKAGE__->belongs_to( 'client' => 'dns::monitor::Schema::client' => 
	{ 'foreign.id' => 'self.client_id' }
);

1;
