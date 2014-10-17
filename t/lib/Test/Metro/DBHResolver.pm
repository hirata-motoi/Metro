package Test::Metro::DBHResolver;

use strict;
use warnings;
use parent 'DBIx::DBHResolver';

use Carp qw/croak/;

sub new {
    my $class = shift;
    croak "Can't use this module unless test" unless $ENV{HARNESS_ACTIVE};
    $class->SUPER::new(@_);
}

sub dsn {
    my ($class, $label) = @_;
    return $class->config->{connect_info}{$label}{dsn};
}

sub database {
    my ($class, $label) = @_;
    my ($database) = $class->dsn($label) =~ /.+dbname=([^;]+).+/;
    return $database;
}

sub set_config_by_label {
    my ($class, $label, $dsn) = @_;

    $class->config->{connect_info}{$label} = {
        dsn   => $dsn,
        attrs => {
            RaiseError         => 1,
            ShowErrorStatement => 1,
            PrintError         => 0,
            PrintWarn          => 0,
            AutoCommit         => $class->_auto_commit($label),
        },
    };
}

sub _auto_commit {
    my ($class, $label) = @_;
    $label =~ qr/^(?:(?!QUEUE_).*)(?:W|M|MASTER)$/i ? 0 : 1;
}

1;

