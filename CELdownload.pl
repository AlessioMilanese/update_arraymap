# Script that downloads the archive file GSM337653.CEL.gz
# and extract the CEL file from the .gz archive file

#!/usr/bin/perl
use File::Fetch;
use Archive::Extract;

######################       DOWNLOAD THE .CEL.GZ FILE

### build a File::Fetch object ###
my $ff = File::Fetch->new(uri => 'ftp://ftp.ncbi.nlm.nih.gov/geo/samples/GSM337nnn/GSM337653/suppl/GSM337653.CEL.gz');
### fetch the uri to cwd() ###
my $where = $ff->fetch() or die $ff->error;


######################       EXTRACT THE .CEL FILE

### build an Archive::Extract object ###
my $ae = Archive::Extract->new( archive => 'GSM337653.CEL.gz' );
### extract to cwd() ###
my $ok = $ae->extract or die $ae->error;


######################       NOW THAT I HAVE .CEL FILE, I DELETE .GZ FILE
unlink 'GSM337653.CEL.gz' or warn "Could not unlink GSM337653.CEL.gz"; 
