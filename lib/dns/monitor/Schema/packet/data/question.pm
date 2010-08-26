package dns::monitor::Schema::packet::data::question;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw(PK::Auto));
__PACKAGE__->table( 'packet_data_question' );
__PACKAGE__->add_columns(
	id => {
		data_type => 'integer',
		size => 32,
		is_auto_increment => 1,
	},
	query_id => {
		data_type => 'integer',
		size => 32,
	},
	response_id => {
		data_type => 'integer',
		size => 32,
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
	}
);
__PACKAGE__->set_primary_key( 'id' );

# Relationships
__PACKAGE__->belongs_to( 'query', 'dns::monitor::Schema::packet::query',
	{ 'foreign.id' => 'self.query_id' }
);
__PACKAGE__->belongs_to( 'response', 'dns::monitor::Schema::packet::response',
	{ 'foreign.id' => 'self.response_id' }
);


1;
