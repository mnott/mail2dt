#!/usr/bin/perl -w

use MIME::Base64 qw(decode_base64);
use URI::Encode qw(uri_decode);

my $filename = "";
my $filename_part = "";
my $in_subject = 0;

while ( <> ) {
	chomp;
	if (m/^Subject: (.*)$/) {
		$in_subject = 1;
		$filename .= subject_decode($1);
	} elsif ( $in_subject == 1 ) {
		if ( m/^ (.*)$/ ) {
			$filename .= subject_decode($1);
		} else {
			$filename =~ s![/_]! !g;
			print "$filename\n";
			last;
		}
	}
}

sub subject_decode {
	my ($subject) = @_;
	1 while $subject =~ s{(.*?)=\?[uU][tT][fF]-8\?B\?(.*?)\?=(.*)}{"$1".decode_base64($2)."$3"}eg;
	1 while $subject =~ s{(.*?)=\?[uU][tT][fF]-8\?Q\?(.*?)\?=(.*)}{"$1".url_decode($2)."$3"}eg;
	return $subject;
}

sub url_decode {
	my ($url) = @_;
	$url =~ s/=/%/g;
	return uri_decode($url);
}
