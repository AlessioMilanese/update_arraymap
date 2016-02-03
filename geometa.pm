sub pgGEOmetaGSM {

=pgOverrideParam

http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM487790&form=text

=cut

  my $args            =   shift;

  $args->{GSMLIST}    //= [ qw(GSM487790 GSM117207) ];
  $args->{pgP}->{ GEOlink } //= 'http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=';
  $args->{ '-logdir' }//= $args{ '-metaroot' };

  my $tmpDir          =   $args->{ '-logdir' }.'/tmp';
  mkdir $tmpDir;

  my $gsmData         =   {};
  my $gseData         =   {};

  for my $i (0..$#{ $args->{GSMLIST} }) {

    my $gsm           =   $args->{GSMLIST}->[$i];
    my $url						=		$args->{pgP}->{ GEOlink }.$gsm.'&form=text';
    my $gsmSoftFile		=		$tmpDir.'/'.$gsm.'.geometa.soft';

    if (
      ! -f $gsmSoftFile
      ||
      $args->{ '-force' } =~ /^y/
    ) {

  		_d('trying '.$gsm.' ('.($i+1).'/'.@{ $args->{GSMLIST} }.')');

  		my $status			=		getstore($url, $gsmSoftFile);
  		_d("no file could be fetched") unless is_success($status);

  	}

    $gsmData->{ $gsm }=   {
                            GSM   =>  $gsm,
                            GSE   =>  'NA',
                            GPL   =>  'NA',
                            URL   =>  $url,
                            FILE  =>  'NA',
                          };

    if (-f $gsmSoftFile) {

  		my @metaLines		=		@{
														pgFile2list(
															%args,
															FILE		=>	$gsmSoftFile,
														)
													};

      my $gse         =   ( grep{ /Sample_series_id ?\= ?GSE\d+/ } @metaLines )[0];
      $gse            =~  s/^.*(GSE\d+?)[^\d]*?$/\1/;
      my $gseDir      =   $tmpDir;

      if ($gse =~ /^GSE\d+?$/) {

        $gseDir       =   $args->{ '-geometadir' }.'/'.$gse;
        mkdir $gseDir;
        $gsmData->{ $gsm }->{GSE} =   $gse;
        $gseData->{ $gse }  =   {
                                  GSE   =>  $gse,
                                  DIR   =>  $gseDir,
                                };

      }

      my $gpl         =   ( grep{ /Sample_platform_id ?\= ?GPL\d+/ } @metaLines )[0];
      $gpl            =~  s/^.*(GPL\d+?)[^\d]*?$/\1/;

      if ($gpl =~ /^GPL\d+?$/) {

        $gsmData->{ $gsm }->{GPL} =   $gpl;

      }

      my $gsmDir      =   $gseDir.'/'.$gsm;
      my $gsmSoft     =   $gsmDir.'/geometa.soft';
      mkdir $gsmDir;
      copy($gsmSoftFile, $gsmSoft);

      $gsmData->{ $gsm }->{FILE}  =   $gsmSoft;

  	} else {

      _d('no file could be loaded', $gsmSoftFile);

  }}

  # GSE

  foreach my $gse (sort keys %{ $gseData }) {

    my $gseSoftFile		=		$tmpDir.'/'.$gse.'.geometa.soft';

    if (
      ! -f $gseSoftFile
      ||
      $args->{ '-force' } =~ /^y/
    ) {

  		_d('trying '.$gse);

      my $url					=		$args->{pgP}->{ GEOlink }.$gse.'&form=text';
  		my $status			=		getstore($url, $gseSoftFile);
  		_d("no file could be fetched") unless is_success($status);

  	}

    if (-f $gseSoftFile) {

      copy($gseSoftFile, $gseData->{ $gse }->{ DIR }.'/geometa.soft');


  }}

  return $gsmData;

}

1;
