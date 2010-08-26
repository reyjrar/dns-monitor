package dns::monitor::Schema::packet::data::answer;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw(PK::Auto));
__PACKAGE__->table( 'packet_data_answer' );
__PACKAGE__->add_columns(
	id => {
		data_type => 'integer',
		size => 16,
		is_auto_increment => 1,
	},
	response_id => {
		data_type => 'integer',
		size => 16,
	},
	name => {
		data_type => 'text',
		size => 255,
	},
	type => {
		data_type => 'text',
		size => 20,
	},
	class => {
		data_type => 'text',
		size => 10,
		default_value => 'IN',
	},
	opts => {
		data_type => 'text',
		size => 255,
	},
	ttl => {
		data_type => 'integer',
		size => 32,
	},
	section => {
		data_type => 'text',
		size => 10,
		default_value => 'answer',
	},
);
__PACKAGE__->set_primary_key( 'id' );

# Relationships
__PACKAGE__->belongs_to( 'response', 'dns::monitor::Schema::packet::response',
	{ 'foreign.id' => 'self.response_id' }
);

1;
