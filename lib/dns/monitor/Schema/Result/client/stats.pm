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

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 day

  data_type: 'date'
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

=head2 queries

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 answers

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 nx

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 errors

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "client_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "day",
  { data_type => "date", is_nullable => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:34:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hPz04HQVdGLtAgQuzo5Ufw


# Relationships
__PACKAGE__->belongs_to( 'client' => 'dns::monitor::Schema::Result::client' => 
	{ 'foreign.id' => 'self.client_id' }
);

1;
