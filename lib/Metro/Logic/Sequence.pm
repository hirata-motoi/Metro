package Metro::Logic::Sequence;
use strict;
use warnings;
use utf8;

use parent qw/Metro::Logic::Base/;

sub get_id {
    my ($self, $table) = @_;

    my $dbh = $self->dbh('TEST_W');
    my $sth = $dbh->prepare("update $table set id=LAST_INSERT_ID(id+1)");
    $sth->execute();
    my $row = $dbh->selectrow_hashref('select LAST_INSERT_ID()');
    my $id = $row->{'LAST_INSERT_ID()'};
    $dbh->disconnect();

    return $id;
}

1;

