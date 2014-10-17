#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Metro::Common;
use YAML;
use LWP::UserAgent;
use HTTP::Request;
use JSON;

my $access_token = Metro::Common->get_key_vault('metro_api_access_token');
my $base_url     = Metro::Common->config->{'metro_api_base_url'};
my $ua           = LWP::UserAgent->new;

my $url = sprintf('https://api.tokyometroapp.jp/api/v2/datapoints?rdf:type=odpt:Train&acl:consumerKey=%s', $access_token);
my $response = $ua->get($url);

if ($response->is_success) {
	print Dump decode_json($response->content);
} else {
	die $response->status_line;
}



