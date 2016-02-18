#!/usr/bin/perl
###############################################################################
# Copyright 2006-2016, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
# start main
#use strict;
use File::Find;
use File::Copy;
use IPC::Open3;

umask(0177);

my $myv = "2.0";

$webpath = '/';

if ($FORM{do} eq "view") {
	&view;
	exit;
}

print "Content-type: text/html\r\n\r\n";

if ($FORM{do} eq "console") {
	print "<HTML>\n<TITLE>ConfigServer Explorer Console</TITLE>\n<BODY>\n";
}
else {
	print <<EOF;

<!DOCTYPE html>
<HTML>
<HEAD>
<TITLE>ConfigServer Explorer</TITLE>
</HEAD>
<BODY>
<style type="text/css">
.tdshade1{background:#FFFFFF;}
.tdshade2,.cellheader{background:#F4F4EA;}
.tdshadeyellow{background:lightyellow;}
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

	print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
	print "<td valign='top' width='100%' nowrap style='font-size: medium'><img src='$images/cse_small.png' align='absmiddle' /> <b>ConfigServer Explorer - cse v$myv</b>&nbsp;&nbsp;&nbsp;&nbsp;</td>\n";
	if ($config{UI_CXS} or $config{UI_CSE}) {
		print "<td valign='top' nowrap style='font-size: medium'><form action='$script' method='post'><select name='csfapp'><option>csf</option>";
		if ($config{UI_CXS}) {print "<option>cxs</option>"}
		if ($config{UI_CSE}) {print "<option selected>cse</option>"}
		print "</select> <input type='submit' class='input' value='Switch'></form>&nbsp;&nbsp;&nbsp;&nbsp;</td>\n";
	}
	print "<td valign='top' nowrap style='font-size: medium'>[<a href='$script?csfaction=csflogout'>cse Logout</a>]</td>\n";
	print "</tr></table><br />\n";
}

$message = "";

if ($fileinc) {&uploadfile}
elsif ($FORM{do} eq "") {&browse}
elsif ($FORM{quit} == 2) {&browse}
elsif ($FORM{do} eq "b") {&browse}
elsif ($FORM{do} eq "p") {&browse}
elsif ($FORM{do} eq "o") {&browse}
elsif ($FORM{do} eq "c") {&browse}
elsif ($FORM{do} eq "m") {&browse}
elsif ($FORM{do} eq "pw") {&browse}
elsif ($FORM{do} eq "r") {&browse}
elsif ($FORM{do} eq "newf") {&browse}
elsif ($FORM{do} eq "newd") {&browse}
elsif ($FORM{do} eq "cnewf") {&cnewf}
elsif ($FORM{do} eq "cnewd") {&cnewd}
elsif ($FORM{do} eq "ren") {&ren}
elsif ($FORM{do} eq "del") {&del}
elsif ($FORM{do} eq "setp") {&setp}
elsif ($FORM{do} eq "seto") {&seto}
elsif ($FORM{do} eq "cd") {&cd}
elsif ($FORM{do} eq "console") {&console}
elsif ($FORM{do} eq "edit") {&edit}
elsif ($FORM{do} eq "Cancel") {&browse}
elsif ($FORM{do} eq "Save") {&save}
elsif ($FORM{do} eq "copyit") {&copyit}
elsif ($FORM{do} eq "moveit") {&moveit}
else {print "Invalid action"};

unless ($FORM{do} eq "console") {
	print "<pre style='font-family: Courier New, Courier; font-size: 12px'>cse: v$myv</pre>";
	print "<p>&copy;2006-2016, <a href='http://www.configserver.com' target='_blank'>ConfigServer Services</a> (Way to the Web Limited)</p>\n";
}
print "\n</BODY>\n</HTML>\n";

exit;
# end main
###############################################################################
# start browse
sub browse {
	my $extra;
	if ($FORM{c}) {
		if (-e "$webpath$FORM{c}") {
			$extra = "&c=$FORM{c}";
		} else {
			$FORM{c} = "";
		}
	}
	if ($FORM{m}) {
		if (-e "$webpath$FORM{m}") {
			$extra = "&m=$FORM{m}"
		} else {
			$FORM{m} = "";
		}
	}

	print "<script language='javascript'>\n";
	print "	function check(file) {return confirm('Click OK to '+file)}\n";
	print "</script>\n";

	$thisdir = $webpath;
	if ($thisdir !~ /\/$/) {$thisdir .= "/"}
	$thisdir .= $FORM{p};
	$thisdir =~ s/\/+/\//g;
	@months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");

	my $errordir = 0;
	opendir (DIR, "$thisdir") or $errordir = 1;
	while (my $file = readdir(DIR)) {
		if (-d "$thisdir/$file") {
			if ($file !~ /^\.$|^\.\.$/) {push (@thisdirs, $file)}
		} else {
			push (@thisfiles, $file);
		}

	}
	closedir (DIR);

	@thisdirs = sort @thisdirs;
	@thisfiles = sort @thisfiles;

	print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
	print "<tr><td><b>STOP! WARNING!</b></p>\n<p>While this utility can be very useful it is also very dangerous indeed. You can easily render your server inoperable and unrecoverable by performing ill advised actions. No warranty or guarantee is provided with the product that protects against system damage.</p>\n</td></tr>\n";
	print "</table><br>\n";

	if ($message) {print "<center><h3>$message</h3></center>\n";}
	print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
	print "<tr><td colspan='10'>";
	print "[<a href=\"$script?do=b&p=$extra\">Home</a>]";
	my $path = "";
	my $cnt = 2;
	my @path = split(/\//,$FORM{p});
	foreach my $dir (@path) {
		if ($dir ne "" and ($dir ne "/")) {
			if ($cnt == @path) {
				print "/$dir";
			} else {
				print "/<a href=\"$script?do=b&p=$path/$dir$extra\">$dir</a>";
			}
			$path .= "/$dir";
			$cnt++;
		}
	}
	if ($FORM{c}) {print "&nbsp;&nbsp;&nbsp;&nbsp;Copy buffer: [$FORM{c}] <a href='$script?do=c&p=$FORM{p}$extra\#new'>paste</a>\n"}
	if ($FORM{m}) {print "&nbsp;&nbsp;&nbsp;&nbsp;Move buffer: [$FORM{m}] <a href='$script?do=m&p=$FORM{p}$extra\#new'>paste</a>\n"}
	print "</td></tr>\n";
	if ($errordir) {
		print "<tr><td colspan='10'>Permission Denied</td></tr>";
	} else {
		if (@thisdirs > 0) {
			print "<tr class='cellheader' align='center'>";
			print "<td>Directory Name</td>";
			print "<td>Size</td>";
			print "<td>Date</td>";
			print "<td>User(uid)/Group(gid)</td>";
			print "<td>Perms</td>";
			print "<td colspan='5'>Actions</td>";
			print "</tr>\n";
		}
		my $class = "tdshade2";
		foreach my $dir (@thisdirs) {
			if ($dir =~/'|"|\||\`/) {
				print "<td colspan='10'>".quotemeta($dir)."Invalid directory name - ignored</td>";
				next;
			}
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$thisdir/$dir");
			if ($size < 1024) {
			}
			elsif ($size < (1024 * 1024)) {
				$size = sprintf("%.1f",($size/1024));
				$size .= "k";
			}
			else {
				$size = sprintf("%.1f",($size/(1024 * 1024)));
				$size .= "M";
			}
			$mode = sprintf "%04o", $mode & 07777;
			$tgid = getgrgid($gid);
			if ($tgid eq "") {$tgid = $gid}
			$tuid = getpwuid($uid);
			if ($tuid eq "") {$tuid = $uid}
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime);
			$year += 1900;
			my $time = sprintf "%02d:%02d:%02d", $hour, $min, $sec;
			$mday = sprintf "%02d", $mday;
			$mtime = "$mday-$months[$mon]-$year $time";
			my $pp = "";
			my $passfile = "$FORM{p}/$dir";
			$passfile =~ s/\//\_/g;
			$passfile =~ s/\\/\_/g;
			$passfile =~ s/\:/\_/g;
			if (-e "$storepath/$passfile.htpasswd") {
				open (PASSFILE, "<$storepath/$passfile.htpasswd") or die $!;
				@passrecs = <PASSFILE>;
				close (PASSFILE);
				chomp @passrecs;
				if (@passrecs > 0) {$pp = "**"}
			}

			print "<tr class='$class'>";
			if ($class eq "tdshade2") {$class = "tdshade1"} else {$class = "tdshade2"}
			if ($FORM{do} eq "r" and ($FORM{f} eq $dir)) {
				print "<form action='$script' method='post'>\n";
				print "<td>";
				print "<input type='hidden' name='do' value='ren'>\n";
				print "<input type='hidden' name='p' value='$FORM{p}'>\n";
				print "<input type='hidden' name='c' value='$FORM{c}'>\n";
				print "<input type='hidden' name='m' value='$FORM{m}'>\n";
				print "<input type='hidden' name='f' value='$dir'>\n";
				print "<input type='text' size='10' name='newf' value='$dir'>\n";
				print "<input type='submit' class='input' value='OK'>\n";
				print "$pp<a name='new'></a></td>";
				print "</form>\n";
			}
			elsif (-r "$webpath$FORM{p}/$dir") {
				print "<td><a href='$script?do=b&p=$FORM{p}/$dir$extra\#new'>$dir</a>$pp</td>";
			}
			else {
				print "<td>$dir</td>";
			}
			print "<td align='right'>$size</td>";
			print "<td align='right'>$mtime</td>";
			if ($FORM{do} eq "o" and ($FORM{f} eq $dir)) {
				print "<form action='$script' method='post'>\n";
				print "<td align='right'>";
				print "<input type='hidden' name='do' value='seto'>\n";
				print "<input type='hidden' name='p' value='$FORM{p}'>\n";
				print "<input type='hidden' name='c' value='$FORM{c}'>\n";
				print "<input type='hidden' name='m' value='$FORM{m}'>\n";
				print "<input type='hidden' name='f' value='$dir'>\n";
				print "<input type='text' size='20' name='newo' value='$tuid:$tgid'>\n";
				print "<input type='submit' class='input' value='OK'>\n";
				print "<a name='new'></a></td>";
				print "</form>\n";
			}
			else {
				print "<td align='right'><a href='$script?do=o&p=$FORM{p}&f=$dir$extra\#new'>$tuid($uid)/$tgid($gid)</a></td>";
			}
			if ($FORM{do} eq "p" and ($FORM{f} eq $dir)) {
				print "<form action='$script' method='post'>\n";
				print "<td align='right'>";
				print "<input type='hidden' name='do' value='setp'>\n";
				print "<input type='hidden' name='p' value='$FORM{p}'>\n";
				print "<input type='hidden' name='c' value='$FORM{c}'>\n";
				print "<input type='hidden' name='m' value='$FORM{m}'>\n";
				print "<input type='hidden' name='f' value='$dir'>\n";
				print "<input type='text' size='3' name='newp' value='$mode'>\n";
				print "<input type='submit' class='input' value='OK'>\n";
				print "<a name='new'></a></td>";
				print "</form>\n";
			}
			else {
				print "<td align='right'><a href='$script?do=p&p=$FORM{p}&f=$dir$extra\#new'>$mode</a></td>";
			}
			print "<td>&nbsp;</td>";
			print "<td align='center'><a href='$script?do=del&p=$FORM{p}&f=$dir$extra' onClick='return check(\"DELETE $dir\")'>delete</a></td>";
			print "<td align='center'><a href='$script?do=r&p=$FORM{p}&f=$dir$extra\#new'>rename</a></td>";
			print "<td align='center'><a href='$script?do=b&p=$FORM{p}&c=$FORM{p}/$dir\#new'>copy</a></td>";
			print "<td align='center'><a href='$script?do=b&p=$FORM{p}&m=$FORM{p}/$dir\#new'>move</a></td>";
			print "</tr>\n";
		}
		if ($FORM{do} eq "newd") {
			print "<tr align='center'>";
			print "<form action='$script' method='post'>\n";
			print "<td>";
			print "<input type='hidden' name='do' value='cnewd'>\n";
			print "<input type='hidden' name='p' value='$FORM{p}'>\n";
			print "<input type='hidden' name='c' value='$FORM{c}'>\n";
			print "<input type='hidden' name='m' value='$FORM{m}'>\n";
			print "<input type='text' size='10' name='newf' value=''>\n";
			print "<input type='submit' class='input' value='OK'>\n";
			print "<a name='new'></a></td>";
			print "</form>\n";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td colspan='5'>&nbsp;</td>";
			print "</tr>\n";
		}
		if (($FORM{do} eq "c") and (-d "$webpath$FORM{c}")) {
			my $newf = (split(/\//,$FORM{c}))[-1];
			print "<tr align='center'>";
			print "<form action='$script' method='post'>\n";
			print "<td>";
			print "<input type='hidden' name='do' value='copyit'>\n";
			print "<input type='hidden' name='p' value='$FORM{p}'>\n";
			print "<input type='hidden' name='c' value='$FORM{c}'>\n";
			print "<input type='hidden' name='m' value='$FORM{m}'>\n";
			print "<input type='text' size='10' name='newf' value='$newf'>\n";
			print "<input type='submit' class='input' value='OK'>\n";
			print "<a name='new'></a></td>";
			print "</form>\n";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td colspan='5'>&nbsp;</td>";
			print "</tr>\n";
		}
		if (($FORM{do} eq "m") and (-d "$webpath$FORM{m}")) {
			my $newf = (split(/\//,$FORM{m}))[-1];
			print "<tr align='center'>";
			print "<form action='$script' method='post'>\n";
			print "<td>";
			print "<input type='hidden' name='do' value='moveit'>\n";
			print "<input type='hidden' name='p' value='$FORM{p}'>\n";
			print "<input type='hidden' name='c' value='$FORM{c}'>\n";
			print "<input type='hidden' name='m' value='$FORM{m}'>\n";
			print "<input type='text' size='10' name='newf' value='$newf'>\n";
			print "<input type='submit' class='input' value='OK'>\n";
			print "<a name='new'></a></td>";
			print "</form>\n";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td colspan='5'>&nbsp;</td>";
			print "</tr>\n";
		}

		if (@thisfiles > 0) {
			print "<tr><td colspan='10'>&nbsp;</td></tr>\n";
			print "<tr class='cellheader' align='center'>";
			print "<td>File Name</td>";
			print "<td>Size</td>";
			print "<td>Date</td>";
			print "<td>User(uid)/Group(gid)</td>";
			print "<td>Perms</td>";
			print "<td colspan='5'>Actions</td>";
			print "</tr>\n";
		}
		$class = "tdshade2";
		foreach my $file (@thisfiles) {
			if ($file =~/'|"|\||\`/) {
				print "<td colspan='10'>".quotemeta($file)."Invalid file name - ignored</td>";
				next;
			}
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$thisdir/$file");
			if ($size < 1024) {
			}
			elsif ($size < (1024 * 1024)) {
				$size = sprintf("%.1f",($size/1024));
				$size .= "k";
			}
			else {
				$size = sprintf("%.1f",($size/(1024 * 1024)));
				$size .= "M";
			}
			$mode = sprintf "%03o", $mode & 00777;
			$tgid = getgrgid($gid);
			if ($tgid eq "") {$tgid = $gid}
			$tuid = getpwuid($uid);
			if ($tuid eq "") {$tuid = $uid}
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime);
			$year += 1900;
			my $time = sprintf "%02d:%02d:%02d", $hour, $min, $sec;
			$mday = sprintf "%02d", $mday;
			$mtime = "$mday-$months[$mon]-$year $time";
			print "<tr class='$class'>";
			if ($class eq "tdshade2") {$class = "tdshade1"} else {$class = "tdshade2"}
			if ($FORM{do} eq "r" and ($FORM{f} eq $file)) {
				print "<form action='$script' method='post'>\n";
				print "<td>";
				print "<input type='hidden' name='do' value='ren'>\n";
				print "<input type='hidden' name='p' value='$FORM{p}'>\n";
				print "<input type='hidden' name='c' value='$FORM{c}'>\n";
				print "<input type='hidden' name='m' value='$FORM{m}'>\n";
				print "<input type='hidden' name='f' value='$file'>\n";
				print "<input type='text' size='20' name='newf' value='$file'>\n";
				print "<input type='submit' class='input' value='OK'>\n";
				print "<a name='new'></a></td>";
				print "</form>\n";
			}
			else {
				$act = "$script?do=view&p=$FORM{p}&f=$file$extra\#new";
				print "<td><a href='$act' target='_blank'>$file</a></td>";
			}
			print "<td align='right'>$size</td>";
			print "<td align='right'>$mtime</td>";
			if ($FORM{do} eq "o" and ($FORM{f} eq $file)) {
				print "<form action='$script' method='post'>\n";
				print "<td align='right'>";
				print "<input type='hidden' name='do' value='seto'>\n";
				print "<input type='hidden' name='p' value='$FORM{p}'>\n";
				print "<input type='hidden' name='c' value='$FORM{c}'>\n";
				print "<input type='hidden' name='m' value='$FORM{m}'>\n";
				print "<input type='hidden' name='f' value='$file'>\n";
				print "<input type='text' size='20' name='newo' value='$tuid:$tgid'>\n";
				print "<input type='submit' class='input' value='OK'>\n";
				print "<a name='new'></a></td>";
				print "</form>\n";
			}
			else {
				print "<td align='right'><a href='$script?do=o&p=$FORM{p}&f=$file$extra\#new'>$tuid($uid)/$tgid($gid)</a></td>";
			}
			if ($FORM{do} eq "p" and ($FORM{f} eq $file)) {
				print "<form action='$script' method='post'>\n";
				print "<td align='right'>";
				print "<input type='hidden' name='do' value='setp'>\n";
				print "<input type='hidden' name='p' value='$FORM{p}'>\n";
				print "<input type='hidden' name='c' value='$FORM{c}'>\n";
				print "<input type='hidden' name='m' value='$FORM{m}'>\n";
				print "<input type='hidden' name='f' value='$file'>\n";
				print "<input type='text' size='3' name='newp' value='$mode'>\n";
				print "<input type='submit' class='input' value='OK'>\n";
				print "<a name='new'></a></td>";
				print "</form>\n";
			}
			else {
				print "<td align='right'><a href='$script?do=p&p=$FORM{p}&f=$file$extra\#new'>$mode</a></td>";
			}
			my $ext = (split(/\./,$file))[-1];
			if (-T "$webpath$FORM{p}/$file") {
				my $act = "";
				print "<td align='center'><a href='$script?do=edit&p=$FORM{p}&f=$file$extra\#new'>edit</a>$act</td>";
			} else {
				print "<td>&nbsp;</td>";
			}
			print "<td align='center'><a href='$script?do=del&p=$FORM{p}&f=$file$extra' onClick='return check(\"DELETE $file\")'>delete</a></td>";
			print "<td align='center'><a href='$script?do=r&p=$FORM{p}&f=$file$extra\#new'>rename</a></td>";
			print "<td align='center'><a href='$script?do=b&p=$FORM{p}&c=$FORM{p}/$file\#new'>copy</a></td>";
			print "<td align='center'><a href='$script?do=b&p=$FORM{p}&m=$FORM{p}/$file\#new'>move</a></td>";
			print "</tr>\n";
		}
		if ($FORM{do} eq "newf") {
			print "<tr align='center'>";
			print "<form action='$script' method='post'>\n";
			print "<td>";
			print "<input type='hidden' name='do' value='cnewf'>\n";
			print "<input type='hidden' name='p' value='$FORM{p}'>\n";
			print "<input type='hidden' name='c' value='$FORM{c}'>\n";
			print "<input type='hidden' name='m' value='$FORM{m}'>\n";
			print "<input type='text' size='10' name='newf' value=''>\n";
			print "<input type='submit' class='input' value='OK'>\n";
			print "<a name='new'></a></td>";
			print "</form>\n";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td colspan='5'>&nbsp;</td>";
			print "</tr>\n";
		}
		if (($FORM{do} eq "c") and (-f "$webpath$FORM{c}")) {
			my $newf = (split(/\//,$FORM{c}))[-1];
			print "<tr align='center'>";
			print "<form action='$script' method='post'>\n";
			print "<td>";
			print "<input type='hidden' name='do' value='copyit'>\n";
			print "<input type='hidden' name='p' value='$FORM{p}'>\n";
			print "<input type='hidden' name='c' value='$FORM{c}'>\n";
			print "<input type='hidden' name='m' value='$FORM{m}'>\n";
			print "<input type='text' size='10' name='newf' value='$newf'>\n";
			print "<input type='submit' class='input' value='OK'>\n";
			print "<a name='new'></a></td>";
			print "</form>\n";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td colspan='5'>&nbsp;</td>";
			print "</tr>\n";
		}
		if (($FORM{do} eq "m") and (-f "$webpath$FORM{m}")) {
			my $newf = (split(/\//,$FORM{m}))[-1];
			print "<tr align='center'>";
			print "<form action='$script' method='post'>\n";
			print "<td>";
			print "<input type='hidden' name='do' value='moveit'>\n";
			print "<input type='hidden' name='p' value='$FORM{p}'>\n";
			print "<input type='hidden' name='c' value='$FORM{c}'>\n";
			print "<input type='hidden' name='m' value='$FORM{m}'>\n";
			print "<input type='text' size='10' name='newf' value='$newf'>\n";
			print "<input type='submit' class='input' value='OK'>\n";
			print "<a name='new'></a></td>";
			print "</form>\n";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td colspan='5'>&nbsp;</td>";
			print "</tr>\n";
		}
	}
	print "</table>\n";

	print "<p align='center' class='cellheader'>All the following actions apply to the current directory</p>\n";
	print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
	print "<tr class='cellheader'><td colspan='2' align='center'>Create New...</td></tr>\n";
	print "<tr align='center'><td><a href='$script?do=newd&p=$FORM{p}$extra\#new'>Create New Directory</a></td>\n<td><a href='$script?do=newf&p=$FORM{p}$extra\#new'>Create Empty File</a></td></tr>\n";
	print "<form action='$script' method='post' enctype='multipart/form-data'>\n";
	print "<input type='hidden' name='p' value='$FORM{p}'>\n";
	print "<input type='hidden' name='c' value='$FORM{c}'>\n";
	print "<input type='hidden' name='m' value='$FORM{m}'>\n";
	print "<tr class='cellheader'><td colspan='2' align='center'>Upload File (64MB max)...</td></tr>\n";
	print "<tr><td colspan='2' align='center'><input type='file' style='border:1px solid #990000' size='40' name='file0'></td></tr>\n";
	print "<tr><td colspan='2' align='center'>Mode:<input type='radio' name='type' value='ascii'>Ascii <input type='radio' name='type' value='binary' checked>Binary <input type='submit' class='input' value='Upload'></td></tr>\n";
	print "</form>\n";
	print "<tr class='cellheader'><td colspan='2' align='center'>Change Directory...</td></tr>\n";
	print "<form action='$script' method='post'>\n";
	print "<input type='hidden' name='p' value='$FORM{p}'>\n";
	print "<input type='hidden' name='c' value='$FORM{c}'>\n";
	print "<input type='hidden' name='m' value='$FORM{m}'>\n";
	print "<input type='hidden' name='do' value='cd'>\n";
	print "<tr align='center'><td colspan='2' align='center'>";
	print "<input type='text' name='directory' value='$thisdir' size='40'>\n";
	print " <input type='submit' class='input' value='Change Directory'></td></tr>\n";
	print "</form>\n";
	print "</table><br><br>\n";

	print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
	print "<tr class='cellheader'><td colspan='2' align='center'>Virtual Console ($thisdir)</td></tr>\n";
	print "<form action='$script' method='post' target='WHMConsole'>\n";
	print "<input type='hidden' name='p' value='$FORM{p}'>\n";
	print "<input type='hidden' name='c' value='$FORM{c}'>\n";
	print "<input type='hidden' name='m' value='$FORM{m}'>\n";
	print "<input type='hidden' name='do' value='console'>\n";
	print "<tr align='center'><td colspan='2' align='center'>";
	print "<iframe width='100%' height='500' name='WHMConsole' style='border: 1px #990000 solid' border='0' frameborder='0' src='$script?do=console&cmd=ls%20-la&p=$FORM{p}'></iframe>\n";
	print "<p>Command: <input type='text' name='cmd' value='' size='80' onFocus='this.value=\"\"'>\n";
	print " <input type='submit' class='input' value='Send'></p><p>Note: You cannot change directory within the console. Use the <i>Change Directory</i> feature above.<br>You can only use non-interactive commands, e.g. <b>top, vi, pico, nano, etc</b> will not work as on a tty device.</td></tr>\n";
	print "</form>\n";
	print "</table><br>\n";
}
# end browse
###############################################################################
# start setp
sub setp {
	my $status = 0;
	chmod (oct("0$FORM{newp}"),"$webpath$FORM{p}/$FORM{f}") or $status = $!;
	if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	&browse;
}
# end setp
###############################################################################
# start seto
sub seto {
	my $status = "";
	my ($uid,$gid) = split (/\:/,$FORM{newo});
	if ($uid !~ /^\d/) {$uid = (getpwnam($uid))[2]}
	if ($gid !~ /^\d/) {$gid = (getgrnam($gid))[2]}
	if ($uid eq "") {$message .= "No such user<br>\n"}
	if ($gid eq "") {$message .= "No such group<br>\n"}

	if ($message eq "") {
		chown ($uid,$gid,"$webpath$FORM{p}/$FORM{f}") or $status = $!;
		if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	}
	&browse;
}
# end seto
###############################################################################
# start ren
sub ren {
	my $status = 0;
	rename ("$webpath$FORM{p}/$FORM{f}","$webpath$FORM{p}/$FORM{newf}") or $status = $!;
	if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	&browse;
}
# end ren
###############################################################################
# start moveit
sub moveit {
	if ("$webpath$FORM{m}" eq "$webpath$FORM{p}/$FORM{newf}") {
		$message = "Move Failed - Cannot overwrite original";
	}
	elsif ((-d "$webpath$FORM{m}") and ("$webpath$FORM{p}/$FORM{newf}" =~ /^$webpath$FORM{m}\//)) {
		$message = "Move Failed - Cannot move inside original";
	}
	else {
		my $status = 0;
		rename ("$webpath$FORM{m}","$webpath$FORM{p}/$FORM{newf}") or $status = $!;
		if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	}
	if ($message eq "") {$FORM{m} = ""}
	&browse;
}
# end moveit
###############################################################################
# start copyit
sub copyit {
	if ("$webpath$FORM{c}" eq "$webpath$FORM{p}/$FORM{newf}") {
		$message = "Copy Failed - Cannot overwrite original";
	}
	elsif ((-d "$webpath$FORM{c}") and ("$webpath$FORM{p}/$FORM{newf}" =~ /^$webpath$FORM{c}\//)) {
		$message = "Copy Failed - Cannot copy inside original";
	}
	else {
		if (-d "$webpath$FORM{c}") {
			$origpath = "$webpath$FORM{c}";
			$destpath = "$webpath$FORM{p}/$FORM{newf}";
			find(\&mycopy, $origpath);
		} else {
			copy ("$webpath$FORM{c}","$webpath$FORM{p}/$FORM{newf}") or $message = "Copy Failed - $!";
			if ($message eq "") {
				my $mode = sprintf "%04o", (stat("$webpath$FORM{c}"))[2] & 00777;
				chmod (oct($mode),"$webpath$FORM{p}/$FORM{newf}") or $message = "Permission Change Failed - $!";
			}
		}
	}
	if ($message eq "") {$FORM{c} = ""}
	&browse;
}
# end copyit
###############################################################################
# start mycopy
sub mycopy {
	my $file  = $File::Find::name;
	(my $dest = $file) =~ s/^\Q$origpath/$destpath/;
	my $status = "";
	if (-d $file) {
		my $err = (split(/\//,$dest))[-1];
		mkpath ($dest) or $status = "Copy Failed Making New Dir [$err] - $!<br>\n";
	} elsif (-f $file) {
		my $err = (split(/\//,$file))[-1];
		copy ($file,$dest) or $status = "Copy Failed [$err] - $!<br>\n";
	}
	if ($status eq "") {
		my $err = (split(/\//,$file))[-1];
		my $mode = sprintf "%04o", (stat("$file"))[2] & 00777;
		chmod (oct($mode),"$dest") or $message .= "Copy Failed Setting Perms [$err] - $!<br>\n";
	} else {
		$message .= $status;
	}
}
# end mycopy
###############################################################################
# start cnewd
sub cnewd {
	my $status = 0;
	if ($FORM{newf} ne "") {
		mkdir ("$webpath$FORM{p}/$FORM{newf}",0777) or $status = $!;
	}
	if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	&browse;
}
# end cnewd
###############################################################################
# start cnewf
sub cnewf {
	my $status = 0;
	if ($FORM{newf} ne "") {
		if (-f ">$webpath$FORM{p}/$FORM{newf}") {
			$status = "File exists";
		} else {
			open (OUT, ">$webpath$FORM{p}/$FORM{newf}") or $status = $!;
			close (OUT);
		}
	}
	if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	&browse;
}
# end cnewf
###############################################################################
# start del
sub del {
	my $status = 0;
	if (-d "$webpath$FORM{p}/$FORM{f}") {
		rmtree("$webpath$FORM{p}/$FORM{f}", 0, 0) or $status = $!;
	} else {
		unlink ("$webpath$FORM{p}/$FORM{f}") or $status = $!;
	}
	if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	&browse;
}
# end del
###############################################################################
# start view
sub view {
	if (-e "$webpath$FORM{p}/$FORM{f}" ) {
		if (-T "$webpath$FORM{p}/$FORM{f}") {
			print "content-type: text/plain\r\n";
		} else {
			print "content-type: application/octet-stream\r\n";
		}
		print "content-disposition: attachment; filename=$FORM{f}\r\n\r\n";

		open(IN,"<","$webpath$FORM{p}/$FORM{f}") or die $!;
		while (<IN>) {print}
		close(IN);
	}else{
		print "content-type: text/html\r\n\r\n";
		print "File [$webpath$FORM{p}/$FORM{f}] not found!";
	}
}
# end view
###############################################################################
# start console
sub console {
	my $thisdir = "$webpath$FORM{p}";
	$thisdir =~ s/\/+/\//g;

	print "<p><pre style='font-family:Courier New;font-size:12px;padding:4px'>\n";
	print "root [$thisdir]# $FORM{cmd}\n";
	chdir $thisdir;

	$| = 1;
	my ($childin, $childout);
	my $cmdpid = open3($childin, $childout, $childout, $FORM{cmd});
	while (my $line = <$childout>) {
		$line =~ s/\</\&lt\;/g;
		$line =~ s/\>/\&gt\;/g;
		print $line;
	}
	waitpid ($cmdpid, 0);
	print "root [$thisdir]# <blink>_</blink></pre></p>\n";
	print "<script>window.scrollTo(0,10000000);</script>";
}
# end console
###############################################################################
# start cd
sub cd {
	if (-d $FORM{directory}) {
		$FORM{p} = $FORM{directory};
	} else {
		$message = "No such directory [$FORM{directory}]";
	}

	&browse;
}
# end cd
###############################################################################
# start edit
sub edit {
	open (IN, "<$webpath$FORM{p}/$FORM{f}") or die $!;
	my @data = <IN>;
	close (IN);

	my $filedata;
	foreach my $line (@data) {
		$line =~ s/\</&lt;/g;
		$line =~ s/\>/&gt;/g;
		$filedata .= $line;
	}

	my $lf = 0;
	if ($filedata =~ /\r/) {$lf = 1}

	print "<script language='javascript'>\n";
	print "	function check(file) {return confirm('Click OK to '+file)}\n";
	print "</script>\n";
	print "<form action='$script' method='post'>\n";
	print "<table align='center' width='95%' border='0' cellspacing='0' cellpadding='4' bgcolor='#FFFFFF' style='border:1px solid #990000'>\n";
	print "<tr><td align='center'>";
	print "<input type='hidden' name='p' value='$FORM{p}'>\n";
	print "<input type='hidden' name='f' value='$FORM{f}'>\n";
	print "<input type='hidden' name='lf' value='$lf'>\n";
	print "<textarea cols='100' rows='25' name='newf' style='font-family:Courier New;font-size:12px'>$filedata</textarea>\n";
	print "</td></tr>\n";
	print "<tr><td align='center'>";
	print "<input type='submit' class='input' name='do' value='Save'> \n";
	print "<input type='submit' class='input' name='do' value='Cancel'>\n";
	print "</td>";
	print "</table>\n";
	print "</form>\n";
}
# end edit
###############################################################################
# start save
sub save {
	unless ($FORM{lf}) {$FORM{newf} =~ s/\r//g}
	my $status = 0;
	open (OUT, ">$webpath$FORM{p}/$FORM{f}") or $status = $!;
	print OUT $FORM{newf};
	close (OUT);

	if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	&browse;
}
# end save
###############################################################################
# start uploadfile
sub uploadfile {
	my $crlf = "\r\n";
	my @data = split (/$crlf/,$fileinc);

	my $boundary = $data[0];

	$boundary =~ s/\"//g;
	$boundary =~ s/$crlf//g;

	my $start = 0;
	my $part_cnt=-1;
	undef @parts;
	my $fileno = 0;

	foreach my $line (@data) {
		if ($line =~ /^$boundary--/) {
			last;
		}
		if ($line =~ /^$boundary/) {
			$part_cnt++;
			$start = 1;
			next;
		}
		if ($start) { 
			$parts[$part_cnt] .= $line.$crlf;
		}
	}

	foreach my $part (@parts) {
		my @partdata = split(/$crlf/,$part);
		undef %header;
		my $body = "";
		my $dobody = 0;
		my $lastfieldname = "";

		foreach my $line (@partdata) {
			if (($line eq "") and !($dobody)) {
				$dobody = 1;
				next;
			}

			if ($dobody) {
				$body .= $line.$crlf;
			} else {
				if ($line =~ /^\s/) {
					$header{$lastfieldname} .= $line;
				} else {
					($fieldname, $value) = split (/\:\s/,$line,2);
					$fieldname = lc $fieldname;
					$fieldname =~ s/-/_/g;
					$header{$fieldname} = $value;
					$lastfieldname = $fieldname;
				}
			}
		}

		my @elements = split(/\;/,$header{content_disposition});
		foreach $element (@elements) {
			$element =~ s/\s//g;
			$element =~ s/\"//g;
			($name,$value) = split(/\=/,$element);
			$FORM{$value} = $body;
			$ele{$name} = $value;
			$ele{$ele{name}} = $value;
			if ($value =~ /^file/) {
				$files = $';
			}
		}
		
		my $filename = $ele{"file$files"};
		if ($filename ne "") {
			$fileno++;
			$filename =~ s/\"//g;
			$filename =~ s/\r//g;
			$filename =~ s/\n//g;
			@bits = split(/\\/,$filename);
			$filetemp=$bits[@bits-1];
			@bits = split(/\//,$filetemp);
			$filetemp=$bits[@bits-1];
			@bits = split(/\:/,$filetemp);
			$filetemp=$bits[@bits-1];
			@bits = split(/\"/,$filetemp);
			$filename=$bits[0];
			push (@filenames, $filename);
			push (@filebodies, $body);
		}
	}

	$FORM{p} =~ s/\r//g;
	$FORM{p} =~ s/\n//g;
	$FORM{type} =~ s/\r//g;
	$FORM{type} =~ s/\n//g;
	$FORM{c} =~ s/\r//g;
	$FORM{c} =~ s/\n//g;
	$FORM{m} =~ s/\r//g;
	$FORM{m} =~ s/\n//g;
	$FORM{caller} =~ s/\r//g;
	$FORM{caller} =~ s/\n//g;

	for (my $x = 0;$x < @filenames ;$x++) {
		$filenames[$x] =~ s/\r//g;
		$filenames[$x] =~ s/\n//g;
		$filenames[$x] =~ s/^file-//g;
		$filenames[$x] = (split (/\\/,$filenames[$x]))[-1];
		$filenames[$x] = (split (/\//,$filenames[$x]))[-1];
		if ($FORM{type} eq "ascii") {$filebodies[$x] =~ s/\r//g}
		if (-e "$webpath$FORM{p}/$filenames[$x]") {
			$extramessage .= "<br>$filenames[$x] - Already exists, delete the original first";
			$fileno--;
			next;
		}
		sysopen (OUT,"$webpath$FORM{p}/$filenames[$x]", O_WRONLY | O_CREAT);
		print OUT $filebodies[$x];
		close (OUT);
		$extramessage .= "<br>$filenames[$x] - Uploaded";
	}

	$message = "$fileno File(s) Uploaded".$extramessage;

	&browse;
}
# end uploadfile
###############################################################################
# start countfiles
sub countfiles {
	if (-d $File::Find::name) {push (@dirs, $File::Find::name)} else {push (@files, $File::Find::name)}
}
# end countfiles
###############################################################################
# loadconfig
sub loadconfig {
	sysopen (IN, "/etc/csf/csf.conf", O_RDWR | O_CREAT) or die "Unable to open file: $!";
	flock (IN, LOCK_SH);
	my @config = <IN>;
	close (IN);
	chomp @config;

	foreach my $line (@config) {
		if ($line =~ /^\#/) {next}
		if ($line !~ /=/) {next}
		my ($name,$value) = split (/=/,$line,2);
		$name =~ s/\s//g;
		if ($value =~ /\"(.*)\"/) {
			$value = $1;
		} else {
			&error(__LINE__,"Invalid configuration line");
		}
		$config{$name} = $value;
	}
}
# end loadconfig
###############################################################################

1;
