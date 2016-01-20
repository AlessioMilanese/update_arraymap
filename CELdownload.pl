# Script that downloads a .txt file

#!/usr/bin/perl

use File::Fetch;

### build a File::Fetch object ###
my $ff = File::Fetch->new(uri => 'http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GPL8355&targ=self&view=brief&form=text');
### fetch the uri to cwd() ###
my $where = $ff->fetch() or die $ff->error;
### fetch the uri to /tmp ###
my $where = $ff->fetch( to => '/tmp' );
