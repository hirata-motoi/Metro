package Test::Metro::mysqld;
use strict;
use warnings;
use JSON;
use File::Spec;
use Test::mysqld;

use Test::Metro;

our $MY_CNF    = $ENV{PROTOSERVER_MY_CNF} || Test::Metro->base_dir . '/my.cnf';
our $JSON_FILE = File::Spec->catfile(File::Spec->tmpdir, 'temperance_mysqld.json');
our $SKIP_DROP_DB_MAP = {
    information_schema => 1,
    mysql              => 1,
    test               => 1,
};

sub new {
    my ($class, $args) = @_;

    $args           ||= +{};
    $args->{my_cnf} ||= +{};
    $args->{my_cnf}{'skip-networking'} = ''; # using unix domain socket

    my $mysqld;
    if ( $ENV{PERL_TEST_MYSQLPOOL_DSN} ) {
        # don't create Test::mysqld instance when use App::Prove::Plugin::MySQLPool
    }
    elsif (my $sock = $ENV{LOCAL_MYSQLD_SOCK}) {
        die "socket:$ENV{LOCAL_MYSQLD_SOCK} is not found." unless -S $sock;
        $args->{auto_start} = 0;
        $args->{my_cnf}{socket} = $sock;
        $mysqld = Test::mysqld->new($args) or die $Test::mysqld::errstr;
    }
    elsif (-e $JSON_FILE) {
        open my $fh, '<', $JSON_FILE or die $!;
        my $obj = decode_json(join '', <$fh>);
        $mysqld = bless $obj, 'Test::mysqld';
    }
    else {
#        if ($ENV{HARNESS_ACTIVE}) {
#            print <<HINT;
# You can use local mysqld process if it is working.
# Please try: 'LOCAL_MYSQLD_SOCK=/tmp/mysql.sock prove -lv t/01_mysqld.t'
#         or: '[other window] script/babyry_mysqld.pl; your_command'
# IT'S SO FAST!!
#HINT
#        }
        $mysqld = Test::mysqld->new($args) or die $Test::mysqld::errstr;
    }
    bless {
        test_mysqld       => $mysqld,
        created_databases => [],
    }, $class;
}

sub dsn {
    my ($self, $dbname) = @_;

    $dbname ||= 'test';

    if ( my $dsn = $ENV{PERL_TEST_MYSQLPOOL_DSN} ) {
        # replace dsn
        $dsn =~ s/^DBI:mysql:dbname=\w+?;/DBI:mysql:dbname=$dbname;mysql_read_default_file=$MY_CNF;/;
        return $dsn;
    } else {
        return $self->{test_mysqld}->dsn(dbname => $dbname, mysql_read_default_file => $MY_CNF);
    }
}

sub dbh {
    my ($self, $dbname) = @_;
    my $dsn = $self->dsn($dbname);
    return DBI->connect($dsn , '', '', {
        AutoCommit => 1,
        RaiseError => 1,
    });
}

sub create_database {
    my ($self, $dbname) = @_;
    my $dbh = $self->dbh;
    $dbh->do("CREATE DATABASE IF NOT EXISTS $dbname");
    Test::Metro->diag("Created database: $dbname");
    push @{ $self->{created_databases} }, $dbname;

    $self->_create_q4m_functions($dbh, $dbname) if $dbname =~ /queue/;
}

sub do_sql {
    my ($self, $dbname, $sql) = @_;

    return unless $sql;

    Test::Metro->diag("Loading SQL to $dbname");

    my $dbh = $self->dbh($dbname);
    chomp $sql;
    map { $dbh->do($_) } grep { $_ =~ /.+/ } split(/;/, $sql);

    Test::Metro->diag("Loaded SQL to $dbname");
}

sub _create_q4m_functions {
    my ($self, $dbh, $dbname) = @_;

    Test::Metro->diag("Install Q4M plugin: $dbname");

    my $rs = $dbh->selectall_hashref('show plugins', 'Name');
    return if defined $rs->{QUEUE};

    # for q4m
    my @setup_queries = (
        q|INSTALL PLUGIN queue SONAME 'libqueue_engine.so'|,
        q|CREATE FUNCTION queue_wait RETURNS INT SONAME 'libqueue_engine.so'|,
        q|CREATE FUNCTION queue_end RETURNS INT SONAME 'libqueue_engine.so'|,
        q|CREATE FUNCTION queue_abort RETURNS INT SONAME 'libqueue_engine.so'|,
        q|CREATE FUNCTION queue_rowid RETURNS INT SONAME 'libqueue_engine.so'|,
        q|CREATE FUNCTION queue_set_srcid RETURNS INT SONAME 'libqueue_engine.so'|,
    );

    for (@setup_queries) {
        $dbh->do($_) or croak( $dbh->errstr );
    }

}

sub cleanup {
    my ($self) = @_;
    my $dbh = $self->dbh;

    # my $rows = $dbh->selectcol_arrayref('SHOW DATABASES');
    my $rows = $self->{created_databases};
    for my $db (@$rows) {
        next if $SKIP_DROP_DB_MAP->{$db};
        $dbh->do("DROP DATABASE IF EXISTS $db");
        Test::Metro->diag("Removed database: $db");
    }
}

sub DESTROY {
    $_[0]->cleanup;
}

1;

