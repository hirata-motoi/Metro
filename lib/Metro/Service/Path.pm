package Metro::Service::Path;
use strict;
use warnings;
use utf8;

use parent qw/Metro::Service::Base/;

use Log::Minimal;
use YAML;
use Math::Combinatorics;
use JSON::XS;

sub get {
    my ($self, $places) = @_;

    my $teng = $self->teng('METRO_R');

    # placesからnearest_station_mapを取得
    my $nearest_station_map = $self->model('NearestStationMap')->get($teng, $places);

    # 同一最寄り駅がある場所をグルーピング
    # [
    #     { places => $places, stations => $stations }
    # ]
    my $place_station_info = group_by_station($nearest_station_map);

    # nearest_station_mapから2地点の組み合わせを全て取得し、その距離をRouteからselect
    my $conbinations = station_conbinations($nearest_station_map);
    my $route = $self->model('Route')->get($teng, $conbinations);

    # 決めでplacesの最初のものをスタート地点とする
    #   TODO スタート地点を入力
    # 経路の順番の組み合わせを全て出して、その中で最短経路を選ぶ
    my $place_orders = place_order($place_station_info);
    my $shortest_route = shortest_route($place_orders, $route, $nearest_station_map);

    # stationsを作る
    my @stations = ();
    my $place_index = 0;
    infof("shortest_route:%s", Dump $shortest_route);
    for my $r (@{$shortest_route->{route}}) {
        my $index = 0;
        my @route_stations = @{ decode_json($r->{route}) };
        if ($route_stations[0] != $r->{station_from}) {
            @route_stations = reverse @route_stations;
        }
        for my $station (@route_stations) {
            my %unit = (
                id => $station,
                name => "", # TODO 名前を引く
            );

            if ($index == 0) {
                $unit{place_index} = $place_index;
                $place_index++;
            }

            push @stations, \%unit;
        }
    }

    # pathsを作る
    my @paths = ();
    my $i = 0;
    for my $station (@stations) {
        last if ! $stations[$i + 1];

        my $next_station = $stations[$i + 1];
        # DBから2地点間の路線と経由時間を引く(同じ路線のはずなので、路線はrailwayからひく でいいかな)
        # 経由時間はrouteからひくでOK
        push @paths, {
            railway        => get_common_railway($self, $station->{id}, $next_station->{id}),
            necessary_time => get_necessary_time($self, $station->{id}, $next_station->{id}),
        };

        $i++;
    }

    # placesを作る
    my $spots = $self->model('TouristSpot')->get($teng, $places);
    my @places_detail = ();
    for my $spot (@$places) {
        push @places_detail, {
            %{$spots->{$spot}},
            image => image_url($spot),
        };
    }

    # {
    #     places => 場所情報の配列,
    #     stations => [
    #         { id => 1, name => 駅名, place_index => 3 }
    #     ],
    #     paths  => [
    #         [ { railway => 路線名, necessary_time => 10 }],
    #         [],
    #         [],
    #     ],
    # }
    return {
        places   => \@places_detail,
        stations => \@stations,
        paths    => \@paths
    };

}

# nearest_station_mapから2地点の組み合わせを全て取得
sub station_conbinations {
    my ($station_map) = @_;

    infof("station_map : %s", Dump $station_map);

    my %station_hash = ();
    for my $stations (values %$station_map) {
       map { $station_hash{$_}++ } @$stations;
    }

    my @uniq_stations = keys %station_hash;

    # 全組み合わせを取得
    my @conbinations = ();
    for my $station1 (@uniq_stations) {
        for my $station2 (@uniq_stations) {
            next if $station1 == $station2;

            push @conbinations, [$station1, $station2];
        }
    }
    return \@conbinations;
}

sub place_order {
    my ($place_station_info) = @_;

    # スタート地点は決めでindex 0
    my $start = shift @$place_station_info;

    my @place_orders = combine(scalar @$place_station_info, @$place_station_info);
    for (@place_orders) {
        unshift @$_, $start;
    }
    return \@place_orders;
}

# {
#     route => [ { station_from => '', station_to => '', route => [1, 3, 4], necessary_time => 10 }
#     total_necessary_time => 30,
#     order => [最寄り駅のリスト]
# }
sub shortest_route {
    my ($place_orders, $route, $nearest_station_map) = @_;

    infof('place_order : %s', Dump $place_orders);

    my @all_route = ();

    for my $order (@$place_orders) {
        my %unit = (order => $order);
        my $index = 0;
        for my $place (@$order) {

            last if ! $order->[$index + 1];

            # placeの最寄り駅リスト
            #my $nearest_stations = $nearest_station_map->{$place};
            my $nearest_stations = $place->{stations};
            # 次のplaceの最寄り駅リスト
            #my $next_nearest_stations = $nearest_station_map->{$order->[$index++]};
            my $next_nearest_stations = $order->[++$index]->{stations};
            # 最短経路を探す
            my $shortest_route;
            for my $station (@$nearest_stations) {
                for my $station2 (@$next_nearest_stations) {
                    my $r = $route->{$station}{$station2};

                    infof("station1:%d station2:%d", $station, $station2);

                    if (!$shortest_route || $shortest_route->{necessary_time} > $r->{necessary_time}) {
                        $shortest_route = {
                            %$r,
                            station_from => $station,
                            station_to   => $station2,
                        };
                    }
                }
            }

            die("shortest_route not found") if !$shortest_route;

            $unit{route}          ||= [];
            push @{$unit{route}}, $shortest_route;
            $unit{total_necessary_time} += $shortest_route->{necessary_time};

            $index++;
        }
        push @all_route, \%unit;
    }

    my @sorted_route = sort { $a->{total_necessary_time} <=> $b->{total_necessary_time} } @all_route;

    return $sorted_route[0];
}

sub get_common_railway {
    my ($self, $from, $to) = @_;

    # fromで検索したrowとtoで検索したrowを比較して共通のrailwayを取得
    my $teng = $self->teng('METRO_R');
    my $railway = $self->model('NecessaryTime')->get_railway($teng, $from, $to);
    return $railway;
}

sub get_necessary_time {
    my ($self, $from, $to) = @_;

    my $teng = $self->teng('METRO_R');
    my $routes = $self->model('Route')->get($teng, [ [$from, $to] ]);

    return $routes->{$from}{$to}{necessary_time};
}

# そのうちクラスに切り出し
sub image_url {
    my ($id) = @_;

    return sprintf('/img/place/%d', $id);
}

# 同一の最寄り駅を持つ場所をグルーピング
sub group_by_station {
    my ($nearest_station_map) = @_;

    my %station_hash = ();
    for my $stations (values %$nearest_station_map) {
        map { $station_hash{$_}++ } @$stations;
    }

    my %already_used_places = ();
    my %grouped_places = ();
    for my $station (sort {$station_hash{$b} <=> $station_hash{$a}} keys %station_hash) {

        next if $station_hash{$station} <= 1;

        for my $place (keys %$nearest_station_map) {

            next if $already_used_places{$place};

            if ( grep { $station == $_ } @{$nearest_station_map->{$place}} ) {
                $grouped_places{$station} ||= [];
                push @{$grouped_places{$station}}, $place;
                $already_used_places{$place}++;
            }
        }
    }

    # [placeのリスト] => [stationリスト]
    my @grouped_place_station_map = ();
    for my $station (keys %grouped_places) {
        my $places = $grouped_places{$station};

        # placesに共通の最寄り駅を探す
        my %station_hash = ();
        for my $place (@$places) {
            map { $station_hash{$place}++ } @{$nearest_station_map->{$place}};
        }
        my @common_stations = grep { $station_hash{$_} == scalar @$places } keys %station_hash;

        push @grouped_place_station_map, {
            places   => $places,
            stations => \@common_stations,
        };
    }

    # 共通の最寄り駅がない場所
    for my $place (keys %$nearest_station_map) {
        next if $already_used_places{$place};
        push @grouped_place_station_map, {
            places   => [$place],
            stations => $nearest_station_map->{$place},
        };
    }

    return \@grouped_place_station_map;
}

1;

