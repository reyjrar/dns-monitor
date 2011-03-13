package dns::monitor::Schema::Result::packet::record::question;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::packet::record::question

=cut

__PACKAGE__->table("packet_record_question");

=head1 ACCESSORS

=head2 id

  data_type: bigint
  default_value: SCALAR(0x1a568fe0)
  is_auto_increment: 1
  is_nullable: 0

=head2 first_ts

  data_type: timestamp without time zone
  default_value: SCALAR(0x1a566f50)
  is_nullable: 0

=head2 last_ts

  data_type: timestamp without time zone
  default_value: SCALAR(0x1a56d790)
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

=head2 reference_count

  data_type: bigint
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    default_value     => \"nextval('packet_record_question_id_seq'::regclass)",
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
  "reference_count",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("packet_record_question_uniq", ["class", "type", "name"]);


# Created by DBIx::Class::Schema::Loader v0.05002 @ 2011-03-12 21:06:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tSe0xgm2o7a0W6+s+YuLGg

# Relationships
__PACKAGE__->has_many('meta', 'dns::monitor::Schema::Result::packet::meta::question',
	{ 'foreign.question_id' => 'self.id' }
);
__PACKAGE__->many_to_many('queries' => 'meta', 'query' );

1;
