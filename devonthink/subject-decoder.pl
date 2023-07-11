#!/usr/bin/perl -w

use MIME::Base64 qw(decode_base64);
use URI::Encode qw(uri_decode);
use URI::Escape qw(uri_unescape);

#binmode STDOUT, ':utf8';

my $filename = "";
my $filename_part = "";
my $in_subject = 0;

while ( <> ) {
	#chomp;
	#print "0: $_\n";
	if (m/^Subject:(.*)$/) {
		#print "1 $1\n";
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
	1 while $subject =~ s{(.*?)=\?[uU][tT][fF]-?8\?[bB]\?(.*?)\?=(.*)}{"$1".decode_base64($2)."$3"}eg;
	1 while $subject =~ s{(.*?)=\?[uU][tT][fF]-?8\?[qQ]\?(.*?)\?=(.*)}{"$1".utf8_decode($2)."$3"}eg;
	1 while $subject =~ s{(.*?)=\?[iI][sS][oO].*?\?[bB]\?(.*?)\?=(.*)}{"$1".decode_base64($2)."$3"}eg;
	1 while $subject =~ s{(.*?)=\?[iI][sS][oO].*?\?[qQ]\?(.*?)\?=(.*)}{"$1".iso_decode($2)."$3"}eg;
	$subject =~ s/&/u/g;
	$subject =~ s/:/ -/g;
	return $subject;
}

sub utf8_decode {
	my ($str) = @_;
	$str =~ s/=/%/g;
	$str = uri_unescape(uri_decode($str));
	return $str;
}

sub iso_decode {
	my ($str) = @_;
	$str =~ s/=/%/g;
	$str = uri_unescape(uri_decode($str, 'iso-8859-1'));
	$str = uri_unescape(uri_decode($str, 'windows-1252'));
	return $str;
}