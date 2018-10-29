#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Mojo::UserAgent;
use Path::Tiny;
use Data::Dumper;

sub Requester {
	my ($url, $cookie) = @_;
	my $ua = Mojo::UserAgent->new;
	# why is their server so goddamn slow
	$ua = $ua->connect_timeout(60)->inactivity_timeout(60)->request_timeout(60);
	return $ua->get($url => {
		'Host' => 'classie-evals.stonybrook.edu',
		'Accept-Language' => 'en-US,en;q=0.9,ko-KR;q=0.8,ko;q=0.7',
		'Cache-Control' => 'max-age=0',
		'Upgrade-Insecure-Requests' => '1',
		'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36',
		'DNT' => '1',
		'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
		'Referer' => 'https://sso.cc.stonybrook.edu/idp/profile/cas/login?execution=e1s1',
		'Cookie' => $cookie
	})->result->body;
}

sub RetrieveHistoricalData {
	my ($courseCode) = @_;
	# temporary until I write a sub to login via user and password
	my $cookie = path('stonybrook_cookie.txt')->slurp; 
	my $response = Requester('https://classie-evals.stonybrook.edu/?SearchKeyword=' . $courseCode . '&SearchTerm=ALL', $cookie);
	if ($response =~ m/<html><head><title>Object moved<\/title><\/head><body>/) {
		# Write sub to login via username and password to get the cookie.
		say "Invalid Credentials, please ensure you're using valid Stony Brook login credentials.";
	}
	else {
		say $response;
	}
}

BEGIN {
	RetrieveHistoricalData('cse305');
}

