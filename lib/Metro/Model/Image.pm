package Metro::Model::Image;

use strict;
use warnings;

use parent qw/Metro::Model::Base/;
use Metro;
use Metro::Common;
use YAML;
use MIME::Base64;
use Data::UUID;
use File::Path;
use Log::Minimal;

sub save {
    my ($self, $image) = @_;

    my $base_dir = Metro->base_dir;
    my $tmp_dir = sprintf '%s/static/image/tmp', $base_dir;
    mkpath($tmp_dir);

    my $ud = new Data::UUID;
    my $uuid = $ud->create_str();

    my $filename = File::Spec->catfile($tmp_dir, sprintf('%s.png', $uuid));
    open my $fh, "> $filename" or croakf("Cannot open $filename");
    print $fh decode_base64($image);
    close $fh;

    return sprintf('%s.png', $uuid);
}

1;

