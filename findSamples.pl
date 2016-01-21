# Script that downloads all the samples that are not in Arraymap.
# In order to do that we download all the samples, series and samples that are
# already in Arraymap. After that, we download all the samples related to the
# platform that are in Arraymap and we check which of those are not in Arraymap.

#!/usr/bin/perl

=pod

perl findSamples.pl -randno 200 -randpf 3 -metaroot /Volumes/arrayRAID/arraymapIn/GEOmeta -dataroot /Volumes/arrayRAID/arraymapIn/GEOupdate

=cut

use lib qw(/Library/WebServer/cgi-bin);
use PG;
use geometa;

use File::Fetch;
use Net::FTP;
use Archive::Tar;
use IO::Handle;
STDOUT->autoflush(1);

print "\n--------------------------------------------------------------------\n";
print "FIND THE SAMPLES/SERIES/PLATTFORMS IN ARRAYMAP.\n";
print "--------------------------------------------------------------------\n\n";

my $start_time = [Time::HiRes::gettimeofday()];

#******** 1. set up for downloading from Arraymap

my %args              =   @ARGV;

$args{ LOC_USERID }   =   getlogin();
$args{ LOC_ROOT }     =   '/Library/WebServer/Documents';

$args{pgP}            =   pgSetPaths(%args);
$args{pgV}            =   setValueDefaults();
%args                 =	  pgModifyArgs(%args);

$args{ '-dataroot' }  //=	'/Users/'.$args{ LOC_USERID }.'/Desktop/GEOupdate';
$args{ '-metaroot' }  //=	'/Users/'.$args{ LOC_USERID }.'/Desktop/GEOmeta';

################################################################################

mkdir $args{ '-dataroot' };
mkdir $args{ '-metaroot' };

################################################################################

my $mongosamples      =   pgGetMongoCursor(
                           %args,
                           MDB      => 'arraymap',
                           MDBCOLL  => 'samples',
                           QUERY    => {},
                           FIELDS   => [ qw(UID PLATFORMID SERIESID) ]
                          );

#******** 2. download samples/plattforms and series in Arraymap

print "download all the platforms...";
my @arraymap_platforms =  map{ $_->{ PLATFORMID } }	(grep{ $_->{ PLATFORMID } =~ /GPL/ } @{ $mongosamples });
@arraymap_platforms   =   uniq(@arraymap_platforms);
print "done: ".scalar(@arraymap_platforms)." platforms found. \n";

if ($args{ '-randpf' } > 0) {

  @arraymap_platforms =   shuffle(@arraymap_platforms);
  @arraymap_platforms =   splice(@arraymap_platforms, 0, $args{ '-randpf' });

}

print "-randpf: ".scalar(@arraymap_platforms)." platforms will be used. \n";

# print "download all the series...";
# my %arraymap_series = map{ $_->{ SERIESID } => 1 } (grep{ $_->{ SERIESID } =~ /GSE/ } @{ $mongosamples });
# @arraymap_series = keys %arraymap_series;
# $size = @arraymap_series;
# print "done: $size series found. \n";

print "get all arrayMap sampleids...";
my %arraymap_samples = map{ $_->{ UID } => 1 } (grep{ $_->{ UID } =~ /GSM/ } @{ $mongosamples });
@arraymap_samples = keys %arraymap_samples;
$size = @arraymap_samples;
print "done: $size samples found. \n\n";

# TODO: execution time => helper sub

# calculate the time needed for the download and printing it
my $diff = Time::HiRes::tv_interval($start_time);
print sprintf("Execution time: %.1f seconds\n", $diff);

###############################################################################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############################################################################
#~~~~~~~~~~~~
#############                           PART 2
#~~~~~~~~~~~~
###############################################################################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############################################################################

print "\n--------------------------------------------------------------------\n";
print "FIND THE SAMPLES THAT ARE NOT IN ARRAYMAP.\n";
print "--------------------------------------------------------------------\n\n";

$start_time           =   [Time::HiRes::gettimeofday()];

use LWP::Simple;

my $n_sample          =   0; # total number of samples

######### print information
print "download the samples in GEO and check which one are already in arraymap...\n";
print "number of platform: ".(scalar keys %arraymap_platforms)."\n";
print "\n0\% |---------------------------| 100\%\n    ";

# variables for printing the progress bar
my $perc              =   $size/30;
my $add               =   $perc;
my $contt             =   0;
my $sampleLogFile     =   $args{ '-dataroot' }."/new_samples.txt";

open(my $fh, '>', $sampleLogFile) or die "Could not open file '$sampleLogFile' $!";

foreach my $plat (sort @arraymap_platforms){

	my $url             =   "http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=$plat&targ=self&view=brief&form=text";
	my $GSMlist         =   [ grep{/GSM\d+/} split(/[\n\r]/,get($url))];

	foreach my $sample (@$GSMlist){

	    my $gsm_id      =   substr("$sample",22);

			if (! any { $gsm_id eq $_ } @arraymap_samples) {

        print $fh "$plat\t$gsm_id\n";
				$n_sample++;
        push @{ $args{GSMLIST} }, $gsm_id;

	}}

  #printing the progress bar
  $contt++;

  if ($contt > $add-1){

		$add              =   $add + $perc + 1;
		print "@";

}}

close $fh;

# calculate the time needed for the download and printing it
$diff                 =   Time::HiRes::tv_interval($start_time);
$mins                 =   $diff/60;
$hours                =   $mins/60;
print sprintf("\n\nExecution time: %.0f minutes (%.1f hours)\n", $mins, $hours);
print "\nnumber of new samples: $n_sample \n\n";

# metadata => GSM soft file download & file structure

print "\n--------------------------------------------------------------------\n";
print "DOWNLOAD OF THE GSM METADATA FILES.\n";
print "--------------------------------------------------------------------\n\n";

$start_time           =   [Time::HiRes::gettimeofday()];

if ($args{ '-randno' }) {

  $args{GSMLIST}	    =   [ shuffle(@{ $args{GSMLIST} }) ];
  $args{GSMLIST} 	    =   [ splice(@{ $args{GSMLIST} }, 0, $args{ '-randno' }) ];

}
_d(scalar(@{ $args{GSMLIST} }), 'GSM soft files will be retrieved');
pgGEOmetaGSM(\%args);

$diff                 =   Time::HiRes::tv_interval($start_time);
$mins                 =   $diff/60;
$hours                =   $mins/60;
print sprintf("\n\nExecution time: %.0f minutes (%.1f hours)\n", $mins, $hours);
