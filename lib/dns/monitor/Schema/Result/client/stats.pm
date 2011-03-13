package dns::monitor::Schema::Result::client::stats;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::client::stats

=cut

__PACKAGE__->table("client_stats");

=head1 ACCESSORS

=head2 client_id

  data_type: bigint
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0

=head2 day

  data_type: date
  default_value: undef
  is_nullable: 0

=head2 first_ts

  data_type: timestamp without time zone
  default_value: SCALAR(0x1a541a80)
  is_nullable: 0

=head2 last_ts

  data_type: timestamp without time zone
  default_value: SCALAR(0x1a566ec0)
  is_nullable: 0

=head2 queries

  data_type: integer
  default_value: 0
  is_nullable: 0

=head2 answers

  data_type: integer
  default_value: 0
  is_nullable: 0

=head2 nx

  data_type: integer
  default_value: 0
  is_nullable: 0

=head2 errors

  data_type: integer
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "client_id",
  {
    data_type      => "bigint",
    default_value  => undef,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "day",
  { data_type => "date", default_value => undef, is_nullable => 0 },
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
  "queries",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "answers",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "nx",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "errors",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("client_id", "day");


# Created by DBIx::Class::Schema::Loader v0.05002 @ 2011-03-12 21:06:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:y4XVF7Di2nP35R6MkqyvrQ


# Relationships
__PACKAGE__->belongs_to( 'client' => 'dns::monitor::Schema::Result::client' => 
	{ 'foreign.id' => 'self.client_id' }
);

1;
