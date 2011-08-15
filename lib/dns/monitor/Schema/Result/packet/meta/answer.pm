package dns::monitor::Schema::Result::packet::meta::answer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::packet::meta::answer

=cut

__PACKAGE__->table("packet_meta_answer");

=head1 ACCESSORS

=head2 response_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 answer_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 ttl

  data_type: 'bigint'
  is_nullable: 0

=head2 section

  data_type: 'char'
  default_value: 'answer'
  is_nullable: 0
  size: 10

=cut

__PACKAGE__->add_columns(
  "response_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "answer_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "ttl",
  { data_type => "bigint", is_nullable => 0 },
  "section",
  {
    data_type => "char",
    default_value => "answer",
    is_nullable => 0,
    size => 10,
  },
);
__PACKAGE__->set_primary_key("response_id", "answer_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:34:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ty1pw9/ADaV/rhkqkes+og

# Relationships
__PACKAGE__->has_one('response', 'dns::monitor::Schema::Result::packet::response',
	{ 'foreign.id' => 'self.response_id' },
);
__PACKAGE__->has_one('answer', 'dns::monitor::Schema::Result::packet::record::answer',
	{ 'foreign.id' => 'self.answer_id' },
);

1;
