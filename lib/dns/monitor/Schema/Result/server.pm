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

  data_type: bigint
  default_value: SCALAR(0x1a5758d0)
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
  default_value: SCALAR(0x1a568f10)
  is_nullable: 0

=head2 last_ts

  data_type: timestamp without time zone
  default_value: SCALAR(0x1a575d60)
  is_nullable: 0

=head2 is_authorized

  data_type: boolean
  default_value: SCALAR(0x1a568240)
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    default_value     => \"nextval('server_id_seq'::regclass)",
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
  "is_authorized",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("server_uniq_ip", ["ip"]);


# Created by DBIx::Class::Schema::Loader v0.05002 @ 2011-03-12 21:06:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TS2wxGgxzfjtO0Va7IADJw

# Relationships
__PACKAGE__->has_many('responses', 'dns::monitor::Schema::Result::packet::response',
	{ 'foreign.server_id' => 'self.id' }
);

1;
