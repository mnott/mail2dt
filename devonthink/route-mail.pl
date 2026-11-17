#!/usr/bin/perl
#
# route-mail.pl ROUTES_FILE EML_FILE
#
# Prints the DEVONthink group UUID an email should be filed into, or nothing.
#
# DEVONthink smart rules only see From/To/Cc. A mail you received as BCC has
# none of your addresses there; the address it was really delivered to is only
# in the delivery headers (Delivered-To, X-Original-To, Envelope-To, or the
# "for <addr>" clause of a Received header). This script looks at all of them.
#
# Server host names (e.g. "by mail.example.com") are deliberately ignored:
# only real addresses are matched, otherwise the receiving mail server's name
# would match every mail.
#
# ROUTES_FILE: one route per line, "pattern  group-uuid" (whitespace separated),
# "#" comments allowed. Routes are tried in order; the first route with a
# pattern contained (case-insensitively) in any address wins - the same
# semantics as a list of "author or recipient contains" smart rules.

use strict;
use warnings;

my ($routes_file, $eml) = @ARGV;
die "usage: $0 ROUTES_FILE EML_FILE\n" unless defined $eml;

my @routes;
open my $rf, '<', $routes_file or exit 0;    # no routes configured: no-op
while (<$rf>) {
	s/#.*//;
	next unless /^\s*(\S+)\s+(\S+)\s*$/;
	push @routes, [lc $1, $2];
}
close $rf;
exit 0 unless @routes;

# Read the header block only, unfolding continuation lines.
open my $fh, '<', $eml or exit 0;
my @headers;
while (my $line = <$fh>) {
	$line =~ s/\r?\n$//;
	last if $line eq '';
	if ($line =~ /^[ \t]/ && @headers) {
		$headers[-1] .= ' ' . ($line =~ s/^\s+//r);
	} else {
		push @headers, $line;
	}
}
close $fh;

my $addr_re = qr/[A-Za-z0-9._%+\-=']+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}/;
my @addresses;
for my $h (@headers) {
	next unless $h =~ /^([A-Za-z\-]+):\s*(.*)$/;
	my ($name, $value) = (lc $1, $2);
	if ($name =~ /^(from|to|cc|bcc|delivered-to|x-original-to|envelope-to)$/) {
		push @addresses, $value =~ /($addr_re)/g;
	} elsif ($name eq 'received') {
		push @addresses, $1 while $value =~ /\bfor\s+<?($addr_re)>?/g;
	}
}
@addresses = map { lc } @addresses;

for my $r (@routes) {
	my ($pattern, $uuid) = @$r;
	for my $a (@addresses) {
		if (index($a, $pattern) >= 0) {
			print $uuid;
			exit 0;
		}
	}
}
exit 0;
