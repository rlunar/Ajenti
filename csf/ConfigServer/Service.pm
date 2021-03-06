###############################################################################
# Copyright 2006-2016, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
# start main
package ConfigServer::Service;

use strict;
use lib '/usr/local/csf/lib';
use Carp;
use IPC::Open3;
use ConfigServer::Config;

BEGIN {
	require Exporter;
	our $VERSION     = 1.00;
	our @ISA         = qw();
	our @EXPORT      = qw();
	our @EXPORT_OK   = qw();
}

my $config = ConfigServer::Config->loadconfig();
my %config = $config->config();

open (IN, "<", "/proc/1/comm");
my $sysinit = <IN>;
close (IN);
chomp $sysinit;
if ($sysinit ne "systemd") {$sysinit = "init"}

# end main
###############################################################################
# start type
sub type {
	return $sysinit;
}
# end type
###############################################################################
# start startlfd
sub startlfd {
	if ($sysinit eq "systemd") {
		&printcmd($config{SYSTEMCTL},"start","lfd.service");
		&printcmd($config{SYSTEMCTL},"status","lfd.service");
	} else {
		&printcmd("/etc/init.d/lfd","start");
	}
}
# end startlfd
###############################################################################
# start stoplfd
sub stoplfd {
	if ($sysinit eq "systemd") {
		&printcmd($config{SYSTEMCTL},"stop","lfd.service");
	}
	else {
		&printcmd("/etc/init.d/lfd","stop");
	}
}
# end stoplfd
###############################################################################
# start restartlfd
sub restartlfd {
	if ($sysinit eq "systemd") {
		&printcmd($config{SYSTEMCTL},"restart","lfd.service");
		&printcmd($config{SYSTEMCTL},"status","lfd.service");
	}
	else {
		&printcmd("/etc/init.d/lfd","restart");
	}
}
# end restartlfd
###############################################################################
# start restartlfd
sub statuslfd {
	if ($sysinit eq "systemd") {
		&printcmd($config{SYSTEMCTL},"status","lfd.service");
	}
	else {
		&printcmd("/etc/init.d/lfd","status");
	}

	return 0
}
# end restartlfd
###############################################################################
# start printcmd
sub printcmd {
	my ($childin, $childout);
	my $pid = open3($childin, $childout, $childout, @_);
	while (<$childout>) {print $_}
	waitpid ($pid, 0);
}
# end printcmd
###############################################################################

1;