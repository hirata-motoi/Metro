package Metro::Service::Image;
use strict;
use warnings;
use utf8;

use parent qw/Metro::Service::Base/;

use Log::Minimal;
use YAML;
use File::Path;
use File::Copy qw/copy/;

sub upload {
    my ($self, $params) = @_;

    my $filepath = $self->model('Image')->save($params->{image});

    return { result => { filepath => $filepath } };
}

1;

