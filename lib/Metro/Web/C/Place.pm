package Metro::Web::C::Place;

use strict;
use warnings;
use utf8;

use parent qw/Metro::Web::C/;
use Metro::Logic::Place;
use Log::Minimal;

sub list {
	my ($self, $c) = @_;

    my $ret = eval {
        Metro::Logic::Place->new->list();
    } || {};

	$self->output_response_json($c, $ret, $@);
}

1;
