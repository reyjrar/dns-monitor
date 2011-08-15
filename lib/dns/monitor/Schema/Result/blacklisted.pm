package dns::monitor::Schema::Result::blacklisted;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::blacklisted

=cut

__PACKAGE__->table("blacklisted");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'blacklisted_id_seq'

=head2 blacklist_id

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

=head2 blacklist_refreshed

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
    sequence          => "blacklisted_id_seq",
  },
  "blacklist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "zone",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "path",
  { data_type => "ltree", is_nullable => 0 },
  "blacklist_refreshed",
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
__PACKAGE__->add_unique_constraint("blacklisted_uniq", ["zone", "blacklist_id"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:34:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SO4z9KtRaWtojpJMoPebZw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
