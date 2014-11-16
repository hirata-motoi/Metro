package Metro::Logic::Image;
use strict;
use warnings;
use utf8;
use parent qw/Metro::Logic::Base/;

use Metro::Service::Image;

sub upload {
    my ($self, $params) = @_;

    my $service = Metro::Service::Image->new;
    return $service->upload($params);
}

1;

