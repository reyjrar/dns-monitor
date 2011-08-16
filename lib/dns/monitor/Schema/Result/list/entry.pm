package dns::monitor::Schema::Result::list::entry;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::list::entry

=cut

__PACKAGE__->table("list_entry");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'list_entry_id_seq'

=head2 list_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 zone

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 path

  data_type: 'ltree'
  is_nullable: 0

=head2 refreshed

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 first_ts

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 last_ts

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "list_entry_id_seq",
  },
  "list_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "zone",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "path",
  { data_type => "ltree", is_nullable => 0 },
  "refreshed",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "first_ts",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "last_ts",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("list_entry_uniq", ["zone", "list_id"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-16 13:01:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z1k6NR7qOtX28KoFS8PR0Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
