# Script that download the CEL files and put them in the directories
# GSE/GPL/GSMnnnn.CEL

#!/usr/bin/perl
use File::Fetch;
use Archive::Extract;
use lib qw(/Library/WebServer/cgi-bin);
use PG;
use LWP::Simple;
STDOUT->autoflush(1);

# TODO file that contains the info of GMSid GSEid GPLid ftp_link:
# TODO /Volumes/arrayRAID/arraymapIn/GEOupdate/gsmdata_celfiles.tab
open my $ff, '<:encoding(UTF-8)', "/Volumes/arrayRAID/arraymapIn/GEOupdate/gsmdata_celfiles.tab" or die;

# TODO: create correct path
# TODO: check if a sample is already downloaded
mkdir "prova_d";

foreach my $ftpCELfile (grep{ /ftp.*?\.CEL\.gz.*?/ } <$ff>) {

  my @info = split ' ', $ftpCELfile;
  $gsm = @info[0];
  $gse = @info[1];
  $gpl = @info[2];
  $address = @info[4];

  # download the tar.gz
  print "$gsm $gse $gpl $address\n";
  my $fh = File::Fetch->new(uri => "$address");
  my $where = $fh->fetch()or die $ff->error;
  # name of the file downloaded
  my $real_name = $fh->file;
  my $real_name_short = substr("$real_name",0,length($real_name)-3);

  #extract the CEL file from the archive
  my $ae = Archive::Extract->new( archive => "$real_name" );
  my $ok = $ae->extract or die $ae->error;

  #delete the archive
  unlink "$real_name" or warn "Could not unlink $gsm.CEL.gz";

  #rename the CEL file
  `mv "$real_name_short" $gsm.CEL`;

  #move the CEL file in the proper directories

  `mv $gsm.CEL prova_d`;

}
