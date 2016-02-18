###############################################################################
# Copyright 2006-2016, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
# start main
package ConfigServer::RBLCheck;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);
use ConfigServer::Config;
use ConfigServer::CheckIP;
use ConfigServer::Slurp;
use ConfigServer::GetIPs;
use ConfigServer::RBLLookup;
use IPC::Open3;
use Net::IP;

BEGIN {
	require Exporter;
	our $VERSION     = 1.00;
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw();
	our @EXPORT_OK   = qw();
}

my ($ui, $failures, $verbose, $cleanreg, $status, %ips, $images, %config,
	$ipresult, $output);

my $ipv4reg = ConfigServer::Config->ipv4reg;
my $ipv6reg = ConfigServer::Config->ipv6reg;

# end main
###############################################################################
# start report
sub report {
	$verbose = shift;
	$images = shift;
	$ui = shift;
	my $config = ConfigServer::Config->loadconfig();
	%config = $config->config();
	$cleanreg = ConfigServer::Slurp->cleanreg;
	$failures = 0;

	$| = 1;

	&startoutput;

	&getethdev;

	my @RBLS = slurp("/usr/local/csf/lib/csf.rbls");

	if (-e "/etc/csf/csf.rblconf") {
		foreach my $line (slurp("/etc/csf/csf.rblconf")) {
			if ($line =~ /^enablerbl:(.*)$/) {
				push @RBLS, $1;
			}
			elsif ($line =~ /^disablerbl:(.*)$/) {
				my $hit = $1;
				for (0..@RBLS) {
					my $x = $_;
					my ($rbl,$rblurl) = split(/:/,$RBLS[$x],2);
					if ($rbl eq $hit) {$RBLS[$x] = ""}
				}
			}
			if ($line =~ /^enableip:(.*)$/) {
				if (checkip(\$1)) {$ips{$1} = 1}
			}
			elsif ($line =~ /^disableip:(.*)$/) {
				if (checkip(\$1)) {delete $ips{$1}}
			}
		}
	}
	@RBLS = sort @RBLS;

	foreach my $ip (sort keys %ips) {
		my $netip = new Net::IP ($ip);
		my $type = $netip->iptype();
		if ($type eq "PUBLIC") {

			if ($verbose and -e "/var/lib/csf/${ip}.rbls") {
				unlink "/var/lib/csf/${ip}.rbls";
			}

			if (-e "/var/lib/csf/${ip}.rbls") {
				my $text = join("\n",slurp("/var/lib/csf/${ip}.rbls"));
				if ($ui) {print $text} else {$output .= $text}
			} else {
				if ($verbose) {
					$ipresult = "";
					my $hits = 0;
					&addtitle("Checked $ip ($type) on ".localtime());

					foreach my $line (@RBLS) {
						my ($rbl,$rblurl) = split(/:/,$line,2);
						if ($rbl eq "") {next}

						my ($rblhit,$rbltxt)  = rbllookup($ip,$rbl);
						my @tmptxt = $rbltxt;
						$rbltxt = "";
						foreach my $line (@tmptxt) {
							$line =~ s/(http(\S+))/<a target="_blank" href="$1">$1<\/a>/g;
							$rbltxt .= "${line}\n";
						}
						$rbltxt =~ s/\n/<br>\n/g;

						if ($rblhit eq "timeout") {
							&addline(0,$rbl,$rblurl,"TIMEOUT");
						}
						elsif ($rblhit eq "") {
							if ($verbose == 2) {
								&addline(0,$rbl,$rblurl,"OK");
							}
						}
						else {
							&addline(1,$rbl,$rblurl,$rbltxt);
							$hits++;
						}
					}
					unless ($hits) {
						my $text;
						$text .= "<tr><td colspan='2' class='section-full'>OK</td></tr>\n";
						$text .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
						if ($ui) {print $text} else {$output .= $text}
						$ipresult .= $text;
					}
					sysopen (OUT, "/var/lib/csf/${ip}.rbls", O_WRONLY | O_CREAT);
					flock(OUT, LOCK_EX);
					print OUT $ipresult;
					close (OUT);
				} else {
					&addtitle("New $ip ($type)");
					my $text;
					$text .= "<tr><td colspan='2' class='section-warning'>NOT CHECKED</td></tr>\n";
					$text .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
					if ($ui) {print $text} else {$output .= $text}
				}
			}
		} else {
			if ($verbose == 2) {
				&addtitle("Skipping $ip ($type)");
				my $text;
				$text .= "<tr><td colspan='2' class='section-full'>OK</td></tr>\n";
				$text .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
				if ($ui) {print $text} else {$output .= $text}
			}
		}
	}
	&endoutput;

	return ($failures,$output);
}
# end report
###############################################################################
# start startoutput
sub startoutput {
	my $text = <<EOF;
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
<table align='center' width='95%' cellspacing='0'>
EOF
	if ($ui) {print $text} else {$output .= $text}
}
# end startoutput
###############################################################################
# start addline
sub addline {
	my $status = shift;
	my $rbl = shift;
	my $rblurl = shift;
	my $comment = shift;
	my $text;
	my $check = $rbl;
	if ($rblurl ne "") {$check = "<a href='$rblurl' target='_blank'>$rbl</a>"}

	if ($status) {
		$text .= "<tr>\n";
		$text .= "<td class='section-warning'>$check</td>\n";
		$text .= "<td class='section-comment'>$comment</td>\n";
		$text .= "</tr>\n";
		$text .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
		$failures ++;
		$ipresult .= $text;
	}
	elsif ($verbose) {
		$text .= "<tr>\n";
		$text .= "<td class='section-ok'>$check</td>\n";
		$text .= "<td class='section-comment'>$comment</td>\n";
		$text .= "</tr>\n";
		$text .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
	}
	if ($ui) {print $text} else {$output .= $text}
}
# end addline
###############################################################################
# start addtitle
sub addtitle {
	my $title = shift;
	my $text;

	$text .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
	$text .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";
	$text .= "<tr><td class='section-title' colspan='2'>$title</td></tr>\n";
	$text .= "<tr><td colspan='2' class='section-gap'>&nbsp;</td></tr>\n";

	$ipresult .= $text;
	if ($ui) {print $text} else {$output .= $text}
}
# end addtitle
###############################################################################
# start endoutput
sub endoutput {
	if ($ui) {print "</table><br>\n"} else {$output .= "</table><br>\n"}
}
# end endoutput
###############################################################################
# start getethdev
sub getethdev {
	my ($childin, $childout);
	my $cmdpid = open3($childin, $childout, $childout, $config{IFCONFIG});
	my @ifconfig = <$childout>;
	waitpid ($cmdpid, 0);
	chomp @ifconfig;
	foreach my $line (@ifconfig) {
		if ($line =~ /inet.*?($ipv4reg)/) {
			my $ip = $1;
			if (checkip(\$ip)) {$ips{$ip} = 1}
		}
#		if ($config{IPV6} and $line =~ /inet6.*?($ipv6reg)/) {
#			my ($ip,undef) = split(/\//,$1);
#			$ip .= "/128";
#			if (checkip(\$ip)) {
#				eval {
#					local $SIG{__DIE__} = undef;
#					$ipscidr6->add($ip);
#				};
#			}
#		}
	}
}
# end getethdev
###############################################################################

1;
