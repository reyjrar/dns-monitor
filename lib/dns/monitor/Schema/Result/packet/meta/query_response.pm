package dns::monitor::Schema::Result::packet::meta::query_response;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::packet::meta::query_response

=cut

__PACKAGE__->table("packet_meta_query_response");

=head1 ACCESSORS

=head2 query_id

  data_type: bigint
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0

=head2 response_id

  data_type: bigint
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "query_id",
  {
    data_type      => "bigint",
    default_value  => undef,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "response_id",
  {
    data_type      => "bigint",
    default_value  => undef,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);
__PACKAGE__->set_primary_key("query_id", "response_id");


# Created by DBIx::Class::Schema::Loader v0.05002 @ 2011-03-01 16:27:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cxDqfWVLlRqEI4UcoUugsw

# Relationships
__PACKAGE__->has_one('query', 'dns::monitor::Schema::Result::packet::query',
	{ 'foreign.id' => 'self.query_id' },
);
__PACKAGE__->has_one('response', 'dns::monitor::Schema::Result::packet::reponse',
	{ 'foreign.id' => 'self.response_id' },
);

1;
