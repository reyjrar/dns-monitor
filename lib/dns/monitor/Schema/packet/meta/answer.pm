package dns::monitor::Schema::packet::meta::answer;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw(PK::Auto));
__PACKAGE__->table( 'packet_meta_answer' );
__PACKAGE__->add_columns(
	response_id	=> {
		data_type	=> 'integer',
		size => 32,
	},
	answer_id => {
		data_type => 'integer',
		size => 32,
	},
	ttl	=> {
		data_type	=> 'integer',
		size => 32,
	},
	section => {
		data_type => 'character',
		size => 10,
		default_value => 'answer',
	},
);
__PACKAGE__->set_primary_key( qw(response_id answer_id) );

# Relationships
__PACKAGE__->has_one('response', 'dns::monitor::Schema::packet::response',
	{ 'foreign.id' => 'self.response_id' },
);
__PACKAGE__->has_one('answer', 'dns::monitor::Schema::packet::record::answer',
	{ 'foreign.id' => 'self.answer_id' },
);
