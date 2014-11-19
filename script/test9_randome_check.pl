#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use YAML;
use Metro::Service::Base;
use SQL::Abstract;
use SQL::Abstract::Plugin::InsertMulti;
use JSON::XS;

my $sqla = SQL::Abstract->new;
my $service = Metro::Service::Base->new;

my $max = 20306;

my $offset = int(rand(20306)) + 1;

my $dbh = $service->dbh('METRO_R');
my $sth = $dbh->prepare("select * from route limit $offset, 1");
$sth->execute();

my $row = $sth->fetchrow_hashref();

my $from = $row->{station_from};
my $to   = $row->{station_to};
my $route = decode_json($row->{route});
my $nt    = $row->{necessary_time};

my ($stmt, @bind) = $sqla->select('station', [qw/id facility title/], {id => {-in => $route}});
my $ret = $dbh->selectall_hashref($stmt, 'id', {}, @bind);

print sprintf("from:%s(%d) to:%s(%d)", $ret->{$from}{title}, $from, $ret->{$to}{title}, $to), "\n";
print sprintf "necessary time: %d\n", $nt;
print "route--\n";
for (@$route) {
    print $ret->{$_}{title}, "\n";
}


