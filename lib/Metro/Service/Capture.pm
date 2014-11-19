package Metro::Service::Capture;
use strict;
use warnings;
use utf8;

use parent qw/Metro::Service::Base/;

use Log::Minimal;
use YAML;
use File::Path;
use File::Spec;

use Metro;

sub send {
    my ($self, $params) = @_;

    my $filepath = File::Spec->catfile(Metro->base_dir, 'static/image/tmp', $params->{filepath});

    croakf("File not found %s", $filepath)
        if ! -f $filepath;

    my %conf = (
        to => $params->{email},
        message => '',
    );

    $self->model('Mail')->send(\%conf, $filepath);
}

1;

