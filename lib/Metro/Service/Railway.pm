package Metro::Service::Railway;
use strict;
use warnings;
use utf8;

use parent qw/Metro::Service::Base/;

sub get_railways {
    my ($self, $station) = @_;

    my $teng = $self->teng('METRO_R');
    return $self->model('Railway')->get_railways($teng, $station);
}

1;

