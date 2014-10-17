package Metro::Model::Sequence;
use strict;
use warnings;
use utf8;

use parent qw/Metro::Model::Base/;

sub get_id {
    my ($self, $teng, $table) = @_;

    $teng->do("UPDATE $table SET id=LAST_INSERT_ID(id+1)");
    my $row = $teng->dbh->selectall_arrayref("SELECT LAST_INSERT_ID() AS id", +{Slice => {}});
    return $row->[0]->{id};
}

1;

