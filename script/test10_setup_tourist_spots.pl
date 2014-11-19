#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use YAML;
use Metro::API;
use Metro::Service::Base;
use SQL::Abstract;
use SQL::Abstract::Plugin::InsertMulti;
use LWP::UserAgent;

my $sqla = SQL::Abstract->new;
my $service = Metro::Service::Base->new;
my $dbh = $service->dbh('METRO_W');
my $ua = LWP::UserAgent->new;

my $file = shift @ARGV || die("required input file path");

my $spots_index = 1;
my @spots = ();
my @nearest_stations = ();


open my $fh, "< $file" or die("Can't open $file");
while (<$fh>) {
    chomp;
    my $line = $_;
    my @elems = grep { $_ } split /\t/, $line;

    my $station_string = $elems[3];
    my @stations = split /,/, $station_string;
    for my $station (@stations) {
        push @nearest_stations, {
            id      => $spots_index,
            station => $station
        };
    }

    # 画像を保存
    my $extension = save_image($spots_index, $elems[2]);
    push @spots, {
        id       => $spots_index++,
        name     => $elems[0],
        name_en  => $elems[1],
        detail   => $elems[5],
        category => get_category($elems[4]),
        extension => $extension,
        more_information_url => $elems[6],
    };
}

$dbh->do('set names utf8');

$dbh->do('delete from tourist_spot');
$dbh->do('delete from nearest_station_map');

my ($stmt, @bind) = $sqla->update_multi('tourist_spot', \@spots);
$dbh->do($stmt, {}, @bind);

($stmt, @bind) = $sqla->update_multi('nearest_station_map', \@nearest_stations);
$dbh->do($stmt, {}, @bind);

$dbh->commit;

sub get_category {
    my $category_str = shift;

    my %map = (
        A => 1,
        B => 2,
        C => 3,
        D => 4,
        E => 5
    );

    my $category_id = $map{$category_str} || die("category_id is undefined str:$category_str");
    return $category_id;
}

sub save_image {
    my ($id, $url) = @_;

    $ua->agent('Mozilla');
    my $request = HTTP::Request->new('GET', $url);
    my $response = $ua->request($request);
    my $prefix = get_prefix($url);
    my $path = File::Spec->catfile(Metro->base_dir, 'static/image/place/', sprintf("%d%s", $id, $prefix));

    print "url : $url\n";

    if ($response->is_success){
        open(OUT, ">$path");
        binmode OUT;
        print OUT $response->content;
        close(OUT);

        return $prefix;
    } else{
        die( sprintf("failed to save image id:$id status:%s\n", $response->status_line) );
    }
}

sub get_prefix {
    my $url = shift;
    my $start = rindex($url, ".");
    my $end   = length($url);
    my $str = substr($url, $start, $end - $start);
    return lc($str);
}
