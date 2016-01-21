# Script that downloads all the samples that are not in Arraymap.
# In order to do that we download all the samples, series and samples that are
# already in Arraymap. After that, we download all the samples related to the
# platform that are in Arraymap and we check which of those are not in Arraymap.

#!/usr/bin/perl

use lib qw(/Library/WebServer/cgi-bin);
use PG;
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

my %args = @ARGV;

$args{ LOC_USERID } = getlogin();
$args{ LOC_ROOT } = '/Library/WebServer/Documents';

$args{pgP} = pgSetPaths(%args);
$args{pgV} = setValueDefaults();
%args =	pgModifyArgs(%args);

$args{ '-out' } ||=	'/Users/'.$args{ LOC_USERID }.'/Desktop/GEOupdate';

$args{pgP}->{ loc_tmpTmp } = $args{ -out };

################################################################################

my $mongosamples = pgGetMongoCursor(
     %args,
     MDB => 'arraymap',
     MDBCOLL => 'samples',
     QUERY => {},
     FIELDS => [ qw(UID PLATFORMID SERIESID) ]
     );

#******** 2. download samples/plattforms and series in Arraymap

print "download all the platforms...";
my %arraymap_platforms = map{ $_->{ PLATFORMID } => 1 }	(grep{ $_->{ PLATFORMID } =~ /GPL/ } @{ $mongosamples });
my @arraymap_platforms = keys %arraymap_platforms;
$size = @arraymap_platforms;
print "done: $size platforms found. \n";

print "download all the series...";
my %arraymap_series = map{ $_->{ SERIESID } => 1 } (grep{ $_->{ SERIESID } =~ /GSE/ } @{ $mongosamples });
@arraymap_series = keys %arraymap_series;
$size = @arraymap_series;
print "done: $size series found. \n";

print "download all the samples...";
my %arraymap_samples = map{ $_->{ UID } => 1 } (grep{ $_->{ UID } =~ /GSM/ } @{ $mongosamples });
@arraymap_samples = keys %arraymap_samples;
$size = @arraymap_samples;
print "done: $size samples found. \n\n";

# calculate the time needed for the download and printing it
my $diff = Time::HiRes::tv_interval($start_time);
$str = sprintf ("Execution time: %.1f seconds\n", $diff);
print $str;

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

$start_time = [Time::HiRes::gettimeofday()];

use LWP::Simple;
use List::Util 'first';

my $n_sample = 0; # total number of samples

######### print information
print "download the samples in GEO and check which one are already in arraymap...\n";
print "number of platform: ".(scalar keys %arraymap_platforms)."\n";
print "\n0\% |---------------------------| 100\%\n    ";

# variables for printing the progress bar
$perc = $size/30;
$add = $perc;
$contt = 0;

my $filename = "new_samples.txt";
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";

foreach my $plat (sort keys %arraymap_platforms){
	my $address            =     "http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=$plat&targ=self&view=brief&form=text";
	my $GSMlist            =     [ grep{/GSM\d+/} split(/[\n\r]/,get($address))];

	foreach my $sample (@$GSMlist){
	    $gsm_id = substr("$sample",22);
			@result = grep /$gsm_id/, @arraymap_samples; #search the $gsm_id in the samples of arraymap
			$res = @result[0];
			if ($res eq $gsm_id){
			}else{ # if the sample is not present in arraymap, I save it
				print $fh "$plat $gsm_id\n";
				$n_sample = $n_sample + 1;
			}
	}

  #printing the progress bar
  $contt = $contt + 1;
  if ($contt > $add-1){
		$add = $add + $perc + 1;
		print "@";
	}
}

close $fh;

# calculate the time needed for the download and printing it
my $diff = Time::HiRes::tv_interval($start_time);
$mins = $diff/60;
$hours = $mins/60;
$str = sprintf ("\n\nExecution time: %.0f minutes (%.1f hours)\n", $mins, $hours);
print $str;
print "\nnumber of new samples: $n_sample \n\n";
