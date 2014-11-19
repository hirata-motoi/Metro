package Metro::Service::NecessaryTime;
use strict;
use warnings;
use utf8;

use Digest::MD5 qw/md5_hex/;
use parent qw/Metro::Service::Base/;

sub get_necessary_time {
    my ($self, $from, $to) = @_;

    my $teng = $self->teng('METRO_R');
    return $self->model('NecessaryTime')->get_necessary_time($teng, $from, $to);
}

1;

