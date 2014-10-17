package Metro::Web::Router;

use Metro;
use parent qw/Router::Simple/;

use Data::Dumper;
use List::MoreUtils qw/uniq/;

sub setup {
    my ($self) = @_;

    for my $pl (dir(Metro->base_dir . "/route")->children) {
        my $routes = $self->flat_route(do $pl)
            or die "route file syntax error in $pl: $!";
        for my $path (keys %$routes) {
            if ( my $method = delete $routes->{$path}{method} ) {
                $self->connect($path, $routes->{$path}, +{method => $method});
            } else {
                $self->connect($path, $routes->{$path});
            }
        }
    }
    print $self->as_string if $ENV{PROTOSERVER_DEBUG};
    return $self;
}

sub flat_route {
    my ($self, $routes) = @_;
    for my $path (keys %$routes) {
        $self->_flatten($path, $routes->{$path}, $routes);
    }
    $routes;
}

sub _flatten {
    my ($self, $path, $parent, $routes) = @_;

    my %route;
    for my $key ( keys %$parent ) {
        unless (ref $parent->{$key} eq 'HASH') {
            $route{$key} = $parent->{$key};
            next;
        }
        next if $key eq 'filter_attr';

        (my $chained_path = join '/', $path, $key) =~ s/\/{2,}/\//g;
        my $child = delete $parent->{$key};
        $child->{controller} ||= $parent->{controller};

        $child->{filters} = exists $child->{filters}?
            [ uniq grep({$_ =~ /^-/} @{$parent->{filters}}), @{$child->{filters}} ]:
            [ grep {$_ =~ /^-/} @{$parent->{filters}} ];

        if (my $p_attr = $parent->{filter_attr}) {
            $child->{filter_attr} = $child->{filter_attr} ?
                +{ %$p_attr, %{$child->{filter_attr}} }: $p_attr;
        }

        $self->_flatten($chained_path, $child, $routes);
        $routes->{$chained_path} = $child;
    }
    \%route;
}

sub as_string {
    my $self = shift;

    return "\n" . join("\n", map { _route_as_string($_); } @{ $self->{routes} }) . "\n\n";
}

sub _route_as_string {
    my $route = shift;
    my $dest = $route->{dest};

    my $struct = +{};

    $struct->{pattern} = $route->{pattern};
    $struct->{role} = $dest->{role} if $dest->{role};
    $struct->{feature} = $dest->{feature} if $dest->{feature};

    $struct->{sequence} = join(" -> ", (map {
        if ( $_ =~ /^-/ ) {
            my $m = $_;
            $m =~ s/^-//;
            $m;
        }
        else {
            $dest->{controller} . "::" . $_;
        }
    } @{ $dest->{filters} }), $dest->{controller} . "::" . $dest->{action});


    return Dumper $struct;
}

1;

