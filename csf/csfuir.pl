#!/usr/bin/perl
###############################################################################
# Copyright 2006-2016, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
# start main
#use strict;
use lib '/usr/local/csf/lib';
use POSIX qw(:sys_wait_h sysconf strftime);
use ConfigServer::Config;
use ConfigServer::CheckIP;

our ($chart, $ipscidr6, $ipv6reg, $ipv4reg, %sanity, %minmaxavg, %config, %ips, $mobile);

umask(0177);

open (IN, "<","/proc/sys/kernel/hostname");
$hostname = <IN>;
chomp $hostname;
close (IN);
$hostshort = (split(/\./,$hostname))[0];
$tz = strftime("%z", localtime);

my $config = ConfigServer::Config->loadconfig();
%config = $config->config();

print <<EOF;

<style type="text/css">
a {
	color: #000000;
	text-decoration: underline;
}
td {
	font-family:Arial, Helvetica, sans-serif;
	font-size:small;
}
body {
	font-family:Arial, Helvetica, sans-serif;
	font-size:small;
}
pre {
	font-family: Courier New, Courier;
	font-size: 12px;
}
.comment {
	border-radius:5px;
	border: 1px solid #DDDDDD;
	padding: 10px;
	font-family: Courier New, Courier;
	font-size: 14px
}
.value-default {
	background:#F5F5F5;
	padding:2px;
	border-radius:5px;
}
.value-other {
	background:#F4F4EA;
	padding:2px;
	border-radius:5px;
}
.value-disabled {
	background:#F5F5F5;
	padding:2px;
	border-radius:5px;
}
.value-warning {
	background:#FFC0CB;
	padding:2px;
	border-radius:5px;
}
.section {
	border-radius:5px;
	border: 2px solid #990000;
	padding: 10px;
	font-size:16px;
	font-weight:bold;
}
EOF
unless (-e "/etc/csuibuttondisable") {
	print <<EOF;
.input {
	min-width:0px;
	padding:3px;
	background:#FFFFFF;
	border-radius:3px;
	border:1px solid #A6C150;
	color:#990000 !important;
	font-family:Verdana, Geneva, sans-serif;
	text-shadow: 0px 1px 1px #CDCDCD;
	font-size:13px;
	font-weight:normal;
	margin:2px;
}
.input:hover {
	cursor:pointer;
	border:1px solid #A6C150;
	box-shadow: 0px 0px 6px 1px #A6C150;
}
input[type=text], textarea, select {
	-webkit-transition: all 0.30s ease-in-out;
	-moz-transition: all 0.30s ease-in-out;
	-ms-transition: all 0.30s ease-in-out;
	-o-transition: all 0.30s ease-in-out;
	transition: all 0.30s ease-in-out;
	border-radius:3px;
	outline: none;
	padding: 3px 0px 3px 3px;
	margin: 5px 1px 3px 0px;
	border: 1px solid #DDDDDD;
}
input[type=text]:focus, textarea:focus, select:focus {
	box-shadow: 0 0 5px #CC0000;
	padding: 3px 0px 3px 3px;
	margin: 5px 1px 3px 0px;
	border: 1px solid #CC0000;
}
EOF
}
print "</style>\n";

if ($FORM{ip} ne "") {$FORM{ip} =~ s/(^\s+)|(\s+$)//g}

if ($FORM{action} ne "" and !checkip(\$FORM{ip})) {
	print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
	print "<tr bgcolor='#FFFFFF'><td>";
	print "[$FORM{ip}] is not a valid IP address\n";
	print "</td></tr></table>\n";
	print "<p><form action='$script' method='post'><input type='submit' class='input' value='Return'></form></p>\n";
} else {
	if ($FORM{action} eq "qallow" and $rprivs{$ENV{REMOTE_USER}}{ALLOW}) {
		if ($FORM{comment} eq "") {
			print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
			print "<tr bgcolor='#FFFFFF'><td>You must provide a Comment for this option</td></tr></table>\n";
		} else {
			$FORM{comment} =~ s/"//g;
			print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
			print "<tr bgcolor='#FFFFFF'><td>";
			print "<p>Allowing $FORM{ip}...</p>\n<p><pre style='font-family: Courier New, Courier; font-size: 12px'>\n";
			my $text = &printcmd("/usr/sbin/csf","-a",$FORM{ip},"ALLOW by Reseller $ENV{REMOTE_USER} ($FORM{comment})");
			print "</p>\n<p>...<b>Done</b>.</p>\n";
			print "</td></tr></table>\n";
			if ($rprivs{$ENV{REMOTE_USER}}{ALERT}) {
				open (IN, "</usr/local/csf/tpl/reselleralert.txt");
				my @alert = <IN>;
				close (IN);
				chomp @alert;

				my @message;
				foreach my $line (@alert) {
					$line =~ s/\[reseller\]/$ENV{REMOTE_USER}/ig;
					$line =~ s/\[action\]/ALLOW/ig;
					$line =~ s/\[ip\]/$FORM{ip}/ig;
					$line =~ s/\[rip\]/$ENV{REMOTE_HOST}/ig;
					$line =~ s/\[text\]/Result of ALLOW:\n\n$text/ig;
					push @message, $line;
				}
				&sendmail(@message);
			}
			&logfile("cPanel Reseller [$ENV{REMOTE_USER}]: ALLOW $FORM{ip}");
		}
		print "<p><form action='$script' method='post'><input type='hidden' name='mobi' value='$FORM{mobi}'><input type='submit' class='input' value='Return'></form></p>\n";
	}
	elsif ($FORM{action} eq "qdeny" and $rprivs{$ENV{REMOTE_USER}}{DENY}) {
		if ($FORM{comment} eq "") {
			print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
			print "<tr bgcolor='#FFFFFF'><td>You must provide a Comment for this option</td></tr></table>\n";
		} else {
			$FORM{comment} =~ s/"//g;
			print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
			print "<tr bgcolor='#FFFFFF'><td>";
			print "<p>Blocking $FORM{ip}...</p>\n<p><pre style='font-family: Courier New, Courier; font-size: 12px'>\n";
			my $text = &printcmd("/usr/sbin/csf","-d",$FORM{ip},"DENY by Reseller $ENV{REMOTE_USER} ($FORM{comment})");
			print "</p>\n<p>...<b>Done</b>.</p>\n";
			print "</td></tr></table>\n";
			if ($rprivs{$ENV{REMOTE_USER}}{ALERT}) {
				open (IN, "</usr/local/csf/tpl/reselleralert.txt");
				my @alert = <IN>;
				close (IN);
				chomp @alert;

				my @message;
				foreach my $line (@alert) {
					$line =~ s/\[reseller\]/$ENV{REMOTE_USER}/ig;
					$line =~ s/\[action\]/DENY/ig;
					$line =~ s/\[ip\]/$FORM{ip}/ig;
					$line =~ s/\[rip\]/$ENV{REMOTE_HOST}/ig;
					$line =~ s/\[text\]/Result of DENY:\n\n$text/ig;
					push @message, $line;
				}
				&sendmail(@message);
			}
			&logfile("cPanel Reseller [$ENV{REMOTE_USER}]: DENY $FORM{ip}");
		}
		print "<p><form action='$script' method='post'><input type='hidden' name='mobi' value='$FORM{mobi}'><input type='submit' class='input' value='Return'></form></p>\n";
	}
	elsif ($FORM{action} eq "qkill" and $rprivs{$ENV{REMOTE_USER}}{UNBLOCK}) {
		my $text = "";
		if ($rprivs{$ENV{REMOTE_USER}}{ALERT}) {
			my ($childin, $childout);
			my $pid = open3($childin, $childout, $childout, "/usr/sbin/csf","-g",$FORM{ip});
			while (<$childout>) {$text .= $_}
			waitpid ($pid, 0);
		}
		print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
		print "<tr bgcolor='#FFFFFF'><td>";
		print "<p>Unblock $FORM{ip}, trying permanent blocks...</p>\n<p><pre style='font-family: Courier New, Courier; font-size: 12px'>\n";
		my $text1 = &printcmd("/usr/sbin/csf","-dr",$FORM{ip});
		print "</p>\n<p>...<b>Done</b>.</p>\n";
		print "<p>Unblock $FORM{ip}, trying temporary blocks...</p>\n<p><pre style='font-family: Courier New, Courier; font-size: 12px'>\n";
		my $text2 = &printcmd("/usr/sbin/csf","-tr",$FORM{ip});
		print "</p>\n<p>...<b>Done</b>.</p>\n";
		print "</td></tr></table>\n";
		print "<p><form action='$script' method='post'><input type='hidden' name='mobi' value='$FORM{mobi}'><input type='submit' class='input' value='Return'></form></p>\n";
		if ($rprivs{$ENV{REMOTE_USER}}{ALERT}) {
			open (IN, "</usr/local/csf/tpl/reselleralert.txt");
			my @alert = <IN>;
			close (IN);
			chomp @alert;

			my @message;
			foreach my $line (@alert) {
				$line =~ s/\[reseller\]/$ENV{REMOTE_USER}/ig;
				$line =~ s/\[action\]/UNBLOCK/ig;
				$line =~ s/\[ip\]/$FORM{ip}/ig;
				$line =~ s/\[rip\]/$ENV{REMOTE_HOST}/ig;
				$line =~ s/\[text\]/Result of GREP before UNBLOCK:\n$text\n\nResult of UNBLOCK:\nPermanent:\n$text1\nTemporary:\n$text2\n/ig;
				push @message, $line;
			}
			&sendmail(@message);
		}
		&logfile("cPanel Reseller [$ENV{REMOTE_USER}]: UNBLOCK $FORM{ip}");
	}
	elsif ($FORM{action} eq "grep" and $rprivs{$ENV{REMOTE_USER}}{GREP}) {
		print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
		print "<tr bgcolor='#FFFFFF'><td>";
		print "<p>Searching for $FORM{ip}...</p>\n<p><pre style='font-family: Courier New, Courier; font-size: 12px'>\n";
		&printcmd("/usr/sbin/csf","-g",$FORM{ip});
		print "</p>\n<p>...<b>Done</b>.</p>\n";
		print "</td></tr></table>\n";
		print "<p><form action='$script' method='post'><input type='submit' class='input' value='Return'></form></p>\n";
	}
	else {
		print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
		print "<tr><th align='left' colspan='2'>csf - ConfigServer Firewall</th></tr>";
		if ($rprivs{$ENV{REMOTE_USER}}{ALLOW}) {print "<tr bgcolor='#F4F4EA'><td><form action='$script' method='post'><input type='hidden' name='action' value='qallow'><input type='submit' class='input' value='Quick Allow'></td><td width='100%'>Allow IP address <input type='text' name='ip' id='allowip' value='' size='18' style='background-color: lightgreen'> through the firewall and add to the allow file (csf.allow).<br>Comment for Allow: <input type='text' name='comment' value='' size='30'> (required)</form></td></tr>\n"}
		if ($rprivs{$ENV{REMOTE_USER}}{DENY}) {print "<tr bgcolor='#F4F4EA'><td><form action='$script' method='post'><input type='hidden' name='action' value='qdeny'><input type='submit' class='input' value='Quick Deny'></td><td width='100%'>Block IP address <input type='text' name='ip' value='' size='18' style='background-color: pink'> in the firewall and add to the deny file (csf.deny).<br>Comment for Block: <input type='text' name='comment' value='' size='30'> (required)</form></td></tr>\n"}
		if ($rprivs{$ENV{REMOTE_USER}}{UNBLOCK}) {print "<tr bgcolor='#F4F4EA'><td><form action='$script' method='post'><input type='hidden' name='action' value='qkill'><input type='submit' class='input' value='Quick Unblock'></td><td width='100%'>Remove IP address <input type='text' name='ip' value='' size='18'> from the firewall (temp and perm blocks)</form></td></tr>\n"}
		if ($rprivs{$ENV{REMOTE_USER}}{GREP}) {print "<tr bgcolor='#F4F4EA'><td><form action='$script' method='post'><input type='hidden' name='action' value='grep'><input type='submit' class='input' value='Search for IP'></td><td width='100%'>Search iptables for IP address <input type='text' name='ip' value='' size='18'></form></td></tr>\n"}
		print "</table><br>\n";
	}
}

print "<pre style='font-family: Courier New, Courier; font-size: 12px'>csf: v$myv</pre>";
print "<p>&copy;2006-2016, <a href='http://www.configserver.com' target='_blank'>ConfigServer Services</a> (Way to the Web Limited)</p>\n";
# end main
###############################################################################
# start printcmd
sub printcmd {
	my $text;
	my ($childin, $childout);
	my $pid = open3($childin, $childout, $childout, @_);
	while (<$childout>) {print $_ ; $text .= $_}
	waitpid ($pid, 0);
	return $text;
}
# end printcmd
###############################################################################
# start sendmail
sub sendmail {
	my @message = @_;
	my $time = localtime(time);
	my $from = $config{LF_ALERT_FROM};

	if ($from =~ /([\w\.\=\-\_]+\@[\w\.\-\_]+)/) {$from = $1}
	if ($from eq "") {$from = "root"}

	open (MAIL, "|$config{SENDMAIL} -f $from -t");
	my $header = 1;
	foreach my $line (@message) {
		$line =~ s/\r//;
		if ($line eq "") {$header = 0}
		$line =~ s/\[time\]/$time $tz/ig;
		$line =~ s/\[hostname\]/$hostname/ig;
		if ($header) {
			if ($config{LF_ALERT_TO}) {$line =~ s/^To:.*$/To: $config{LF_ALERT_TO}/i}
			if ($config{LF_ALERT_FROM}) {$line =~ s/^From:.*$/From: $config{LF_ALERT_FROM}/i}
		}
		print MAIL $line."\n";
	}
	close (MAIL);
}
# end sendmail
###############################################################################
# start logfile
sub logfile {
	my $line = shift;
	my @ts = split(/\s+/,scalar localtime);
	if ($ts[2] < 10) {$ts[2] = " ".$ts[2]}
	sysopen (LOGFILE,"/var/log/lfd.log", O_WRONLY | O_APPEND | O_CREAT);
	flock (LOGFILE, LOCK_EX);
	print LOGFILE "$ts[1] $ts[2] $ts[3] $hostshort lfd[$$]: $line\n";
	close (LOGFILE);
}
# end logfile
###############################################################################

1;
