# Script that counts the number of .CEL files of the samples that we need to download

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

# platform that we are going to analyze
# platforms: "GPL6801", "GPL2641", "GPL3718", "GPL3720", "GPL2004", "GPL2005", "GPL1266"

my @celPlatforms      =   ("GPL6801", "GPL2641", "GPL3718", "GPL3720", "GPL2004", "GPL2005", "GPL1266");

my @n_samples;

for (my $i=0; $i <= 20; $i++) {
  $n_samples[$i] = 0;
  print "$i = $n_samples[$i]\n";
}

print "start\n";

my $gsmIndexFile      =   "/Volumes/arrayRAID/arraymapIn/GEOupdate/gsmdata.tab";
my @gsmIndex          =   @{ pgFile2list($gsmIndexFile) };
my @gsmInfoKeys       =   split("\t", shift(@gsmIndex));
my %gsmInfo;

foreach (@gsmIndex) {

  my @currentGSM      =   split("\t", $_);
  my $currentGSMmap   =   { map{ $gsmInfoKeys[$_] => $currentGSM[$_] } 0..@#gsmInfoKeys };

_d($currentGSMmap->{GPL}, $currentGSMmap->{GSM});


}

exit;


foreach my $gpl (@celPlatforms) {

}


open my $fh, '<:encoding(UTF-8)', "/Volumes/arrayRAID/arraymapIn/GEOupdate/gsmdata.tab" or die;
while (my $line = <$fh>) {
    if (any { $line =~ /$_/ } @celPlatforms) {
        #$file_name =
        #print "$line\n";
        my $strn      =   $line;
        $strn         =~  m/^|\t(\/Volumes.*?soft)\t|$/;
        $address      =   $1;

        open my $ff, '<:encoding(UTF-8)', $address or die;
        my $contator  =   grep{ /!Sample_supplementary_file = ftp.*?\.CEL\.gz.*?/ } <$ff>;
        $n_samples[$contator] = $n_samples[$contator] +1;

    }
}

for (my $i=0; $i <= 20; $i++) {
  print "$i = $n_samples[$i]\n";
}
