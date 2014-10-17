package Metro::Web::C;

use strict;
use warnings;
use utf8;
use parent qw/Metro::Web/;

use Log::Minimal;
use Data::Dump qw/dump/;

sub set_validate_data_to_flash {
    my ($self, $c, $validator, $attr) = @_;

    $attr ||= +{};
    my $message_data = +{
        %$attr,
        form_messages => $validator->get_messages,
        params        => $c->req->parameters->as_hashref,
        #message       => $c->l("messages:validate_fail"),
        warning       => 1,
    };

    $c->flash($message_data);
}

sub output_response {
    my ($self, $c, $path, $data, $e) = @_;

    return $c->render($path, $data) if ! $e;

    $self->_log_exception($c, $e);
    return $c->res_500;
}

sub output_response_json {
    my ($self, $c, $data, $e) = @_;

    return $c->render_json($data) if ! $e;

    $self->_log_exception($c, $e);
    my $res = $c->render_json($data);
    $res->status(500);
    return $res;
}

sub _log_exception {
    my ($self, $c, $e) = @_;

    my $error       = sprintf('ERROR=%s', $e);

    my $req         = $c->req;
    my $request_uri = sprintf('REQ=%s %s', $req->method, $req->request_uri);
    my $user_agent  = sprintf('UA=%s', $req->user_agent);

    my $parameters  = sprintf('PARAMS=%s', dump $req->parameters->as_hashref); # hash_ref
    my $user        = sprintf('USER_ID=%d', $c->stash->{user_id});

    my $str = join "\t", $error, $user, $request_uri, $user_agent, $parameters;
    critf($str);
}

1;

