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

my $file = shift @ARGV || die("required input file path");

my $spots_index = 0;
my @spots = ();
my @nearest_stations = ();

open my $fh, "< $file" or die("Can't open $file");
while (<$fh>) {
    chomp;
    my $line = $_;
    my @elems = grep { $_ } split / /, $line;

    push @spots, {
        id     => $spots_index++,
        name   => $elems[0],
        detail => "",
    };

    my $station_string = $elems[2];
    my @stations = split /,/, $station_string;
    for my $station (@stations) {
        push @nearest_stations, {
            id      => $spots_index,
            station => $station
        };
    }
}

my ($stmt, @bind) = $sqla->update_multi('tourist_spot', \@spots);
$dbh->do($stmt, {}, @bind);

($stmt, @bind) = $sqla->update_multi('nearest_station_map', \@nearest_stations);
$dbh->do($stmt, {}, @bind);

$dbh->commit;

