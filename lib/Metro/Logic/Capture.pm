package Metro::Logic::Capture;
use strict;
use warnings;
use utf8;
use parent qw/Metro::Logic::Base/;

use Metro::Service::Capture;

sub send {
    my ($self, $params) = @_;

    my $service = Metro::Service::Capture->new;
    return $service->send($params);
}

1;

