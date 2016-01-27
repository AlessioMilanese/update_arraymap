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
#my @celPlatforms      =   ("GPL3718");

my @n_samples;

print "start\n";

my $gsmIndexFile      =   "/Volumes/arrayRAID/arraymapIn/GEOupdate/gsmdata.tab";
my @gsmIndex          =   @{ pgFile2list($gsmIndexFile) };
my @gsmInfoKeys       =   split("\t", shift(@gsmIndex));
my %gsmInfo;

foreach (@gsmIndex) {

  my @currentGSM      =   split("\t", $_);
  my $currentGSMmap   =   { map{ $gsmInfoKeys[$_] => $currentGSM[$_] } 0..$#gsmInfoKeys };

  if (any { $currentGSMmap->{GPL} eq $_ } @celPlatforms) {

    $gsmInfo{ $currentGSMmap->{GSM} } =   $currentGSMmap;

  }

}

_d(scalar keys %gsmInfo, 'GSM have been found for any of', @celPlatforms);

foreach my $gsm (sort keys %gsmInfo) {

  open my $ff, '<:encoding(UTF-8)', $gsmInfo{ $gsm }->{FILE} or die;
  my @ftpFiles        =   grep{ /Sample_supplementary_file = ftp.*?\.CEL\.gz.*?/ } <$ff>;
  chomp @ftpFiles;
  foreach my $ftpCELfile (@ftpFiles) {
    $ftpCELfile       =~  s/^.*?\= (ftp.*?\.CEL\.gz).*?$/$1/;
#    $ftpCELfile       =~  s/[^\w\:\.\/]//g;
    push(@{ $gsmInfo{ $gsm }->{CELFILEFTP} }, $ftpCELfile);

  }

  _d($gsm, scalar @{$gsmInfo{ $gsm }->{CELFILEFTP}}, 'CEL files');

}

my $celInfoFile       =   $gsmIndexFile;
$celInfoFile          =~  s/\.\w\w\w$/_celfiles.tab/;

pgWriteFile(
  FILE					    =>	$celInfoFile,
  CONTENT					  =>	join("\n", map{ join("\t", ($_, $gsmInfo{ $_ }->{GPL}, scalar @{ $gsmInfo{ $_ }->{CELFILEFTP} }, $gsmInfo{ $_ }->{CELFILEFTP}->[0])) } keys %gsmInfo),
);

_d(scalar(grep{ scalar @{ $gsmInfo{ $_ }->{CELFILEFTP} } == 1 } keys %gsmInfo), 'of', scalar keys %gsmInfo, 'GSM had 1 CEL file');
_d(scalar(grep{ scalar @{ $gsmInfo{ $_ }->{CELFILEFTP} } > 1 } keys %gsmInfo), 'of', scalar keys %gsmInfo, 'GSM had more than 1 CEL file');
_d(scalar(grep{ scalar @{ $gsmInfo{ $_ }->{CELFILEFTP} } < 1 } keys %gsmInfo), 'of', scalar keys %gsmInfo, 'GSM had no CEL file');
