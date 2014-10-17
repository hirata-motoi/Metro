package Metro::Service::Session;
use strict;
use warnings;
use utf8;

use Digest::MD5 qw/md5_hex/;
use parent qw/Metro::Service::Base/;

sub set {
    my ($self, $user_id) = @_;

    my $teng = $self->teng('PROTOSERVER_MAIN_W');
    $teng->txn_begin;
    my $session_id = $self->model('Session')->set($teng, {user_id => $user_id});
    $teng->txn_commit;
    return $session_id;
}

sub get {
    my ($self, $session_id) = @_;

    my $teng = $self->teng('PROTOSERVER_MAIN_R');
    return $self->model('Session')->get($teng, $session_id);
}

1;

