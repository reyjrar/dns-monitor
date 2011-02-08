package dns::monitor::Schema::conversation;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw(PK::Auto TimeStamp InflateColumn::DateTime));
__PACKAGE__->table( 'conversation' );
__PACKAGE__->add_columns(
	id	=> {
		data_type	=> 'integer',
		size => 32,
		is_auto_increment => 1,
	},
	server_id => {
		data_type => 'integer',
		size => 32,
	},
	client_id => {
		data_type => 'integer',
		size => 32,
	},
	first_ts	=> {
		data_type => 'datetime',
		size => 20,
		inflate_datetime => 1,
		set_on_create => 1,
	},
	last_ts  => {
		data_type => 'datetime',
		size => 20,
		inflate_datetime => 1,
		set_on_update => 1,
		set_on_create => 1,
	},
	client_is_server => {
		data_type => 'bool',
		default_value => 'false',
	},
);
__PACKAGE__->set_primary_key('id');

# Constraints
__PACKAGE__->add_unique_constraint( 'conversation_uniq_server_client' => [qw(server_id client_id)] );

# Relationships
__PACKAGE__->has_one('server', 'dns::monitor::Schema::server',
	{ 'foreign.id' => 'self.server_id' },
);
__PACKAGE__->has_one('client', 'dns::monitor::Schema::client',
	{ 'foreign.id' => 'self.client_id' },
);
