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



my $contator = 0;

my @n_samples;

for (my $i=0; $i <= 20; $i++) {
  $n_samples[$i] = 0;
  print "$i = $n_samples[$i]\n";
}


print "start\n";

open my $fh, '<:encoding(UTF-8)', "/Volumes/arrayRAID/arraymapIn/GEOupdate/gsmdata.tab" or die;
while (my $line = <$fh>) {
    if ($line =~ /GPL6801/ || $line =~ /GPL2641/ || $line =~ /GPL3718/ || $line =~ /GPL3720/ || $line =~ /GPL2004/ || $line =~ /GPL2005/ || $line =~ /GPL1266/) {
        #$file_name =
        #print "$line\n";
        my $strn = $line;
        $strn =~ m/(\/Volumes.*?soft)/;
        $address = $1;

        open my $ff, '<:encoding(UTF-8)', $address or die;
        $contator = 0;
        while (my $line2 = <$ff>) {
            if ($line2 =~ /!Sample_supplementary_file = ftp.*?\.CEL\.gz.*?/){
               $contator = $contator + 1;
            }
        }
        $n_samples[$contator] = $n_samples[$contator] +1;
    }
}

for (my $i=0; $i <= 20; $i++) {
  print "$i = $n_samples[$i]\n";
}
