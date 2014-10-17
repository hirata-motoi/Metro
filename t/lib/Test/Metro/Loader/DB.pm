package Test::Metro::Loader::DB;
use strict;
use warnings;

use Class::Load qw/load_class/;
use Data::Dumper;
use Carp qw/croak/;

use Test::Metro::mysqld;
use Test::Metro::DBHResolver;
use Metro::DBI;

our $LOADED_RESOLVER  = undef;

sub new {
    my ($class, $specs) = @_;

    croak "Can't use this module unless test" unless $ENV{HARNESS_ACTIVE};

    __parse_specs(
        env      => undef,
        specs    => $specs,
        callback => sub { __check_spec(@_) },
    );
    bless { specs => $specs }, $class;
}

sub __parse_specs {
    my (%args) = @_;

    my $specs    = $args{specs};
    my $callback = $args{callback} || sub {};

    if (ref $specs eq 'ARRAY') {
        map { $callback->($_) } @$specs;
    }
    else {
        die "Spec formatting is wrong.";
    }
}

sub __check_spec {
    my ($spec) = @_;

    my $mes = "Spec formatting is wrong.";
    die $mes unless (defined $spec->{database});
    die $mes unless (defined $spec->{node} && ref $spec->{node} eq 'ARRAY');
    die $mes if (defined $spec->{fixture} && ref $spec->{fixture} ne 'ARRAY');
}

sub load {
    my ($self) = @_;

    my $mysqld = Test::Metro::mysqld->new;
    $self->mysqld($mysqld);

    __parse_specs(
        env      => undef,
        specs    => $self->{specs},
        callback => sub { $self->_load(@_) },
    );
    $self->rewrite_resolver($Metro::DBI::resolver);
    $self;
}

sub mysqld {
    my ($self, $mysqld) = @_;
    $self->{mysqld} = $mysqld if $mysqld;
    $self->{mysqld};
}

sub _load {
    my ($self, $spec) = @_;

    my $dbname = $spec->{database};
    $self->mysqld->create_database($dbname);

    $self->_load_sql($dbname, 'schema', $dbname);

    for my $table (@{ $spec->{fixture} }) {
        $self->_load_sql($dbname, 'fixture', $dbname, $table);
    }

    my $resolver = $self->_loaded_resolver();
    for my $label (@{ $spec->{node} }) {
        $resolver->set_config_by_label($label, $self->mysqld->dsn($dbname));
    }
    $self->_set_resolver($resolver);
}

sub _load_sql {
    my ($self, $dbname, @module_name) = @_;
    my $module = Test::Metro->module_name(@module_name);
    eval { load_class($module) };
    die qq{Cannot load module: $module} if ($@);
    $self->mysqld->do_sql($dbname, $module->read);
}

sub _loaded_resolver {
    my ($self) = @_;

    my $resolver = $LOADED_RESOLVER || Test::Metro::DBHResolver->new;
    return $resolver;
}

sub _set_resolver {
    my ($self, $resolver) = @_;

    $LOADED_RESOLVER = $resolver;
}

sub get_resolver {
    my ($self) =@_;
    return $LOADED_RESOLVER;
};

sub rewrite_resolver {
    my ($self, $client_resolver) = @_;
    $client_resolver->config($LOADED_RESOLVER->config);
    $client_resolver;
}

sub ruledcluster_config {
    my ($self) = @_;
    my $connect_info = $LOADED_RESOLVER->config->{connect_info};
    my $node_config  = {};

    for my $node (keys %$connect_info) {
        my $_dsn = $connect_info->{$node}->{dsn};
        die 'Unknown format'
            if not $_dsn =~ /^(DBI:mysql:dbname=.+;)user=(.+)$/;

        $node_config->{$node} =  +{
            dsn   => $1,
            user  => $2,
            pass  => "",
            attrs => $connect_info->{$node}{attrs},
        };
    }
    return {
        node     => $node_config,
        clusters => +{},
    };
}

1;

