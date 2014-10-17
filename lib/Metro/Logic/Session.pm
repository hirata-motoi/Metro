package Metro::Logic::Session;
use strict;
use warnings;
use utf8;

use Digest::MD5 qw/md5_hex/;
use parent qw/Metro::Logic::Base/;

use Metro::Service::Session;

sub create {
    my ($self, $user_id) = @_;
    return md5_hex(time . $user_id);
}

sub set {
    my ($self, $user_id, $session_id) = @_;

    my $service = Metro::Service::Session->new;
    return $service->set($user_id);
}

sub get {
    my ($self, $session_id) = @_;

    my $service = Metro::Service::Session->new;
    return $service->get($session_id);
}

1;

