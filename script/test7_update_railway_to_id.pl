#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use YAML;
use Metro::API;
use Metro::Service::Base;
use SQL::Abstract;
use SQL::Abstract::Plugin::InsertMulti;

my $sqla = SQL::Abstract->new;
my $service = Metro::Service::Base->new;
my $dbh = $service->dbh('METRO_W');
my $stations;
_setup_stations();

my ($stmt, @bind) = $sqla->select('railway');

my $sth = $dbh->prepare($stmt);
$sth->execute(@bind);

while (my $row = $sth->fetchrow_hashref()) {
    my $facility = $row->{station_facility};
    $row->{station_facility} = _get_station_id($row->{station_facility});

    my ($stmt, @bind) = $sqla->update('railway', {
        station_facility => $row->{station_facility}
    }, {
        station_facility => $facility,
    });
    $dbh->do($stmt, {}, @bind);
}
$dbh->commit;

sub _setup_stations {
    $stations = $dbh->selectall_hashref('select * from station', 'facility');
}

sub _get_station_id {
    my $facility = shift;
    return $stations->{'TokyoMetro.' . $facility}{'id'};
}
