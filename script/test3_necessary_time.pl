#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use YAML;
use Metro::Service::Base;
use Metro::API;
use SQL::Abstract;
use SQL::Abstract::Plugin::InsertMulti;

my $sqla = SQL::Abstract->new;
my $service = Metro::Service::Base->new;
my $stations;

_setup_stations();

my $params = {
    'rdf:type' => 'odpt:Railway',
    type       => 'datapoints',
};

my $obj = Metro::API->new;
my $res_hash = $obj->request($params);

for my $r (@$res_hash) {
    my $travel_time = $r->{'odpt:travelTime'};
    my $railway = $r->{'owl:sameAs'};

    my @rows   = ();
    my $seq_id = 0;
    for my $t (@$travel_time) {
        my @elems_from = split ':', $t->{'odpt:fromStation'};
        my $from_str = $elems_from[$#elems_from];
        my @elems_from_sub = split /\./, $from_str;
        my @elems_to   = split ':', $t->{'odpt:toStation'};
        my @elems_to_sub = split /\./, $elems_to[$#elems_to];


        my $from = _get_station_id( $elems_from_sub[$#elems_from_sub] );
        my $to   = _get_station_id( $elems_to_sub[$#elems_to_sub] );
        my $necessary_time = $t->{'odpt:necessaryTime'};

        push @rows, {
            railway => $railway,
            seq_id  => $seq_id,
            station_from    => $from,
            station_to      => $to,
            necessary_time => $necessary_time
        };
        $seq_id++;
    }

    _insert(@rows);
}

sub _insert {
    my @rows = @_;

    my ($stmt, @bind) = $sqla->update_multi('necessary_time', \@rows);

    my $dbh = $service->dbh('METRO_W');
    $dbh->do($stmt, {}, @bind);
    $dbh->commit;
}

sub _setup_stations {
    my $dbh = $service->dbh('METRO_R');
    $stations = $dbh->selectall_hashref('select * from station', 'facility');
}

sub _get_station_id {
    my ($facility) = shift;
    return $stations->{'TokyoMetro.' . $facility}{id};
}
