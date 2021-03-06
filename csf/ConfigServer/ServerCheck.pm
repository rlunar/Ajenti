###############################################################################
# Copyright 2006-2016, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
# start main
package ConfigServer::ServerCheck;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);
use IPC::Open3;
use ConfigServer::Slurp;
use ConfigServer::Sanity;
use ConfigServer::Config;
use ConfigServer::GetIPs;
use ConfigServer::CheckIP;
use ConfigServer::Service;

my (%config, $cpconf, %daconfig, $cleanreg, $mypid, $childin, $childout,
    $verbose, $cpurl, @processes, $total, $failures, $current, $DEBIAN,
	$output, $sysinit);

my $ipv4reg = ConfigServer::Config->ipv4reg;
my $ipv6reg = ConfigServer::Config->ipv6reg;

BEGIN {
	require Exporter;
	our $VERSION     = 1.05;
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw();
	our @EXPORT_OK   = qw();
}
# end main
###############################################################################
# start report
sub report {
	$verbose = shift;
	my $config = ConfigServer::Config->loadconfig();
	%config = $config->config();
	$cleanreg = ConfigServer::Slurp->cleanreg;

	if (defined $ENV{WEBMIN_VAR} and defined $ENV{WEBMIN_CONFIG}) {
		$config{GENERIC} = 1;
		$config{DIRECTADMIN} = 0;
	}
	elsif (-e "/usr/local/cpanel/version") {
		eval ('
			use lib "/usr/local/cpanel";
			use Cpanel::cPanelFunctions ();
			use Cpanel::Form			();
			use Cpanel::Config          ();
			');
		$cpconf = Cpanel::Config::loadcpconf();
	}
	elsif (-e "/usr/local/directadmin/conf/directadmin.conf") {
		open (IN, "<", "/usr/local/directadmin/conf/directadmin.conf");
		my @data = <IN>;
		close (IN);
		chomp @data;
		foreach my $line (@data) {
			my ($name,$value) = split(/\=/,$line);
			$daconfig{$name} = $value;
		}
		$config{DIRECTADMIN} = 1;
	}
	elsif (-e "/etc/psa/psa.conf") {
		$config{PLESK} = 1;
	}

	$failures = 0;
	$total = 0;
	my $linestyle = '#F4F4EA';
	if ($ENV{cp_security_token}) {$cpurl = $ENV{cp_security_token}}
	$DEBIAN = 0;
	if (-e "/etc/lsb-release" or -e "/etc/debian_version") {$DEBIAN = 1}

	$sysinit = ConfigServer::Service::type();
	if ($sysinit ne "systemd") {$sysinit = "init"}

	opendir (PROCDIR, "/proc");
	while (my $pid = readdir(PROCDIR)) {
		if ($pid !~ /^\d+$/) {next}
		push @processes, readlink("/proc/$pid/exe");
	}

	&startoutput;

	&firewallcheck;
	&servercheck;
	&sshtelnetcheck;
	unless ($config{DNSONLY} or $config{GENERIC}) {&mailcheck}
	unless ($config{DNSONLY} or $config{GENERIC}) {&apachecheck}
	unless ($config{DNSONLY} or $config{GENERIC}) {&phpcheck}
	unless ($config{DNSONLY} or $config{GENERIC}) {&whmcheck}
	if ($config{DIRECTADMIN}) {
		&mailcheck;
		&apachecheck;
		&phpcheck;
		&dacheck;
	}
	&servicescheck;

	&endoutput;
	return $output;
}
# end report
###############################################################################
# start startoutput
sub startoutput {
	$output .= <<EOF;
<style type="text/css">
.section-full {
	background:#BDECB6;
	padding:4px;
	border: 1px solid #DDDDDD;
	border-radius:5px;
}
.section-ok {
	background:#BDECB6;
	padding:4px;
	border-top: 1px solid #DDDDDD; 
	border-left: 1px solid #DDDDDD;
	border-bottom: 1px solid #DDDDDD;
	border-top-left-radius:5px;
	border-bottom-left-radius:5px;
}
.section-warning {
	background:#FFD1DC;
	padding:4px;
	border-top: 1px solid #DDDDDD;
	border-left: 1px solid #DDDDDD;
	border-bottom: 1px solid #DDDDDD;
	border-top-left-radius:5px;
	border-bottom-left-radius:5px;
}
.section-title {
	padding: 4px;
	border: 1px solid #DDDDDD;
	border-radius:5px;
	font-size:16px;
	font-weight:bold;
}
.section-comment {
	padding:4px;
	border-top: 1px solid #DDDDDD;
	border-right: 1px solid #DDDDDD;
	border-bottom: 1px solid #DDDDDD;
	border-top-right-radius:5px;
	border-bottom-right-radius:5px;
}
.section-gap {
	line-height: 4px;
}
</style>
EOF
	if ($config{THIS_UI} and !$config{GENERIC}) {
		$output .= "<p align='center'><strong>Note: Internal WHM links will not work within the csf Integrated UI</strong></p>\n";
	}
	$output .= "<table align='center' width='95%' cellspacing='0'>\n";

}
# end startoutput
###############################################################################
# start addline
sub addline {
	my $status = shift;
	my $check = shift;
	my $comment = shift;
	$total++;

	if ($status) {
		$output .= "<tr>\n";
		$output .= "<td class='section-warning'>$check</td>\n";
		$output .= "<td class='section-comment'>$comment</td>\n";
		$output .= "</tr>\n";
		$output .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
		$failures ++;
		$current++;
	}
	elsif ($verbose) {
		$output .= "<tr>\n";
		$output .= "<td class='section-ok'>$check</td>\n";
		$output .= "<td class='section-comment'>$comment</td>\n";
		$output .= "</tr>\n";
		$output .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
		$current++;
	}
}
# end addline
###############################################################################
# start addtitle
sub addtitle {
	my $title = shift;
	if (defined $current and $current == 0) {
		$output .= "<tr><td colspan='2' class='section-full'>OK</td></tr>\n";
		$output .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
	}
	$current = 0;
	$output .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
	$output .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
	$output .= "<tr><td class='section-title' colspan='2'>$title</td></tr>\n";
	$output .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
}
# end addtitle
###############################################################################
# start endoutput
sub endoutput {
	if (defined $current and $current == 0) {
		$output .= "<tr><td colspan='2' class='section-full'>OK</td></tr>\n";
		$output .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
	}
	$output .= "</table><br>\n";

	my $gap = int(($total-3)/4);
	my $score = ($total - $failures);
	my $width = int ((400 / $total) * $score) - 4;
	$output .= "<br>\n<table align='center' cellpadding='4' bgcolor='FFFFFF' style='border:1px solid #990000; border-radius:5px;'>\n<tr><td bgcolor='#FFFFFF'>\n";
	$output .= "<p align='center'>Your Score: <big><b>$score/$total</b>*</big></p>\n";
	$output .= <<EOF;
<p align='center'>
<table width='500' cellpadding='0' cellspacing='0'>
<tr>
<td width='300' bgcolor='#FFD1DC' style='border-top: 1px solid #DDDDDD; border-left: 1px solid #DDDDDD; border-bottom: 1px solid #DDDDDD;padding-top:4px; padding-bottom:4px; border-top-left-radius:4px;border-bottom-left-radius:4px'>&nbsp;</td>
<td width='60' bgcolor='#FFFDD8' style='border-top: 1px solid #DDDDDD; border-bottom: 1px solid #DDDDDD;padding-top:4px; padding-bottom:4px'>&nbsp;</td>
<td width='20' bgcolor='#BDECB6' style='border-top: 1px solid #DDDDDD; border-right: 1px solid #DDDDDD; border-bottom: 1px solid #DDDDDD;padding-top:4px; padding-bottom:4px; border-top-right-radius:4px;border-bottom-right-radius:4px'>&nbsp;</td>
<td width='100' style='padding-top:4px; padding-bottom:4px' nowrap>&nbsp;$total (max)&nbsp;</td>
</tr>
</table>
<table width='500' cellpadding='0' cellspacing='0'>
<tr>
<td width='$width' style='padding-top:4px; padding-bottom:4px'>&nbsp;</td>
<td width='1' bgcolor='#990000' style='padding-top:4px; padding-bottom:4px'>&nbsp;</td>
<td nowrap style='padding-top:4px; padding-bottom:4px'>$score (score)</td>
</tr>
</table>
EOF
	$output .= "<p>*This scoring does not necessarily reflect the security of your server or the relative merits of each check";
	$output .= "</td></tr></table>";
}
# end endoutput
###############################################################################
# start firewallcheck
sub firewallcheck {
	&addtitle("Firewall Check");
	my $status = 0;
	open (IN, "</etc/csf/csf.conf");
	my @config = <IN>;
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

	$status = 0;
	if (-e "/etc/csf/csf.disable") {$status = 1}
	&addline($status,"csf enabled check","csf is currently disabled and should be enabled otherwise it is not functioning");
	
	if (-x $config{IPTABLES}) {
		my ($childin, $childout);
		my $mypid = open3($childin, $childout, $childout, $config{IPTABLES},"-L","INPUT","-n");
		my @iptstatus = <$childout>;
		waitpid ($mypid, 0);
		chomp @iptstatus;
		$status = 0;
		if ($iptstatus[0] =~ /policy ACCEPT/) {$status = 1}
		&addline($status,"csf running check","iptables is not configured. You need to start csf");
	}

	$status = 0;
	if ($config{TESTING}) {$status = 1}
	&addline($status,"TESTING mode check","csf is in TESTING mode. If the firewall is working set TESTING to \"0\" in the Firewall Configuration otherwise it will continue to be stopped");

	$status = 0;
	unless ($config{RESTRICT_SYSLOG}) {$status = 1}
	&addline($status,"RESTRICT_SYSLOG option check","Due to issues with syslog/rsyslog you should consider enabling this option. See the Firewall Configuration (/etc/csf/csf.conf) for more information");

	$status = 0;
	unless ($config{AUTO_UPDATES}) {$status = 1}
	&addline($status,"AUTO_UPDATES option check","To keep csf up to date and secure you should enable AUTO_UPDATES. You should also monitor our <a href='http://blog.configserver.com' target='_blank'>blog</a>");

	$status = 0;
	unless ($config{LF_DAEMON}) {$status = 1}
	&addline($status,"lfd enabled check","lfd is disabled in the csf configuration which limits the affectiveness of this application");

	$status = 0;
	if ($config{TCP_IN} =~ /\b3306\b/) {$status = 1}
	&addline($status,"Incoming MySQL port check","The TCP incoming MySQL port (3306) is open. This can pose both a security and server abuse threat since not only can hackers attempt to break into MySQL, any user can host their SQL database on your server and access it from another host and so (ab)use your server resources");

	unless ($config{DNSONLY} or $config{GENERIC}) {
		unless ($config{VPS}) {
			$status = 0;
			unless ($config{SMTP_BLOCK}) {$status = 1}
			&addline($status,"SMTP_BLOCK option check","This option will help prevent the most common form of spam abuse on a server that bypasses exim and sends spam directly out through port 25. Enabling this option will prevent any web script from sending out using socket connection, such scripts should use the exim or sendmail binary instead");
		}

		$status = 0;
		unless ($config{LF_SCRIPT_ALERT}) {$status = 1}
		&addline($status,"LF_SCRIPT_ALERT option check","This option will notify you when a large amount of email is sent from a particular script on the server, helping track down spam scripts");
	}

	$status = 0;
	my @options = ("LF_SSHD","LF_FTPD","LF_SMTPAUTH","LF_POP3D","LF_IMAPD","LF_HTACCESS","LF_MODSEC","LF_CPANEL","LF_CPANEL_ALERT","SYSLOG_CHECK","RESTRICT_UI");
	if ($config{GENERIC}) {@options = ("LF_SSHD","LF_FTPD","LF_SMTPAUTH","LF_POP3D","LF_IMAPD","LF_HTACCESS","LF_MODSEC","SYSLOG_CHECK","FASTSTART","RESTRICT_UI");}
	if ($config{DNSONLY}) {@options = ("LF_SSHD","LF_CPANEL","SYSLOG_CHECK","FASTSTART","RESTRICT_UI")}

	foreach my $option (@options) {
		$status = 0;
		unless ($config{$option}) {$status = 1}
		&addline($status,"$option option check","This option helps prevent brute force attacks on your server services");
	}

	$status = 0;
	unless ($config{LF_DIRWATCH}) {$status = 1}
	&addline($status,"LF_DIRWATCH option check","This option will notify when a suspicious file is found in one of the common temp directories on the server");

	$status = 0;
	unless ($config{LF_INTEGRITY}) {$status = 1}
	&addline($status,"LF_INTEGRITY option check","This option will notify when an executable in one of the common directories on the server changes in some way. This helps alert you to potential rootkit installation or server compromise");

	$status = 0;
	unless ($config{FASTSTART}) {$status = 1}
	&addline($status,"FASTSTART option check","This option can dramatically improve the startup time of csf and the rule loading speed of lfd");

	$status = 0;
	if ($config{URLGET} == 1) {$status = 1}
	&addline($status,"URLGET option check","This option determines which perl module is used to upgrade csf. It is recommended to set this to use LWP rather than HTTP::Tiny so that upgrades are performed over an SSL connection");

	$status = 0;
	if ($config{PT_USERKILL} == 1) {$status = 1}
	&addline($status,"PT_USERKILL option check","This option should not normally be enabled as it can easily lead to legitimate processes being terminated, use csf.pignore instead");

	unless ($config{DNSONLY} or $config{GENERIC}) {
		$status = 0;
		if ($config{PT_SKIP_HTTP}) {$status = 1}
		&addline($status,"PT_SKIP_HTTP option check","This option disables checking of processes running under apache and can limit false-positives but may then miss running exploits");
	}

	$status = 0;
	if (!$config{LF_IPSET} and !$config{VPS} and ($config{CC_DENY} or $config{CC_ALLOW} or $config{CC_ALLOW_FILTER} or $config{CC_ALLOW_PORTS} or $config{CC_DENY_PORTS})) {$status = 1}
	&addline($status,"LF_IPSET option check","If support by your OS, you should install ipset and enable LF_IPSET when using Country Code (CC_*) filters");

	unless ($config{DNSONLY} or $config{GENERIC}) {
		$status = 0;
		unless ($config{PT_ALL_USERS}) {$status = 1}
		&addline($status,"PT_ALL_USERS option check","This option ensures that almost all Linux accounts are checked with Process Tracking, not just the cPanel ones");
	}

	sysopen (IN, "/etc/csf/csf.conf", O_RDWR | O_CREAT);
	flock (IN, LOCK_SH);
	my @confdata = <IN>;
	close (IN);
	chomp @confdata;

	foreach my $line (@confdata) {
		if (($line !~ /^\#/) and ($line =~ /=/)) {
			my ($start,$end) = split (/=/,$line,2);
			my $name = $start;
			$name =~ s/\s/\_/g;
			if ($end =~ /\"(.*)\"/) {$end = $1}
			my ($insane,$range,$default) = sanity($start,$end);
			if ($insane) {
				&addline(1,"$start sanity check","$start = $end. Recommended range: $range (Default: $default)");
			}
		}
	}
}
# end firewallcheck
###############################################################################
# start servercheck
sub servercheck {
	&addtitle("Server Check");
	my $status = 0;

	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("/tmp");
	my $pmode = sprintf "%03o", $mode & 07777;

	$status = 0;
	if ($pmode != 1777) {$status = 1}
	&addline($status,"Check /tmp permissions","/tmp should be chmod 1777");

	$status = 0;
	if (($uid != 0) or ($gid != 0)) {$status = 1}
	&addline($status,"Check /tmp ownership","/tmp should be owned by root:root");

	if (-d "/var/tmp") {
		($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("/var/tmp");
		$pmode = sprintf "%04o", $mode & 07777;

		$status = 0;
		if ($pmode != 1777) {$status = 1}
		&addline($status,"Check /var/tmp permissions","/var/tmp should be chmod 1777");

		$status = 0;
		if (($uid != 0) or ($gid != 0)) {$status = 1}
		&addline($status,"Check /var/tmp ownership","/var/tmp should be owned by root:root");
	}

	if (-d "/usr/tmp") {
		($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("/usr/tmp");
		$pmode = sprintf "%04o", $mode & 07777;

		$status = 0;
		if ($pmode != 1777) {$status = 1}
		&addline($status,"Check /usr/tmp permissions","/usr/tmp should be chmod 1777");

		$status = 0;
		if (($uid != 0) or ($gid != 0)) {$status = 1}
		&addline($status,"Check /usr/tmp ownership","/usr/tmp should be owned by root:root");
	}

	$status = 0;
	if (&getportinfo(53)) {
		my @files = ("/var/named/chroot/etc/named.conf","/etc/named.conf","/etc/bind/named.conf","/var/named/chroot/etc/bind/named.conf");
		my @namedconf;
		my @morefiles;
		my $hit;
		foreach my $file (@files) {
			if (-e $file) {
				$hit = 1;
				open (IN, "<$file");
				my @conf = <IN>;
				close (IN);
				chomp @conf;
				if (my @ls = grep {$_ =~ /^\s*include\s+(.*)\;\s*$/i} @conf) {
					foreach my $more (@ls) {
						if ($more =~ /^\s*include\s+\"(.*)\"\s*\;\s*$/i) {push @morefiles, $1}
					}
				}
				@namedconf = (@namedconf, @conf);
			}
		}
		foreach my $file (@morefiles) {
			if (-e $file) {
				open (IN, "<$file");
				my @conf = <IN>;
				close (IN);
				chomp @conf;
				@namedconf = (@namedconf, @conf);
			}
		}

		if ($hit) {
			if (my @ls = grep {$_ =~ /^\s*(recursion\s+no|allow-recursion)/} @namedconf) {$status = 0} else {$status = 1}
			&addline($status,"Check for DNS recursion restrictions","You have a local DNS server running but do not appear to have any recursion restrictions set. This is a security and performance risk and you should look at restricting recursive lookups to the local IP addresses only");

			if (my @ls = grep {$_ =~ /^\s*(query-source\s[^\;]*53)/} @namedconf) {$status = 1} else {$status = 0}
			&addline($status,"Check for DNS random query source port","ISC recommend that you do not configure BIND to use a static query port. You should remove/disable the query-source line that specifies port 53 from the named configuration files");
		}
	}

	if (!$DEBIAN and $sysinit eq "init" and -x "/sbin/runlevel") {
		$status = 0;
		$mypid = open3($childin, $childout, $childout, "/sbin/runlevel");
		my @conf = <$childout>;
		waitpid ($mypid, 0);
		chomp @conf;
		my (undef,$runlevel) = split(/\s/,$conf[0]);
		if ($runlevel != 3) {$status = 1}
		&addline($status,"Check server runlevel","The servers runlevel is currently set to $runlevel. For a secure server environment you should only run the server at runlevel 3. You can fix this by editing /etc/inittab and changing the initdefault line to:<br><b>id:3:initdefault:</b><br>and then rebooting the server");
	}

	$status = 0;
	if ((-e "/var/spool/cron/nobody") and !(-z "/var/spool/cron/nobody")) {$status = 1}
	&addline($status,"Check nobody cron","You have a nobody cron log file - you should check that this has not been created by an exploit");

	$status = 0;
	my ($isfedora, $isrh, $version, $conf) = 0;
	if (-e "/etc/fedora-release") {
		open (IN, "</etc/fedora-release");
		$conf = <IN>;
		close (IN);
		$isfedora = 1;
		if ($conf =~ /release (\d+)/i) {$version = $1}
	} elsif (-e "/etc/redhat-release") {
		open (IN, "</etc/redhat-release");
		$conf = <IN>;
		close (IN);
		$isrh = 1;
		if ($conf =~ /release (\d+)/i) {$version = $1}
	}
	chomp $conf;

	if ($isrh or $isfedora) {
		if (($isfedora and $version < 19) or ($isrh and $version =~ /^2/) or ($isrh and $version =~ /^3/) or ($isrh and $version =~ /^4/)) {$status = 1}
		&addline($status,"Check Operating System support","You are running an OS - <i>$conf</i> - that is no longer supported by the OS vendor, or is about to become obsolete. This means that you will be receiving no OS updates (i.e. application or security bug fixes) or kernel updates and should consider moving to an OS that is supported as soon as possible");
	}

	$status = 0;
	if ($] < 5.008008) {
		$status = 1;
	} else {$status = 0}
	&addline($status,"Check perl version","The version of perl (v$]) is out of date and you should upgrade it");

	unless ($config{DNSONLY}) {
		if (-e "/usr/bin/mysql") {
#			$status = 1;
#			$mypid = open3($childin, $childout, $childout, "/usr/bin/mysql","-V");
#			my @version = <$childout>;
#			waitpid ($mypid, 0);
#			chomp @version;
#			$version[0] =~ /Distrib (\d+)\.(\d+)\.(\d+)/;
#			my $mas = $1;
#			my $maj = $2;
#			my $min = $3;
#			if ($mas >= 5 and $maj >= 1) {$status = 0}
#			&addline($status,"Check MySQL version","You are running a legacy version of MySQL (v$mas.$maj.$min) and should consider upgrading to v5.5+ as recommended by MySQL");

			if ($DEBIAN and -e "/etc/mysql/my.cnf") {
				$status = 1;
				open (IN, "</etc/mysql/my.cnf");
				my @conf = <IN>;
				close (IN);
				chomp @conf;
				if (my @ls = grep {$_ =~ /^\s*local-infile\s*=\s*0/i} @conf) {$status = 0}
				&addline($status,"Check MySQL LOAD DATA disallows LOCAL","You should disable LOAD DATA LOCAL commands in MySQL by adding the following to the [mysqld] section of /etc/mysql/my.cnf and restarting MySQL:<br><b>local-infile=0</b><br>See <a target='_blank' href='http://dev.mysql.com/doc/mysql-security-excerpt/5.0/en/load-data-local.html'>this link</a>");
			}
			elsif (-e "/etc/my.cnf") {
				$status = 1;
				open (IN, "</etc/my.cnf");
				my @conf = <IN>;
				close (IN);
				chomp @conf;
				if (my @ls = grep {$_ =~ /^\s*local-infile\s*=\s*0/i} @conf) {$status = 0}
				&addline($status,"Check MySQL LOAD DATA disallows LOCAL","You should disable LOAD DATA LOCAL commands in MySQL by adding the following to the [mysqld] section of /etc/my.cnf and restarting MySQL:<br><b>local-infile=0</b><br>See <a target='_blank' href='http://dev.mysql.com/doc/mysql-security-excerpt/5.0/en/load-data-local.html'>this link</a>");
			}
		}
	}

	$status = 0;
	while (my ($name,undef,$uid) = getpwent()) {
		if (($uid == 0) and ($name ne "root")) {$status = 1}
	}
	&addline($status,"Check SUPERUSER accounts","You have accounts other than root set up with UID 0. This is a considerable security risk. You should use <b>su</b>, or best of all <b>sudo</b> for such access");

	unless ($config{DNSONLY} or $config{GENERIC}) {
		$status = 0;
		unless (-e "/etc/cxs/cxs.data") {
			$status = 1;
		}
		&addline($status,"Check for cxs","You should consider using <b><u><a href='http://www.configserver.com/cp/cxs.html' target='_blank'>cxs</a></u></b> to scan web script and ftp uploads and user accounts for exploits uploaded to the server");
	}

	if (-e $config{IFCONFIG}) {
		my $cmdpid = open3($childin, $childout, $childout, $config{IFCONFIG});
		my @ifconfig = <$childout>;
		waitpid ($cmdpid, 0);
		chomp @ifconfig;

		$status = 0;
		my $ipv6 = "";
		unless ($config{IPV6}) {
			foreach my $line (@ifconfig) {
				if ($line =~ /inet6.*?($ipv6reg)/) {
					if ($ipv6) {$ipv6 .= ", "}
					$ipv6 .= $1;
					$status = 1;
					if ($ipv6 eq "::1") {$ipv6 = ""; $status = 0}
				}
			}
		}
		&addline($status,"Check for IPv6","IPv6 appears to be enabled [ifconfig: <b>$ipv6</b>]. If ip6tables is installed, you should enable the csf IPv6 firewall (IPV6 in csf.conf)");
	}

	if ($sysinit eq "init") {
		$status = 1;
		my $syslog = 0;
		if (grep {$_ =~ /\/syslogd\s*/} @processes) {
			$syslog = 1;
			if (grep {$_ =~ /\/klogd$/} @processes) {$status = 0}
			&addline($status,"Check for kernel logger","syslogd appears to be running, but not klogd which logs kernel firewall messages to syslog. You should ensure that klogd is running");
		}
		if (grep {$_ =~ /\/rsyslogd\s*/} @processes) {
			$syslog = 1;
			if (grep {$_ =~ /\/rklogd\s*/} @processes) {
				$status = 0;
			} else {
				open (IN, "</etc/rsyslog.conf");
				my @conf = <IN>;
				close (IN);
				chomp @conf;
				if (grep {$_ =~ /^\$ModLoad imklog/} @conf) {$status = 0}
			}
			&addline($status,"Check for kernel logger","rsyslogd appears to be running, but klog may not be loaded which logs kernel firewall messages to rsyslog. You should modify /etc/rsyslogd to load the klog module with:<br><b>\$ModLoad imklog</b><br>Then restart rsyslog");
		}
		unless ($syslog) {
			$status = 1;
			&addline($status,"Check for syslog or rsyslog","Neither syslog nor rsyslog appear to be running");
		}
	}

	$status = 0;
	if (grep {$_ =~ /\/dhclient\s*/} @processes) {$status = 1}
	&addline($status,"Check for dhclient","dhclient appears to be running which suggests that the server is obtaining an IP address via DHCP. This can pose a security risk. You should configure static IP addresses for all ethernet controllers");

	unless ($config{VPS}) {
		$status = 1;
		open (IN, "<", "/proc/swaps");
		my @swaps = <IN>;
		close (IN);
		if (scalar(@swaps) > 1) {$status = 0}
		&addline($status,"Check for swap file","The server appears to have no swap file. This is usually considered a stability and performance risk. You should either add a swap partition, or <a href='http://www.cyberciti.biz/faq/linux-add-a-swap-file-howto/' target='_blank'>create one via a normal file on an existing partition</a>");

		if (-e "/etc/redhat-release") {
			open (IN, "</etc/redhat-release");
			$conf = <IN>;
			close (IN);
			chomp $conf;

			$status = 0;
			if ($conf =~ /^((CentOS)|(Red Hat Enterprise))/i) {$status = 1}
			&addline($status,"Check for CloudLinux","You should consider upgrading to <a target='_blank' href='http://cloudlinux.com'>CloudLinux</a> which provides advanced security features, especially for web servers");

			if ($conf =~ /^CloudLinux/i) {
				$status = 0;
				if (-e "/usr/sbin/cagefsctl") {
				} else {$status = 1}
				&addline($status,"CloudLinux CageFS","CloudLinux <a target='_blank' href='http://docs.cloudlinux.com/index.html?cagefs.html'>CageFS</a> is not installed. This CloudLinux option greatly improves server security on we servers by separating user accounts into their own environment");

				unless ($status) {
					$status = 0;
					$mypid = open3($childin, $childout, $childout, "/usr/sbin/cagefsctl","--cagefs-status");
					my @conf = <$childout>;
					waitpid ($mypid, 0);
					chomp @conf;
					if ($conf[0] !~ /^Enabled/) {$status = 1}
					&addline($status,"CloudLinux CageFS Enabled","CloudLinux <a target='_blank' href='http://docs.cloudlinux.com/index.html?cagefs.html'>CageFS</a> is not enabled. This CloudLinux option greatly improves server security on we servers by separating user accounts into their own environment");
				}

				$status = 0;
				open (IN, "</proc/sys/fs/enforce_symlinksifowner");
				$conf = <IN>;
				close (IN);
				chomp $conf;
				if ($conf < 1) {$status = 1}
				&addline($status,"CloudLinux Symlink Protection","CloudLinux <a target='_blank' href='http://docs.cloudlinux.com/index.html?securelinks.html'>Symlink Protection</a> is not configured. You should configure it in /etc/sysctl.conf to prevent symlink attacks on web servers");

				$status = 0;
				open (IN, "</proc/sys/fs/proc_can_see_other_uid");
				$conf = <IN>;
				close (IN);
				chomp $conf;
				if ($conf > 0) {$status = 1}
				&addline($status,"CloudLinux Virtualised /proc","CloudLinux <a target='_blank' href='http://docs.cloudlinux.com/index.html?virtualized__proc_filesystem.html'>Virtualised /proc</a> is not configured. You should configure it in /etc/sysctl.conf to prevent users accessing server resources that they do not need on web servers");

				$status = 0;
				open (IN, "</proc/sys/kernel/user_ptrace");
				$conf = <IN>;
				close (IN);
				chomp $conf;
				if ($conf > 0) {$status = 1}
				&addline($status,"CloudLinux Disable ptrace","CloudLinux <a target='_blank' href='http://docs.cloudlinux.com/index.html?ptrace_block.html'>Disable ptrace</a> is not configured. You should configure it in /etc/sysctl.conf to prevent users accessing server resources that they do not need on web servers");
			}
		}
	}
}
# end servercheck
###############################################################################
# start whmcheck
sub whmcheck {
	my $status = 0;
	&addtitle("WHM Settings Check");

	$status = 0;
	unless ($cpconf->{alwaysredirecttossl}) {$status = 1}
	&addline($status,"Check cPanel login is SSL only","You should check <i>WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Always redirect users to the ssl/tls ports when visiting /cpanel, /webmail, etc.</i>");

	$status = 0;
	unless ($cpconf->{skipboxtrapper}) {$status = 1}
	&addline($status,"Check boxtrapper is disabled","Having boxtrapper enabled can very easily lead to your server being listed in common RBLs and usually has the effect of increasing the overall spam load, not reducing it. You should disable it in <i>WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > BoxTrapper Spam Trap</i>");

	$status = 0;
	if (-e "/var/cpanel/greylist/enabled") {$status = 1}
	&addline($status,"Check GreyListing is disabled","Using GreyListing can and will lead to lost legitimate emails. It can also cause significant problems with \"password verification\" systems. See <a href='https://en.wikipedia.org/wiki/Greylisting#Disadvantages' target='_blank'>here</a> for more information");

	if (defined $cpconf->{popbeforesmtp}) {
		$status = 0;
		if ($cpconf->{popbeforesmtp}) {$status = 1}
		&addline($status,"Check popbeforesmtp is disabled","Using pop before smtp is considered a security risk, SMTP AUTH should be used instead. You should disable it in <i>WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Pop-before-SMTP</i>");
	} else {
		$status = 0;
		unless ($cpconf->{skipantirelayd}) {$status = 1}
		&addline($status,"Check antirelayd is disabled","Using pop before smtp is considered a security risk, SMTP AUTH should be used instead. You should disable it in <i>WHM > <a href='$cpurl/scripts/srvmng' target='_blank'>Service Manager</a> > Antirelayd</i>");
	}

	$status = 0;
	unless ($cpconf->{maxemailsperhour}) {$status = 1}
	&addline($status,"Check max emails per hour is set","To limit the damage that can be caused by potential spammers on the server you should set a value for <i>WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > The maximum each domain can send out per hour</i>");

	$status = 0;
	if ($cpconf->{resetpass}) {$status = 1}
	&addline($status,"Check whether users can reset passwords via email","This option has been vulnerable in the past, so you should uncheck <i>WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow cPanel users to reset their password via email</i>");

	unless ($cpconf->{nativessl} eq undef) {
		$status = 0;
		unless ($cpconf->{nativessl}) {$status = 1}
		&addline($status,"Check whether native cPanel SSL is enabled","You should enable this option so that lfd tracks SSL cpanel login attempts <i>WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Use native SSL support if possible, negating need for Stunnel</i>");
	}

	$status = 0;
    my $cc = '/usr/bin/cc';
    while ( readlink($cc) ) {
        $cc = readlink($cc);
    }
    if ( $cc !~ /^\// ) { $cc = '/usr/bin/' . $cc; }
    my $mode = substr( sprintf( "%o", ( ( stat($cc) )[2] ) ), 2, 4 );
    if ( $mode > 750 ) {$status = 1}
	&addline($status,"Check compilers","You should disable compilers <i>WHM > Security Center > <a href='$cpurl/scripts2/tweakcompilers' target='_blank'>Compilers Tweak</a></i>");

	if (-e "/etc/pure-ftpd.conf" and ($cpconf->{ftpserver} eq "pure-ftpd") and !(-e "/etc/ftpddisable")) {
		$status = 0;
		open (IN, "</etc/pure-ftpd.conf");
		my @conf = <IN>;
		close (IN);
		chomp @conf;
		if (my @ls = grep {$_ =~ /^\s*NoAnonymous\s*(no|off)/i} @conf) {$status = 1}
		&addline($status,"Check Anonymous FTP Logins","Used as an attack vector by hackers and should be disabled unless actively used <i>WHM > <a href='$cpurl/scripts2/ftpconfiguration' target='_blank'>FTP Server Configuration</a> > Allow Anonymous Logins</b> > No</i>");
		$status = 0;
		if (my @ls = grep {$_ =~ /^\s*AnonymousCantUpload\s*(no|off)/i} @conf) {$status = 1}
		&addline($status,"Check Anonymous FTP Uploads","Used as an attack vector by hackers and should be disabled unless actively used <i>WHM > <a href='$cpurl/scripts2/ftpconfiguration' target='_blank'>FTP Server Configuration</a> > Allow Anonymous Uploads</b> > No</i>");

		$status = 0;
		my $ciphers;
		my $error;
		if (my @ls = grep {$_ =~ /^\s*TLSCipherSuite/} @conf) {
			if ($ls[0] =~ /TLSCipherSuite\s+(.*)$/) {$ciphers = $1}
			$ciphers =~ s/\s*|\"|\'//g;
			if ($ciphers eq "") {
				$status = 1;
			} else {
				if (-x "/usr/bin/openssl") {
					my ($childin, $childout);
					my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
					my @openssl = <$childout>;
					waitpid ($cmdpid, 0);
					chomp @openssl;
					if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
					if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
				}
			}
		} else {$status = 1}
		if ($status == 2) {
			&addline($status,"Check pure-ftpd weak SSL/TLS Ciphers (TLSCipherSuite)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
		}
		&addline($status,"Check pure-ftpd weak SSL/TLS Ciphers (TLSCipherSuite)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable SSLv2 in <i>WHM > <a href='$cpurl/scripts2/ftpconfiguration' target='_blank'>FTP Server Configuration</a> > TLS Cipher Suite</b> > Remove +SSLv2 or Add -SSLv2</i>");

		$status = 0;
		unless (-e "/var/cpanel/conf/pureftpd/root_password_disabled") {$status = 1}
		&addline($status,"Check FTP Logins with Root Password","Allowing root login via FTP is a considerable security risk and should be disabled <i>WHM > <a href='$cpurl/scripts2/ftpconfiguration' target='_blank'>FTP Server Configuration</a> > Allow Logins with Root Password</b> > No</i>");
	}

	if (-e "/var/cpanel/conf/proftpd/main" and ($cpconf->{ftpserver} eq "proftpd") and !(-e "/etc/ftpddisable")) {
		$status = 0;
		open (IN, "</var/cpanel/conf/proftpd/main");
		my @conf = <IN>;
		close (IN);
		chomp @conf;
		if (my @ls = grep {$_ =~ /^cPanelAnonymousAccessAllowed: 'yes'/i} @conf) {$status = 1}
		&addline($status,"Check Anonymous FTP Logins","Used as an attack vector by hackers and should be disabled unless actively used <i>WHM > <a href='$cpurl/scripts2/ftpconfiguration' target='_blank'>FTP Server Configuration</a> > Allow Anonymous Logins</b> > No</i>");

		$status = 0;
		my $ciphers;
		my $error;
		if (my @ls = grep {$_ =~ /^\s*TLSCipherSuite/} @conf) {
			if ($ls[0] =~ /TLSCipherSuite\:\s+(.*)$/) {$ciphers = $1}
			$ciphers =~ s/\s*|\"|\'//g;
			if ($ciphers eq "") {
				$status = 1;
			} else {
				if (-e "/usr/bin/openssl") {
					my ($childin, $childout);
					my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
					my @openssl = <$childout>;
					waitpid ($cmdpid, 0);
					chomp @openssl;
					if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
					if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
				}
			}
		} else {$status = 1}
		if ($status == 2) {
			&addline($status,"Check proftpd weak SSL/TLS Ciphers (TLSCipherSuite)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
		}
		&addline($status,"Check proftpd weak SSL/TLS Ciphers (TLSCipherSuite)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable SSLv2 in <i>WHM > <a href='$cpurl/scripts2/ftpconfiguration' target='_blank'>FTP Server Configuration</a> > TLS Cipher Suite</b> > Remove +SSLv2 or Add -SSLv2</i>");

		if ($config{VPS}) {
			$status = 0;
			open (IN, "</etc/proftpd.conf");
			my @conf = <IN>;
			close (IN);
			chomp @conf;
			if (my @ls = grep {$_ =~ /^\s*PassivePorts\s+(\d+)\s+(\d+)/} @conf) {
				if ($config{TCP_IN} !~ /\b$1:$2\b/) {$status = 1}
			} else {$status = 1}
			&addline($status,"Check VPS FTP PASV hole","Since the Virtuozzo VPS iptables ip_conntrack_ftp kernel module is currently broken you have to open a PASV port hole in iptables for incoming FTP connections to work correctly. See the csf readme.txt under 'A note about FTP Connection Issues' on how to do this");
		}
	}

	$status = 0;
	if ($cpconf->{allowremotedomains}) {$status = 1}
	&addline($status,"Check allow remote domains","User can park domains that resolve to other servers on this server. You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow Creation of Parked/Addon Domains that resolve to other servers");

	$status = 0;
	unless ($cpconf->{blockcommondomains}) {$status = 1}
	&addline($status,"Check block common domains","User can park common domain names on this server. You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Prevent users from parking/adding on common internet domains");

	$status = 0;
	if ($cpconf->{allowparkonothers}) {$status = 1}
	&addline($status,"Check allow park domains","User can park/addon domains that belong to other users on this server. You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow users to Park/Addon Domains on top of domains owned by other users");

	$status = 0;
	if ($cpconf->{proxysubdomains}) {$status = 1}
	&addline($status,"Check proxy subdomains","This option can mask a users real IP address and hinder security. You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Proxy subdomains");

	$status = 1;
	if ($cpconf->{cpaddons_notify_owner}) {$status = 0}
	&addline($status,"Check cPAddons update email to owner","You should have cPAddons email users if cPAddon installations require updating WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Notify owners when their users have cPAddon installations that need updated");

	$status = 1;
	if ($cpconf->{cpaddons_notify_root}) {$status = 0}
	&addline($status,"Check cPAddons update email to root","You should have cPAddons email root if cPAddon installations require updating WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Notify cPAddons Adminstrator of cPAddon installations that need updated");

	if (-e "/etc/cpupdate.conf") {
		open (IN, "</etc/cpupdate.conf");
		my @conf = <IN>;
		close (IN);
		chomp @conf;

		$status = 0;
		if (my @ls = grep {$_ =~ /^CPANEL=(edge|beta|nightly)/i} @conf) {$status = 1}
		&addline($status,"Check cPanel tree","Running EDGE/BETA on a production server could lead to server instability");

		$status = 1;
		if (my @ls = grep {$_ =~ /^UPDATES=daily/i} @conf) {$status = 0}
		&addline($status,"Check cPanel updates","You have cPanel updating disabled, this can pose a security and stability risk. <i>WHM > <a href='$cpurl/scripts2/updateconf' target='_blank'>Update Config</a> >cPanel/WHM Updates > Daily Updates > Update cPanel & WHM daily</i>");

		$status = 0;
		if (grep {$_ =~ /^SYSUP=/i} @conf) {$status = 1}
		if (grep {$_ =~ /^SYSUP=daily/i} @conf) {$status = 0}
		&addline($status,"Check package updates","You have package updating disabled, this can pose a security and stability risk. <i>WHM > <a href='$cpurl/scripts2/updateconf' target='_blank'>Update Config</a> >cPanel Package Updates > Automatic</i>");

		$status = 1;
		if (my @ls = grep {$_ =~ /^RPMUP=daily/i} @conf) {$status = 0}
		&addline($status,"Check security updates","You have security updating disabled, this can pose a security and stability risk. <i>WHM > <a href='$cpurl/scripts2/updateconf' target='_blank'>Update Config</a> >Operating System Package Updates > Automatic</i>");
	} else {&addline(1,"Check cPanel updates","Unable to find /etc/cpupdate.conf");}

	$status = 1;
	if ($cpconf->{account_login_access} eq "user") {$status = 0}
	&addline($status,"Check accounts that can access a cPanel user","You should consider setting this option to \"user\" after use. WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Accounts that can access a cPanel user account");

	$status = 0;
	if ($cpconf->{php_register_globals}) {$status = 1}
	&addline($status,"Check cPanel php for register_globals","PHP register_globals is considered a high security risk. You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > cPanel PHP Register Globals (disabling may break 3rd party PHP cPanel apps)");

	unless ($status) {
		$status = 0;
		open (IN, "</usr/local/cpanel/3rdparty/etc/php.ini");
		my @conf = <IN>;
		close (IN);
		chomp @conf;
		if (my @ls = grep {$_ =~ /^\s*register_globals\s*=\s*on/i} @conf) {$status = 1}
		&addline($status,"Check cPanel php.ini file for register_globals","PHP register_globals is considered a high security risk. It is currently enabled in /usr/local/cpanel/3rdparty/etc/php.ini and should be disabled (disabling may break 3rd party PHP cPanel apps)");
	}

	$status = 0;
	if ($cpconf->{emailpasswords}) {$status = 1}
	&addline($status,"Check cPanel passwords in email","You should not send passwords out in plain text emails. You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Send passwords when creating a new account");

	$status = 0;
	if ($cpconf->{coredump}) {$status = 1}
	&addline($status,"Check core dumps","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Generate core dumps");

	$status = 1;
	if ($cpconf->{cookieipvalidation} eq "strict") {$status = 0}
	&addline($status,"Check Cookie IP Validation","You should enable strict Cookie IP validation in WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Cookie IP validation");

	$status = 1;
	if ($cpconf->{use_apache_md5_for_htaccess}) {$status = 0}
	&addline($status,"Check MD5 passwords with Apache","You should enable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Use MD5 passwords with Apache");

	$status = 1;
	if ($cpconf->{referrerblanksafety}) {$status = 0}
	&addline($status,"Check Referrer Blank Security","You should enable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Blank referrer safety check");

	$status = 1;
	if ($cpconf->{referrersafety}) {$status = 0}
	&addline($status,"Check Referrer Security","You should enable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Referrer safety check");

	$status = 1;
	if ($cpconf->{skiphttpauth}) {$status = 0}
	&addline($status,"Check HTTP Authentication","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Enable HTTP Authentication");

	$status = 0;
	if ($cpconf->{skipparentcheck}) {$status = 1}
	&addline($status,"Check Parent Security","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow other applications to run the cPanel and admin binaries");

	$status = 0;
	if ($cpconf->{"cpsrvd-domainlookup"}) {$status = 1}
	&addline($status,"Check Domain Lookup Security","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > cpsrvd username domain lookup");

	$status = 1;
	if ($cpconf->{"cgihidepass"}) {$status = 0}
	&addline($status,"Check Password ENV variable","You should enable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Hide login password from cgi scripts ");

	$status = 0;
	if (-e "/var/cpanel/smtpgidonlytweak") {$status = 1}
	&addline($status,"Check SMTP Restrictions","This option in WHM will not function when running csf. You should disable WHM > Security Center > <a href='$cpurl/scripts2/smtpmailgidonly' target='_blank'>SMTP Restrictions</a> and use the csf configuration option SMTP_BLOCK instead");

	if (-e "/etc/wwwacct.conf" and -x $config{IFCONFIG}) {
		$status = 1;
		open (IN, "</etc/wwwacct.conf");
		my @conf = <IN>;
		close (IN);
		chomp @conf;

		my %ips;
		my ($childin, $childout);
		my $cmdpid = open3($childin, $childout, $childout, $config{IFCONFIG});
		my @ifconfig = <$childout>;
		waitpid ($cmdpid, 0);
		chomp @ifconfig;
		my $iface;

		($config{ETH_DEVICE},undef) = split (/:/,$config{ETH_DEVICE},2);

		foreach my $line (@ifconfig) {
			if ($line =~ /inet \w*:(\d+\.\d+\.\d+\.\d+)/) {
				my $ip = $1;
				$ips{$ip} = 1;
			}
		}

		my $nameservers;
		my $local = 0;
		my $allns = 0;
		foreach my $line (@conf) {
			if ($line =~ /^NS(\d)?\s+(.*)\s*$/) {
				my $ns = $2;
				$ns =~ s/\s//g;
				if ($ns) {
					$allns++;
					$nameservers .= "<b>$ns</b><br>\n";
					my $ip;
					if (checkip(\$ns)) {
						$ip = $ns;
						if ($ips{$ip}) {$local++}
					} else {
						my @ips = getips($ns);
						unless (scalar @ips) {&addline(1,"Check nameservers","Unable to resolve nameserver [$ns]")}
						my $hit = 0;
						foreach my $oip (@ips) {
							if ($ips{$oip}) {$hit = 1}
						}
						if ($hit) {$local++}
					}
				}
			}
		}
		if ($local < $allns) {$status = 0}
		&addline($status,"Check nameservers","At least one of the configured nameservers:<br>\n$nameservers should be located in a topologically and geographically dispersed location on the Internet - See RFC 2182 (Section 3.1)");
	}

	if (-e "/usr/local/cpanel/bin/register_appconfig") {
		$status = 0;
		if ($cpconf->{permit_unregistered_apps_as_reseller}) {$status = 1}
		&addline($status,"Check AppConfig Required","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow apps that have not registered with AppConfig to be run when logged in as a reseller in WHM");

		$status = 0;
		if ($cpconf->{permit_unregistered_apps_as_root}) {$status = 1}
		&addline($status,"Check AppConfig as root","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow apps that have not registered with AppConfig to be run when logged in as root or a reseller with the \"all\" ACL in WHM");

		$status = 0;
		if ($cpconf->{permit_appconfig_entries_without_acls}) {$status = 1}
		&addline($status,"Check AppConfig ACLs","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow WHM apps registered with AppConfig to be executed even if a Required ACLs list has not been defined");

		$status = 0;
		if ($cpconf->{permit_appconfig_entries_without_features}) {$status = 1}
		&addline($status,"Check AppConfig Feature List","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow cPanel and Webmail apps registered with AppConfig to be executed even if a Required Features list has not been defined");
	}

	$status = 0;
	if ($cpconf->{"disable-security-tokens"}) {$status = 1}
	&addline($status,"Check Security Tokens","Security Tokens should not be disabled as without them security of WHM/cPanel is compromised. The setting disable-security-tokens=0 should be set in /var/cpanel/cpanel.config");
}
# end whmcheck
###############################################################################
# start dacheck
sub dacheck {
	my $status = 0;
	&addtitle("DirectAdmin Settings Check");

	$status = 0;
	unless ($daconfig{SSL}) {$status = 1}
	&addline($status,"Check DirectAdmin login is SSL only","You should enable SSL only login to <a href='http://help.directadmin.com/item.php?id=15' target='_blank'>DirectAdmin</a>");

	if (($daconfig{ftpconfig} =~ /proftpd.conf/) and ($daconfig{pureftp} != 1)) {
		$status = 0;
		open (IN, "<", $daconfig{ftpconfig});
		my @conf = <IN>;
		close (IN);
		chomp @conf;

		my $ciphers;
		my $error;
		if (my @ls = grep {$_ =~ /^\s*TLSCipherSuite/} @conf) {
			if ($ls[0] =~ /TLSCipherSuite\s+(.*)$/) {$ciphers = $1}
			$ciphers =~ s/\s*|\"|\'//g;
			if ($ciphers eq "") {
				$status = 1;
			} else {
				if (-e "/usr/bin/openssl") {
					my ($childin, $childout);
					my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
					my @openssl = <$childout>;
					waitpid ($cmdpid, 0);
					chomp @openssl;
					if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
					if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
				}
			}
		} else {$status = 1}
		if ($status == 2) {
			&addline($status,"Check proftpd weak SSL/TLS Ciphers (TLSCipherSuite)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
		}
		&addline($status,"Check proftpd weak SSL/TLS Ciphers (TLSCipherSuite)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should add a TLSCipherSuite with SSLv2 disabled in $daconfig{ftpconfig}. For example,<br><b>&lt;IfModule mod_tls.c><br>TLSCipherSuite HIGH:MEDIUM:+TLSv1:!SSLv2:+SSLv3<br>&lt;/IfModule> container</b>");

		if ($config{VPS}) {
			$status = 0;
			if (my @ls = grep {$_ =~ /^\s*PassivePorts\s+(\d+)\s+(\d+)/} @conf) {
				if ($config{TCP_IN} !~ /\b$1:$2\b/) {$status = 1}
			} else {$status = 1}
			&addline($status,"Check VPS FTP PASV hole","Since the Virtuozzo VPS iptables ip_conntrack_ftp kernel module is currently broken you have to open a PASV port hole in iptables for incoming FTP connections to work correctly. See the csf readme.txt under 'A note about FTP Connection Issues' on how to do this");
		}
	}

	if (-x $config{IFCONFIG}) {
		$status = 1;

		my %ips;
		my ($childin, $childout);
		my $cmdpid = open3($childin, $childout, $childout, $config{IFCONFIG});
		my @ifconfig = <$childout>;
		waitpid ($cmdpid, 0);
		chomp @ifconfig;
		my $iface;

		($config{ETH_DEVICE},undef) = split (/:/,$config{ETH_DEVICE},2);

		foreach my $line (@ifconfig) {
			if ($line =~ /inet \w*:(\d+\.\d+\.\d+\.\d+)/) {
				my $ip = $1;
				$ips{$ip} = 1;
			}
		}

		my $nameservers;
		for (my $x = 1; $x < 3; $x++) {
			my $ns = $daconfig{"ns$x"};
			$ns =~ s/\s//g;
			if ($ns) {
				$nameservers .= "<b>$ns</b><br>\n";
				my $ip;
				if ($ns =~ /\d+\.\d+\.\d+\.d+/) {
					$ip = $ns;
				} else {
					eval {
						local $SIG{__DIE__} = undef;
						local $SIG{'ALRM'} = sub {die};
						alarm(5);
						$ip = gethostbyname($ns);
						$ip = inet_ntoa($ip);
						alarm(0);
					};
					alarm(0);
					unless ($ip) {&addline(1,"Check nameservers","Unable to resolve nameserver [$ns] within 5 seconds")}
				}
				if ($ip) {
					unless ($ips{$ip}) {$status = 0}
				}
			}
		}
		&addline($status,"Check nameservers","At least one of the configured nameservers:<br>\n$nameservers should be located in a topologically and geographically dispersed location on the Internet - See RFC 2182 (Section 3.1)");
	}
}
# end dacheck
###############################################################################
# start mailcheck
sub mailcheck {
	&addtitle("Mail Check");

	my $status = 0;
	unless ($config{DIRECTADMIN}) {
		if (-e "/root/.forward") {
			if (-z "/root/.forward") {$status = 1}
		} else {$status = 1}
		&addline($status,"Check root forwarder","The root account should have a forwarder set so that you receive essential email from your server");
	}

	if (-e "/etc/exim.conf" and -x "/usr/sbin/exim") {
		$status = 0;
		my ($childin, $childout);
		my $cmdpid = open3($childin, $childout, $childout, "/usr/sbin/exim","-bP");
		my @eximconf = <$childout>;
		waitpid ($cmdpid, 0);
		chomp @eximconf;
		if (my @ls = grep {$_ =~ /^\s*log_selector/} @eximconf) {
			if (($ls[0] !~ /\+all/) and ($ls[0] !~ /\+arguments/) and ($ls[0] !~ /\+arguments/)) {$status = 1}
		} else {$status = 1}
		if ($config{DIRECTADMIN}) {
			&addline($status,"Check exim for extended logging (log_selector)","You should enable extended exim logging to enable easier tracking potential outgoing spam issues. Add:<br><b>log_selector = +arguments +subject +received_recipients</b><br>to /etc/exim.conf");
		} else {
			&addline($status,"Check exim for extended logging (log_selector)","You should enable extended exim logging to enable easier tracking potential outgoing spam issues. Add:<br><b>log_selector = +arguments +subject +received_recipients</b><br>in WHM > <a href='$cpurl/scripts2/displayeximconfforedit' target='_blank'>Exim Configuration Manager</a> > Advanced Editor > log_selector");
		}

		$status = 0;
		my $ciphers;
		my $error;
		if (my @ls = grep {$_ =~ /^\s*tls_require_ciphers/} @eximconf) {
			(undef,$ciphers) = split(/\=/,$ls[0]);
			$ciphers =~ s/\s*|\"|\'//g;
			if ($ciphers eq "") {
				$status = 1;
			} else {
				if (-x "/usr/bin/openssl") {
					my ($childin, $childout);
					my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
					my @openssl = <$childout>;
					waitpid ($cmdpid, 0);
					chomp @openssl;
					if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
					if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
				}
			}
		} else {$status = 1}
		if ($status == 2) {
			&addline($status,"Check exim weak SSL/TLS Ciphers (tls_require_ciphers)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
		}
		if ($config{DIRECTADMIN}) {
			&addline($status,"Check exim weak SSL/TLS Ciphers (tls_require_ciphers)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should edit /etc/exim.conf and set tls_require_ciphers to explicitly exclude it. For example:<br><b>tls_require_ciphers=ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP</b>");
		} else {
			&addline($status,"Check exim weak SSL/TLS Ciphers (tls_require_ciphers)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable WHM > <a href='$cpurl/scripts2/displayeximconfforedit' target='_blank'>Exim Configuration Manager</a> > Allow weak ssl/tls ciphers to be used, and also ensure tls_require_ciphers in /etc/exim.conf does not allow SSLv2 as openssl currently shows that it does");
		}
	} else {&addline(1,"Check exim configuration","Unable to find /etc/exim.conf and/or /usr/sbin/exim");}

	if ($config{DIRECTADMIN}) {
		if (-e "/etc/dovecot.conf" and ($daconfig{dovecot})) {
			$status = 0;
			open (IN, "</etc/dovecot.conf");
			my @conf = <IN>;
			close (IN);
			chomp @conf;
			my $ciphers;
			my $error;
			if (my @ls = grep {$_ =~ /^ssl_cipher_list/} @conf) {
				(undef,$ciphers) = split(/\=/,$ls[0]);
				$ciphers =~ s/\s*|\"|\'//g;
				if ($ciphers eq "") {
					$status = 1;
				} else {
					if (-x "/usr/bin/openssl") {
						my ($childin, $childout);
						my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
						my @openssl = <$childout>;
						waitpid ($cmdpid, 0);
						chomp @openssl;
						if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
						if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
					}
				}
			} else {$status = 1}
			if ($status == 2) {
				&addline($status,"Check dovecot weak SSL/TLS Ciphers (ssl_cipher_list)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
			}
			&addline($status,"Check dovecot weak SSL/TLS Ciphers (ssl_cipher_list)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should /etc/dovecot.conf and set ssl_cipher_list to explicitly exclude it. For example:<br><b>ssl_cipher_list = ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP</b>");
		}
	} else {
		if (-e "/etc/dovecot/dovecot.conf" and ($cpconf->{mailserver} eq "dovecot")) {
			$status = 0;
			open (IN, "</etc/dovecot/dovecot.conf");
			my @conf = <IN>;
			close (IN);
			chomp @conf;
			$status = 0;
			my $ciphers;
			my $error;
			if (my @ls = grep {$_ =~ /^ssl_cipher_list/} @conf) {
				(undef,$ciphers) = split(/\=/,$ls[0]);
				$ciphers =~ s/\s*|\"|\'//g;
				if ($ciphers eq "") {
					$status = 1;
				} else {
					if (-x "/usr/bin/openssl") {
						my ($childin, $childout);
						my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
						my @openssl = <$childout>;
						waitpid ($cmdpid, 0);
						chomp @openssl;
						if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
						if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
					}
				}
			} else {$status = 1}
			if ($status == 2) {
				&addline($status,"Check dovecot weak SSL/TLS Ciphers (ssl_cipher_list)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
			}
			&addline($status,"Check dovecot weak SSL/TLS Ciphers (ssl_cipher_list)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable SSLv2 in <i>WHM > <a href='$cpurl/scripts2/mailserversetup' target='_blank'>Mailserver Configuration</a> > SSL Cipher List</b> > Remove +SSLv2 or Add -SSLv2</i>");
		}

		if (-e "/usr/lib/courier-imap/etc/imapd-ssl" and ($cpconf->{mailserver} eq "courier")) {
			$status = 0;
			open (IN, "</usr/lib/courier-imap/etc/imapd-ssl");
			my @conf = <IN>;
			close (IN);
			chomp @conf;
			$status = 0;
			my $ciphers;
			my $error;
			if (my @ls = grep {$_ =~ /^TLS_CIPHER_LIST/} @conf) {
				(undef,$ciphers) = split(/\=/,$ls[0]);
				$ciphers =~ s/\s*|\"|\'//g;
				if ($ciphers eq "") {
					$status = 1;
				} else {
					if (-x "/usr/bin/openssl") {
						my ($childin, $childout);
						my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
						my @openssl = <$childout>;
						waitpid ($cmdpid, 0);
						chomp @openssl;
						if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
						if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
					}
				}
			} else {$status = 1}
			if ($status == 2) {
				&addline($status,"Check Courier IMAP weak SSL/TLS Ciphers (TLS_CIPHER_LIST)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
			}
			&addline($status,"Check Courier IMAP weak SSL/TLS Ciphers (TLS_CIPHER_LIST)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable SSLv2 in <i>WHM > <a href='$cpurl/scripts2/mailserversetup' target='_blank'>Mailserver Configuration</a> > IMAP TLS/SSL Cipher List</b> > Remove +SSLv2 or Add -SSLv2</i>");
		}

		if (-e "/usr/lib/courier-imap/etc/pop3d-ssl" and ($cpconf->{mailserver} eq "courier")) {
			$status = 0;
			open (IN, "</usr/lib/courier-imap/etc/pop3d-ssl");
			my @conf = <IN>;
			close (IN);
			chomp @conf;
			$status = 0;
			my $ciphers;
			my $error;
			if (my @ls = grep {$_ =~ /^TLS_CIPHER_LIST/} @conf) {
				(undef,$ciphers) = split(/\=/,$ls[0]);
				$ciphers =~ s/\s*|\"|\'//g;
				if ($ciphers eq "") {
					$status = 1;
				} else {
					if (-x "/usr/bin/openssl") {
						my ($childin, $childout);
						my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
						my @openssl = <$childout>;
						waitpid ($cmdpid, 0);
						chomp @openssl;
						if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
						if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
					}
				}
			} else {$status = 1}
			if ($status == 2) {
				&addline($status,"Check Courier POP3D weak SSL/TLS Ciphers (TLS_CIPHER_LIST)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
			}
			&addline($status,"Check Courier POP3D weak SSL/TLS Ciphers (TLS_CIPHER_LIST)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable SSLv2 in <i>WHM > <a href='$cpurl/scripts2/mailserversetup' target='_blank'>Mailserver Configuration</a> > POP3 TLS/SSL Cipher List</b> > Remove +SSLv2 or Add -SSLv2</i>");
		}
	}
}
# end mailcheck
###############################################################################
# start phpcheck
sub phpcheck {
	&addtitle("PHP Check");

	unless (-x "/usr/local/bin/php") {&addline(1,"PHP Binary","/usr/local/bin/php not found or not executable"); return}

	open (IN, "</usr/local/lib/php.ini");
	my @phpini = <IN>;
	close (IN);
	chomp @phpini;

	open (OUT, ">/var/lib/csf/csf.php.ini");
	foreach my $line (@phpini) {
		if ($line =~ /^\s*zlib\.output\_compression/) {next}
		print OUT "$line\n";
	}
	close (OUT);

	my $status = 0;
	my ($childin, $childout);
	my $mypid = open3($childin, $childout, $childout, "/usr/local/bin/php","-c","/var/lib/csf/csf.php.ini","-i");
	my @conf = <$childout>;
	waitpid ($mypid, 0);
	chomp @conf;

	unlink ("/var/lib/csf/csf.php.ini");

	if (my @ls = grep {$_ =~ /^PHP License/} @conf) {
		my $version = 0;
		my ($mas,$maj,$min);
		if (my @ls = grep {$_ =~ /^PHP Version\s*=>\s*/i} @conf) {
			my $line = $ls[0];
			$line =~ /^PHP Version\s*=>\s*(.*)/i;
			($mas,$maj,$min) = split(/\./,$1);
			$version = "$mas.$maj.$min";
			if ($mas < 5) {$status = 1}
			if ($mas == 5 and $maj < 4) {$status = 1}
		}
		open (IN, "</usr/local/apache/conf/php.conf.yaml");
		my @phpyamlconf = <IN>;
		close (IN);
		chomp @phpyamlconf;
		if (my @ls = grep {$_ =~ /php4:/i} @phpyamlconf) {
			if ($ls[0] !~ /none/) {
				$status = 1;
				$version = "4.*";
			}
		}
		&addline($status,"Check php version (/usr/local/bin/php)","Any version of PHP (Current: $version) older than v5.4.* is now obsolete and should be considered a security threat. You should upgrade exclusively to PHP v5.4+");

		$status = 1;
		if (my @ls = grep {$_ =~ /^enable_dl\s*=>\s*Off/i} @conf) {
			$status = 0;
		}
		if (my @ls = grep {$_ =~ /^disable_functions\s*=>.*dl.*/i} @conf) {
			$status = 0;
		}
		&addline($status,"Check php for enable_dl or disabled dl()","You should modify /usr/local/lib/php.ini and set:<br><b>enable_dl = Off</b><br>This prevents users from loading php modules that affect everyone on the server. Note that if use dynamic libraries, such as ioncube, you will have to load them directly in the PHP configuration (usually in /usr/local/lib/php.ini)");
		
		$status = 1;
		if (my @ls = grep {$_ =~ /^disable_functions\s*=>.*\,/i} @conf) {
			$status = 0;
		}
		&addline($status,"Check php for disable_functions","You should modify the PHP configuration and disable commonly abused php functions, e.g.:<br><b>disable_functions = show_source, system, shell_exec, passthru, exec, phpinfo, popen, proc_open</b><br>Some client web scripts may break with some of these functions disabled, so you may have to remove them from this list");

		$status = 1;
		if (my @ls = grep {$_ =~ /^disable_functions\s*=>.*ini_set.*/i} @conf) {
			$status = 0;
		}
		&addline($status,"Check php for ini_set disabled","You should consider adding ini_set to the disable_functions in the PHP configuration as this setting allows PHP scripts to override global security and performance settings for PHP scripts. Adding ini_set can break PHP scripts and commenting out any use of ini_set in such scripts is advised");

		my $oldver = "$mas.$maj";
		if ($oldver < 5.4) {
			$status = 1;
			if (my @ls = grep {$_ =~ /^register_globals\s*=>\s*Off/i} @conf) {
				$status = 0;
			}
			&addline($status,"Check php for register_globals","You should modify the PHP configuration and set:<br><b>register_globals = Off</b><br>unless it is absolutely necessary as it is seen as a significant security risk");

			$status = 1;
			if (my @ls = grep {$_ =~ /^suhosin.simulation\s*=>\s*Off/i} @conf) {
				$status = 0;
			}
			&addline($status,"Check php for Suhosin","You should recompile PHP with Suhosin to add greater security to PHP");
		}

		unless ($config{DIRECTADMIN}) {
			$status = 0;
			unless ($cpconf->{phpopenbasedirhome}) {$status = 1}
			&addline($status,"Check php open_basedir protection","To help prevent PHP scripts from straying outside their cPanel account, you should check <i>WHM > Security Center > <a href='$cpurl/scripts2/tweakphpdir' target='_blank'>php open_basedir Tweak</a></i>");
		}
	} else {
		$status = 1;
		&addline($status,"Check php","Unable to examine PHP settings due to an error in the output from: /usr/local/bin/php -i");
	}
}
# end phpcheck
###############################################################################
# start apachecheck
sub apachecheck {
	&addtitle("Apache Check");

	my $status = 0;
	my $mypid;
	my ($childin, $childout);
	my %ea4;

	if (-e "/usr/local/cpanel/version" and -e "/etc/cpanel/ea4/is_ea4" and -e "/etc/cpanel/ea4/paths.conf") {
		my @file = slurp("/etc/cpanel/ea4/paths.conf");
		$ea4{enabled} = 1;
		foreach my $line (@file) {
			$line =~ s/$cleanreg//g;
			if ($line =~ /^(\s|\#|$)/) {next}
			if ($line !~ /=/) {next}
			my ($name,$value) = split (/=/,$line,2);
			$value =~ s/^\s+//g;
			$value =~ s/\s+$//g;
			$ea4{$name} = $value;
		}
	}

	if ($ea4{enabled}) {
		unless (-x $ea4{bin_httpd}) {&addline(1,"HTTP Binary","$ea4{bin_httpd} not found or not executable"); return}
	}
	elsif ($config{DIRECTADMIN}) {
		unless (-x "/usr/sbin/httpd") {&addline(1,"HTTP Binary","/usr/sbin/httpd not found or not executable"); return}
	}
	else {
		unless (-x "/usr/local/apache/bin/httpd") {&addline(1,"HTTP Binary","/usr/local/apache/bin/httpd not found or not executable"); return}
	}

	if ($ea4{enabled}) {
		$mypid = open3($childin, $childout, $childout, $ea4{bin_httpd},"-v");
	}
	elsif ($config{DIRECTADMIN}) {
		$mypid = open3($childin, $childout, $childout, "/usr/sbin/httpd","-v");
	}
	else {
		$mypid = open3($childin, $childout, $childout, "/usr/local/apache/bin/httpd","-v");
	}
	my @version = <$childout>;
	waitpid ($mypid, 0);
	chomp @version;
	$version[0] =~ /Apache\/(\d+)\.(\d+)\.(\d+)/;
	my $mas = $1;
	my $maj = $2;
	my $min = $3;
	if ("$mas.$maj" < 2.2) {$status = 1}
	&addline($status,"Check apache version","You are running a legacy version of apache (v$mas.$maj.$min) and should consider upgrading to v2.2.* as recommended by the Apache developers");

	unless ($config{DIRECTADMIN}) {
		my $ruid2 = 0;
		if ($ea4{enabled}) {
			$mypid = open3($childin, $childout, $childout, $ea4{bin_httpd},"-M");
		}
		else {
			$mypid = open3($childin, $childout, $childout, "/usr/local/apache/bin/httpd","-M");
		}
		my @modules = <$childout>;
		waitpid ($mypid, 0);
		chomp @modules;
		if (my @ls = grep {$_ =~ /ruid2_module/} @modules) {$ruid2 = 1}

		if (my @ls = grep {$_ =~ /security2_module/} @modules) {$status = 0} else {$status = 1}

		&addline($status,"Check apache for ModSecurity","You should install the ModSecurity apache module during the easyapache build process to help prevent exploitation of vulnerable web scripts, together with a set of rules");

		$status = 0;
		if (my @ls = grep {$_ =~ /frontpage_module/} @modules) {$status = 1}
		&addline($status,"Check apache for FrontPage","Microsoft Frontpage Extensions were EOL in 2006 and there is no support for bugs or security issues. For this reason, it should be considered a security risk to continue using them. You should rebuild apache through easyapache and deselect the option to build them");

		$status = 1;
		if (my @ls = grep {$_ =~ /suexec_module/} @modules) {$status = 0}
		&addline($status,"Check Suexec","To reduce the risk of hackers accessing all sites on the server from a compromised CGI web script, you should set <i>WHM > <a href='$cpurl/scripts2/phpandsuexecconf' target='_blank'>Suexec on</a></i>");

		my @conf;
		if (-e "/usr/local/apache/conf/httpd.conf") {
			open (IN, "</usr/local/apache/conf/httpd.conf");
			@conf = <IN>;
			close (IN);
			chomp @conf;
		}
		if (-e "$ea4{file_conf}") {
			open (IN, "<$ea4{file_conf}");
			@conf = <IN>;
			close (IN);
			chomp @conf;
		}
		if (@conf) {
			$status = 0;
			my $ciphers;
			my $error;
			if (my @ls = grep {$_ =~ /^\s*SSLCipherSuite/} @conf) {
				$ls[0] =~ s/^\s+//g;
				(undef,$ciphers) = split(/\ /,$ls[0]);
				$ciphers =~ s/\s*|\"|\'//g;
				if ($ciphers eq "") {
					$status = 1;
				} else {
					if (-x "/usr/bin/openssl") {
						my ($childin, $childout);
						my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
						my @openssl = <$childout>;
						waitpid ($cmdpid, 0);
						chomp @openssl;
						if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
						if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
					}
				}
			} else {$status = 1}
			if ($status == 2) {
				&addline($status,"Check Apache weak SSL/TLS Ciphers (SSLCipherSuite)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
			}
			&addline($status,"Check Apache weak SSL/TLS Ciphers (SSLCipherSuite)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable SSLv2 in WHM > Apache Configuration > <a href='$cpurl/scripts2/globalapachesetup' target='_blank'>Global Configuration</a> > SSLCipherSuite > Add -SSLv2 to SSLCipherSuite and/or remove +SSLv2. Do not forget to Save AND then Rebuild Configuration and Restart Apache, otherwise the changes will not take effect in httpd.conf");

			$status = 0;
			if (my @ls = grep {$_ =~ /^\s*TraceEnable Off/} @conf) {
				$status = 0;
			} else {$status = 1}
			&addline($status,"Check apache for TraceEnable","You should set TraceEnable to Off in: WHM > Apache Configuration > <a href='$cpurl/scripts2/globalapachesetup' target='_blank'>Global Configuration</a> > TraceEnable > Off. Do not forget to Save AND then Rebuild Configuration and Restart Apache, otherwise the changes will not take effect in httpd.conf");
			$status = 0;
			if (my @ls = grep {$_ =~ /^\s*ServerSignature Off/} @conf) {
				$status = 0;
			} else {$status = 1}
			&addline($status,"Check apache for ServerSignature","You should set ServerSignature to Off in: WHM > Apache Configuration > <a href='$cpurl/scripts2/globalapachesetup' target='_blank'>Global Configuration</a> > ServerSignature > Off. Do not forget to Save AND then Rebuild Configuration and Restart Apache, otherwise the changes will not take effect in httpd.conf");
			$status = 0;
			if (my @ls = grep {$_ =~ /^\s*ServerTokens ProductOnly/} @conf) {
				$status = 0;
			} else {$status = 1}
			&addline($status,"Check apache for ServerTokens","You should set ServerTokens to ProductOnly in: WHM > Apache Configuration > <a href='$cpurl/scripts2/globalapachesetup' target='_blank'>Global Configuration</a> > ServerTokens > ProductOnly. Do not forget to Save AND then Rebuild Configuration and Restart Apache, otherwise the changes will not take effect in httpd.conf");
			$status = 0;
			if (my @ls = grep {$_ =~ /^\s*FileETag None/} @conf) {
				$status = 0;
			} else {$status = 1}
			&addline($status,"Check apache for FileETag","You should set FileETag to None in: WHM > Apache Configuration > <a href='$cpurl/scripts2/globalapachesetup' target='_blank'>Global Configuration</a> > FileETag > None. Do not forget to Save AND then Rebuild Configuration and Restart Apache, otherwise the changes will not take effect in httpd.conf");
		}

		my @apacheconf;
		if (-e "/usr/local/apache/conf/php.conf.yaml") {
			open (IN, "</usr/local/apache/conf/php.conf.yaml");
			@apacheconf = <IN>;
			close (IN);
			chomp @apacheconf;
		}
		if (-e "$ea4{dir_conf}/php.conf.yaml") {
			open (IN, "<$ea4{dir_conf}/php.conf.yaml");
			@apacheconf = <IN>;
			close (IN);
			chomp @apacheconf;
		}
		if (@apacheconf) {
			unless ($ruid2) {
				$status = 0;
				if (my @ls = grep {$_ =~ /suphp/} @apacheconf) {
					$status = 0;
				} else {$status = 1}
				&addline($status,"Check suPHP","To reduce the risk of hackers accessing all sites on the server from a compromised PHP web script, you should enable suPHP when you build apache/php. Note that there are sideeffects when enabling suPHP on a server and you should be aware of these before enabling it.<br>Don\'t forget to enable it as the default PHP handler in <i>WHM > <a href='$cpurl/scripts2/phpandsuexecconf' target='_blank'>PHP 5 Handler</a></i>");
		
				$status = 0;
				unless ($cpconf->{userdirprotect}) {$status = 1}
				&addline($status,"Check mod_userdir protection","To prevents users from stealing bandwidth or hackers hiding access to your servers, you should check <i>WHM > Security Center > <a href='$cpurl/scripts2/tweakmoduserdir' target='_blank'>mod_userdir Tweak</a></i>");
			}
		}
	}
}
# end apachecheck
###############################################################################
# start sshtelnetcheck
sub sshtelnetcheck {
	my $status = 0;
	&addtitle("SSH/Telnet Check");

	if (-e "/etc/ssh/sshd_config") {
		open (IN, "</etc/ssh/sshd_config");
		my @sshconf = <IN>;
		close (IN);
		chomp @sshconf;
		if (my @ls = grep {$_ =~ /^\s*Protocol/i} @sshconf) {
			if ($ls[0] =~ /1/) {$status = 1}
		} else {$status = 0}
		&addline($status,"Check SSHv1 is disabled","You should disable SSHv1 by editing /etc/ssh/sshd_config and setting:<br><b>Protocol 2</b>");

		$status = 0;
		my $sshport = "22";
		if (my @ls = grep {$_ =~ /^\s*Port/i} @sshconf) {
			if ($ls[0] =~ /^\s*Port\s+(\d*)/i) {
				$sshport = $1;
				if ($sshport eq "22") {$status = 1}
			} else {$status = 1}
		} else {$status = 1}
		&addline($status,"Check SSH on non-standard port","You should consider moving SSH to a non-standard port [currently:$sshport] to evade basic SSH port scans. Don't forget to open the port in the firewall first!");

		$status = 0;
		if (my @ls = grep {$_ =~ /^\s*PasswordAuthentication/i} @sshconf) {
			if ($ls[0] =~ /\byes\b/i) {$status = 1}
		} else {$status = 1}
		&addline($status,"Check SSH PasswordAuthentication","For ultimate SSH security, you should consider disabling PasswordAuthentication and only allow access using PubkeyAuthentication");

		$status = 0;
		if (my @ls = grep {$_ =~ /^\s*UseDNS/i} @sshconf) {
			if ($ls[0] !~ /\bno\b/i) {$status = 1}
		} else {$status = 1}
		&addline($status,"Check SSH UseDNS","You should disable UseDNS by editing /etc/ssh/sshd_config and setting:<br><b>UseDNS no</b><br>Otherwise, lfd will be unable to track SSHD login failures successfully as the log files will not report IP addresses");
	} else {&addline(1,"Check SSH configuration","Unable to find /etc/ssh/sshd_config");}

	$status = 0;
	my $check = &getportinfo("23");
	if ($check) {$status = 1}
	&addline($status,"Check telnet port 23 is not in use","It appears that something is listening on port 23 which is normally used for telnet. Telnet is an insecure protocol and you should disable the telnet daemon if it is running");

	unless ($config{DNSONLY} or $config{GENERIC}) {
		unless ($config{VPS}) {
			if (-e "/etc/profile") {
				$status = 0;
				open (IN, "</etc/profile");
				my @profile = <IN>;
				close (IN);
				chomp @profile;
				if (grep {$_ =~ /^LIMITUSER=\$USER/} @profile) {
					$status = 0;
				} else {$status = 1}
				&addline($status,"Check shell limits","You should enable shell resource limits to prevent shell users from consuming server resources - DOS exploits typically do this. A quick way to set this is to use WHM > <a href='$cpurl/scripts2/modlimits' target='_blank'>Shell Fork Bomb Protection</a>");
			} else {&addline(1,"Check shell limits","Unable to find /etc/profile");}
		}

		$status = 0;
		if (-e "/var/cpanel/killproc.conf") {
			open (IN, "</var/cpanel/killproc.conf");
			my @proc = <IN>;
			close (IN);
			chomp @proc;
			if (@proc < 9) {$status = 1}
			&addline($status,"Check Background Process Killer","You should enable each item in the WHM > <a href='$cpurl/scripts2/dkillproc' target='_blank'>Background Process Killer</a>");
		} else {&addline(1,"Check Background Process Killer","You should enable each item in the WHM > <a href='$cpurl/scripts2/dkillproc' target='_blank'>Background Process Killer</a>")}
	}
}
# end sshtelnetcheck
###############################################################################
# start servicescheck
sub servicescheck {
	if (-x "/sbin/chkconfig") {
		&addtitle("Server Services Check");
		my $status = 0;
		my @services = ("cups","xfs","nfslock","canna","FreeWnn","cups-config-daemon","iiim","mDNSResponder","nifd","rpcidmapd","bluetooth","anacron","gpm","saslauthd","avahi-daemon","avahi-dnsconfd","hidd","pcscd","sbadm","xinetd","qpidd","portreserve","rpcbind");
		my ($childin, $childout);
		my $mypid = open3($childin, $childout, $childout, "/sbin/chkconfig","--list");
		my @chkconfig = <$childout>;
		waitpid ($mypid, 0);
		chomp @chkconfig;

		foreach my $service (@services) {
			if ($service eq "xinetd" and $config{PLESK}) {next}
			$status = 0;
			if (my @ls = grep {$_ =~ /^$service\b/} @chkconfig) {
				if ($ls[0] =~ /\:on/) {$status = 1}
			}
			&addline($status,"Check server startup for $service","On most servers $service is not needed and should be stopped and disabled from starting if it is not required. This service is currently enabled in init and can usually be disabled using:<br><b>service $service stop<br>chkconfig $service off</b>");
		}
	}
}
# end servicescheck
###############################################################################
# start getportinfo
sub getportinfo {
	my $port = shift;
	my $hit = 0;

	foreach my $proto ("udp","tcp","udp6","tcp6") {
		open (IN, "</proc/net/$proto");
		while (<IN>) {
			my @rec = split();
			if ($rec[9] =~ /uid/) {next}
			my (undef,$sport) = split(/:/,$rec[1]);
			if (hex($sport) == $port) {$hit = 1}
		}
		close (IN);
	}

	return $hit;
}
# end getportinfo
###############################################################################

1;
