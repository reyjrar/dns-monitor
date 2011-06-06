package dns::monitor::Schema::Result::client;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::client

=cut

__PACKAGE__->table("client");

=head1 ACCESSORS

=head2 id

  data_type: bigint
  default_value: SCALAR(0x1a53ea20)
  is_auto_increment: 1
  is_nullable: 0

=head2 ip

  data_type: inet
  default_value: undef
  is_nullable: 0

=head2 hostname

  data_type: character varying
  default_value: undef
  is_nullable: 1
  size: 255

=head2 first_ts

  data_type: timestamp without time zone
  default_value: SCALAR(0x1a52d160)
  is_nullable: 0

=head2 last_ts

  data_type: timestamp without time zone
  default_value: SCALAR(0x1999a900)
  is_nullable: 0

=head2 is_local

  data_type: boolean
  default_value: SCALAR(0x1a53efa0)
  is_nullable: 0

=head2 role_server_id

  data_type: bigint
  default_value: undef
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    default_value     => \"nextval('client_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable       => 0,
  },
  "ip",
  { data_type => "inet", default_value => undef, is_nullable => 0 },
  "hostname",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
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
  "is_local",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "role_server_id",
  {
    data_type      => "bigint",
    default_value  => undef,
    is_foreign_key => 1,
    is_nullable    => 1,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("client_uniq_ip", ["ip"]);


# Created by DBIx::Class::Schema::Loader v0.05002 @ 2011-03-12 21:06:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:maFwi+ZhZRSRw5/wtqgz8w


# Relationships
__PACKAGE__->belongs_to( 'as_server' => 'dns::monitor::Schema::Result::server',
	{ 'foreign.id' => 'self.role_server_id' }
);
__PACKAGE__->belongs_to( 'server_by_ip' => 'dns::monitor::Schema::Result::server',
	{ 'foreign.ip' => 'self.ip' }
);

1;
