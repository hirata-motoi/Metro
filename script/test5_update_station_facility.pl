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
my ($stmt, @bind) = $sqla->select('station');

my $sth = $dbh->prepare($stmt);
$sth->execute(@bind);

my @rows = ();
my $id = 1;
while (my $row = $sth->fetchrow_hashref()) {
    my $facility = $row->{facility};
    my @elems = split ':', $facility;

    $row->{facility} = $elems[$#elems];
    push @rows, $row;

    $id++;
}

($stmt, @bind) = $sqla->update_multi('station', \@rows);
$dbh->do($stmt, {}, @bind);
$dbh->commit;

