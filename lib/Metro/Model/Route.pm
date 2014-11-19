package Metro::Model::Route;
use strict;
use warnings;
use utf8;

use SQL::Abstract;
use YAML;
use Log::Minimal;

use parent qw/Metro::Model::Base/;

sub get {
    my ($self, $teng, $conbinations) = @_;

    my @creteria = ();
    for (@$conbinations) {
        push @creteria, {
            station_from => $_->[0],
            station_to   => $_->[1]
        };
    }

    my %route = ();

    my $sqla = SQL::Abstract->new;
    my ($stmt, @bind) = $sqla->select('route', [qw/station_from station_to route necessary_time/], {-or => \@creteria});
    my @rows = $teng->search_by_sql($stmt, \@bind);
    for my $row (@rows) {
        my $from = $row->station_from;
        my $to   = $row->station_to;

        $route{$from}{$to} = {
            route => $row->route,
            necessary_time => $row->necessary_time,
        };
    }

    return \%route;
}

1;

