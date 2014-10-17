package Test::Metro;
use strict;
use warnings;
use File::Spec;
use String::CamelCase qw/camelize/;

our $VERSION = '0.01';

# from Amon2
sub base_dir($) {
    my $path = ref $_[0] || $_[0];
    $path =~ s!::!/!g;
    if (my $libpath = $INC{"$path.pm"}) {
        $libpath =~ s!\\!/!g; # win32
        $libpath =~ s!(?:blib/)?lib/+$path\.pm$!!;
        File::Spec->rel2abs($libpath || './');
    } else {
        File::Spec->rel2abs('./');
    }
}

sub debug { $ENV{PROTOSERVER_DEBUG} }
sub diag  { chomp $_[1]; print STDERR "# [diag] $_[1]\n" if $_[0]->debug }

sub module_name {
    my $class = shift;
    return join '::', __namespace(@_);
}

sub module_path {
    my $class = shift;
    my $file = File::Spec->catfile(__PACKAGE__->base_dir, 'lib', __namespace(@_));
    "$file.pm";
}

sub __namespace {
    my ($type, @stuff) = @_;

    my @namespace = (__PACKAGE__, camelize($type));
    push @namespace, map { camelize($_) } @stuff;
    @namespace;
}

1;

