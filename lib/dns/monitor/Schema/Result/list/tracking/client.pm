package dns::monitor::Schema::Result::list::tracking::client;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::list::tracking::client

=cut

__PACKAGE__->table("list_tracking_client");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'list_tracking_client_id_seq'

=head2 list_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 client_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 reference_count

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

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

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "list_tracking_client_id_seq",
  },
  "list_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "client_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "reference_count",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
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
);
__PACKAGE__->set_primary_key("list_id", "client_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-16 13:01:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HhhYhLZZiGsXw55zPI7HtA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
