package Test::Metro::Reader;
use strict;
use warnings;

our %DATA_POS = ();

sub read {
    my ($class) = @_;
    my ($package) = caller;
    my $fh = $package."::DATA";
    $DATA_POS{$package} ||= tell $fh;
    seek $fh, $DATA_POS{$package}, 0;
    my $data = do { local $/; <$fh> };
    return $data;
}

1;
__DATA__
This section must be overridden.
