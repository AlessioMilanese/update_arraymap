# Script that downloads the archive file GSM337653.CEL.gz
# and extract the CEL file from the .gz archive file

#!/usr/bin/perl
use File::Fetch;
use Archive::Extract;
use lib qw(/Library/WebServer/cgi-bin);
use PG;
use LWP::Simple;
STDOUT->autoflush(1);

# clear screen
print "\033[2J";    #clear the screen
print "\033[0;0H"; #jump to 0,0

#################  command-line input
$num_args = $#ARGV + 1;
if ($num_args != 1) {
    print "\nUsage: CELdownload.pl platform_id\n";
    print "Example: CELdownload.pl GPL2005\n\n";
    exit;
}

$plat=$ARGV[0];

print "DOWNLOADING .CEL FILES OF THE PLATFORM $plat\n";

###############################################################################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############################################################################
#~~~~~~~~~~~~
#############     FIND THE SAMPLES THAT ARE NOT PRESENT IN ARRAYMAP
#~~~~~~~~~~~~
###############################################################################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############################################################################

printf "\ndownload of samples in arraymap...";

my %args = @ARGV;

$args{ LOC_USERID } = getlogin();
$args{ LOC_ROOT } = '/Library/WebServer/Documents';

$args{pgP} = pgSetPaths(%args);
$args{pgV} = setValueDefaults();
%args =	pgModifyArgs(%args);

$args{ '-out' } ||=	'/Users/'.getlogin().'/Desktop/GEOupdate';

$args{pgP}->{ loc_tmpTmp } = $args{ -out };

################################################################################

my $mongosamples = pgGetMongoCursor(
     %args,
     MDB => 'arraymap',
     MDBCOLL => 'samples',
     QUERY => {},
     FIELDS => [ qw(UID PLATFORMID SERIESID) ]
     );

my %arraymap_samples = map{ $_->{ UID } => 1 } (grep{ $_->{ UID } =~ /GSM/ } @{ $mongosamples });
@arraymap_samples = keys %arraymap_samples;

printf "done\n";

################################################################################

print "\ndownload the data of the platform...";

my $address = "http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=$plat&targ=self&view=brief&form=text";
my $GSMlist = [ grep{/GSM\d+/} split(/[\n\r]/,get($address))];

print "done\n";

my @GSM_to_download;
my $n_sample = 0;
my $n_tot_sample = 0;

print "\nfind the samples ID that we need to download...";

foreach my $sample (@$GSMlist){
    $n_tot_sample = $n_tot_sample + 1;
    $gsm_id = substr("$sample",22);
    @result = grep /$gsm_id/, @arraymap_samples; #search the $gsm_id in the samples of arraymap
    $res = @result[0];
    if ($res eq $gsm_id){
    }else{ # if the sample is not present in arraymap, I save it
      @GSM_to_download[$n_sample]=$gsm_id;
      $n_sample = $n_sample + 1;
    }
}

print "done\n";
print "number of samples of this platform: $n_tot_sample\n";
print "number of new samples: $n_sample\n";

################################################################################

print "\nDownload the CEL files:\n";

my $n_data_avaiable = 0;
my $n_data_not_avaiable = 0;
my $contatore = 1;

foreach my $sample (@GSM_to_download){

######################       DOWNLOAD THE .CEL.GZ FILE
print "($contatore/$n_sample)$sample: download .CEL.gz...";
$contatore = $contatore + 1;

#check if the file exists
#!Sample_supplementary_file = ftp
my $address = "http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=$sample&targ=self&view=brief&form=text";
my $info = [ grep{/!Sample_supplementary_file = ftp/} split(/[\n\r]/,get($address))];

if (@$info) { #if a ftp link exists

#prepare name for the directory of the ftp server (example GSM337nnn)
$sample_short = substr("$sample",0,length($sample)-3);
$directory_name = $sample_short . "nnn";

### build a File::Fetch object ###
my $ff = File::Fetch->new(uri => "ftp://ftp.ncbi.nlm.nih.gov/geo/samples/$directory_name/$sample/suppl/$sample.CEL.gz");
### fetch the uri to cwd() ###
mkdir $plat;

my $where = $ff->fetch()or die $ff->error;
print "done";
######################       EXTRACT THE .CEL FILE
print "\n           extract the .CEL file...";

### build an Archive::Extract object ###
my $ae = Archive::Extract->new( archive => "$sample.CEL.gz" );
### extract to cwd() ###
my $ok = $ae->extract or die $ae->error;

`mv "$sample.CEL" $plat`;
print "done";
######################       NOW THAT I HAVE .CEL FILE, I DELETE .GZ FILE
print "\n           delete .gz file...";

unlink "$sample.CEL.gz" or warn "Could not unlink $sample.CEL.gz";
print "done\n";

$n_data_avaiable = $n_data_avaiable  + 1;

} else { # @a is empty
  print "no data avaible. \n";
  $n_data_not_avaiable = $n_data_not_avaiable  + 1;
}
}

#### print summary
print "\nANALYSIS OF $plat:\n\n";
print "number of samples of this platform: $n_tot_sample\n";
print "number of new samples: $n_sample\n";
print "number of .CEL files downloaded: $n_data_avaiable\n";
print "number of samples without data: $n_data_not_avaiable\n\n";
