package dns::monitor::Schema::Result::list::type;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PK::Auto");

=head1 NAME

dns::monitor::Schema::Result::list::type

=cut

__PACKAGE__->table("list_type");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'list_type_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 score

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "list_type_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "score",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("list_type_uniq", ["name"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-16 13:01:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5Z4UAtkIRcnRHmIgMqdglQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
