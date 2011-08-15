package dns::monitor::Schema::Result::server;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::server

=cut

__PACKAGE__->table("server");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'server_id_seq'

=head2 ip

  data_type: 'inet'
  is_nullable: 0

=head2 hostname

  data_type: 'varchar'
  is_nullable: 1
  size: 255

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

=head2 is_authorized

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "server_id_seq",
  },
  "ip",
  { data_type => "inet", is_nullable => 0 },
  "hostname",
  { data_type => "varchar", is_nullable => 1, size => 255 },
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
  "is_authorized",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("server_uniq_ip", ["ip"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:34:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e4PydSUUlgL5RT1/gRCsRQ

# Relationships
__PACKAGE__->has_many('responses', 'dns::monitor::Schema::Result::packet::response',
	{ 'foreign.server_id' => 'self.id' }
);

1;
