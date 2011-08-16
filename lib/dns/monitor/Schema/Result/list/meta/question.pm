package dns::monitor::Schema::Result::list::meta::question;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::list::meta::question

=cut

__PACKAGE__->table("list_meta_question");

=head1 ACCESSORS

=head2 list_entry_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 question_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "list_entry_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "question_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("question_id", "list_entry_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-16 13:01:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pK8sA7EFwSfrhfhCd+W1XA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
