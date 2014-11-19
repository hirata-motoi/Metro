package Metro::Model::Mail;
use strict;
use warnings;
use utf8;

use YAML;
use Log::Minimal;
use Email::Sender::Simple qw/sendmail/;
use Email::MIME;
use Email::MIME::Creator;
use Encode;
use IO::All;

use parent qw/Metro::Model::Base/;

sub send {
    my ($self, $params, $file) = @_;

    my @parts   = (
        Email::MIME->create(
            'attributes' => {
                'content_type' => 'text/plain',
                'charset'      => 'ISO-2022-JP',
                'encoding'     => '7bit',
            },
            'body' => Encode::encode( 'iso-2022-jp', '' ), # body
        ),
        Email::MIME->create(
            'attributes' => {
                'fimename'     => 'path.png',
                'content_type' => 'image/png',
                'encoding'     => 'base64',
                'name'         => $file,
            },
            'body' => io($file)->all,
        ),
    );
    my $mail = Email::MIME->create(
        'header' => [
            'From'    => encode('MIME-Header-ISO_2022_JP', $params->{from} || 'info@smart-travel-japan.com'),
            'To'      => encode('MIME-Header-ISO_2022_JP', $params->{to}),
            'Subject' => encode('MIME-Header-ISO_2022_JP', 'From Metro Browser'),
        ],
        'parts'  => [ @parts ],
    );

    sendmail($mail) or croakf('Failed to send email');

    return;
}

sub send_test {
    my ($self) = @_;
    infof("send_test called");

my $contents = {
    from    => 'from@example.com',
    to      => 'hirata.motoi@gmail.com',
    subject => '電子メール',
    body    => 'サンプル',
    envelope_sender => 'envelope_sender@example.com',
};

my $mail = Email::MIME->create(
    header => [
        From    => $contents->{from},
        To      => $contents->{to},
        Subject => Encode::encode('MIME-Header-ISO_2022_JP', $contents->{subject}),
    ],
    attributes => { 
        content_type => 'text/plain',
        charset  => 'ISO-2022-JP',
        encoding => '7bit',
    },
    body_str => $contents->{body},
);

    eval{ sendmail($mail, {from => $contents->{envelope_sender}}) };
    if ($@) {
        infof("error : $@");
    }
}

1;

