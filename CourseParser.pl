#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Mojo::UserAgent;
use Path::Tiny;
use Data::Dumper;

sub LoginRequester {
	my ($ua, $url, $username, $password) = @_;
	# why is their server so goddamn slow
	$ua = $ua->max_redirects(5)->connect_timeout(60)->inactivity_timeout(60)->request_timeout(60);
	
	$ua = $ua->cookie_jar(Mojo::UserAgent::CookieJar->new);

	#$ua->proxy->http('http://10.1.165.159:8888')->https('http://10.1.165.159:8888');

	$ua->get('https://classie-evals.stonybrook.edu' => {
		'Host' => 'classie-evals.stonybrook.edu',
		'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36',
		'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
		'Accept-Language' => 'en-US,en;q=0.5',
		'Accept-Encoding' => 'gzip, deflate, br',
		'Connection' => 'keep-alive',
		'Upgrade-Insecure-Requests' => '1'
	})->result;

	my $response = $ua->post('https://sso.cc.stonybrook.edu/idp/profile/cas/login?execution=e1s1' => {
		'Host' => 'sso.cc.stonybrook.edu',
		'Cache-Control' => 'max-age=0',
		'Origin' => 'https://sso.cc.stonybrook.edu',
		'Connection' => 'keep-alive',
		'Upgrade-Insecure-Requests' => '1',
		'Accept-Language' => 'en-US,en;q=0.9,ko-KR;q=0.8,ko;q=0.7',
		'Cache-Control' => 'max-age=0',
		'Upgrade-Insecure-Requests' => '1',
		'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36',
		'DNT' => '1',
		'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
		'Referer' => 'https://sso.cc.stonybrook.edu/idp/profile/cas/login?execution=e4s1'
	} => form => {
		'j_username' => $username,
		'j_password' => $password,
		'_eventId_proceed' => ''
	})->result->body;

	if ($response =~ m/Current User: $username/) {
		return 1;
	}
	else {
		return 0;
	}
}

sub PageRequester {
	my ($ua, $url) = @_;
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
	})->result->body;
}

sub RetrieveHistoricalData {
	my ($ua, $courseCode) = @_;
	my $response = PageRequester($ua, 'https://classie-evals.stonybrook.edu/?SearchKeyword=' . $courseCode . '&SearchTerm=ALL');
	if ($response =~ m/<html><head><title>Object moved<\/title><\/head><body>/) {
		# Write sub to login via username and password to get the cookie.
		say "Invalid Credentials, please ensure you're using valid Stony Brook login credentials.";
		return 0;
	}
	else {
		return $response;
	}
}

BEGIN {
	my $username = "x";
	my $password = "x";
	my $ua = Mojo::UserAgent->new;
	if (LoginRequester($ua, 'https://sso.cc.stonybrook.edu/idp/profile/cas/login?execution=e4s1', $username, $password) eq 1) {
		say "Successfully logged in.";
	}
	else {
		say "Unable to login.";
	}

	print "Choose a course & code. (e.g.: CSE114): ";
	chomp (my $course = uc(<STDIN>));

	say "Retrieving historical data for course: " . $course;

	my $historical = RetrieveHistoricalData($ua, $course);

	if ($historical eq 0) {
		die "Error fetching data...\n";
	}
	else {
		my %professorData = ($historical =~ m/<a href="\/Instructor\/Details\/(\w+)">([^<]+)<\/a>/g);
		say "Professor List: " . Dumper \%professorData;

		my %courseData = ($historical =~ m/<a href="\/Section\/Details\/([^"]+)">([^<]+)<\/a>/g);
		say "Course List: " . Dumper \%courseData;

		while (my ($key, $value) = each (%courseData)) {
			$value = $courseData{$key};
			say "Fetching data for " . $value;
			my $prevCourse = "https://classie-evals.stonybrook.edu/Section/Details/" . $key;
			my $prevCourseData = PageRequester($ua, $prevCourse);
			my %prevCourseGradeData = ($prevCourseData =~ m/function drawChartGradeDistAFPNC\(\) \{[^\[]+([^\]]+)],[^\[]+([^\)]+)/g);
			say Dumper \%prevCourseGradeData;
		}
	}
}

