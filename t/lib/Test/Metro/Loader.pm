package Test::Metro::Loader;

use strict;
use warnings;

use Class::Load qw/load_class/;
use Data::Dumper;
use Carp qw/croak/;

sub factory {
    my ($middle_ware, $specs) = @_;

    croak "Can't use this module unless test" unless $ENV{HARNESS_ACTIVE};

    my $loader = 'Test::Metro::Loader::';
    if ( $middle_ware eq 'db' ) {
        $loader .= 'DB';
    } else {
        croak "$middle_ware is an unkown middleware."
    }

    eval { load_class($loader) };
    croak qq{Cannot load module: $loader, $@} if $@;

    $loader->new($specs);
}

1;

