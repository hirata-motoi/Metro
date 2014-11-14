#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use YAML;
use Clone qw/clone/;
use SQL::Abstract;
use SQL::Abstract::Plugin::InsertMulti;
use JSON::XS;
use List::MoreUtils qw/any/;

use Metro::API;
use Metro::Service::Node;
use Metro::Service::Station;
use Metro::Service::Railway;
use Metro::Service::NecessaryTime;
use Metro::Service::Route;
use Metro::Service::Base;

my $sqla = SQL::Abstract->new;
my $s = Metro::Service::Base->new;
my $dbh = $s->dbh('METRO_W');

my $service = Metro::Service::Node->new;
my $service_station = Metro::Service::Station->new;
my $service_railway = Metro::Service::Railway->new;
my $service_necessary_time = Metro::Service::NecessaryTime->new;
my $service_route = Metro::Service::Route->new;

# TODO 乗り換え時間を考慮する
#  1駅につき2分とか加算すればいいんでないかな

# 接続点のnodeリストを取得
my $nodes = $service->get_nodes();

# 全駅からランダムに2つ選ぶ
my $stations = $service_station->get_stations();

# 始点と終点に隣り合う駅を選ぶ
# 始点・終点はidの昇順に並び替える
my $total_count = 0;
my %route = ();
for my $from (sort @$stations) {
    for my $to (sort @$stations) {
        next if $from == $to;
        next if $route{$from}{$to};

        my $nodes_clone = clone $nodes;
        # 隣り合う駅との所要時間を出してedgeにセット
        for ($from, $to) {
            setup_nodes($nodes_clone, $_);
        }
        # fromとtoが同一路線だった場合
        setup_nodes_same_railway($nodes_clone, $from, $to);
        # ダイクストラ法で始点と終点の経路を算出
        my ($route, $nt) = $service_route->get_shortest_route($nodes_clone, $from, $to);

        # routeをDBにsave
        # 始点 終点 経路リスト(json) 所用時間
        save($route, $nt, $from, $to);
        $total_count++;
        if ($total_count % 100 == 0) {
            print "total_count : $total_count\n";
        }
    }
}

sub save {
    my ($route, $nt, $from, $to) = @_;

    my $sqla = SQL::Abstract->new;
    my $s = Metro::Service::Base->new;
    my $dbh = $s->dbh('METRO_W');

    my $params = [{
        station_from   => $from,
        station_to     => $to,
        route          => encode_json($route),
        necessary_time => $nt
    }];
    my ($stmt, @bind) = $sqla->update_multi('route', $params);
    $dbh->do($stmt, {}, @bind);
    $dbh->commit;
}

sub setup_nodes {
    my ($ns, $id) = @_;

    my $node = {
        id       => $id,
        edges    => {},
        distance => 0,
        done     => 0,
        from     => undef
    };

    my $adjacent_from = get_adjacent_stations($ns, $id) or return;
    for my $station (@$adjacent_from) {
        if (my @adjacent_stations =  grep { $_->{id} == $station->{station_from}} @$ns) {
            my $id2 = $adjacent_stations[0]->{id};
            my $time = $service_necessary_time->get_necessary_time($station->{station_from}, $id);
            $adjacent_stations[0]->{edges}{$id} = $time;
            $node->{edges}{$id2} = $time;
        }
    }
    push @$ns, $node;
}

sub setup_nodes_same_railway {
    my ($nodes, $from, $to) = @_;

    my $railways_from = $service_railway->get_railways($from);
    my $railways_to   = $service_railway->get_railways($to);

    my $same_railway;
    for my $railway (@$railways_from) {
        $same_railway = $railway if any { $_ eq $railway } @$railways_to;
    }
    return if !$same_railway;

    my $node_from = (grep { $_->{id} == $from } @$nodes)[0];
    my $node_to   = (grep { $_->{id} == $to } @$nodes)[0];

    my $time = $service_necessary_time->get_necessary_time($from, $to);
    $node_from->{edges}{$to} = $time;
    $node_to->{edges}{$from} = $time;
}

sub get_adjacent_stations {
    my ($ns, $from) = @_;

    # fromが接続駅に一致してたらスキップ
    return if grep { $_->{id} == $from } @$ns;
    # fromのラインを取得
    my $railways = $service_railway->get_railways($from);

    my %nodes_and_from = (
        $from => 1
    );
    map { $nodes_and_from{$_->{id}} += 1 } @$ns;

    my @adjacent_stations = ();
    for my $railway (@$railways) {
        my %unit = ();
        my $stations = $service_station->get_stations_by_railway($railway);
        # 折り返しを考慮して前半だけに限定
        my $scalar = scalar @$stations;
        $stations = [@$stations[0 .. $scalar/2]]; # 終端駅があるので $scalar/2 - 1をしてはいけない

        # 接続駅とfromだけに限定
        my @filtered_stations = grep { $nodes_and_from{$_->{station_from}} } @$stations;

        my $i = 0;
        for my $station (@filtered_stations) {
            if ($station->{station_from} != $from) {
                $i++;
                next;
            }
            if ($i > 0) {
                $unit{pre} = $filtered_stations[$i - 1];
            }
            if ($i < $#filtered_stations) {
                $unit{after} = $filtered_stations[$i + 1];
            }
        }
        push @adjacent_stations, values %unit;
    }
    return \@adjacent_stations;
}


