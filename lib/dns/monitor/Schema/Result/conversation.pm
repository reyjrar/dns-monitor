package dns::monitor::Schema::Result::conversation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::conversation

=cut

__PACKAGE__->table("conversation");

=head1 ACCESSORS

=head2 id

  data_type: bigint
  default_value: SCALAR(0x1a566c20)
  is_auto_increment: 1
  is_nullable: 0

=head2 server_id

  data_type: bigint
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0

=head2 client_id

  data_type: bigint
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0

=head2 first_ts

  data_type: timestamp without time zone
  default_value: SCALAR(0x1a5684d0)
  is_nullable: 0

=head2 last_ts

  data_type: timestamp without time zone
  default_value: SCALAR(0x1a568e20)
  is_nullable: 0

=head2 client_is_server

  data_type: boolean
  default_value: SCALAR(0x1a568430)
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    default_value     => \"nextval('conversation_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable       => 0,
  },
  "server_id",
  {
    data_type      => "bigint",
    default_value  => undef,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "client_id",
  {
    data_type      => "bigint",
    default_value  => undef,
    is_foreign_key => 1,
    is_nullable    => 0,
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
  "client_is_server",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("conversation_uniq_server_client", ["server_id", "client_id"]);


# Created by DBIx::Class::Schema::Loader v0.05002 @ 2011-03-12 21:06:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1+eNVCGsy2qQ4DWD3MXnBw

# Relationships
__PACKAGE__->has_one('server', 'dns::monitor::Schema::Result::server',
	{ 'foreign.id' => 'self.server_id' },
);
__PACKAGE__->has_one('client', 'dns::monitor::Schema::Result::client',
	{ 'foreign.id' => 'self.client_id' },
);

1;
