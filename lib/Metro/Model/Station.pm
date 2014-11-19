package Metro::Model::Station;

use strict;
use warnings;
use utf8;

use parent qw/Metro::Model::Base/;
use Metro::Common;
use YAML;

sub get_connecting_stations {
    my ($self, $teng) = @_;

    my @stations = $teng->search_by_sql(q/
        SELECT
            station_facility, count(railway) AS c
        FROM railway
        GROUP BY station_facility
        HAVING c > 1;
    /, []);
    my @facilities = map { $_->station_facility } @stations;
    return \@facilities;
}

sub get_stations {
    my ($self, $teng) = @_;

    my @stations;

    my @rows = $teng->search('station');
    for my $row (@rows) {
        push @stations, $row->id;
    }

    return \@stations;
}

sub get_station_info {
    my ($self, $teng, $stations) = @_;

    my %station_info = ();

    my @rows = $teng->search('station', { id => $stations });
    for my $row (@rows) {
        $station_info{$row->id} = $row->get_columns;
    }
    return \%station_info;
}

# このクラスでいいのか？ stationに順番をrailwayと順番を含める必要がある気がする
sub get_stations_by_railway {
    my ($self, $teng, $railway) = @_;

    if ($railway !~ /^odpt.Railway:TokyoMetro/) {
        $railway = sprintf("odpt.Railway:TokyoMetro.%s", $railway);
    }

    my @rows = $teng->search('necessary_time', { railway => $railway });
    my @stations = ();
    for my $row (@rows) {
        my $unit = $row->get_columns;
        $unit->{title} = decode_utf8($unit->{title});
        push @stations, $unit;
    }

    return \@stations;
}
1;

