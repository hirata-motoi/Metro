package Metro::Logic::Place;
use strict;
use warnings;
use utf8;
use parent qw/Metro::Logic::Base/;

use Metro::Service::Place;

sub list {
    my ($self) = @_;

    my $service = Metro::Service::Place->new;
    return $service->list();
}

1;

