package dns::monitor::Schema::packet::query;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw(PK::Auto TimeStamp InflateColumn::DateTime));
__PACKAGE__->table( 'packet_query' );
__PACKAGE__->add_columns(
	id => {
		data_type => 'integer',
		size => 32,
		is_auto_increment => 1,
	},
	client_id => {
		data_type => 'integer',
		size => 32,
	},
	client_port => {
		data_type => 'integer',
		size => 32,
		is_nullable => 1,
	},
	server_id => {
		data_type => 'integer',
		size => 32,
	},
	server_port => {
		data_type => 'integer',
		size => 32,
		is_nullable => 1,
	},
	query_ts => {
		data_type => 'datetime',
		size => 20,
		inflate_datetime => 1,
		set_on_create => 1,
	},
	query_serial => {
		data_type => 'integer',
		size => 32,
	},
	response_id => {
		data_type => 'integer',
		size => 32,
		is_nullable => 1,
	},
	conversation_id => {
		data_type => 'integer',
		size => 32,
	},
	opcode => { data_type => 'character varying', size => 12, },
	count_questions => { data_type => 'integer', size => 32, },
	flag_recursive				=> { data_type => 'bool', default_value => 'false', },
	flag_truncated				=> { data_type => 'bool', default_value => 'false', },
	flag_checking				=> { data_type => 'bool', default_value => 'false', },
);
__PACKAGE__->set_primary_key( 'id' );

#------------------------------------------------------------------------#
# Relationships
__PACKAGE__->belongs_to( 'client', 'dns::monitor::Schema::client',
	{ 'foreign.id' => 'self.client_id' }
);

__PACKAGE__->belongs_to( 'server', 'dns::monitor::Schema::server',
	{ 'foreign.id' => 'self.server_id' }
);

__PACKAGE__->belongs_to('response', 'dns::monitor::Schema::packet::response',
	{ 'foreign.id' => 'self.response_id' },
);

__PACKAGE__->has_one( 'conversation', 'dns::monitor::Schema::packet::meta::conversation',
	{ 'foreign.id' => 'self.conversation_id' }
);

__PACKAGE__->has_many( 'query_questions', 'dns::monitor::Schema::packet::meta::question',
	{ 'foreign.query_id' => 'self.id' }
);
__PACKAGE__->many_to_many( questions => 'query_questions', 'question');

1;
