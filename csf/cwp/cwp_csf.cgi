#!/usr/bin/perl
#WHMADDON:addonupdates:ConfigServer Security&<b>Firewall</b>
###############################################################################
# Copyright 2006-2013, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
# start main

use strict;
use File::Find;
use Fcntl qw(:DEFAULT :flock);
use Sys::Hostname qw(hostname);
use IPC::Open3;

our ($script, $images, $myv, %FORM);

open (IN, "</etc/csf/version.txt") or die $!;
$myv = <IN>;
close (IN);
chomp $myv;

$script = "/csf/cwp_csf.php";
$images = "/csf/images";

my $buffer = $ENV{'QUERY_STRING'};
if ($buffer eq "") {$buffer = $ENV{POST}}
my @pairs = split(/&/, $buffer);
foreach my $pair (@pairs) {
	my ($name, $value) = split(/=/, $pair);
	$value =~ tr/+/ /;
	$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	$FORM{$name} = $value;
}

#foreach my $key (keys %ENV) {
#	print "<p>$key = $ENV{$key}</p>\n";
#}

print <<EOF;
<!DOCTYPE html>
<HTML>
<HEAD>
<TITLE>ConfigServer Security & Firewall</TITLE>
</HEAD>
<BODY>
EOF

unless ($FORM{action} eq "tailcmd" or $FORM{action} eq "logtailcmd" or $FORM{action} eq "loggrepcmd") {
	print "<img src='$images/csf_small.png' align='absmiddle' alt='csf logo'> <b style='font-size: 16px'>ConfigServer Security & Firewall - csf v$myv</b>";
}

do "/usr/local/csf/bin/csfui.pl";

1;
