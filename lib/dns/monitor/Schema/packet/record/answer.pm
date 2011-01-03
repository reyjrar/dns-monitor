package dns::monitor::Schema::packet::record::answer;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw(PK::Auto TimeStamp InflateColumn::DateTime));
__PACKAGE__->table( 'packet_record_answer' );
__PACKAGE__->add_columns(
	id => {
		data_type => 'integer',
		size => 32,
		is_auto_increment => 1,
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
	name => {
		data_type => 'character varying',
		size => 255,
	},
	type => {
		data_type => 'character varying',
		size => 20,
	},
	class => {
		data_type => 'character varying',
		size => 10,
		default_value => 'IN',
	},
	value => {
		data_type => 'character varying',
		size => 255,
		is_nullable => 1,
	},
	opts => {
		data_type => 'character varying',
		size => 255,
		is_nullable => 1,
	},
	reference_count => {
		data_type => 'integer',
		size => 32,
		default_value => 0,
	},
);
__PACKAGE__->set_primary_key( 'id' );

# Relationships
__PACKAGE__->has_many( 'meta', 'dns::monitor::Schema::packet::meta::answer',
	{ 'foreign.answer_id' => 'self.id' }
);
__PACKAGE__->many_to_many('responses' => 'meta', 'response' );

1;
