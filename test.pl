#!/usr/bin/perl

# setting the paths; the input value prvides the base path otherwise derived from File::Basename

use lib qw(/Library/WebServer/cgi-bin);
use PG;
use geometa;

my %args 							=		@ARGV;

$args{pgV}						=		setValueDefaults();
$args{pgP}						=		pgSetPaths(LOC_ROOT =>	'/Library/WebServer/Documents');

%args									=		pgModifyArgs(%args);

pgGEOmetaGSM(\%args);

1;
