package Metro::Model::NearestStationMap;
use strict;
use warnings;
use utf8;

use parent qw/Metro::Model::Base/;

sub get {
    my ($self, $teng, $places) = @_;

    my @rows = $teng->search('nearest_station_map', {id => {in => $places}});

    my %station_map = ();
    for my $row (@rows) {
        $station_map{$row->id} ||= [];
        push @{$station_map{$row->id}}, $row->station;
    }
    return \%station_map;
}

1;

