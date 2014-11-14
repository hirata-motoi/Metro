package Metro::Model::Railway;

use strict;
use warnings;
use utf8;

use parent qw/Metro::Model::Base/;
use Metro::Common;
use YAML;

sub get_railways {
    my ($self, $teng, $station) = @_;

    my @railways = ();

    my @rows = $teng->search('railway', { station_facility => $station });
    for my $row (@rows) {
        push @railways, $row->railway;
    }

    return \@railways;
}

1;

