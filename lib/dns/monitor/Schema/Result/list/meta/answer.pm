package dns::monitor::Schema::Result::list::meta::answer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::list::meta::answer

=cut

__PACKAGE__->table("list_meta_answer");

=head1 ACCESSORS

=head2 list_entry_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 answer_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 list_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "list_entry_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "answer_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "list_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("answer_id", "list_entry_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-12-09 16:59:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KGpkIgzrNEMuBgVT9bBm4A

# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->has_one('answer', 'dns::monitor::Schema::Result::packet::record::answer',
	{ 'foreign.id' => 'self.answer_id' },
);
__PACKAGE__->has_one('entry', 'dns::monitor::Schema::Result::list::entry',
	{ 'foreign.id' => 'self.list_entry_id' },
);
__PACKAGE__->has_one('list', 'dns::monitor::Schema::Result::list',
	{ 'foreign.id' => 'self.list_id' },
);

1;
