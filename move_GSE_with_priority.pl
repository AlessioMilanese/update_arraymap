# Script that move the .CEL files from the download directory to the aroma directory
# prioritizing the ones related to cancer
# changing the name of the platform name

#!/usr/bin/perl
use File::Fetch;
use Archive::Extract;
use lib qw(/Library/WebServer/cgi-bin);
use PG;
use LWP::Simple;
STDOUT->autoflush(1);

#-------------------------------------------------------------------------------
#-------------------------      ROOTS
#-------------------------------------------------------------------------------
my $meta_root = "/Users/alessio/Desktop/GEOmeta";
#"/Volumes/arrayRAID/arraymapIn/GEOmeta"
my $from_root = "/Users/alessio/Desktop/from"; #from where to copy data
my $dest_root = "/Users/alessio/Desktop/to"; #destination

#-------------------------------------------------------------------------------
#------------------------  COMPUTATION
#-------------------------------------------------------------------------------

# find the list of series that we have (there are not the ones already in arraymap)
opendir my $dh, $from_root
  or die "$0: opendir: $!";

my @from_dirs = grep {-d "$from_root/$_" && ! /^\.{1,2}$/} readdir($dh);

#-------------------------------------------------------------------------------
#-----------  find the gse that are related to cancer
#-------------------------------------------------------------------------------

my $is_cancer = 0;
my $contator = 1;
my $n_gse = scalar @from_dirs;

print "\nthere are " . $n_gse . " new GSEs (not in Arraymap).\n\n";
print "search the GSE linked to cancer:\n";

foreach my $gse (sort @from_dirs){
  print "$contator/$n_gse - ";
  $contator++;

  $is_cancer = 0;
  $file = "$meta_root/$gse/geometa.soft" ;
  open my $fh, '<:encoding(UTF-8)', $file or die;

  while (my $line = <$fh>) {
      if ($line =~ /cancer/ ||  $line =~ /tumor/ || $line =~ /carcinoma/ || $line =~ /leukemia/ || $line =~ /lymphoma/) {
          $is_cancer = 1;
      }
  }

  #if the gse is related to cancer
  if ($is_cancer == 1){
    print "$gse :: cancer :: copy...";
    # copy the files
    `cp -R "$from_root/$gse" "$dest_root/$gse" `;
    print "done\n";
  }else{
    print "$gse :: not cancer\n";
  }
}
