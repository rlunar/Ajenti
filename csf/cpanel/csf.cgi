#!/usr/bin/perl
#WHMADDON:csf:ConfigServer Security&<b>Firewall</b>
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

use lib '/usr/local/cpanel';
use Cpanel::cPanelFunctions ();
use Cpanel::Form			();
use Cpanel::Config          ();
use Whostmgr::HTMLInterface ();
use Whostmgr::ACLS			();

Whostmgr::ACLS::init_acls();

our ($reseller, $script, $images, %rprivs, $myv, %FORM);

if (-e "/usr/local/cpanel/bin/register_appconfig") {
	$script = "csf.cgi";
	$images = "csf";
} else {
	$script = "addon_csf.cgi";
	$images = "csf";
}

print "Content-type: text/html\r\n\r\n";

open (IN,"<","/etc/csf/csf.resellers");
while (my $line = <IN>) {
	my ($user,$alert,$privs) = split(/\:/,$line);
	$privs =~ s/\s//g;
	foreach my $priv (split(/\,/,$privs)) {
		$rprivs{$user}{$priv} = 1;
	}
	$rprivs{$user}{ALERT} = $alert;
}
close (IN);
$reseller = 0;
if (!Whostmgr::ACLS::hasroot()) {
	if ($rprivs{$ENV{REMOTE_USER}}{USE}) {
		$reseller = 1;
	} else {
		print "You do not have access to ConfigServer Firewall.\n";
		exit();
	}
}

eval ('use Cpanel::Rlimit			();');
unless ($@) {Cpanel::Rlimit::set_rlimit_to_infinity()}

open (IN, "</etc/csf/version.txt") or die $!;
$myv = <IN>;
close (IN);
chomp $myv;

%FORM = Cpanel::Form::parseform();

print <<EOF;
<!DOCTYPE html>
<HTML>
<HEAD>
<TITLE>ConfigServer Security & Firewall</TITLE>
</HEAD>
<BODY>
EOF
unless ($FORM{action} eq "tailcmd" or $FORM{action} eq "logtailcmd" or $FORM{action} eq "loggrepcmd") {
	print <<EOF;
<style>
#navigation{position:fixed;width:100%;z-index:99999;margin:0;padding:0;border:0;outline:0;top:0;left:0;font-size:13px;vertical-align:baseline;background:transparent;font-family:Lucida Sans Unicode,Lucida Grande,sans-serif;font-style:normal;line-height:18px;color:#333}
#breadcrumbs{min-height:43px}#breadcrumbs p{background-color:#eaeaea;border-bottom-style:solid;border-bottom-color:#cecece;border-width:1px;margin:0;padding:7px 12px}#breadcrumbs p,#breadcrumbs p a{color:#4c4c4c;text-decoration:none;font-family:verdana,arial,helvetica,clean,sans-serif;line-height:16px}#breadcrumbs p a.active{font-weight:700;color:#666;text-decoration:none}#breadcrumbs p a:hover{color:#000}
#breadcrumbsContainer{background-color:#eaeaea;border-bottom-style:solid;border-bottom-color:#cecece;min-height:41px;border-width:0 0 1px 0}.breadcrumbs{margin:0;padding:10px 12px 1px 12px;height:24px;list-style-image:none;list-style-position:outside}.breadcrumbs li{display:inline;padding:3px 3px 3px 3px}.breadcrumbs ul li,ol li{line-height:24px}.breadcrumbs li a{color:#4c4c4c;-ms-filter:"alpha(opacity=70)";filter:alpha(opacity=70);-webkit-opacity:.7;-moz-opacity:.7;-khtml-opacity:.7;opacity:.7}.breadcrumbs li a:link,a:visited,a:active{text-decoration:none;cursor:default}.breadcrumbs li img{position:relative;width:18px;height:18px;top:4px}
.breadcrumbs li a:hover{cursor:pointer;color:#000;-ms-filter:"alpha(opacity=100)";filter:alpha(opacity=100);-webkit-opacity:1;-moz-opacity:1;-khtml-opacity:1;opacity:1;text-decoration:none}.breadcrumbs li .leafNode{color:#333;-ms-filter:"alpha(opacity=90)";filter:alpha(opacity=90);-webkit-opacity:.9;-moz-opacity:.9;-khtml-opacity:.9;opacity:.9}
</style>
<div id="navigation">
	<div id="breadcrumbsContainer" class="hideBreadcrumbs">
        <ul id="breadcrumbs_list" class="breadcrumbs">
        <li><a href="$ENV{cp_security_token}/scripts/command?PFILE=main"><img border="0" alt='Home' src='/images/home.png' /><span class="imagenode">Home</span></a> <span>&raquo;</span></li>
		<li><a href="$ENV{cp_security_token}/scripts/command?PFILE=Plugins"><span>Plugins</span></a> <span>&raquo;</span></li>
		<li><a href="$script" class="leafNode"><span>ConfigServer Security &amp; Firewall</span></a></li>
        </ul>
    </div>
</div>
<br>
<br>
<br>
EOF
	print "<img src='$images/csf_small.png' align='absmiddle' alt='csf logo'> <b style='font-size: 16px'>ConfigServer Security &amp; Firewall - csf v$myv</b>";
}

if ($reseller) {
	do "/usr/local/csf/bin/csfuir.pl";
} else {
	do "/usr/local/csf/bin/csfui.pl";
}
print "</BODY>\n</HTML>\n";
1;
