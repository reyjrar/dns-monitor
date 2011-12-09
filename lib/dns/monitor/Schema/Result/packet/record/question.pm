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

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'packet_record_question_id_seq'

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
    sequence          => "packet_record_question_id_seq",
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
  "reference_count",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("packet_record_question_uniq", ["class", "type", "name"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:34:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rBvoSUUZ4eiWPOT/PV3JDQ

# Relationships
__PACKAGE__->has_many('meta', 'dns::monitor::Schema::Result::packet::meta::question',
	{ 'foreign.question_id' => 'self.id' }
);
__PACKAGE__->many_to_many('queries' => 'meta', 'query' );

# Many-to-Many Lists:
__PACKAGE__->has_many( 'list_meta', 'dns::monitor::Schema::Result::list::meta::question',
	{ 'foreign.question_id' => 'self.id' }
);
__PACKAGE__->many_to_many('lists' => 'list_meta', 'list' );

1;
