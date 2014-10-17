package Metro::Model::ImageFile::Jpeg;

use strict;
use warnings;
use parent qw/Metro::Model::ImageFile/;
use Metro;
use Metro::Common;
use Metro::Model::UploadS3;

use Log::Minimal;
use Imager::ExifOrientation;

sub new {
    my ($class, $params) = @_;

    my $img = Imager::ExifOrientation->rotate( path => $params->{path} )
        or croak("Can't read $params->{path}");

    my $self = +{
        %$params,
        img => $img
    };
    return bless $self, $class;
}

1;

