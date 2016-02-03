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

print <<END;

--------------------------------------------------------------------------------
FIND THE SAMPLES/SERIES/PLATTFORMS IN ARRAYMAP
--------------------------------------------------------------------------------

END

my $start_time        =   [Time::HiRes::gettimeofday()];

#******** 1. set up for downloading from Arraymap

my %args              =   @ARGV;

$args{ LOC_USERID }   =   getlogin();
$args{ LOC_ROOT }     =   '/Library/WebServer/Documents';

$args{ '-dataroot' }  //=	'/Users/'.$args{ LOC_USERID }.'/Desktop/GEOupdate';
$args{ '-metaroot' }  //=	'/Users/'.$args{ LOC_USERID }.'/Desktop/GEOmeta';
$args{ '-arraymap' }  //= 'n';
$args{ '-getmeta' }   //= 'y';
$args{ '-randno' }    //= -1;
$args{ '-randpf' }    //= -1;
$args{ '-selpf' }     //= 'GPL11157,GPL16131,GPL18637';


$args{pgP}            =   pgSetPaths(%args);
$args{pgV}            =   setValueDefaults();
%args                 =	  pgModifyArgs(%args);

################################################################################

mkdir $args{ '-dataroot' };
mkdir $args{ '-metaroot' };

################################################################################

my $mongoSamples      =   pgGetMongoCursor(
                           %args,
                           MDB      => 'arraymap',
                           MDBCOLL  => 'samples',
                           QUERY    => {},
                           FIELDS   => [ qw(UID PLATFORMID SERIESID) ]
                          );

#******** 2. download samples/plattforms and series in Arraymap

print "download all the platforms...";
my @arraymapPlatforms =   map{ $_->{ PLATFORMID } }	(grep{ $_->{ PLATFORMID } =~ /GPL/ } @{ $mongoSamples });
@arraymapPlatforms    =   uniq(@arraymapPlatforms);
print "done: ".@arraymapPlatforms." platforms found. \n";

if ($args{ '-selpf' } =~ /GPL/) {

  push(@arraymapPlatforms , split(',', $args{ '-selpf' }));
  print "platforms ".$args{ '-selpf' }.' added; now '.@arraymapPlatforms." platforms. \n";

}

if ($args{ '-randpf' } > 0) {

  @arraymapPlatforms  =   shuffle(@arraymapPlatforms);
  @arraymapPlatforms  =   splice(@arraymapPlatforms, 0, $args{ '-randpf' });
  print "-randpf: ".scalar(@arraymapPlatforms)." platforms will be used. \n";

}

# print "download all the series...";
# my %arraymap_series = map{ $_->{ SERIESID } => 1 } (grep{ $_->{ SERIESID } =~ /GSE/ } @{ $mongoSamples });
# @arraymap_series = keys %arraymap_series;
# $size = @arraymap_series;
# print "done: $size series found. \n";

################################################################################
#
# arraymap sample filtering
#
################################################################################

=for comment

The next part first creates an empty array for array ids, which will later be
matched against the new retrievals.
If the parameter '-arraymap' is set to "n" (default), then the array will
be populated with the existing array ids from arraymap.

=cut

my @arraymapSamples   =   ();

if ($args{ '-arraymap' } !~ /y/) {

  print "\n--------------------------------------------------------------------\n";
  print "RETRIEVAL OF ARRAYMAP IDS FOR EXCLUSION.\n";
  print "--------------------------------------------------------------------\n\n";

  print "getting existing arrayMap array ids...";

  @arraymapSamples    =   map{ $_->{ UID } } (grep{ $_->{ UID } =~ /^GSM/ } @{ $mongoSamples });
  @arraymapSamples    =   uniq(@arraymapSamples);

  print "done: ".scalar(@arraymapSamples)." arrays found. These will not be retrieved again.\n\n";

}

# TODO: execution time => helper sub

# calculate the time needed for the download and printing it
my $diff              =   Time::HiRes::tv_interval($start_time);
print sprintf("Execution time: %.1f seconds\n", $diff);

################################################################################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
################################################################################
#~~~~~~~~~~~~
#############                           PART 2
#~~~~~~~~~~~~
################################################################################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
################################################################################

$start_time           =   [Time::HiRes::gettimeofday()];

my $n_sample          =   0; # total number of samples

######### print information
print "download the samples in GEO and check which one are already in arraymap...\n";
print "number of platforms: ".(scalar @arraymapPlatforms)."\n";
print "\n0\% |---------------------------| 100\%\n    ";

# variables for printing the progress bar
my $perc              =   scalar(@arraymapPlatforms) / 30;
my $add               =   $perc;
my $contt             =   0;
my $sampleLogFile     =   $args{ '-dataroot' }."/new_samples.txt";

open(my $fh, '>', $sampleLogFile) or die "Could not open file '$sampleLogFile' $!";

foreach my $plat (sort @arraymapPlatforms){

	my $url             =   "http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=$plat&targ=self&view=brief&form=text";
	my $GSMlist         =   [ grep{/GSM\d+/} split(/[\n\r]/,get($url))];

	foreach my $sample (@$GSMlist){

	    my $gsm_id      =   substr("$sample",22);

			if (! any { $gsm_id eq $_ } @arraymapSamples) {

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

print "\nnumber of new samples: $n_sample \n\n";

if ($args{ '-randno' }) {

  $args{GSMLIST}      =   [ shuffle(@{ $args{GSMLIST} }) ];
  $args{GSMLIST}      =   [ splice(@{ $args{GSMLIST} }, 0, $args{ '-randno' }) ];

  print "\n-randno: number of random new samples: ".(scalar @{ $args{GSMLIST} })." \n\n";

}

# calculate the time needed for the download and printing it
$diff                 =   Time::HiRes::tv_interval($start_time);
$mins                 =   $diff/60;
$hours                =   $mins/60;
print sprintf("\n\nExecution time: %.0f minutes (%.1f hours)\n", $mins, $hours);

################################################################################
#
# metadata => GSM soft file download & file structure
#
################################################################################

if ($args{ '-getmeta' } !~ /^n/i) {

  print "\n------------------------------------------------------------------\n";
  print "DOWNLOAD OF THE GSM METADATA FILES.\n";
  print "------------------------------------------------------------------\n\n";

  $start_time         =   [Time::HiRes::gettimeofday()];

  _d(scalar(@{ $args{GSMLIST} }), 'GSM soft files will be retrieved');
  my $gsmData         =   pgGEOmetaGSM(\%args);

  $diff               =   Time::HiRes::tv_interval($start_time);
  $mins               =   $diff/60;
  $hours              =   $mins/60;
  print sprintf("\n\nMetadata download time: %.0f minutes (%.1f hours)\n", $mins, $hours);

  my @gsmKeys         =   sort keys $gsmData->{$args{GSMLIST}->[0]};
  my @gsmTable        =   join("\t", @gsmKeys);

  foreach my $gsm (sort @{ $args{GSMLIST} }) {

    push(@gsmTable, join("\t", @{ $gsmData->{$gsm} }{ @gsmKeys }));

  }

  pgWriteFile(
  	FILE					    =>	$args{ '-dataroot' }.'/gsmdata.tab',
  	CONTENT					  =>	join("\n", @gsmTable),
  );

  _d('wrote', $args{ '-dataroot' }.'/gsmdata.tab');

  if (
    $args{ '-randno' } < 1
    &&
    $args{ '-randpf' } < 1
  ) {

    copy($args{ '-dataroot' }.'/gsmdata.tab', $args{ '-dataroot' }.'/gsmdata_'._formatDay().'_'.@{ $args{GSMLIST} }.'.tab');

  }

}
