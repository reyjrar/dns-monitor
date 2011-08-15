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

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'conversation_id_seq'

=head2 server_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 client_id

  data_type: 'bigint'
  is_foreign_key: 1
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

=head2 client_is_server

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
    sequence          => "conversation_id_seq",
  },
  "server_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "client_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
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
  "client_is_server",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("conversation_uniq_server_client", ["server_id", "client_id"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:34:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r5AQ1yJjArZONhVC1sVwHQ

# Relationships
__PACKAGE__->has_one('server', 'dns::monitor::Schema::Result::server',
	{ 'foreign.id' => 'self.server_id' },
);
__PACKAGE__->has_one('client', 'dns::monitor::Schema::Result::client',
	{ 'foreign.id' => 'self.client_id' },
);

1;
