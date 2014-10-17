package Metro::Service::Base;
use strict;
use warnings;
use utf8;

use parent qw/Class::Accessor::Fast/;

use Metro::DBI;
use DBIx::Simple;
use Teng::Schema::Loader;
use SQL::Abstract;
use SQL::Abstract::Plugin::InsertMulti;
use Data::Dump;
use Class::Load qw/load_class/;
use String::CamelCase qw/camelize/;
use SQL::Maker;

SQL::Maker->load_plugin('InsertMulti');

sub dbh {
    my ($self, $label) = @_;

    my $resolver = Metro::DBI->resolver();
    my $dbh = $resolver->connect($label);
    $dbh;
}

sub dx {
    my ($self, $label, $dbh) = @_;

    $dbh ||= $self->dbh($label);
    my $dx = DBIx::Simple->new($dbh);
    return $dx;
}

sub teng {
    my ($self, $label) = @_;

    $self->{teng} ||= {};
    return $self->{teng}{$label} if $self->{teng}{$label};

    my $teng = Teng::Schema::Loader->load(
        namespace => 'Metro::Teng',
        dbh       => $self->dbh($label),
    );
    $teng->load_plugin('Count');
    $teng->load_plugin('Lookup');
    $self->{teng}{$label} = $teng;
    return $self->{teng}{$label};
}

sub dump {
    my ($self, $params) = @_;
    return Data::Dump::dump($params);
}

sub model {
    my ($self, $model_name) = @_;

    my $class = 'Metro::Model::' . camelize($model_name);
    load_class($class);
    return $class->new;
}

1;

