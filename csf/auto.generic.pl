#!/usr/bin/perl
###############################################################################
# Copyright 2006-2016, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
use strict;
use Fcntl qw(:DEFAULT :flock);
use IPC::Open3;

umask(0177);

our (%config, %configsetting, $vps);

open (VERSION, "<","/etc/csf/version.txt");
my $version = <VERSION>;
close (VERSION);
chomp $version;
$version =~ s/\W/_/g;
system("/bin/cp","-avf","/etc/csf/csf.conf","/var/lib/csf/backup/".time."_pre_v${version}_upgrade");

&loadcsfconfig;

if (-e "/proc/vz/veinfo") {
	$vps = 1;
} else {
	open (IN, "<","/proc/self/status"); 
	foreach my $line (<IN>) {
		chomp $line;
		if ($line =~ /^envID:\s*(\d+)\s*$/) {
			if ($1 > 0) {
				$vps = 1;
				last;
			}
		}
	}
	close (IN);
}

#if (-d "/usr/local/cwpsrv/") {
#	sysopen (IN,"/usr/local/cwpsrv/htdocs/resources/admin/include/3rdparty.php", O_RDWR | O_CREAT);
#	flock (IN, LOCK_EX);
#	my @data = <IN>;
#	chomp @data;
#	seek (IN, 0, 0);
#	truncate (IN, 0);
#	my $hit = 0;
#	foreach my $line (@data) {
#		if ($line =~ /cwp_csf_r/) {$hit = 1}
#		print IN "$line\n";
#	}
#	unless ($hit) {print IN "<li><a href=\"index.php?module=cwp_csf_r\"><span class=\"icon16 icomoon-icon-arrow-right-3\"></span>Official csf UI</a></li>\n"}
#	close (IN);
#
#
## Need to add port 2030 and 2030 to TCP_IN if first time installing
#
#}

if (-e "/etc/csf/csf.blocklists") {
	sysopen (IN,"/etc/csf/csf.blocklists", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($line =~ /feeds\.dshield\.org/) {$line =~ s/feeds\.dshield\.org/www\.dshield\.org/g}
		if ($line =~ /openbl\.org/) {$line =~ s/http\:\/\/www\.openbl\.org/https\:\/\/www\.openbl\.org/g}
		if ($line =~ /openbl\.org/) {$line =~ s/http(s)?\:\/\/www\.us\.openbl\.org/https\:\/\/www\.openbl\.org/g}
		print IN "$line\n";
	}
	close (IN);
}
if (-e "/var/lib/csf/csf.tempban") {
	sysopen (IN,"/var/lib/csf/csf.tempban", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($line =~ /^\d+\:/) {$line =~ s/\:/\|/g}
		print IN "$line\n";
	}
	close (IN);
}
if (-e "/var/lib/csf/csf.tempallow") {
	sysopen (IN,"/var/lib/csf/csf.tempallow", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($line =~ /^\d+\:/) {$line =~ s/\:/\|/g}
		print IN "$line\n";
	}
	close (IN);
}

if ($config{TESTING}) {

	open (IN, "</etc/ssh/sshd_config") or die $!;
	flock (IN, LOCK_SH) or die $!;
	my @sshconfig = <IN>;
	close (IN);
	chomp @sshconfig;

	my $sshport = "22";
	foreach my $line (@sshconfig) {
		if ($line =~ /^Port (\d+)/) {$sshport = $1}
	}

	$config{TCP_IN} =~ s/\s//g;
	if ($config{TCP_IN} ne "") {
		foreach my $port (split(/\,/,$config{TCP_IN})) {
			if ($port eq $sshport) {$sshport = "22"}
		}
	}

	if ($sshport ne "22") {
		$config{TCP_IN} .= ",$sshport";
		$config{TCP6_IN} .= ",$sshport";
		open (IN, "</etc/csf/csf.conf") or die $!;
		flock (IN, LOCK_SH) or die $!;
		my @config = <IN>;
		close (IN);
		chomp @config;
		open (OUT, ">/etc/csf/csf.conf") or die $!;
		flock (OUT, LOCK_EX) or die $!;
		foreach my $line (@config) {
			if ($line =~ /^TCP6_IN/) {
				print OUT "TCP6_IN = \"$config{TCP6_IN}\"\n";
				print "\n*** SSH port $sshport added to the TCP6_IN port list\n\n";
			}
			elsif ($line =~ /^TCP_IN/) {
				print OUT "TCP_IN = \"$config{TCP_IN}\"\n";
				print "\n*** SSH port $sshport added to the TCP_IN port list\n\n";
			}
			else {
				print OUT $line."\n";
			}
		}
		close OUT;
		&loadcsfconfig;

	}

	open (FH, "<", "/proc/sys/kernel/osrelease");
	my @data = <FH>;
	close (FH);
	chomp @data;
	if ($data[0] =~ /^(\d+)\.(\d+)\.(\d+)/) {
		my $maj = $1;
		my $mid = $2;
		my $min = $3;
		if ($maj == 3 and $mid > 6) {
			open (IN, "</etc/csf/csf.conf") or die $!;
			flock (IN, LOCK_SH) or die $!;
			my @config = <IN>;
			close (IN);
			chomp @config;
			open (OUT, ">/etc/csf/csf.conf") or die $!;
			flock (OUT, LOCK_EX) or die $!;
			foreach my $line (@config) {
				if ($line =~ /^USE_CONNTRACK =/) {
					print OUT "USE_CONNTRACK = \"1\"\n";
					print "\n*** USE_CONNTRACK Enabled\n\n";
				} else {
					print OUT $line."\n";
				}
			}
			close OUT;
			&loadcsfconfig;
		}
	}

	if (-e $config{IP6TABLES} and !$vps) {
		my ($childin, $childout);
		my $cmdpid = open3($childin, $childout, $childout, $config{IFCONFIG});
		my @ifconfig = <$childout>;
		waitpid ($cmdpid, 0);
		chomp @ifconfig;
		if (grep {$_ =~ /^\s*inet6/} @ifconfig) {
			$config{IPV6} = 1;
			open (FH, "<", "/proc/sys/kernel/osrelease");
			my @data = <FH>;
			close (FH);
			chomp @data;
			if ($data[0] =~ /^(\d+)\.(\d+)\.(\d+)/) {
				my $maj = $1;
				my $mid = $2;
				my $min = $3;
				if (($maj > 2) or (($maj > 1) and ($mid > 6)) or (($maj > 1) and ($mid > 5) and ($min > 19))) {
					$config{IPV6_SPI} = 1;
				} else {
					$config{IPV6_SPI} = 0;
				}
			}
			open (IN, "</etc/csf/csf.conf") or die $!;
			flock (IN, LOCK_SH) or die $!;
			my @config = <IN>;
			close (IN);
			chomp @config;
			open (OUT, ">/etc/csf/csf.conf") or die $!;
			flock (OUT, LOCK_EX) or die $!;
			foreach my $line (@config) {
				if ($line =~ /^IPV6 =/) {
					print OUT "IPV6 = \"$config{IPV6}\"\n";
					print "\n*** IPV6 Enabled\n\n";
				}
				elsif ($line =~ /^IPV6_SPI =/) {
					print OUT "IPV6_SPI = \"$config{IPV6_SPI}\"\n";
					print "\n*** IPV6_SPI set to $config{IPV6_SPI}\n\n";
				} else {
					print OUT $line."\n";
				}
			}
			close OUT;
			&loadcsfconfig;
		}
	}
}

open (IN, "<csf.generic.conf") or die $!;
flock (IN, LOCK_SH) or die $!;
my @config = <IN>;
close (IN);
chomp @config;
open (OUT, ">/etc/csf/csf.conf") or die $!;
flock (OUT, LOCK_EX) or die $!;
foreach my $line (@config) {
	if ($line =~ /^\#/) {
		print OUT $line."\n";
		next;
	}
	if ($line !~ /=/) {
		print OUT $line."\n";
		next;
	}
	my ($name,$value) = split (/=/,$line,2);
	$name =~ s/\s//g;
	if ($value =~ /\"(.*)\"/) {
		$value = $1;
	} else {
		print "Error: Invalid configuration line [$line]";
	}
	if ($configsetting{$name}) {
		print OUT "$name = \"$config{$name}\"\n";
	} else {
		print OUT $line."\n";
		print "New setting: $name\n";
	}
}
close OUT;

if ($config{TESTING}) {
	my @netstat = `netstat -lpn`;
	chomp @netstat;
	my @tcpports;
	my @udpports;
	my @tcp6ports;
	my @udp6ports;
	foreach my $line (@netstat) {
		if ($line =~ /^(\w+).* (\d+\.\d+\.\d+\.\d+):(\d+)/) {
			if ($2 eq '127.0.0.1') {next}
			if ($1 eq "tcp") {
				push @tcpports, $3;
			}
			elsif ($1 eq "udp") {
				push @udpports, $3;
			}
		}
		if ($line =~ /^(\w+).* (::):(\d+) /) {
			if ($1 eq "tcp") {
				push @tcp6ports, $3;
			}
			elsif ($1 eq "udp") {
				push @udp6ports, $3;
			}
		}
	}

	@tcpports = sort { $a <=> $b } @tcpports;
	@udpports = sort { $a <=> $b } @udpports;
	@tcp6ports = sort { $a <=> $b } @tcp6ports;
	@udp6ports = sort { $a <=> $b } @udp6ports;

	print "\nTCP ports currently listening for incoming connections:\n";
	my $last = "";
	foreach my $port (@tcpports) {
		if ($port ne $last) {
			if ($port ne $tcpports[0]) {print ","}
			print $port;
			$last = $port;
		}
	}
	print "\n\nUDP ports currently listening for incoming connections:\n";
	$last = "";
	foreach my $port (@udpports) {
		if ($port ne $last) {
			if ($port ne $udpports[0]) {print ","}
			print $port;
			$last = $port;
		}
	}
	my $opts = "TCP_*, UDP_*";
	if (@tcp6ports or @udp6ports) {
		$opts .= ", IPV6, TCP6_*, UDP6_*";
		print "\n\nIPv6 TCP ports currently listening for incoming connections:\n";
		my $last = "";
		foreach my $port (@tcp6ports) {
			if ($port ne $last) {
				if ($port ne $tcp6ports[0]) {print ","}
				print $port;
				$last = $port;
			}
		}
		print "\n";
		print "\nIPv6 UDP ports currently listening for incoming connections:\n";
		$last = "";
		foreach my $port (@udp6ports) {
			if ($port ne $last) {
				if ($port ne $udp6ports[0]) {print ","}
				print $port;
				$last = $port;
			}
		}
	}
	print "\n\nNote: The port details above are for information only, csf hasn't been auto-configured.\n\n";
	print "Don't forget to:\n";
	print "1. Configure the following options in the csf configuration to suite your server: $opts\n";
	print "2. Restart csf and lfd\n";
	print "3. Set TESTING to 0 once you're happy with the firewall, lfd will not run until you do so\n";
}

if ($ENV{SSH_CLIENT}) {
	my $ip = (split(/ /,$ENV{SSH_CLIENT}))[0];
	if ($ip =~ /(\d+\.\d+\.\d+\.\d+)/) {
		print "\nAdding current SSH session IP address to the csf whitelist in csf.allow:\n";
		system("/usr/sbin/csf -a $1 csf SSH installation/upgrade IP address");
	}
}

exit;
###############################################################################
sub loadcsfconfig {
	open (IN, "</etc/csf/csf.conf") or die $!;
	flock (IN, LOCK_SH) or die $!;
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
			print "Error: Invalid configuration line [$line]";
		}
		$config{$name} = $value;
		$configsetting{$name} = 1;
	}
}
###############################################################################
