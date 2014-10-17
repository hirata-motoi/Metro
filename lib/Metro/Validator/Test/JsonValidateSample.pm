package Metro::Validator::Test::JsonValidateSample;

use strict;
use warnings;
use parent qw/Metro::Validator/;

sub form_validator_conf {
    +{
        name_f => [qw/EMAIL_LOOSE INT NOT_NULL/],
        name_l => [qw/NOT_NULL INT EMAIL_LOOSE/],
    };
}

sub do_logic_validate {
    my ($self, $c, $validator) = @_;

    my $id = $c->req->param('id');

    if ( ! $id ) {
        $validator->set_error(id => 'NOT_NULL');
    }
}

1;

