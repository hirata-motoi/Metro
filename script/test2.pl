#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use YAML;
use Metro::API;

my $params = {
    'rdf:type' => 'odpt:Station',
    type       => 'datapoints',
};

my $obj = Metro::API->new;
my $res_hash = $obj->request($params);

for my $r (@$res_hash) {
    print Dump {
        facility => $r->{'odpt:facility'},
        connectingRailway => $r->{'odpt:connectingRailway'},
    };
}
