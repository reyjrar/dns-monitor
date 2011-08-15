package dns::monitor::Schema::Result::blacklisted::answer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::blacklisted::answer

=cut

__PACKAGE__->table("blacklisted_answer");

=head1 ACCESSORS

=head2 blacklisted_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 answer_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "blacklisted_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "answer_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("answer_id", "blacklisted_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:34:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:p0MXCIeX3iiZuc2FjJeUlg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
