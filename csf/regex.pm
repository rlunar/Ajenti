#!/usr/bin/perl
###############################################################################
# Copyright 2006-2016, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################

###############################################################################
#		&logfile("debug: [$1] [$2] [$3] ip:[$4] [$5] acc:[$6] [$7] [$8] [$9]");
# start processline
sub processline {
	my $line = shift;
	my $lgfile = shift;
	$line =~ s/\n//g;
	$line =~ s/\r//g;

	if (-e "/usr/local/csf/bin/regex.custom.pm") {
		my ($text,$ip,$app,$trigger,$ports,$temp) = &custom_line($line,$lgfile);
		if ($text) {
				return ($text,$ip,$app,$trigger,$ports,$temp);
		}
	}

#openSSH
#RH
	if (($config{LF_SSHD}) and (($lgfile eq "/var/log/messages") or ($lgfile eq "/var/log/secure") or ($globlogs{SSHD_LOG}{$lgfile})) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?sshd\[\d+\]: pam_unix\(sshd:auth\): authentication failure; logname=\S* uid=\S* euid=\S* tty=\S* ruser=\S* rhost=(\S+)\s+(user=(\S+))?/)) {
		$ip = $3; $acc = $5; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed SSH login from","$ip|$acc","sshd")} else {return}
	}
	if (($config{LF_SSHD}) and (($lgfile eq "/var/log/messages") or ($lgfile eq "/var/log/secure") or ($globlogs{SSHD_LOG}{$lgfile})) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?sshd\[\d+\]: Failed none for (\S*) from (\S+) port \S+/)) {
        $ip = $4; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed SSH login from","$ip|$acc","sshd")} else {return}
	}
	if (($config{LF_SSHD}) and (($lgfile eq "/var/log/messages") or ($lgfile eq "/var/log/secure") or ($globlogs{SSHD_LOG}{$lgfile})) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?sshd\[\d+\]: Failed password for (invalid user |illegal user )?(\S*) from (\S+)( port \S+ \S+\s*)?/)) {
        $ip = $5; $acc = $4; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed SSH login from","$ip|$acc","sshd")} else {return}
	}
	if (($config{LF_SSHD}) and (($lgfile eq "/var/log/messages") or ($lgfile eq "/var/log/secure") or ($globlogs{SSHD_LOG}{$lgfile})) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?sshd\[\d+\]: Failed keyboard-interactive(\/pam)? for (invalid user )?(\S*) from (\S+) port \S+/)) {
        $ip = $6; $acc = $4; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed SSH login from","$ip|$acc","sshd")} else {return}
	}
	if (($config{LF_SSHD}) and (($lgfile eq "/var/log/messages") or ($lgfile eq "/var/log/secure") or ($globlogs{SSHD_LOG}{$lgfile})) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?sshd\[\d+\]: Invalid user (\S*) from (\S+)/)) {
        $ip = $4; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed SSH login from","$ip|$acc","sshd")} else {return}
	}
	if (($config{LF_SSHD}) and (($lgfile eq "/var/log/messages") or ($lgfile eq "/var/log/secure") or ($globlogs{SSHD_LOG}{$lgfile})) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?sshd\[\d+\]: User (\S*) from (\S+)\s* not allowed because not listed in AllowUsers/)) {
        $ip = $4; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed SSH login from","$ip|$acc","sshd")} else {return}
	}
	if (($config{LF_SSHD}) and (($lgfile eq "/var/log/messages") or ($lgfile eq "/var/log/secure") or ($globlogs{SSHD_LOG}{$lgfile})) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?sshd\[\d+\]: Did not receive identification string from (\S+)/)) {
        $ip = $3; $acc = ""; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed SSH login from","$ip|$acc","sshd")} else {return}
	}
	if (($config{LF_SSHD}) and (($lgfile eq "/var/log/messages") or ($lgfile eq "/var/log/secure") or ($globlogs{SSHD_LOG}{$lgfile})) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?sshd\[\d+\]: refused connect from (\S+)/)) {
        $ip = $3; $acc = ""; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed SSH login from","$ip|$acc","sshd")} else {return}
	}

#Debian/Ubuntu
	if (($config{LF_SSHD}) and (($lgfile eq "/var/log/messages") or ($lgfile eq "/var/log/secure") or ($globlogs{SSHD_LOG}{$lgfile})) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?sshd\[\d+\]: Illegal user (\S*) from (\S+)/)) {
        $ip = $4; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed SSH login from","$ip|$acc","sshd")} else {return}
	}

#Gentoo
	if (($config{LF_SSHD}) and (($lgfile eq "/var/log/messages") or ($lgfile eq "/var/log/secure") or ($globlogs{SSHD_LOG}{$lgfile})) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?sshd\[\d+\]: error: PAM: Authentication failure for (\S*) from (\S+)/)) {
        $ip = $4; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed SSH login from","$ip|$acc","sshd")} else {return}
	}

#courier-imap
	if (($config{LF_POP3D}) and ($globlogs{POP3D_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ pop3d(-ssl)?: LOGIN FAILED, user=(\S*), ip=\[(\S+)\]\s*$/)) {
        $ip = $4; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed POP3 login from","$ip|$acc","pop3d")} else {return}
	}
	if (($config{LF_IMAPD}) and ($globlogs{IMAPD_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ imapd(-ssl)?: LOGIN FAILED, user=(\S*), ip=\[(\S+)\]\s*$/)) {
        $ip = $4; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed IMAP login from","$ip|$acc","imapd")} else {return}
	}

#uw-imap
	if (($config{LF_POP3D}) and ($globlogs{POP3D_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ ipop3d\[\d+\]: Login failed user=(\S*) auth=\S+ host=\S+ \[(\S+)\]\s*$/)) {
        $ip = $3; $acc = $2; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed POP3 login from","$ip|$acc","pop3d")} else {return}
	}
	if (($config{LF_IMAPD}) and ($globlogs{IMAPD_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ imapd\[\d+\]: Login failed user=(\S*) auth=\S+ host=\S+ \[(\S+)\]\s*$/)) {
        $ip = $3; $acc = $2; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed IMAP login from","$ip|$acc","imapd")} else {return}
	}

#dovecot
	if (($config{LF_POP3D}) and ($globlogs{POP3D_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ dovecot(\[\d+\])?: pop3-login: (Aborted login|Disconnected|Disconnected: Inactivity)( \(auth failed, \d+ attempts( in \d+ secs)?\))?: (user=(<\S*>)?, )?method=\S+, rip=(\S+), lip=/)) {
        $ip = $8; $acc = $7; $ip =~ s/^::ffff://; $acc =~ s/^<|>$//g;
		if (checkip(\$ip)) {return ("Failed POP3 login from","$ip|$acc","pop3d")} else {return}
	}
	if (($config{LF_IMAPD}) and ($globlogs{IMAPD_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ dovecot(\[\d+\])?: imap-login: (Aborted login|Disconnected|Disconnected: Inactivity)( \(auth failed, \d+ attempts( in \d+ secs)?\))?: (user=(<\S*>)?, )?method=\S+, rip=(\S+), lip=/)) {
        $ip = $8; $acc = $7; $ip =~ s/^::ffff://; $acc =~ s/^<|>$//g;
		if (checkip(\$ip)) {return ("Failed IMAP login from","$ip|$acc","imapd")} else {return}
	}
	if (($config{LF_POP3D}) and ($globlogs{POP3D_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) pop3-login: Info: (Aborted login|Disconnected|Disconnected: Inactivity)( \(auth failed, \d+ attempts( in \d+ secs)?\))?: (user=(<\S*>)?, )?method=\S+, rip=(\S+), lip=/)) {
        $ip = $7; $acc = $6; $ip =~ s/^::ffff://; $acc =~ s/^<|>$//g;
		if (checkip(\$ip)) {return ("Failed POP3 login from","$ip|$acc","pop3d")} else {return}
	}
	if (($config{LF_IMAPD}) and ($globlogs{IMAPD_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) imap-login: Info: (Aborted login|Disconnected|Disconnected: Inactivity)( \(auth failed, \d+ attempts( in \d+ secs)?\))?: (user=(<\S*>)?, )?method=\S+, rip=(\S+), lip=/)) {
        $ip = $7; $acc = $6; $ip =~ s/^::ffff://; $acc =~ s/^<|>$//g;
		if (checkip(\$ip)) {return ("Failed IMAP login from","$ip|$acc","imapd")} else {return}
	}

#Kerio Mailserver
	if (($config{LF_POP3D}) and ($globlogs{POP3D_LOG}{$lgfile}) and ($line =~ /^\S+ \S+ POP3: User (\S*) doesn\'t exist\. Attempt from IP address (\S+)\s*$/)) {
        $ip = $2; $acc = $1; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed POP3 login from","$ip|$acc","pop3d")} else {return}
	}
	if (($config{LF_POP3D}) and ($globlogs{POP3D_LOG}{$lgfile}) and ($line =~ /^\S+ \S+ POP3: Invalid password for user (\S*)\. Attempt from IP address (\S+)\s*$/)) {
        $ip = $2; $acc = $1; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed POP3 login from","$ip|$acc","pop3d")} else {return}
	}
	if (($config{LF_IMAPD}) and ($globlogs{IMAPD_LOG}{$lgfile}) and ($line =~ /^\S+ \S+ IMAP: User (\S*) doesn\'t exist\. Attempt from IP address (\S+)\s*$/)) {
        $ip = $2; $acc = $1; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed IMAP login from","$ip|$acc","imapd")} else {return}
	}
	if (($config{LF_IMAPD}) and ($globlogs{IMAPD_LOG}{$lgfile}) and ($line =~ /^\S+ \S+ IMAP: Invalid password for user (\S*)\. Attempt from IP address (\S+)\s*$/)) {
        $ip = $2; $acc = $1; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed IMAP login from","$ip|$acc","imapd")} else {return}
	}
	if (($config{LF_SMTPAUTH}) and ($globlogs{SMTPAUTH_LOG}{$lgfile}) and ($line =~ /^\S+ \S+ smtp: User (\S*) doesn\'t exist\. Attempt from IP address (\S+)\s*$/)) {
        $ip = $2; $acc = $1; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed IMAP login from","$ip|$acc","imapd")} else {return}
	}

#pure-ftpd
	if (($config{LF_FTPD}) and ($globlogs{FTPD_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ pure-ftpd: \(\?\@(\S+)\) \[WARNING\] Authentication failed for user \[(\S*)\]/)) {
        $ip = $2; $acc = $3; $ip =~ s/^::ffff://; $ip =~ s/\_/\:/g;
		if (checkip(\$ip)) {return ("Failed FTP login from","$ip|$acc","ftpd")} else {return}
	}

#proftpd
	if (($config{LF_FTPD}) and ($globlogs{FTPD_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ proftpd\[\d+\]:? \S+ \([^\[]+\[(\S+)\]\)( -)?:? - no such user \'(\S*)\'/)) {
        $ip = $2; $acc = $4; $ip =~ s/^::ffff://; $acc =~ s/:$//g;
		if (checkip(\$ip)) {return ("Failed FTP login from","$ip|$acc","ftpd")} else {return}
	}
	if (($config{LF_FTPD}) and ($globlogs{FTPD_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ proftpd\[\d+\]:? \S+ \([^\[]+\[(\S+)\]\)( -)?:? USER (\S*) no such user found from/)) {
        $ip = $2; $acc = $4; $ip =~ s/^::ffff://; $acc =~ s/:$//g;
		if (checkip(\$ip)) {return ("Failed FTP login from","$ip|$acc","ftpd")} else {return}
	}
	if (($config{LF_FTPD}) and ($globlogs{FTPD_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ proftpd\[\d+\]:? \S+ \([^\[]+\[(\S+)\]\)( -)?:? - SECURITY VIOLATION/)) {
        $ip = $2; $acc = ""; $ip =~ s/^::ffff://; $acc =~ s/:$//g;
		if (checkip(\$ip)) {return ("Failed FTP login from","$ip|$acc","ftpd")} else {return}
	}
	if (($config{LF_FTPD}) and ($globlogs{FTPD_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ proftpd\[\d+\]:? \S+ \([^\[]+\[(\S+)\]\)( -)?:? - USER (\S*) \(Login failed\): Incorrect password/)) {
        $ip = $2; $acc = $4; $ip =~ s/^::ffff://; $acc =~ s/:$//g;
		if (checkip(\$ip)) {return ("Failed FTP login from","$ip|$acc","ftpd")} else {return}
	}

#vsftpd
	if (($config{LF_FTPD}) and ($globlogs{FTPD_LOG}{$lgfile}) and ($line =~ /^\S+ \S+ \d+ \S+ \d+ \[pid \d+] \[(\S+)\] FAIL LOGIN: Client "(\S+)"/)) {
        $ip = $2; $acc = $1; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed FTP login from","$ip|$acc","ftpd")} else {return}
	}
	if (($config{LF_FTPD}) and ($globlogs{FTPD_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ vsftpd\[\d+\]: pam_unix\(\S+\): authentication failure; logname=\S*\s+\S+\s+\S+\s+\S+\s+ruser=\S*\s+rhost=(\S+)(\s+user=(\S*))?/)) {
        $ip = $2; $acc = $4; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed FTP login from","$ip|$acc","ftpd")} else {return}
	}
	if (($config{LF_FTPD}) and ($globlogs{FTPD_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ vsftpd\(pam_unix\)\[\d+\]: authentication failure; logname=\S*\s+\S+\s+\S+\s+\S+\s+ruser=\S*\s+rhost=(\S+)(\s+user=(\S*))?/)) {
        $ip = $2; $acc = $4; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed FTP login from","$ip|$acc","ftpd")} else {return}
	}

#apache htaccess
	if (($config{LF_HTACCESS}) and ($globlogs{HTACCESS_LOG}{$lgfile}) and ($line =~ /^\[\S+\s+\S+\s+\S+\s+\S+\s+\S+\] \[(\w*:)?error\] (\[pid \d+(:tid \d+)?\] )?\[client (\S+)\] (\w+: )?user (\S*)(( not found:)|(: authentication failure for))/)) {
        $ip = $4; $acc = $6; $ip =~ s/^::ffff://;
		if (split(/:/,$ip) == 2) {$ip =~ s/:\d+$//}
		if (checkip(\$ip)) {return ("Failed web page login from","$ip|$acc","htpasswd")} else {return}
	}
#nginx
	if (($config{LF_HTACCESS}) and ($globlogs{HTACCESS_LOG}{$lgfile}) and ($line =~ /^\S+ \S+ \[error\] \S+ \*\S+ no user\/password was provided for basic authentication, client: (\S+),/)) {
        $ip = $1; $acc = ""; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed web page login from","$ip|$acc","htpasswd")} else {return}
	}
	if (($config{LF_HTACCESS}) and ($globlogs{HTACCESS_LOG}{$lgfile}) and ($line =~ /^\S+ \S+ \[error\] \S+ \*\S+ user \"(\S*)\": password mismatch, client: (\S+),/)) {
        $ip = $2; $acc = $1; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed web page login from","$ip|$acc","htpasswd")} else {return}
	}
	if (($config{LF_HTACCESS}) and ($globlogs{HTACCESS_LOG}{$lgfile}) and ($line =~ /^\S+ \S+ \[error\] \S+ \*\S+ user \"(\S*)\" was not found in \".*?\", client: (\S+),/)) {
        $ip = $2; $acc = $1; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed web page login from","$ip|$acc","htpasswd")} else {return}
	}

#cxs
	if (($config{LF_CXS}) and ($globlogs{MODSEC_LOG}{$lgfile}) and ($line =~ /^\[\S+\s+\S+\s+\S+\s+\S+\s+\S+\] \[(\w*:)?error\] (\[pid \d+(:tid \d+)?\] )?\[client (\S+)\] (\w+: )?ModSecurity: Access denied with code \d\d\d \(phase 2\)\. File \"[^\"]*\" rejected by the approver script \"\/etc\/cxs\/cxscgi\.sh\"/)) {
        $ip = $4; $acc = ""; $ip =~ s/^::ffff://;
		if (split(/:/,$ip) == 2) {$ip =~ s/:\d+$//}
		if (checkip(\$ip)) {return ("cxs mod_security triggered by","$ip|$acc","cxs")} else {return}
	}

#mod_security v1
	if (($config{LF_MODSEC}) and ($globlogs{MODSEC_LOG}{$lgfile}) and ($line =~ /^\[\S+\s+\S+\s+\S+\s+\S+\s+\S+\] \[error\] \[client (\S+)\] mod_security: Access denied/)) {
        $ip = $1; $acc = ""; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("mod_security triggered by","$ip|$acc","mod_security")} else {return}
	}

#mod_security v2 (apache)
	if (($config{LF_MODSEC}) and ($globlogs{MODSEC_LOG}{$lgfile}) and ($line =~ /^\[\S+\s+\S+\s+\S+\s+\S+\s+\S+\] \[(\w*:)?error\] (\[pid \d+(:tid \d+)?\] )?\[client (\S+)\] (\w+: )?ModSecurity:(( \[[^]]+\])*)? Access denied/)) {
        $ip = $4; $acc = ""; $ip =~ s/^::ffff://;
		if (split(/:/,$ip) == 2) {$ip =~ s/:\d+$//}
		$ruleid = "unknown";
		if ($line =~ /\[id "(\d+)"\]/) {$ruleid = $1}
		if (checkip(\$ip)) {return ("mod_security (id:$ruleid) triggered by","$ip|$acc","mod_security")} else {return}
	}
#mod_security v2 (nginx)
	if (($config{LF_MODSEC}) and ($globlogs{MODSEC_LOG}{$lgfile}) and ($line =~ /^\S+ \S+ \[\S+\] \S+ \[client (\S+)\] ModSecurity:(( \[[^]]+\])*)? Access denied/)) {
        $ip = $1; $acc = ""; $ip =~ s/^::ffff://;
		$ruleid = "unknown";
		if ($line =~ /\[id "(\d+)"\]/) {$ruleid = $1}
		if (checkip(\$ip)) {return ("mod_security (id:$ruleid) triggered by","$ip|$acc","mod_security")} else {return}
	}

#BIND
	if (($config{LF_BIND}) and ($globlogs{BIND_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ named\[\d+\]: client (\S+)\#\d+(\s\(\S+\))?\:( view external\:)? (update|zone transfer|query \(cache\)) \'[^\']*\' denied$/)) {
        $ip = $2; $acc = ""; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("bind triggered by","$ip|$acc","bind")} else {return}
	}

#suhosin
	if (($config{LF_SUHOSIN}) and ($globlogs{SUHOSIN_LOG}{$lgfile})and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ suhosin\[\d+\]: ALERT - .* \(attacker \'(\S+)\'/)) {
		$ip = $2; $acc = ""; $ip =~ s/^::ffff://;
		if ($line !~ /script tried to increase memory_limit/) {
			if (checkip(\$ip)) {return ("Suhosin triggered by","$ip|$acc","suhosin")} else {return}
		}
	}

#cPanel/WHM
	if (($config{LF_CPANEL}) and ($globlogs{CPANEL_LOG}{$lgfile}) and ($line =~ /^\[\S+\s+\S+\s+\S+\] \w+ \[\w+] (\S+) - (\S+) \"[^\"]+\" FAILED LOGIN/)) {
        $ip = $1; $acc = $2; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed cPanel login from","$ip|$acc","cpanel")} else {return}
	}
	if (($config{LF_CPANEL}) and ($globlogs{CPANEL_LOG}{$lgfile}) and ($line =~ /^(\S+) - (\S+)? \[\S+ \S+\] \"[^\"]*\" FAILED LOGIN/)) {
        $ip = $1; $acc = $2; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed cPanel login from","$ip|$acc","cpanel")} else {return}
	}

#webmin
	if (($config{LF_WEBMIN}) and ($globlogs{WEBMIN_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ webmin\[\d+\]: Invalid login as (\S+) from (\S+)/)) {
        $ip = $3; $acc = $2; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed Webmin login from","$ip|$acc","webmin")} else {return}
	}

#DirectAdmin
	if (($config{LF_DIRECTADMIN}) and ($globlogs{DIRECTADMIN_LOG}{$lgfile}) and ($line =~ /^\S+ \'(\S+)\' \d+ (failed login attempts\. Account|failed login attempt on account) \'(\S+)\'/)) {
        $ip = $1; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed DirectAdmin login from","$ip|$acc","directadmin")} else {return}
	}
	if (($config{LF_DIRECTADMIN}) and ($globlogs{DIRECTADMIN_LOG_R}{$lgfile}) and ($line =~ /^\[\S+\s+\S+\s+\S+\]: IMAP Error: Login failed for (\S+) from (\S+)\. AUTHENTICATE PLAIN: Authentication failed\. in \/var\/www\/html\/roundcubemail/)) {
        $ip = $2; $acc = $1; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed DirectAdmin Roundcube login from","$ip|$acc","directadmin")} else {return}
	}
	if (($config{LF_DIRECTADMIN}) and ($globlogs{DIRECTADMIN_LOG_S}{$lgfile}) and ($line =~ /^\S+\s+\S+ \[LOGIN_ERROR\] (\S+)( \(\S+\))? from (\S+): Unknown user or password incorrect\.\s*$/)) {
        $ip = $3; $acc = $1; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed DirectAdmin SquirrelMail login from","$ip|$acc","directadmin")} else {return}
	}
	if (($config{LF_DIRECTADMIN}) and ($globlogs{DIRECTADMIN_LOG_P}{$lgfile}) and ($line =~ /^\S+\s+\S+\s+\S+: pma auth user='(\S+)' status='mysql-denied' ip='(\S+)'\s*$/)) {
        $ip = $2; $acc = $1; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed DirectAdmin phpMyAdmin login from","$ip|$acc","directadmin")} else {return}
	}

#Exim SMTP AUTH
	if (($config{LF_SMTPAUTH}) and ($globlogs{SMTPAUTH_LOG}{$lgfile}) and ($line =~ /^\S+\s+\S+\s+(\[\d+\] )?(\S+) authenticator failed for \S+ (\S+ )?\[(\S+)\](:\S*:?)?( I=\S+| \d+\:)? 535 Incorrect authentication data( \(set_id=(\S+)\))?/)) {
        $ip = $4; $acc = $8; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed SMTP AUTH login from","$ip|$acc","smtpauth")} else {return}
	}

#Exim Syntax Errors
	if (($config{LF_EXIMSYNTAX}) and ($globlogs{SMTPAUTH_LOG}{$lgfile}) and ($line =~ /^\S+\s+\S+\s+(\[\d+\] )?SMTP call from (\S+ )?\[(\S+)\](:\S*:?)?( I=\S+)? dropped: too many syntax or protocol errors/)) {
        $ip = $3; $acc = ""; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Exim syntax errors from","$ip|$acc","eximsyntax")} else {return}
	}

#mod_qos
	if (($config{LF_QOS}) and ($globlogs{HTACCESS_LOG}{$lgfile}) and ($line =~ /^\[\S+\s+\S+\s+\S+\s+\S+\s+\S+\] \[(\w*:)?error\] (\[pid \d+(:tid \d+)?\] )?\[client (\S+)\] (\w+: )?mod_qos\(\d+\): access denied,/)) {
        $ip = $4; $acc = ""; $ip =~ s/^::ffff://;
		if (split(/:/,$ip) == 2) {$ip =~ s/:\d+$//}
		if (checkip(\$ip)) {return ("mod_qos triggered by","$ip|$acc","mod_qos")} else {return}
	}

#Apache symlink race condition
	if (($config{LF_SYMLINK}) and ($globlogs{MODSEC_LOG}{$lgfile}) and ($line =~ /^\[\S+\s+\S+\s+\S+\s+\S+\s+\S+\] \[(\w*:)?error\] (\[pid \d+(:tid \d+)?\] )?\[client (\S+)\] (\w+: )?Caught race condition abuser/)) {
        $ip = $4; $acc = ""; $ip =~ s/^::ffff://;
		if (split(/:/,$ip) == 2) {$ip =~ s/:\d+$//}
		if ($line !~ /\/cgi-sys\/suspendedpage\.cgi$/) {
			if (checkip(\$ip)) {return ("symlink race condition triggered by","$ip|$acc","symlink")} else {return}
		}
	}

#courier-imap (Plesk)
	if (($config{LF_POP3D}) and ($globlogs{POP3D_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ (courier-)?pop3d(-ssl)?: LOGIN FAILED, user=(\S*), ip=\[(\S+)\]\s*$/)) {
		$ip = $5; $acc = $4; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed POP3 login from","$ip|$acc","pop3d")} else {return}
	}
	if (($config{LF_IMAPD}) and ($globlogs{IMAPD_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ (courier-)?imapd(-ssl)?: LOGIN FAILED, user=(\S*), ip=\[(\S+)\]\s*$/)) {
		$ip = $5; $acc = $4; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed IMAP login from","$ip|$acc","imapd")} else {return}
	}

#Qmail SMTP AUTH (Plesk)
	if (($config{LF_SMTPAUTH}) and ($globlogs{SMTPAUTH_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ smtp_auth(?:\[\d+\])?: FAILED: (\S*) - password incorrect from \S+ \[(\S+)\]\s*$/)) {
		$ip = $3; $acc = $2; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed SMTP AUTH login from","$ip|$acc","smtpauth")} else {return}
	}

#Postfix SMTP AUTH (Plesk)
	if (($config{LF_SMTPAUTH}) and ($globlogs{SMTPAUTH_LOG}{$lgfile}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ postfix\/smtpd(?:\[\d+\])?: warning: \S+\[(\S+)\]: SASL (?:LOGIN|PLAIN|(?:CRAM|DIGEST)-MD5) authentication failed/)) {
		$ip = $2; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("Failed SMTP AUTH login from","$ip","smtpauth")} else {return}
	}

}
# end processline
###############################################################################
# start processloginline
sub processloginline {
	my $line = shift;

#courier-imap
	if (($config{LT_POP3D}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ pop3d(-ssl)?: LOGIN, user=(\S*), ip=\[(\S+)\], port=\S+/)) {
        $ip = $4; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("pop3d",$acc,$ip)} else {return}
	}
	if (($config{LT_IMAPD}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ imapd(-ssl)?: LOGIN, user=(\S*), ip=\[(\S+)\], port=\S+/)) {
        $ip = $4; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("imapd",$acc,$ip)} else {return}
	}

#dovecot
	if (($config{LF_POP3D}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ dovecot(\[\d+\])?: pop3-login: Login: user=<(\S*)>, method=\S+, rip=(\S+), lip=/)) {
        $ip = $4; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("pop3d",$acc,$ip)} else {return}
	}
	if (($config{LF_IMAPD}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ dovecot(\[\d+\])?: imap-login: Login: user=<(\S*)>, method=\S+, rip=(\S+), lip=/)) {
        $ip = $4; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ("imapd",$acc,$ip)} else {return}
	}
}
# end processloginline
###############################################################################
# start processsshline
sub processsshline {
	my $line = shift;

	if (($config{LF_SSH_EMAIL_ALERT}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?sshd\[\d+\]: Accepted (\S+) for (\S+) from (\S+) port \S+/)) {
        $ip = $5; $acc = $4; $how = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ($acc,$ip,$how)} else {return}
	}
}
# end processsshline
###############################################################################
# start processsuline
sub processsuline {
	my $line = shift;

#RH + Debian/Ubuntu
	if (($config{LF_SU_EMAIL_ALERT}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?su: pam_unix\(su(-l)?:session\): session opened for user\s+(\S+)\s+by\s+(\S+)\s*$/)) {
		return ($4,$5,"Successful login");
	}
	if (($config{LF_SU_EMAIL_ALERT}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?su: pam_unix\(su(-l)?:auth\): authentication failure; logname=\S*\s+\S+\s+\S+\s+\S+\s+ruser=(\S+)+\s+\S+\s+user=(\S+)\s*$/)) {
		return ($5,$4,"Failed login");
	}

	if (($config{LF_SU_EMAIL_ALERT}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?su\[\d+\]: pam_unix\(su(-l)?:session\): session opened for user\s+(\S+)\s+by\s+(\S+)\s*$/)) {
		return ($4,$5,"Successful login");
	}
	if (($config{LF_SU_EMAIL_ALERT}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?su\[\d+\]: pam_unix\(su(-l)?:auth\): authentication failure; logname=\S*\s+\S+\s+\S+\s+\S+\s+ruser=(\S+)+\s+\S+\s+user=(\S+)\s*$/)) {
		return ($5,$4,"Failed login");
	}

	if (($config{LF_SU_EMAIL_ALERT}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?su\(pam_unix\)\[\d+\]: session opened for user\s+(\S+)\s+by\s+(\S+)\s*$/)) {
		return ($3,$4,"Successful login");
	}
	if (($config{LF_SU_EMAIL_ALERT}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) (\S+ )?su\(pam_unix\)\[\d+\]: authentication failure; logname=\S*\s+\S+\s+\S+\s+\S+\s+ruser=(\S+)+\s+\S+\s+user=(\S+)\s*$/)) {
		return ($4,$3,"Failed login");
	}

}
# end processsuline
###############################################################################
# start processconsoleline
sub processconsoleline {
	my $line = shift;

	if (($config{LF_CONSOLE_EMAIL_ALERT}) and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ login(\[\d+\])?: ROOT LOGIN/)) {
		return 1;
	}
}
# end processconsoleline
###############################################################################
# start processcpanelline
sub processcpanelline {
	my $line = shift;

	if ($config{LF_CPANEL_ALERT} and ($line =~ /^(\S+)\s+\-\s+(\w+)\s+\[[^\]]+\]\s\"[^\"]+\"\s200\s/)) {
        $ip = $1; $acc = $2; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ($ip,$acc)} else {return}
	}
}
# end processcpanelline
###############################################################################
# start processwebminline
sub processwebminline {
	my $line = shift;

	if ($config{LF_WEBMIN_EMAIL_ALERT} and ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ webmin\[\d+\]: Successful login as (\S+) from (\S+)/)) {
        $ip = $3; $acc = $2; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ($acc,$ip)} else {return}
	}
}
# end processwebminline
###############################################################################
# start scriptlinecheck
sub scriptlinecheck {
	my $line = shift;

	if ($config{LF_SCRIPT_ALERT}) {
		my $fulldir;
		if ($line =~ /^\S+\s+\S+\s+(\[\d+\]\s)?cwd=(.*) \d+ args:/) {$fulldir = $2}
		elsif ($line =~ /^\S+\s+\S+\s+(\[\d+\]\s)?\S+ H=localhost (.*)PWD=(.*)  REMOTE_ADDR=\S+$/) {$fulldir = $3}
		if ($fulldir ne "") {
			my (undef,$dir,undef) = split(/\//,$fulldir);
			if ($dir eq "home") {return $fulldir}
			if ($cpconfig{HOMEDIR} and ($fulldir =~ /^$cpconfig{HOMEDIR}/)) {return $fulldir}
			if ($cpconfig{HOMEMATCH} and ($dir =~ /$cpconfig{HOMEMATCH}/)) {return $fulldir}
		}
	}
}
# end scriptlinecheck
###############################################################################
# start relaycheck
sub relaycheck {
	my $line = shift;
	my $tline = $line;
	$tline =~ s/".*"/""/g;
	my @bits =split(/\s+/,$tline);
	my $ip;

	if ($tline !~ /^\S+\s+\S+\s+(\[\d+\]\s)?\S+ <=/) {return}

	if ($tline =~ / U=(\S+) P=local /) {
		return ($1, "LOCALRELAY");
	}

	if ($tline =~ / H=[^=]*\[(\S+)\]/) {
		$ip = $1;
		unless (checkip(\$ip) or $ip eq "127.0.0.1") {return}
	} else {
		return;
	}

	if (($tline =~ / A=(courier_plain|courier_login|dovecot_plain|dovecot_login|fixed_login|fixed_plain|login|plain):/) and ($tline =~ / P=(esmtpa|esmtpsa) /)) {
		return ($ip, "AUTHRELAY");
	}

	if ($tline =~ / P=(smtp|esmtp|esmtps) /) {
		return ($ip, "RELAY");
	}

}
# end relaycheck
###############################################################################
# start pslinecheck
sub pslinecheck {
	my $line = shift;
	if ($line !~ /^(\S+|\S+\s+\d+\s+\S+) \S+ kernel:\s(\[[^\]]+\]\s)?Firewall:/) {return}
	if ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ kernel:\s(\[[^\]]+\]\s)?Firewall: \*INVALID\*/ and $config{PS_PORTS} !~ /INVALID/) {return}

	if ($line =~ /IN=\S+.*SRC=(\S+).*PROTO=(\w+).*DPT=(\d+)/) {
        $ip = $1; $proto = $2; $port = $3; $ip =~ s/^::ffff://;
		if ($config{PS_PORTS} !~ /OPEN/) {
			my $hit = 0;
			if ($proto eq "TCP" and $line =~ /kernel:\s(\[[^\]]+\]\s)?Firewall: \*TCP_IN Blocked\*/) {
				foreach my $ports (split(/\,/,$config{TCP_IN})) {
					if ($ports =~ /\:/) {
						my ($start,$end) = split(/\:/,$ports);
						if ($port >= $start and $port <= $end) {$hit = 1}
					}
					elsif ($port == $ports) {$hit = 1}
					if ($hit) {last}
				}
				if ($hit) {
					if ($config{DEBUG} >= 1) {&logfile("debug: *Port Scan* ignored TCP_IN port: $ip:$port")}
					return;
				}
			}
			elsif ($proto eq "UDP" and $line =~ /kernel:\s(\[[^\]]+\]\s)?Firewall: \*UDP_IN Blocked\*/) {
				foreach my $ports (split(/\,/,$config{UDP_IN})) {
					if ($ports =~ /\:/) {
						my ($start,$end) = split(/\:/,$ports);
						if ($port >= $start and $port <= $end) {$hit = 1}
					}
					elsif ($port == $ports) {$hit = 1}
					if ($hit) {last}
				}
				if ($hit) {
					if ($config{DEBUG} >= 1) {&logfile("debug: *Port Scan* ignored UDP_IN port: $ip:$port")}
					return;
				}
			}
		}
		if (checkip(\$ip)) {return ($ip,$port)} else {return}
	}
	if ($line =~ /IN=\S+.*SRC=(\S+).*PROTO=(ICMP)/) {
        $ip = $1; $port = $2; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ($ip,$port)} else {return}
	}
	if ($line =~ /IN=\S+.*SRC=(\S+).*PROTO=(ICMPv6)/) {
        $ip = $1; $port = $2; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ($ip,$port)} else {return}
	}
}
# end pslinecheck
###############################################################################
# start uidlinecheck
sub uidlinecheck {
	my $line = shift;
	if ($line !~ /^(\S+|\S+\s+\d+\s+\S+) \S+ kernel:\s(\[[^\]]+\]\s)?Firewall:/) {return}
	if ($line =~ /OUT=\S+.*DPT=(\S+).*UID=(\d+)/) {return ($1,$2)}
}
# end uidlinecheck
###############################################################################
# start portknockingcheck
sub portknockingcheck {
	my $line = shift;
	if ($line !~ /^(\S+|\S+\s+\d+\s+\S+) \S+ kernel:\s(\[[^\]]+\]\s)?Knock: \*\d+_IN\*/) {return}

	if ($line =~ /SRC=(\S+).*DPT=(\d+)/) {
        $ip = $1; $port = $2; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ($ip,$port)} else {return}
	}
}
# end portknockingcheck
###############################################################################
# start processdistftpline
sub processdistftpline {
	my $line = shift;
#pure-ftpd
	if ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ pure-ftpd: \(\?\@(\S+)\) \[INFO\] (\S*) is now logged in$/) {
        $ip = $2; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ($ip,$acc)} else {return}
	}
#proftpd
	if ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ proftpd\[\d+\]: \S+ \([^\[]+\[(\S+)\]\) - USER (\S*): Login successful\.\s*$/) {
        $ip = $2; $acc = $3; $ip =~ s/^::ffff://;
		if (checkip(\$ip)) {return ($ip,$acc)} else {return}
	}
}
# end processdistftpline
###############################################################################
# start processdistsmtpline
sub processdistsmtpline {
	my $line = shift;
	my $tline = $line;
	$tline =~ s/".*"/""/g;
	my @bits =split(/\s+/,$tline);
	my $ip;

	if ($tline !~ /^\S+\s+\S+\s+(\[\d+\]\s)?\S+ <=/) {return}

	if ($tline =~ / U=(\S+) P=local /) {return}

	if ($tline =~ / H=[^=]*\[(\S+)\]/) {
		$ip = $1;
		unless (checkip(\$ip) or $ip eq "127.0.0.1") {return}
	} else {
		return;
	}

	if (($tline =~ / A=(courier_plain|courier_login|dovecot_plain|dovecot_login|fixed_login|fixed_plain|login|plain):(\S+)/)){
		my $account = $2;
		if (($tline =~ / P=(esmtpa|esmtpsa) /)) {return ($ip, $account)}
	}
}
# end processdistsmtpline
###############################################################################
# start loginline404
sub loginline404 {
	my $line = shift;
	if ($line =~ /^\[\S+\s+\S+\s+\S+\s+\S+\s+\S+\] \[(\w*:)?error\] (\[pid \d+(:tid \d+)?\] )?\[client (\S+)\] (\w+: )?File does not exist\:/) {
        $ip = $4; $ip =~ s/^::ffff://;
		if (split(/:/,$ip) == 2) {$ip =~ s/:\d+$//}
		if (checkip(\$ip)) {return ($ip)} else {return}
	}
}
# end loginline404
###############################################################################
# start loginline403
sub loginline403 {
	my $line = shift;
	if ($line =~ /^\[\S+\s+\S+\s+\S+\s+\S+\s+\S+\] \[(\w*:)?error\] (\[pid \d+(:tid \d+)?\] )?\[client (\S+)\] (\w+: )?client denied by server configuration\:/) {
        $ip = $4; $ip =~ s/^::ffff://;
		if (split(/:/,$ip) == 2) {$ip =~ s/:\d+$//}
		if (checkip(\$ip)) {return ($ip)} else {return}
	}
}
# end loginline403
###############################################################################
# start statscheck
sub statscheck {
	my $line = shift;
	if ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ kernel:\s(\[[^\]]+\]\s)?(Firewall|Knock):/) {return 1}
}
# end statscheck
###############################################################################
# start syslogcheckline
sub syslogcheckline {
	my $line = shift;
	if ($line =~ /^(\S+|\S+\s+\d+\s+\S+) \S+ lfd\[\d+\]: SYSLOG check \[(\S+)\]\s*$/) {
		if ($2 eq $syslogcheckcode) {return 1} else {return}
	}
}
# end syslogcheckline
###############################################################################

1;
