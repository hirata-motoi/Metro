package Metro::Service::Station;
use strict;
use warnings;
use utf8;

use parent qw/Metro::Service::Base/;

sub get_connecting_stations {
    my ($self) = @_;

    my $teng = $self->teng('METRO_R');
    return $self->model('Station')->get_connecting_stations($teng);
}

sub get_stations {
    my ($self) = @_;

    my $teng = $self->teng('METRO_R');
    return $self->model('Station')->get_stations($teng);
}

sub get_stations_by_railway {
    my ($self, $railway) = @_;

    my $teng = $self->teng('METRO_R');
    return $self->model('Station')->get_stations_by_railway($teng, $railway);
}

1;

