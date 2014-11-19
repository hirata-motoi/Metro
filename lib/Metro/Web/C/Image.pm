package Metro::Web::C::Image;

use strict;
use warnings;
use utf8;

use parent qw/Metro::Web::C/;
use Metro::Logic::Image;
use Log::Minimal;
use YAML;

sub upload {
    my ($self, $c) = @_;

    my $image = $c->req->param('image');

    my $params = {
        image => $image,
    };

    my $logic = Metro::Logic::Image->new;
    my $ret = eval { $logic->upload($params) } || {};
    $self->output_response_json($c, $ret, $@);
}

1;

