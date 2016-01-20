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



use File::Fetch;
### build a File::Fetch object ###
my $ff = File::Fetch->new(uri => 'http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GPL8355&targ=self&view=brief&form=text');
### fetch the uri to cwd() ###
my $where = $ff->fetch() or die $ff->error;
### fetch the uri to /tmp ###
my $where = $ff->fetch( to => '/tmp' );
