# Script that counts the number of .CEL files of the samples that we need to download

#!/usr/bin/perl
use File::Fetch;
use Archive::Extract;
use lib qw(/Library/WebServer/cgi-bin);
use PG;
use LWP::Simple;
STDOUT->autoflush(1);

# platform that we are going to analyze
# platforms: "GPL6801", "GPL2641", "GPL3718", "GPL3720", "GPL2004", "GPL2005", "GPL1266"

my %args              =   @ARGV;

$args{ LOC_USERID }   =   getlogin();
$args{ LOC_ROOT }     =   '/Library/WebServer/Documents';

$args{ '-dataroot' }  //=	'/Volumes/arrayRAID/arraymapIn/GEOupdate';
$args{ '-metaroot' }  //=	'/Volumes/arrayRAID/arraymapIn/GEOmeta';
$args{ '-arraymap' }  //= 'n';
$args{ '-getmeta' }   //= 'n';
$args{ '-randno' }    //= -1;
$args{ '-gpl' }       //= "GPL6801,GPL2641,GPL3718,GPL3720,GPL2004,GPL2005,GPL1266";

$args{pgP}            =   pgSetPaths(%args);
$args{pgV}            =   setValueDefaults();
%args                 =	  pgModifyArgs(%args);

################################################################################

my @celPlatforms      =   split(',', $args{ '-gpl' });

my @n_samples;

print "start\n";

my $gsmIndexFile      =   $args{ '-dataroot' }."/gsmdata.tab";
my @gsmIndex          =   @{ pgFile2list($gsmIndexFile) };
my @gsmInfoKeys       =   split("\t", shift(@gsmIndex));
my %gsmInfo;

my $arraymapGPL       =   [];

if ($args{ '-arraymap' } !~ /y/i) {

  _d('looking up arraymap for existing samples');

  $arraymapGSM		    =	  pgGetMongoDistinct(
                            %args,
                            MDBCOLL		=>	'samples',
                            MDB       =>  'arraymap',
                            KEY				=>	'UID',
                            QUERY			=>	{},
                          );

  _d('retrieved', scalar @{ $arraymapGSM },'arraymap IDs for filtering');

}

foreach (@gsmIndex) {

  my @currentGSM      =   split("\t", $_);
  my $currentGSMmap   =   { map{ $gsmInfoKeys[$_] => $currentGSM[$_] } 0..$#gsmInfoKeys };

  if (
    (any { $currentGSMmap->{GPL} eq $_ } @celPlatforms)
    &&
    (! any { $currentGSMmap->{GSM} eq $_ } @{ $arraymapGSM })
  ) {

    $gsmInfo{ $currentGSMmap->{GSM} } =   $currentGSMmap;

}}

_d(scalar keys %gsmInfo, 'GSM have been found for any of', @celPlatforms);

foreach my $gsm (sort keys %gsmInfo) {

  $gsmInfo{ $gsm }->{CELFILEFTP}  =   [];

  open my $ff, '<:encoding(UTF-8)', $gsmInfo{ $gsm }->{FILE} or die;

  foreach my $ftpCELfile (grep{ /Sample_supplementary_file = ftp.*?\.CEL\.gz.*?/ } <$ff>) {

    chomp $ftpCELfile;
    $ftpCELfile       =~  s/^.*?\= (ftp.*?\.CEL\.gz).*?$/$1/;
    push(@{ $gsmInfo{ $gsm }->{CELFILEFTP} }, $ftpCELfile);

  }

  _d($gsm, scalar @{$gsmInfo{ $gsm }->{CELFILEFTP}}, 'CEL files');

}

my $amMarker          =   $args{ '-arraymap' } =~ /y/i ? 'with_arraymap' : q{};
my $celInfoFile       =   $gsmIndexFile;
$celInfoFile          =~  s/\.\w\w\w$/_celfiles_$amMarker.tab/;

pgWriteFile(
  FILE					      =>	$celInfoFile,
  CONTENT					    =>	join("\n", map{ join("\t", ($_, $gsmInfo{ $_ }->{GSE}, $gsmInfo{ $_ }->{GPL}, scalar @{ $gsmInfo{ $_ }->{CELFILEFTP} }, $gsmInfo{ $_ }->{CELFILEFTP}->[0])) } sort keys %gsmInfo),
);

_d(scalar(grep{ scalar @{ $gsmInfo{ $_ }->{CELFILEFTP} } == 1 } keys %gsmInfo), 'of', scalar keys %gsmInfo, 'GSM had 1 CEL file');
_d(scalar(grep{ scalar @{ $gsmInfo{ $_ }->{CELFILEFTP} } > 1 } keys %gsmInfo), 'of', scalar keys %gsmInfo, 'GSM had more than 1 CEL file');
_d(scalar(grep{ scalar @{ $gsmInfo{ $_ }->{CELFILEFTP} } < 1 } keys %gsmInfo), 'of', scalar keys %gsmInfo, 'GSM had no CEL file');
