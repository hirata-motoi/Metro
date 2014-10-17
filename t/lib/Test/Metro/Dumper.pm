package Test::Metro::Dumper;
use strict;
use warnings;
use File::Temp;
use File::Copy qw/copy/;
use File::Path qw/make_path/;
use File::Basename qw/dirname/;
use Teng::Schema::Dumper;
use Metro;

use Test::Metro;
use Test::Metro::DBHResolver;

sub new {
    my ($class, %args) = @_;

    my $name    = $args{name};
    my $tables  = $args{tables};
    my $fixture = $args{fixture};
    my $config  = $args{config};

    die "Mandatory parameter missing: name" unless $name;

    die "Parameter:tables has to be ARRAYREF"
        if (defined $tables && ref $tables ne 'ARRAY');
    die "Parameter:fixture has to be ARRAYREF"
        if (defined $fixture && ref $fixture ne 'ARRAY');

    Test::Metro::DBHResolver->load($config || __config_file($service));

    bless {
        region   => $region,
        dbh      => Test::Metro::DBHResolver->resolver($name),
        database => Test::Metro::DBHResolver->database($name),
        tables   => $tables  || [],
        data     => $fixture || [],
        schema   => "",
        fixture  => {},
        teng     => $args{teng} ? 1 : 0,
    }, $class;
}

sub __config_file {
    my $env = $ENV{APP_ENV} && $ENV{APP_ENV} eq 'development' ? 'development' : 'local';
    sprintf("%s/config/db/dev.yaml", Metro->base_dir, $env);
}

sub dbh {
    $_[0]->{dbh};
}

sub database {
    my ($self, $label) = @_;
    my ($database) = $self->dsn($label) =~ /.+dbname=([^;]+).+/;
    return $database;
}

sub _use_infomation_schema {
    $_[0]->dbh->do('USE information_schema');
}

sub _use_database {
    $_[0]->dbh->do(sprintf 'USE %s', $_[0]->{database});
}

sub run {
    my ($self) = @_;

    my $tables = $self->get_tables;

    for my $table (@$tables) {
        next unless $self->want_schema($table);
        $self->create_schema($table);

        next unless $self->want_fixture($table);
        $self->create_fixture($table);
    }

    $self->dump;
}

sub get_tables {
    my ($self) = @_;

    $self->_use_infomation_schema;
    my $tables = $self->dbh->selectcol_arrayref(
        'SELECT table_name FROM tables WHERE table_schema=?', undef, $self->{database},
    ) or die;

    printf "database:%s is not found.\n", $self->{database}
        unless scalar @$tables;

    return $tables;
}

sub want_schema {
    my ($self, $table) = @_;
    return 1 unless scalar @{ $self->{tables} };
    return (grep { $_ eq $table } @{ $self->{tables} }) ? 1 : 0;
}

sub create_schema {
    my ($self, $table) = @_;

    $self->_use_database;
    my $ref = $self->dbh->selectrow_arrayref("SHOW CREATE TABLE $table")
        or die $self->dbh->errstr;

    my $schema = $ref->[1];
    $schema =~ s/ AUTO_INCREMENT=\d+//;  # Really?
    $self->{schema} .= "$schema;\n\n";
}

sub want_fixture {
    my ($self, $table) = @_;

    return (defined $self->{data} && grep { $_ eq $table } @{ $self->{data} })
        ? 1 : 0;
}

sub create_fixture {
    my ($self, $table) = @_;

    my $columns = $self->_get_columns($table);
    my $str_columns = join ",", @$columns;
    my $rows = $self->_get_data($table, $str_columns);

    return unless scalar @$rows;

    $self->{fixture}{$table} .= "INSERT INTO $table ($str_columns) VALUES\n";

    my @sql_values;
    for my $row (@$rows) {
        my @vals = map { $self->dbh->quote($row->{$_}) } @$columns;
        push @sql_values, sprintf "  (%s)",  join(", ", @vals);
    }
    $self->{fixture}{$table} .= join(",\n", @sql_values) . ";\n\n";
}

sub _get_columns {
    my ($self, $table) = @_;

    $self->_use_infomation_schema;
    my $columns = $self->dbh->selectcol_arrayref(
        'SELECT column_name FROM columns WHERE table_schema=? and table_name=?',
        { Slice => {} },
        $self->{database}, $table,
    ) or die $self->dbh->errstr;

    return $columns;
}

sub _get_data {
    my ($self, $table, $columns) = @_;

    $self->_use_database;
    my $rows = $self->dbh->selectall_arrayref("SELECT $columns FROM $table", { Slice => {} })
        or die $self->dbh->errstr;

    return $rows;
}

sub dump {
    my ($self) = @_;

    my $db = $self->{database};
    my $module_name = Test::Metro->module_name('schema', $self->{region}, $db);
    my $path = Test::Metro->module_path('schema', $self->{region}, $db);
    my $text = __module_text($module_name, $self->{schema});
    __create_module($path, $text);

    for my $tbl (keys %{ $self->{fixture} }) {
        my $module_name = Test::Metro->module_name('fixture', $self->{region}, $db, $tbl);
        my $path = Test::Metro->module_path('fixture', $self->{region}, $db, $tbl);
        my $text = __module_text($module_name, $self->{fixture}{$tbl});
        __create_module($path, $text);
    }

    $self->_create_teng_schema if $self->{teng};
}

sub __module_text {
    my ($module_name, $text) = @_;

    return <<"MODULE";
package $module_name;
use strict;
use warnings;
use parent qw/Test::Metro::Reader/;
sub read { \$_[0]->SUPER::read }
1;
__DATA__
$text
MODULE
}

sub __create_module {
    my ($path, $text) = @_;

    my $fh = File::Temp->new;
    $fh->print($text);
    $fh->close;

    my $dir = dirname($path);
    make_path $dir unless -d $dir;

    copy( $fh->filename, $path )
        or die "failed to copy module file:$path - $!";

    print "Created: $path\n";
}

sub _create_teng_schema {
    my ($self) = @_;


    my $db = $self->{database};
    my @ns = ('teng', $self->{region}, $db);
    my $module_name = Test::Metro->module_name(@ns);
    my $module_path = Test::Metro->module_path(@ns);
    __create_module($module_path, <<"MODULE");
package $module_name;
use parent 'Teng';
1;
MODULE

    my $schema_path = Test::Metro->module_path(@ns, 'Schema');
    my $schema = Teng::Schema::Dumper->dump(
        dbh       => $self->dbh,
        namespace => $module_name,
    );
    __create_module($schema_path, $schema);
}

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Temperance::Dumper - Dump mysql table schema and teng schema.

=head1 SYNOPSIS

  use Temperance::Dumper;
  my $dumper = Temperance::Dumper->new(
      service  => 'jp_dev_service',
      name     => 'OPEN_R',
      tables   => [ qw/foo_bar_map_table foo_master_table bar_master_table/ ],  # optional
      fixture  => [ qw/foo_master_table bar_master_table/ ],                    # optional
      teng     => 1,                                                            # optional
  );
  $dumper->run;

=head1 DESCRIPTION

Temperance::Dumper is MySQL schema dumper. It also supports Teng.

MySQL schema will dump to Temperance::Schema::*

Teng schema will dump to Temperance::Teng::* if you specified teng option.

=head1 AUTHOR

Kosuke Arisawa E<lt>arisawa.kosuke@dena.jp<gt>

=head1 COPYRIGHT

Copyright 2012- Kosuke Arisawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
