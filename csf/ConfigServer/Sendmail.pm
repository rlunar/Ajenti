###############################################################################
# Copyright 2006-2016, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
# start main
package ConfigServer::Sendmail;

use strict;
use lib '/usr/local/csf/lib';
use Carp;
use POSIX qw(strftime);
use ConfigServer::Config;

BEGIN {
	require Exporter;
	our $VERSION     = 1.01;
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw(sendmail);
	our @EXPORT_OK   = qw();
}

my $config = ConfigServer::Config->loadconfig();
my %config = $config->config();
my $tz = strftime("%z", localtime);
my $hostname;
if (-e "/proc/sys/kernel/hostname") {
	open (IN, "</proc/sys/kernel/hostname");
	$hostname = <IN>;
	chomp $hostname;
	close (IN);
} else {
	$hostname = "unknown";
}

# end main
###############################################################################
# start sendmail
sub sendmail {
	my $from = shift;
	my $to = shift;
	my @message = @_;
	my $time = localtime(time);
	my $data;

	if ($from =~ /([\w\.\=\-\_]+\@[\w\.\-\_]+)/) {$from = $1}
	if ($from eq "") {$from = "root"}
	if ($to =~ /([\w\.\=\-\_]+\@[\w\.\-\_]+)/) {$to = $1}
	if ($to eq "") {$to = "root"}

	my $header = 1;
	foreach my $line (@message) {
		chomp $line;
		$line =~ s/\r//;
		if ($line eq "") {$header = 0}
		$line =~ s/\[time\]/$time $tz/ig;
		$line =~ s/\[hostname\]/$hostname/ig;
		if ($header) {
			if ($line =~ /^To:(.*)$/i) {
				$line =~ s/^To:.*$/To: $to/i;
			}
			if ($line =~ /^From:(.*)$/i) {
				$line =~ s/^From:.*$/From: $from/i;
			}
		}
		$data .= $line."\n";
	}

	if ($config{LF_ALERT_SMTP}) {
		if ($from !~ /\@/) {$from .= '@'.$hostname}
		if ($to !~ /\@/) {$to .= '@'.$hostname}
		my $smtp = Net::SMTP->new($config{LF_ALERT_SMTP}, Timeout => 10) or croak ("*Error* Unable to send SMTP alert via [$config{LF_ALERT_SMTP}]: $!");
		if (defined $smtp) {
			$smtp->mail($from);
			$smtp->to($to);
			$smtp->data();
			$smtp->datasend($data);
			$smtp->dataend();
			$smtp->quit();
		}
	} else {
		local $SIG{CHLD} = 'DEFAULT';
		open (MAIL, "|$config{SENDMAIL} -f $from -t") or croak ("*Error* Unable to send SENDMAIL alert via [$config{SENDMAIL}]: $!");
		print MAIL $data;
		close (MAIL);
	}

	return;
}
# end sendmail
###############################################################################

1;