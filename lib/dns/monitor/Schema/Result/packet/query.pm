package dns::monitor::Schema::Result::packet::query;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::packet::query

=cut

__PACKAGE__->table("packet_query");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'packet_query_id_seq'

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

=head2 query_ts

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 query_serial

  data_type: 'bigint'
  is_nullable: 0

=head2 conversation_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 opcode

  data_type: 'varchar'
  is_nullable: 0
  size: 12

=head2 count_questions

  data_type: 'bigint'
  is_nullable: 0

=head2 flag_recursive

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 flag_truncated

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 flag_checking

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
    sequence          => "packet_query_id_seq",
  },
  "client_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "client_port",
  { data_type => "bigint", is_nullable => 1 },
  "server_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "server_port",
  { data_type => "bigint", is_nullable => 1 },
  "query_ts",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "query_serial",
  { data_type => "bigint", is_nullable => 0 },
  "conversation_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "opcode",
  { data_type => "varchar", is_nullable => 0, size => 12 },
  "count_questions",
  { data_type => "bigint", is_nullable => 0 },
  "flag_recursive",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "flag_truncated",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "flag_checking",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "capture_time",
  { data_type => "numeric", is_nullable => 1, size => [16, 6] },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:34:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A9JPa/V8Kg/hjbB8iSN+1Q

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

__PACKAGE__->has_many( 'query_questions', 'dns::monitor::Schema::Result::packet::meta::question',
	{ 'foreign.query_id' => 'self.id' }
);
__PACKAGE__->many_to_many( questions => 'query_questions', 'question');

__PACKAGE__->has_many( 'query_response', 'dns::monitor::Schema::Result::packet::meta::query_response',
	{ 'foreign.query_id' => 'self.id' }
);
__PACKAGE__->many_to_many( response => 'query_response', 'response');

1;
