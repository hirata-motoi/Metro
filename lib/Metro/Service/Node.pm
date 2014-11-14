package Metro::Service::Node;
use strict;
use warnings;
use utf8;

use parent qw/Metro::Service::Base/;

sub get_nodes {
    my ($self) = @_;

    my $teng = $self->teng('METRO_R');
    return $self->model('Node')->get_nodes($teng);
}

1;

