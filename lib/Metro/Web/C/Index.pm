package Metro::Web::C::Index;

use strict;
use warnings;
use utf8;

use parent qw/Metro::Web::C/;

sub show {
    my ($self, $c) = @_;
    $self->output_response($c, "index.tx", {}, undef);
}

sub print {
    my ($self, $c) = @_;
    $self->output_response($c, "print.tx", {}, undef);
}

sub manual {
    my ($self, $c) = @_;
    $self->output_response($c, "manual_parent.tx", {}, undef);
}

1;
