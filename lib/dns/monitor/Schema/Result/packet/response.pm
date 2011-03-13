package dns::monitor::Schema::Result::packet::response;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::packet::response

=cut

__PACKAGE__->table("packet_response");

=head1 ACCESSORS

=head2 id

  data_type: bigint
  default_value: SCALAR(0x1a575420)
  is_auto_increment: 1
  is_nullable: 0

=head2 client_id

  data_type: bigint
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0

=head2 client_port

  data_type: bigint
  default_value: undef
  is_nullable: 1

=head2 server_id

  data_type: bigint
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0

=head2 server_port

  data_type: bigint
  default_value: undef
  is_nullable: 1

=head2 query_serial

  data_type: bigint
  default_value: undef
  is_nullable: 0

=head2 response_ts

  data_type: timestamp without time zone
  default_value: SCALAR(0x1a575d40)
  is_nullable: 0

=head2 conversation_id

  data_type: bigint
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0

=head2 opcode

  data_type: character varying
  default_value: undef
  is_nullable: 0
  size: 10

=head2 status

  data_type: character varying
  default_value: undef
  is_nullable: 0
  size: 10

=head2 size_answer

  data_type: bigint
  default_value: 0
  is_nullable: 0

=head2 count_answer

  data_type: bigint
  default_value: 0
  is_nullable: 0

=head2 count_additional

  data_type: bigint
  default_value: 0
  is_nullable: 0

=head2 count_authority

  data_type: bigint
  default_value: 0
  is_nullable: 0

=head2 count_question

  data_type: bigint
  default_value: 0
  is_nullable: 0

=head2 flag_authoritative

  data_type: boolean
  default_value: SCALAR(0x1a5689e0)
  is_nullable: 0

=head2 flag_authenticated

  data_type: boolean
  default_value: SCALAR(0x1a53e8b0)
  is_nullable: 0

=head2 flag_truncated

  data_type: boolean
  default_value: SCALAR(0x1a566d70)
  is_nullable: 0

=head2 flag_checking_desired

  data_type: boolean
  default_value: SCALAR(0x1a575bd0)
  is_nullable: 0

=head2 flag_recursion_desired

  data_type: boolean
  default_value: SCALAR(0x1a53ec90)
  is_nullable: 0

=head2 flag_recursion_available

  data_type: boolean
  default_value: SCALAR(0x1a575b20)
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    default_value     => \"nextval('packet_response_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable       => 0,
  },
  "client_id",
  {
    data_type      => "bigint",
    default_value  => undef,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "client_port",
  { data_type => "bigint", default_value => undef, is_nullable => 1 },
  "server_id",
  {
    data_type      => "bigint",
    default_value  => undef,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "server_port",
  { data_type => "bigint", default_value => undef, is_nullable => 1 },
  "query_serial",
  { data_type => "bigint", default_value => undef, is_nullable => 0 },
  "response_ts",
  {
    data_type     => "timestamp without time zone",
    default_value => \"now()",
    is_nullable   => 0,
  },
  "conversation_id",
  {
    data_type      => "bigint",
    default_value  => undef,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "opcode",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 10,
  },
  "status",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 10,
  },
  "size_answer",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "count_answer",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "count_additional",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "count_authority",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "count_question",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "flag_authoritative",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "flag_authenticated",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "flag_truncated",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "flag_checking_desired",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "flag_recursion_desired",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "flag_recursion_available",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.05002 @ 2011-03-12 21:06:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JGQErPH9xliHgsPu1AUlvg

#------------------------------------------------------------------------#
# Relationships
__PACKAGE__->belongs_to( 'client', 'dns::monitor::Schema::Result::client',
	{ 'foreign.id' => 'self.client_id' }
);
__PACKAGE__->belongs_to( 'server', 'dns::monitor::Schema::Result::server',
	{ 'foreign.id' => 'self.server_id' }
);
__PACKAGE__->has_one( 'conversation', 'dns::monitor::Schema::Result::conversation',
	{ 'foreign.id' => 'self.conversation_id' }
);

__PACKAGE__->has_many('response_answers', 'dns::monitor::Schema::Result::packet::meta::answer',
	{ 'foreign.response_id' => 'self.id' }
);
__PACKAGE__->many_to_many( answers => 'response_answers', 'answer' );

__PACKAGE__->has_many('response_query', 'dns::monitor::Schema::Result::packet::meta::query_response',
	{ 'foreign.response_id' => 'self.id' }
);
__PACKAGE__->many_to_many( query => 'response_query', 'query' );


1;
