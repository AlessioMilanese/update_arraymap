# Script that download the CEL files and put them in the directories
# GSE/GPL/GSMnnnn.CEL

#!/usr/bin/perl
use File::Fetch;
use Archive::Extract;
use lib qw(/Library/WebServer/cgi-bin);
use PG;
use LWP::Simple;
STDOUT->autoflush(1);

my %args              =   @ARGV;

$args{ '-dataroot' }  //=	'/Volumes/arrayRAID/arraymapIn/GEOupdate';
$args{ '-metaroot' }  //=	'/Volumes/arrayRAID/arraymapIn/GEOmeta';
$args{ '-celroot' }   //=	'/Volumes/arrayRAID/arraymapIn/affyRaw';
$args{ '-celinfo' }   //=	$args{ '-dataroot' }.'/gsmdata_celfiles.tab';

my $downloadDir       =   $args{ '-celroot' }.'/tmp';
mkdir $downloadDir;

# file that contains the info of GMSid GSEid GPLid ftp_link:
# /Volumes/arrayRAID/arraymapIn/GEOupdate/gsmdata_celfiles.tab

# NOTE: Better not to leave filehandles open.
# Also allows retrieving the total number later on.

open my $ff, '<:encoding(UTF-8)', $args{ '-celinfo' } or die;
my @ftpCelFiles       =   grep{ /ftp.*?\.CEL\.gz.*?/ } <$ff>;
chomp @ftpCelFiles;
close $ff;

# NOTE: this could be solved with a
# for my $i (0..$#ftpCelFiles}) {
# ... construct; no separate counter needed.

for my $i (0..$#ftpCelFiles) {

  my @info            =   split("\t", $ftpCelFiles[$i]);
  $gsm                =   @info[0];
  $gse                =   @info[1];
  $gpl                =   @info[2];
  $address            =   @info[4];

  print _formatTime().': '.($i+1)."/".(scalar @ftpCelFiles).' ('.$gsm.':'.$gse.':'.$gpl.'): ';

# NOTE: you needed a base path here; also just pre-created the path definitions.
  my $gseDir          =   $args{ '-celroot' }.'/'.$gse;
  my $gplDir          =   $gseDir.'/'.$gpl;
  my $celFile         =   $gplDir.'/'.$gsm.'.CEL';

# TODO: %args isn't even defined
  if ( # check if the file is already present
    ! -f $celFile
    ||
    $args->{ '-force' } =~ /^y/
    ) {
    print "downloading...";

    # download the tar.gz
    my $fh            =   File::Fetch->new(uri => "$address");
    my $where         =   $fh->fetch(to => $downloadDir )or die $ff->error;

    # name of the file downloaded
    my $real_name     =   $fh->file;
    my $real_name_short = substr("$real_name",0,length($real_name)-3);

    mkdir $gseDir;
    mkdir $gplDir;

    #extract the CEL file from the archive
# NOTE: Nice to use Archive::Extract; didn't know this one.
# Npw directly extracting into th ecorrect directory, and then only renaming if
# name has some additions.

    my $ae            =   Archive::Extract->new( archive => $downloadDir.'/'.$real_name );
    my $ok            =   $ae->extract( to => $gplDir) or die $ae->error;

    #delete the archive
    unlink $downloadDir.'/'.$real_name or warn "Could not unlink $gsm.CEL.gz";

    if ($real_name_short ne $gsm.'.CEL') {

      #rename the CEL file
      move($gplDir.'/'.$real_name_short, $celFile);

    }

    print "done\n";

    } else {
      print "file already downloaded\n";
    }
}
