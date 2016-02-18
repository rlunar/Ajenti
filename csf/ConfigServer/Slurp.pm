###############################################################################
# Copyright 2006-2016, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
# start main
package ConfigServer::Slurp;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);
use Carp;

BEGIN {
	require Exporter;
	our $VERSION     = 1.01;
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw(slurp);
	our @EXPORT_OK   = qw();
}

our $slurpreg = qr/(?>\x0D\x0A?|[\x0A-\x0C\x85\x{2028}\x{2029}])/;
our $cleanreg = qr/(\r)|(\n)|(^\s+)|(\s+$)/;

# end main
###############################################################################
# start slurp
sub slurp {
	my $file = shift;
	if (-e $file) {
		sysopen (FILE, $file, O_RDONLY) or carp "*Error* Unable to open [$file]: $!";
		flock (FILE, LOCK_SH) or carp "*Error* Unable to lock [$file]: $!";
		my $text = do {local $/; <FILE>};
		close (FILE);
		return split(/$slurpreg/,$text);
	} else {
		carp "*Error* File does not exist: [$file]";
	}
}
# end slurp
###############################################################################
# start slurpreg
sub slurpreg {
	return $slurpreg;
}
# end slurpreg
###############################################################################
# start cleanreg
sub cleanreg {
	return $cleanreg;
}
# end cleanreg
###############################################################################

1;