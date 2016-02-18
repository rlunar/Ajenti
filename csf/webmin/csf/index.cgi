#!/usr/bin/perl
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

our ($script, $images, $myv, %FORM, %in);

open (IN, "</etc/csf/version.txt") or die $!;
$myv = <IN>;
close (IN);
chomp $myv;

$script = "index.cgi";
$images = "csfimages";

print "Content-type: text/html\r\n\r\n";

do '../web-lib.pl';      
&init_config();         
&ReadParse();
%FORM = %in;

print <<EOF;
<!DOCTYPE html>
<HTML>
<HEAD>
<TITLE>ConfigServer Security & Firewall</TITLE>
</HEAD>
<BODY>
EOF
unless ($FORM{action} eq "tailcmd" or $FORM{action} eq "logtailcmd" or $FORM{action} eq "loggrepcmd") {
	print "<img src='csfimages/csf_small.png' align='absmiddle' alt='csf logo'> <b style='font-size: 16px'>ConfigServer Security & Firewall - csf v$myv</b>";
}

do "/usr/local/csf/bin/csfui.pl";
print "</BODY>\n</HTML>\n";

1;
