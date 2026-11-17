#!/usr/bin/perl -w
# Reads an RFC 822 mail on STDIN, prints a filesystem-safe filename from its Subject.

use strict;
use Encode qw(decode);
use Unicode::Normalize;

binmode STDOUT, ':utf8';
binmode STDIN, ':raw';

# Collect the (possibly folded) Subject header as raw bytes.
my $raw = undef;
while (my $line = <STDIN>) {
	last if $line =~ /^\r?$/;                       # end of headers
	if (defined $raw) {
		if ($line =~ /^[ \t]/) { $raw .= $line; next; }
		last;
	}
	$raw = $1 if $line =~ /^Subject:(.*)$/is;
}
$raw = '' unless defined $raw;
$raw =~ s/\r?\n//g;                                 # unfold

# Undecoded 8-bit bytes in the header: assume UTF-8, fall back to Windows-1252.
my $subject = eval { decode('UTF-8', $raw, Encode::FB_CROAK | Encode::LEAVE_SRC) };
$subject = decode('cp1252', $raw) unless defined $subject;

# Decode RFC 2047 encoded words (=?charset?B|Q?...?=), any charset.
my $decoded = eval { decode('MIME-Header', $subject) };
$subject = $decoded if defined $decoded;

$subject = NFC($subject);
$subject =~ s/&/u/g;
$subject =~ s/:/ -/g;
$subject =~ s/[\/\\]/-/g;
$subject =~ s/[\x00-\x1F\x7F]//g;
$subject =~ s/\s+/ /g;
$subject =~ s/^[\s.]+//;    # leading dots would make a hidden file DEVONthink ignores
$subject =~ s/\s+$//;
$subject = '(kein Betreff)' if $subject eq '';

print "$subject\n";
