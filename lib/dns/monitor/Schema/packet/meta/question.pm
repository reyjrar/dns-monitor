package dns::monitor::Schema::packet::meta::question;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw(PK::Auto));
__PACKAGE__->table( 'packet_meta_question' );
__PACKAGE__->add_columns(
	query_id	=> {
		data_type	=> 'integer',
		size => 32,
	},
	question_id => {
		data_type => 'integer',
		size => 32,
	},
);
__PACKAGE__->set_primary_key( qw(query_id question_id) );

# Relationships
__PACKAGE__->has_one('query', 'dns::monitor::Schema::packet::query',
	{ 'foreign.id' => 'self.query_id' },
);
__PACKAGE__->has_one('question', 'dns::monitor::Schema::packet::record::question',
	{ 'foreign.id' => 'self.question_id' },
);
