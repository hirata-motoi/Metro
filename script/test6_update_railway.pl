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
my ($stmt, @bind) = $sqla->select('railway');

my $sth = $dbh->prepare($stmt);
$sth->execute(@bind);

while (my $row = $sth->fetchrow_hashref()) {
    my $facility = $row->{station_facility};
    my $railway  = $row->{railway};

    my @facility_elems = split /\./, $facility;
    my @railway_elems = split /\./, $railway;

    $row->{station_facility} = $facility_elems[$#facility_elems];
    $row->{railway} = $railway_elems[$#railway_elems];

    my ($stmt, @bind) = $sqla->update('railway', $row, {
        station_facility => $facility,
        railway => $railway
    });
    $dbh->do($stmt, {}, @bind);
}
$dbh->commit;

