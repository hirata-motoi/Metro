package Metro::Service::Place;
use strict;
use warnings;
use utf8;

use parent qw/Metro::Service::Base/;

use Log::Minimal;
use YAML;

sub list {
    my ($self) = @_;

    my $teng = $self->teng('METRO_R');
    my $tourist_spot_list = $self->model('TouristSpot')->list($teng);

    infof(Dump $tourist_spot_list);

    # 画像のURLを作る
    for my $spot (@$tourist_spot_list) {
        $spot->{image} = image_url($spot->{id});
    }

    # scoreを取得
    return $tourist_spot_list;
}

# そのうちクラスに切り出し
sub image_url {
    my ($id) = @_;

    return sprintf('/img/place/%d', $id);
}

1;

