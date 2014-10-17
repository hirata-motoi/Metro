package Metro::FormValidator;

use strict;
use warnings;
use utf8;
use Metro;
use parent qw/FormValidator::Lite/;
use File::Spec;
use Encode qw/decode_utf8/;
use Carp;

sub set_error_message {
    my ($self, $keystr) = @_;
    
    my $message_file = File::Spec->catfile(Metro->base_dir, 'config', 'message.conf');
    my $data = do($message_file) or croak("Failed to read $message_file");

    my %message = ();
    for my $param_name ( keys %{ $data->{$keystr} } ) {
        for my $rule ( keys %{ $data->{$keystr}{$param_name} } ) {
            my $pair = join '.', $param_name, lc($rule);
            my $message = decode_utf8($data->{$keystr}{$param_name}{$rule});

            $self->set_message( $pair => $message );
        }
    }
}

sub get_messages {
    my ($self) = @_;

    my $errors = $self->errors;

    my %messages = ();
    for my $param_name ( keys %$errors ) {
        my @errors = $self->get_error_messages_from_param($param_name);
        $messages{$param_name} = \@errors;
    }
    return \%messages;
}

1;

