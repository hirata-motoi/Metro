package Metro::Web::C::Capture;

use strict;
use warnings;
use utf8;

use parent qw/Metro::Web::C/;
use Metro::Logic::Capture;
use Log::Minimal;
use YAML;

sub send {
    my ($self, $c) = @_;

    my $params = {
        filepath => $c->req->param('filepath'),
        email    => $c->req->param('email'),
    };

    my $logic = Metro::Logic::Capture->new;
    my $ret = eval { $logic->send($params) } || {};
    $self->output_response_json($c, $ret, $@);
}

1;

