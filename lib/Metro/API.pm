package Metro::API;

use strict;
use warnings;

use parent qw/Metro/;
use Log::Minimal;
use Metro;
use Metro::ConfigLoader;
use Metro::Common;
use URI;
use URL::Encode;
use LWP::UserAgent;
use HTTP::Request::Common;
use YAML;
use JSON;
use Carp;
use Log::Minimal;
use File::Spec;
use URI::Escape;

=put

metroのAPIを叩く基本機能を実装する

request
  parameter
    params
      request parameterに使うkeyとvalueの組み合わせをhashで受け取る
  url
    configからbase_urlを取得
    パラメータにaccess_tokenを付加

  object
    singletonパターンで実装

　result
    decodeしてhashで返す
=cut

my $__SINGLETON;
my $ua = LWP::UserAgent->new;

sub new {
    if ($__SINGLETON) {
        return $__SINGLETON;
    }
    my $class = shift;
    $__SINGLETON = bless { @_ }, $class;
    return $__SINGLETON;
}

sub request {
    my ($self, $params) = @_;

    if (my $error = _validate($params) ) {
        croakf('Invalid parameter error:%s', $error);
    }

    my $config   = Metro::Common->config;
    my $base_url = $config->{metro_api_base_url};
    my $secret   = Metro::Common->get_key_vault('metro_api_access_token');
    my $type     = delete $params->{type};
    my $data_uri = delete $params->{data_uri};

    my @paths = ();
    push @paths, $type     if $type;
    push @paths, $data_uri if $data_uri;

    my $url = sprintf '%s/%s?%s', $base_url, File::Spec->catfile(@paths), _create_param_string({%$params, 'acl:consumerKey' => $secret});

    print $url, "\n";
    my $req = GET($url);
    my $res = $ua->request($req);

    if (!$res) {
        croak(sprintf('Failed to get response params:%s', Dump $params));
        return;
    }

    if (!$res->is_success) {
        croak(sprintf('Failed to get status:%s', $res->status_line));
        return;
    }

    return decode_json($res->content);
}

# どうやらas_stringを使うと全てのparameterがurl encodeされてしまうらしい  :  はencodeされるといかんみたい
sub _create_param_string {
    my $params = shift;

    my @elems = ();

    for my $key (keys %$params) {
        push @elems, sprintf('%s=%s', $key, uri_escape_utf8($params->{$key}));
    }
    return join '&', @elems;
}


# datapoints -> rdf:type rquired
# datapoints && data_uri -> parameter not required
# places -> rdf:type lat lon radius required
# places && data_uri -> parameter not required
# TODO 細かくmethodに切り出し
sub _validate {
    my $params = shift;

    unless ( $params->{type} && ($params->{type} eq 'datapoints' || $params->{type} eq 'places') ) {
        return sprintf('invalid type : %s', $params->{type});
    }

#    if ($params->{'data_uri'}) {
#         if ( my @redundant_keys =  grep { $_ ne 'data_uri' && $_ ne 'type' } keys %$params) {
#             return sprintf('invalid parameters : %s', join(' ,', @redundant_keys));
#         }
#         return;
#    }
#
#    if ($params->{type} eq 'datapoints') {
#        my @redundant_keys = grep { $_ ne 'type' && $_ ne 'rdf:type'} keys %$params;
#        return if !@redundant_keys;
#        return sprintf('invalid parameters : %s', join(' ,', @redundant_keys));
#    }
#
#    if ($params->{type} eq 'places') {
#        # TODO confに切り出し
#        my @redundant_keys = grep { $_ ne 'type' && $_ ne 'lat' && $_ ne 'lon' && $_ ne 'radius'} keys %$params;
#        return if scalar !@redundant_keys;
#        return sprintf('invalid parameters : %s', join(' ,', @redundant_keys));
#    }
#
#    return 'invalid type && data_uri';
    return;
}

1;

