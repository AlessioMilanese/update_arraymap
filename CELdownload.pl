# Script that downloads a .txt file

#!/usr/bin/perl

use File::Fetch;

### build a File::Fetch object ###
my $ff = File::Fetch->new(uri => 'ftp://ftp.ncbi.nlm.nih.gov/geo/samples/GSM337nnn/GSM337653/suppl/GSM337653.CEL.gz');
### fetch the uri to cwd() ###
my $where = $ff->fetch() or die $ff->error;
### fetch the uri to /tmp ###
my $where = $ff->fetch( to => '/tmp' );
