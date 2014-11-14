package Metro::Model::TouristSpot;
use strict;
use warnings;
use utf8;

use parent qw/Metro::Model::Base/;

sub list {
    my ($self, $teng) = @_;

    my @rows = $teng->search('tourist_spot');

    my @list = ();
    for my $row (@rows) {
        my $spot = $row->get_columns;
        push @list, $spot;
    }

    return \@list;
}

sub get {
    my ($self, $teng, $places) = @_;

    my @rows = $teng->search('tourist_spot', {id => {in => $places}});

    my %spots = ();
    for my $row (@rows) {
        $spots{$row->id} = $row->get_columns;
    }
    return \%spots;
}

1;

