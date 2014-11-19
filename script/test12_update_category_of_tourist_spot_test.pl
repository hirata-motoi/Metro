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

my $service = Metro::Service::Base->new;
my $dbh = $service->dbh('METRO_R');
#$dbh->do('set names utf8'); # なぜかこれ使わないと文字化けする

my ($stmt, @bind) = $sql->select('tourist_spot', [qw/id/]);
my $sth = $dbh->prepare($stmt);
$sth->execute(@bind);

my @creteria = ();
while (my ($id) = $sth->fetchrow_array()) {
    push @creteria, {
        id => $id,
        category => int(rand(6)) + 1,
    };
}

# DBにimport
my $dbh_w = $service->dbh('METRO_W');
($stmt, @bind) = $sql->update_multi('tourist_spot', \@creteria);
$dbh_w->do($stmt, {}, @bind);

$dbh_w->commit;



