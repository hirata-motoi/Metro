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

my @stations = ();
my %railway  = ();

for my $r (@$res) {
    my $facility = $r->{'odpt:facility'};
    my $title = $r->{'dc:title'};

    push @stations, { facility => $facility, title => $title };

    my $railway = $r->{'odpt:railway'};
    my @connecting_railways = grep {$_ =~ /^odpt.Railway:TokyoMetro/} @{$r->{'odpt:connectingRailway'}};

    $railway{$facility} ||= [];
    push @{$railway{$facility}}, $railway, @connecting_railways;
}

# facilityをuniqに
my %station_hash = ();
my @uniq_stations = grep { !$station_hash{$_->{facility}}++ } @stations;
#print Dump \@uniq_stations;

# railwayをuniqに
my %uniq_railway = ();
for my $facility (keys %railway) {
    my %hash = ();
    my @uniq_railways = grep { !$hash{$_}++ } @{$railway{$facility}};
    $uniq_railway{$facility} = \@uniq_railways;
}

# DBにimport
my $service = Metro::Service::Base->new;
my $dbh = $service->dbh('METRO_W');
my ($stmt, @bind) = $sql->insert_multi('station', \@uniq_stations);
$dbh->do($stmt, {}, @bind);

my @railway_params = ();
for my $facility (keys %uniq_railway) {
    for my $railway (@{$uniq_railway{$facility}}) {
        push @railway_params, { station_facility => $facility, railway => $railway};
    }
}
print Dump \@railway_params;
($stmt, @bind) = $sql->insert_multi('railway', \@railway_params);
$dbh->do($stmt, {}, @bind);

$dbh->commit;



