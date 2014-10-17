package Metro::Web::Dispatcher;
use strict;
use warnings;
use utf8;

use Metro::Web::Router;

use File::Stamped;
use Sys::Hostname qw/hostname/;
use Encode qw/decode_utf8/;
use Log::Minimal;
use Path::Class;
use Carp;
use String::CamelCase qw/camelize/;

use constant +{
    FILTER_RESULT_RESPONSE  => 'response',
    FILTER_RESULT_VALIDATOR => 'validator',
};

my $router = Metro::Web::Router->new;
{
    for my $pl (dir(Metro->base_dir . "/route")->children) {
        my $route = $router->flat_route(do $pl)
            or die "route file syntax error in $pl: $!";
        for my $path (keys %$route) {
            if ( my $method = delete $route->{$path}{method} ) {
                $router->connect($path, $route->{$path}, +{method => $method});
            } else {
                $router->connect($path, $route->{$path});
            }
        }
    }
    print $router->as_string if $ENV{PROTOSERVER_DEBUG};
}

{ # for access log
    my $fh = File::Stamped->new(pattern => Metro->base_dir . "/log/access.log.%Y%m%d");
    my $hostname = hostname;
    my $access_print = sub {
        my ($time, $type, $message, $trace) = @_;
        print {$fh} decode_utf8(sprintf("(%s) %s [%s] %s at %s\n", $hostname, $time, $type, $message, $trace));
    };
    sub _access_log { $access_print }
}

sub dispatch {
    my ($class, $c) = @_;

    my $web_root = $ENV{DEBUG_WEB_ROOT} || ref Metro->context;
    my $req      = $c->request;

    my $p = $router->match($req->env) or return $c->res_404();
    if ( !$p->{nocheck} && ! _valid_entitlement() ) {
        return $c->res_403();
    }

    $c->{args} = $p;
    my $action = $p->{action};
    my $controller_class = "$web_root\::C::$p->{controller}";
    eval "require $controller_class" or croak "failed to load controller class $controller_class: $@";

    # filter
    my $filter_results = _filter($c, $p, $controller_class);
    if ( $filter_results->{ FILTER_RESULT_RESPONSE() } ) {
        return $filter_results;
    }
    delete $p->{filters};

    # process
    my $result = eval { $controller_class->$action($c, $p, $filter_results->{ FILTER_RESULT_VALIDATOR() }) };
    if ( my $e = $@ ) {
        critf("Internal Server Error: %s", $e);
        return $c->res_500();
    }
    return $result;
}

sub _filter {
    my ($c, $p, $controller_class) = @_;

    my $filters  = $p->{filters}        or return;
    my $web_root = $ENV{DEBUG_WEB_ROOT} || ref Metro->context;
    my $args     = $p->{filter_args}    || undef;

    my $results = {};
    for my $filter ( @$filters ) {
        my $res;

        if ( $filter =~ /::/ ) {
            my @structs      = split /::/, $filter;
            my $action       = pop @structs;
            my $controller   = join "::", @structs;
            my $filter_class = "$web_root\::Filter::$controller";

            eval "require $filter_class" or die "failed to load filter class: $filter_class";

            $res = $filter_class->$action($c, $p, $args);
            debugf("processed the filter: %s::%s", $filter_class, $action) if $ENV{PROTOSERVER_DEBUG};
        } elsif ( $filter eq 'validator' ) {
            my $validator_class =  $controller_class;
            $validator_class    =~ s/Web::C/Validator/;
            $validator_class    = join('::', $validator_class, camelize($p->{action}));

            eval "require $validator_class" or die "failed to load filter class: $validator_class";
            $res = $validator_class->validate($c, $p, $args);
        } else {
            $res = $controller_class->$filter($c, $p, $args);
            debugf("processed the filter: %s::%s", $controller_class, $filter) if $ENV{PROTOSERVER_DEBUG};
        }

        my $res_type = ref $res eq 'Amon2::Web::Response'  ? FILTER_RESULT_RESPONSE  :
                       ref $res eq 'Metro::FormValidator' ? FILTER_RESULT_VALIDATOR : '';
        $results->{$res_type} = $res;
    }

    $results->{ FILTER_RESULT_VALIDATOR() } ||= Metro::FormValidator->new($c->req);
    return $results;
}

# TODO implement
sub _valid_entitlement {
    return 1;
}

1;
