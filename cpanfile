requires 'Amon2',                           '6.00';
requires 'DBD::SQLite',                     '1.33';
requires 'HTML::FillInForm::Lite',          '1.11';
requires 'HTTP::Session2',                  '0.04';
requires 'JSON',                            '2.50';
requires 'Module::Functions',               '2';
requires 'Plack::Middleware::ReverseProxy', '0.09';
requires 'Router::Boom',                    '0.06';
requires 'Starlet',                         '0.20';
requires 'Teng',                            '0.18';
requires 'Test::WWW::Mechanize::PSGI';
requires 'Test::mysqld';
requires 'Text::Xslate',                    '2.0009';
requires 'Time::Piece',                     '1.20';
requires 'perl',                            '5.010_001';
requires 'Log::Minimal',                    '0.17';
requires 'DBIx::DBHResolver',               '0.17';
requires 'DBIx::Simple',                    '1.35';
requires 'DateTime',                        '1.06';
requires 'DBD::mysql',                      '4.025';
requires 'File::Stamped',                   '0.03';
requires 'Path::Class',                     '0.33';
requires 'Router::Simple',                  '0.15';
requires 'SQL::Abstract',                   '1.75';
requires 'SQL::Abstract::Plugin::InsertMulti', '0.04';
requires 'String::CamelCase';
requires 'Jcode',                           '2.07';
requires 'MIME::Entity',                    '5.505';
requires 'AWS::CLIWrapper',                 '1.01';
requires 'Imager',                          '0.98';
requires 'Module::Install::Repository',     '0.06';
requires 'git@github.com:zentooo/Amon2-Plugin-Web-Stash.git';
requires 'FormValidator::Lite',             '0.37';

requires 'Plack::Middleware::BetterStackTrace', '0.02';
requires 'Data::Dump',                          '1.22';
requires 'String::Random',                      '0.26';
requires 'Image::Info',                         '1.36';
requires 'Imager::ExifOrientation',             '0.07';
requires 'Sub::Retry',                          '0.06';
requires 'LWP::Protocol::https';
requires 'URL::Encode';
requires 'JSON::XS',                            '3.01';
requires 'Math::Combinatorics',                 '0.09';
requires 'Mail::Sendmail',                      '0.79';
requires 'Data::UUID',                          '1.219';
requires 'Email::Sender',                       '1.300016';
requires 'Email::MIME',                         '1.926';
requires 'IO::All',                             '0.82';

on configure => sub {
    requires 'Module::Build', '0.38';
    requires 'Module::CPANfile', '0.9010';
};

on test => sub {
    requires 'Test::More', '0.98';
};
