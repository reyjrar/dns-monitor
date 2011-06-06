package dns::monitor::Schema::Result::packet::record::answer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::packet::record::answer

=cut

__PACKAGE__->table("packet_record_answer");

=head1 ACCESSORS

=head2 id

  data_type: bigint
  default_value: SCALAR(0x1a509450)
  is_auto_increment: 1
  is_nullable: 0

=head2 first_ts

  data_type: timestamp without time zone
  default_value: SCALAR(0x1a56d8a0)
  is_nullable: 0

=head2 last_ts

  data_type: timestamp without time zone
  default_value: SCALAR(0x1a566800)
  is_nullable: 0

=head2 name

  data_type: character varying
  default_value: undef
  is_nullable: 0
  size: 255

=head2 type

  data_type: character varying
  default_value: undef
  is_nullable: 0
  size: 20

=head2 class

  data_type: character varying
  default_value: IN
  is_nullable: 0
  size: 10

=head2 value

  data_type: character varying
  default_value: undef
  is_nullable: 1
  size: 255

=head2 opts

  data_type: character varying
  default_value: undef
  is_nullable: 1
  size: 255

=head2 reference_count

  data_type: bigint
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    default_value     => \"nextval('packet_record_answer_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable       => 0,
  },
  "first_ts",
  {
    data_type     => "timestamp without time zone",
    default_value => \"now()",
    is_nullable   => 0,
  },
  "last_ts",
  {
    data_type     => "timestamp without time zone",
    default_value => \"now()",
    is_nullable   => 0,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "class",
  {
    data_type => "character varying",
    default_value => "IN",
    is_nullable => 0,
    size => 10,
  },
  "value",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "opts",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "reference_count",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(
  "packet_record_answer_uniq",
  ["class", "type", "name", "value"],
);


# Created by DBIx::Class::Schema::Loader v0.05002 @ 2011-03-12 21:06:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cLRUtQXIrn9tHt6ZeH7nfg

# Relationships
__PACKAGE__->has_many( 'meta', 'dns::monitor::Schema::Result::packet::meta::answer',
	{ 'foreign.answer_id' => 'self.id' }
);
__PACKAGE__->many_to_many('responses' => 'meta', 'response' );

1;
