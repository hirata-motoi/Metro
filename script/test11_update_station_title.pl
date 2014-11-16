#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use YAML;
use Metro::API;
use Metro::Service::Base;
use SQL::Abstract;
use SQL::Abstract::Plugin::InsertMulti;

my $sql = SQL::Abstract->new;

# 駅のリストを取得
#   各駅を通っている路線リストも必要
#my $params = {
#    'rdf:type' => 'odpt:Station',
#    type       => 'datapoints',
#};
#これで駅のリストが得られる。
#  odpt:facility   odpt.StationFacility:TokyoMetro.Wakoshi
#  dc:title: 和光市
#  odpt:railway: odpt.Railway:TokyoMetro.Fukutoshin
#  odpt:connectingRailway:

my $params = {
    'rdf:type' => 'odpt:Station',
    type       => 'datapoints',
};

my $obj = Metro::API->new;
my $res = $obj->request($params);

my %stations = ();
my %railway  = ();

for my $r (@$res) {
    my $facility = (split /:/, $r->{'odpt:facility'})[1];
    my $title = $r->{'dc:title'};
    $stations{$facility} = { facility => $facility, title => $title };

}
my $service = Metro::Service::Base->new;
my $dbh = $service->dbh('METRO_W');
$dbh->do('set names utf8'); # なぜかこれ使わないと文字化けする

my $station = $dbh->selectall_hashref('select * from station', 'facility');
for my $facility (keys %$station) {
    $station->{$facility}{title} = $stations{$facility}{title};
}


# facilityをuniqに
my %station_hash = ();
my @uniq_stations = grep { !$station_hash{$_->{facility}}++ } values %$station;

# DBにimport
my ($stmt, @bind) = $sql->update_multi('station', \@uniq_stations);
$dbh->do($stmt, {}, @bind);

$dbh->commit;



