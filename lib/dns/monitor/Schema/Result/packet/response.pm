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

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'packet_response_id_seq'

=head2 client_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 client_port

  data_type: 'bigint'
  is_nullable: 1

=head2 server_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 server_port

  data_type: 'bigint'
  is_nullable: 1

=head2 query_serial

  data_type: 'bigint'
  is_nullable: 0

=head2 response_ts

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 conversation_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 opcode

  data_type: 'varchar'
  is_nullable: 0
  size: 12

=head2 status

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 size_answer

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=head2 count_answer

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=head2 count_additional

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=head2 count_authority

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=head2 count_question

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=head2 flag_authoritative

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 flag_authenticated

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 flag_truncated

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 flag_checking_desired

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 flag_recursion_desired

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 flag_recursion_available

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 capture_time

  data_type: 'numeric'
  is_nullable: 1
  size: [16,6]

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "packet_response_id_seq",
  },
  "client_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "client_port",
  { data_type => "bigint", is_nullable => 1 },
  "server_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "server_port",
  { data_type => "bigint", is_nullable => 1 },
  "query_serial",
  { data_type => "bigint", is_nullable => 0 },
  "response_ts",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "conversation_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "opcode",
  { data_type => "varchar", is_nullable => 0, size => 12 },
  "status",
  { data_type => "varchar", is_nullable => 0, size => 20 },
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
  "capture_time",
  { data_type => "numeric", is_nullable => 1, size => [16, 6] },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:34:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vfN0R9Gi3RogI6ntXSo70Q

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
