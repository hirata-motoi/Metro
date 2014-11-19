package Metro::Model::Node;

use strict;
use warnings;
use utf8;

use parent qw/Metro::Model::Base/;
use Metro::Common;
use YAML;

sub get_nodes {
    my ($self, $teng) = @_;

    my @rows = $teng->search('nodes');
    my %nodes_hash = ();
    for my $row (@rows) {
        $nodes_hash{$row->station} ||={
            id       => $row->station,
            edges    => {},
            distance => 0,
            done     => 0,
            from     => undef
        };
        $nodes_hash{$row->station}{edges}{$row->connecting_station} = $row->necessary_time;
    }
    return [values %nodes_hash];
}

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

1;

