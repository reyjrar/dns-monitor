package dns::monitor::Schema::Result::blacklisted::question;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::blacklisted::question

=cut

__PACKAGE__->table("blacklisted_question");

=head1 ACCESSORS

=head2 blacklisted_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 question_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "blacklisted_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "question_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("question_id", "blacklisted_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:34:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2yS+/GqREyef1+u6STdN/A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
