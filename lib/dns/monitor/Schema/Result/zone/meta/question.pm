package dns::monitor::Schema::Result::zone::meta::question;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::zone::meta::question

=cut

__PACKAGE__->table("zone_question");

=head1 ACCESSORS

=head2 zone_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 question_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "zone_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "question_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("zone_id", "question_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:34:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jmXdHYs7pSS9OoiKA1hOTA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
