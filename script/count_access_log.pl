#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use YAML;
use DateTime;

use Metro::Service::Base;
use SQL::Abstract;
use SQL::Abstract::Plugin::InsertMulti;

my @files = ();
my $command_ls = 'sudo ls /etc/httpd/logs/';
open my $f, "$command_ls |";
while (<$f>) {
    chomp;
    my @elems = grep { $_ && $_ ne '' && $_ ne ' ' } (split / /, $_);
    push @files, @elems;
}
close $f;


my $dt = DateTime->now->set_time_zone('Asia/Tokyo');
#$dt->add(days => -1);

my $month = substr $dt->month_name, 0, 3;
my $day   = sprintf '%02d', $dt->day;
my $year  = sprintf '%04d', $dt->year;

my $date_str = sprintf '%d/%s/%d', $day, $month, $year;

my $ymd = $dt->ymd('');
my @rows = ();
for my $file (@files) {
    next if $file !~ /access_log/;

    my $command = sprintf 'sudo cat /etc/httpd/logs/%s', $file;
    open my $fh, "$command |" or die("Can't run $command");
    while (<$fh>) {
        chomp;

        my @elems = split / /, $_;

        if ($elems[3] !~ m|$date_str|) {
            next;
        }

        if ($elems[6] =~ /\.(jpg|png|gif|js\?t=|css\?)/) {
    
        } else {
            push @rows, {
                date  => $ymd,
                'log' => $_,
            };
        }
    }
    close $fh;
}

for my $row (@rows) {
    my @e = split / /, $row->{log};
    if ($e[0] ne '121.2.194.2') {
        print $e[0], "\n";
    }
}

__DATA__
my $sqla = SQL::Abstract->new;
my ($stmt, @bind) = $sqla->insert_multi('access_log', \@rows);
my $service = Metro::Service::Base->new;
my $dbh = $service->dbh('METRO_W');
$dbh->do($stmt, {}, @bind);
$dbh->commit;



