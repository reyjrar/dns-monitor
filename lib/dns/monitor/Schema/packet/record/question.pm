package dns::monitor::Schema::packet::record::question;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw(PK::Auto));
__PACKAGE__->table( 'packet_record_question' );
__PACKAGE__->add_columns(
	id => {
		data_type => 'integer',
		size => 32,
		is_auto_increment => 1,
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
	reference_count => {
		data_type => 'integer',
		size => 32,
		default_value => 0,
	},
);
__PACKAGE__->set_primary_key( 'id' );

# Relationships
__PACKAGE__->has_many('meta', 'dns::monitor::Schema::packet::meta::question',
	{ 'foreign.question_id' => 'self.id' }
);
__PACKAGE__->many_to_many('queries' => 'meta', 'query' );

1;
