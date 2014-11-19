package Metro::Model::NecessaryTime;


use strict;
use warnings;

use parent qw/Metro::Model::Base/;
use Metro::Common;
use YAML;

# 2駅を渡して所要時間を得る
# 同じ路線でなければundefを返す
sub get_necessary_time {
    my ($self, $teng, $from, $to) = @_;

    # 同じ路線上にあるかをチェック
    # railwayテーブルからチェック
    my $railway = $self->get_railway($teng, $from, $to);
    return if !$railway;

    return $self->get_necessary_time_with_stations($teng, $from, $to, $railway);
}

# 2つの駅に共通して通っている路線を取得
sub get_railway {
    my ($self, $teng, $from, $to) = @_;

    my @railways_from_itr = $teng->search('railway', { station_facility => $from});
    my @railways_to_itr   = $teng->search('railway', { station_facility => $to});

    my %uniq_railway = ();
    map { $uniq_railway{$_->railway}++ } @railways_from_itr, @railways_to_itr;

    my @same_railway = grep { $uniq_railway{$_} == 2 } keys %uniq_railway;
    return if !@same_railway;

    # TODO same_railwayの要素が2つ以上ある場合

    return $same_railway[0];
}

sub get_necessary_time_with_stations {
    my ($self, $teng, $from, $to, $railway) = @_;

    $railway = 'odpt.Railway:TokyoMetro.' . $railway;

    my @railways = $teng->search('necessary_time', { railway => $railway });

    my $available = 0;
    my @stations = ();
    for my $row (@railways) {

        if ($row->station_from == $from) {
            $available = 1;
            @stations = ();
        }

        if ($available) {
            push @stations, $row;
        }

        if ($row->station_to == $to) {
            $available = 0;
            last if @stations;
        }
    }

    # TODO 通過経路を取得するために@stationsの要素を使うかもしれない
    my $necessary_time = 0;
    map { $necessary_time += $_->necessary_time } @stations;

    return $necessary_time;
}

1;

