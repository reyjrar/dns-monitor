package dns::monitor::Schema::Result::packet::meta::question;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::packet::meta::question

=cut

__PACKAGE__->table("packet_meta_question");

=head1 ACCESSORS

=head2 query_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 question_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "query_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "question_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("query_id", "question_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:34:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MmxOFoBIMbSmpxNllFMDBg

# Relationships
__PACKAGE__->has_one('query', 'dns::monitor::Schema::Result::packet::query',
	{ 'foreign.id' => 'self.query_id' },
);
__PACKAGE__->has_one('question', 'dns::monitor::Schema::Result::packet::record::question',
	{ 'foreign.id' => 'self.question_id' },
);

1;
