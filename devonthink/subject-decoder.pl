#!/usr/bin/perl -w

use MIME::Base64 qw(decode_base64);
use URI::Encode qw(uri_decode);
use URI::Escape qw(uri_unescape);
use Encode qw(decode encode);
use Unicode::Normalize;

binmode STDOUT, ':utf8';
binmode STDIN, ':utf8';

my $filename = "";
my $filename_part = "";
my $in_subject = 0;

while ( <> ) {
	if (m/^Subject:(.*)$/) {
		$in_subject = 1;
		$filename .= subject_decode($1);
	} elsif ( $in_subject == 1 ) {
		if ( m/^ (.*)$/ ) {
			$filename .= subject_decode($1);
		} else {
			$filename =~ s/^\s+//; # remove leading whitespace
			# Only clean up characters that are actually problematic for filesystems
			$filename =~ s/[\/\\]/-/g;  # Replace slashes with hyphen
			$filename =~ s/[\x00-\x1F\x7F]//g;  # Remove control characters
			print "$filename\n";
			last;
		}
	}
}

sub subject_decode {
	my ($subject) = @_;
	1 while $subject =~ s{(.*?)=\?[uU][tT][fF]-?8\?[bB]\?(.*?)\?=(.*)}{"$1".decode('UTF-8', decode_base64($2))."$3"}eg;
	1 while $subject =~ s{(.*?)=\?[uU][tT][fF]-?8\?[qQ]\?(.*?)\?=(.*)}{"$1".decode('UTF-8', utf8_decode($2))."$3"}eg;
	1 while $subject =~ s{(.*?)=\?[iI][sS][oO].*?\?[bB]\?(.*?)\?=(.*)}{"$1".decode('ISO-8859-1', decode_base64($2))."$3"}eg;
	1 while $subject =~ s{(.*?)=\?[iI][sS][oO].*?\?[qQ]\?(.*?)\?=(.*)}{"$1".decode('ISO-8859-1', iso_decode($2))."$3"}eg;

	# Normalize Unicode characters
	$subject = NFC($subject);

	$subject =~ s/&/u/g;
	$subject =~ s/:/ -/g;

	# Remove any remaining control characters
	$subject =~ s/[\x00-\x1F\x7F]//g;

	return $subject;
}

sub utf8_decode {
	my ($str) = @_;
	$str =~ s/=/%/g;
	$str = uri_unescape(uri_decode($str));
	$str =~ s/_/ /g;  # Convert any underscores back to spaces
	return $str;
}

sub iso_decode {
	my ($str) = @_;
	$str =~ s/=/%/g;
	$str = uri_unescape(uri_decode($str, 'iso-8859-1'));
	$str = uri_unescape(uri_decode($str, 'windows-1252'));
	$str =~ s/_/ /g;  # Convert any underscores back to spaces
	return $str;
}