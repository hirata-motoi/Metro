package Metro::Web::C::Path;

use strict;
use warnings;
use utf8;

use parent qw/Metro::Web::C/;
use Metro::Logic::Path;
use Log::Minimal;
use YAML;

sub get {
	my ($self, $c) = @_;

    my @places = $c->req->param('p');

    my $ret = eval {
        Metro::Logic::Path->new->get(\@places);
    } || {};

	$self->output_response_json($c, $ret, $@);
}

1;
