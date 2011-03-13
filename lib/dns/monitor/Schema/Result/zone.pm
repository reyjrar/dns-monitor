package dns::monitor::Schema::Result::zone;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::zone

=cut

__PACKAGE__->table("zone");

=head1 ACCESSORS

=head2 id

  data_type: bigint
  default_value: SCALAR(0x1a575410)
  is_auto_increment: 1
  is_nullable: 0

=head2 parent_id

  data_type: bigint
  default_value: 0
  is_nullable: 0

=head2 name

  data_type: character varying
  default_value: undef
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    default_value     => \"nextval('zone_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable       => 0,
  },
  "parent_id",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("zone_uniq_name", ["name"]);


# Created by DBIx::Class::Schema::Loader v0.05002 @ 2011-03-12 21:06:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:d5iQBjYEO1yHpiS1wNYNFQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
