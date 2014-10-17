package Metro::Model::Base;

use strict;
use warnings;
use utf8;
use parent qw/Class::Accessor::Fast/;

use SQL::Abstract;
use SQL::Abstract::Plugin::InsertMulti;
use SQL::Maker;

SQL::Maker->load_plugin('InsertMulti');

sub escape4like {
    my ($self, $str) = @_;
    $str =~ s/\\/\\\\/g;
    $str =~ s/%/\\%/g;
    $str =~ s/_/\\_/g;
    return $str;
}

sub sql {
    my ($self) = @_;
    return SQL::Abstract->new;
}

sub maker {
    my ($self) = @_;
    return SQL::Maker->new(driver => 'mysql');
}


1;

