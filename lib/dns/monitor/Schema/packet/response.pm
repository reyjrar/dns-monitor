package dns::monitor::Schema::packet::response;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw(PK::Auto TimeStamp InflateColumn::DateTime));
__PACKAGE__->table( 'packet_response' );
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
	server_id => {
		data_type => 'integer',
		size => 32,
	},
	query_serial => {
		data_type => 'integer',
		size => 32
	},
	response_ts => {
		data_type => 'datetime',
		size => 20,
		inflate_datetime => 1,
		set_on_create => 1,
	},
	opcode => { data_type => 'character varying', size => 10, },
	status => { data_type => 'character varying', size => 10, },
	size_answer => { data_type => 'integer', size => 32, default_value => 0 },
	count_answer		=> { data_type => 'integer', size => 32, default_value => 0 },
	count_additional	=> { data_type => 'integer', size => 32, default_value => 0 },
	count_authority		=> { data_type => 'integer', size => 32, default_value => 0 },
	count_question		=> { data_type => 'integer', size => 32, default_value => 0 },
	flag_authoritative			=> { data_type => 'bool', default_value => 'false', },
	flag_authenticated			=> { data_type => 'bool', default_value => 'false', },
	flag_truncated				=> { data_type => 'bool', default_value => 'false', },
	flag_checking_desired		=> { data_type => 'bool', default_value => 'false', },
	flag_recursion_desired		=> { data_type => 'bool', default_value => 'false', },
	flag_recursion_available	=> { data_type => 'bool', default_value => 'false', },
	
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

__PACKAGE__->has_many('questions', 'dns::monitor::Schema::packet::data::question',
	{ 'foreign.response_id' => 'self.id' }
);

1;
