sub pgGEOmetaGSM {

=pgOverrideParam

http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM487790&form=text

=cut

  my $args            =   shift;

  $args->{GSMLIST}    //= [ qw(GSM487790 GSM117207) ];
  $args->{pgP}->{ GEOlink } //= 'http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=';

  my $tmpDir          =   $args->{ '-metaroot' }.'/tmp';
  mkdir $tmpDir;

  my $gsmData      =   {};

  for my $i (0..$#{ $args->{GSMLIST} }) {

    my $gsm           =   $args->{GSMLIST}->[$i];
    my $url						=		$args->{pgP}->{ GEOlink }.$gsm.'&form=text';
    my $file					=		$tmpDir.'/'.$gsm.'.geometa.soft';

    if (
      ! -f $file
      ||
      $args->{ '-force' } =~ /^y/
    ) {

  		_d('trying '.$gsm.' ('.($i+1).'/'.@{ $args->{GSMLIST} }.')');

  		my $status			=		getstore($url, $file);
  		_d("no file could be fetched") unless is_success($status);

  	}

    $gsmData->{ $gsm }=   {
                            GSM   =>  $gsm,
                            GSE   =>  'NA',
                            GPL   =>  'NA',
                            URL   =>  $url,
                            FILE  =>  'NA',
                          }

    if (-f $file) {

  		my @metaLines		=		@{
														pgFile2list(
															%args,
															FILE		=>	$file,
														)
													};

      my $gse         =   ( grep{ /Sample_series_id ?\= ?GSE\d+/ } @metaLines )[0];
      $gse            =~  s/^.*(GSE\d+?)[^\d]*?$/\1/;
      my $gseDir      =   $tmpDir.'/'.$gsm;

      if ($gse =~ /^GSE\d+?$/) {

        $gseDir       =   $args->{ '-metaroot' }.'/'.$gse;
        mkdir $gseDir;
        $gsmData->{ $gsm }->{GSE} =   $gse;

      }

      my $gpl         =   ( grep{ /Sample_platform_id ?\= ?GPL\d+/ } @metaLines )[0];
      $gpl            =~  s/^.*(GPL\d+?)[^\d]*?$/\1/;

      if ($gpl =~ /^GPL\d+?$/) {

        $gsmData->{ $gsm }->{GLP} =   $gpl;

      }

      my $gsmDir      =   $gseDir.'/'.$gsm;
      my $gsmSoft     =   $gsmDir.'/geometa.soft';
      mkdir $gsmDir;
      copy($file, $gsmSoft);

      $gsmData->{ $gsm }->{FILE}  =   $gsmSoft;

  	} else {

      _d('no file could be loaded', $file);

    }

  	my $metaParsed		=		$sampleDir.'/meta.tab';

  }

  return $gsmData;

}

1;
