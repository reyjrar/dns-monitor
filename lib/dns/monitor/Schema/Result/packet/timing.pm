package dns::monitor::Schema::Result::packet::timing;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::packet::timing

=cut

__PACKAGE__->table("packet_timing");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'packet_timing_id_seq'

=head2 conversation_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 query_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 response_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 difference

  data_type: 'numeric'
  is_nullable: 0
  size: [11,6]

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "packet_timing_id_seq",
  },
  "conversation_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "query_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "response_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "difference",
  { data_type => "numeric", is_nullable => 0, size => [11, 6] },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-14 11:36:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:baiWMaY2FyYJkBuwVMl7cQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
