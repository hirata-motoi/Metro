package Metro::Web::C::Test;

use strict;
use warnings;
use utf8;

use parent qw/Metro::Web::C/;

sub test {
	my ($self, $c) = @_;
	$self->output_response_json($c, { a => 111 }, undef);
}

1;
