package Metro::Logic::Path;
use strict;
use warnings;
use utf8;
use parent qw/Metro::Logic::Base/;

use Metro::Service::Path;

sub get {
    my ($self, $places) = @_;

    my $service = Metro::Service::Path->new;
    return $service->get($places);
}

1;

