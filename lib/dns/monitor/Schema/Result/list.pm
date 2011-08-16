package dns::monitor::Schema::Result::list;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::list

=cut

__PACKAGE__->table("list");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'list_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 80

=head2 type_id

  data_type: 'smallint'
  is_foreign_key: 1
  is_nullable: 0

=head2 track

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 can_refresh

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 refresh_url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 refresh_every

  data_type: 'interval'
  default_value: '7 days'
  is_nullable: 1

=head2 refresh_last_ts

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "list_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 80 },
  "type_id",
  { data_type => "smallint", is_foreign_key => 1, is_nullable => 0 },
  "track",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "can_refresh",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "refresh_url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "refresh_every",
  { data_type => "interval", default_value => "7 days", is_nullable => 1 },
  "refresh_last_ts",
  { data_type => "timestamp", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-16 13:01:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9ob3SjYp9lxHGbpYQvl8ZQ


# Relationships
__PACKAGE__->has_many('entries' => 'dns::monitor::Schema::Result::list::entry' =>
	{ 'foreign.list_id' => 'self.id' }
);
__PACKAGE__->belongs_to('type' => 'dns::monitor::Schema::Result::list::type' =>
	{ 'foreign.id' => 'self.type_id' }
);

1;
