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

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'packet_record_answer_id_seq'

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

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 class

  data_type: 'varchar'
  default_value: 'IN'
  is_nullable: 0
  size: 10

=head2 value

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 opts

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 reference_count

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "packet_record_answer_id_seq",
  },
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
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "class",
  { data_type => "varchar", default_value => "IN", is_nullable => 0, size => 10 },
  "value",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "opts",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "reference_count",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(
  "packet_record_answer_uniq",
  ["class", "type", "name", "value"],
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:34:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dJ6jD57smhIz2v33dL93lw

# Relationships
__PACKAGE__->has_many( 'meta', 'dns::monitor::Schema::Result::packet::meta::answer',
	{ 'foreign.answer_id' => 'self.id' }
);
__PACKAGE__->many_to_many('responses' => 'meta', 'response' );

1;
