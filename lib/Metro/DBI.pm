package Metro::DBI;

use 5.014;
use warnings;

use Log::Minimal;
use DBIx::DBHResolver;
use Metro;
use Metro::Common;

our $resolver;
{
    my $env = $ENV{APP_ENV} || 'local';

    $resolver = DBIx::DBHResolver->new;

    my $db_config = Metro::Common->db_config;
    $resolver->config($db_config);
}

sub resolver {
    my ($self) = @_;
    return $resolver ||
        croakf("not exists DBHResolver");
}

1;
