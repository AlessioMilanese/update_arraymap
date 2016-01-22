sub pgGEOmetaGSM {

=pgOverrideParam

http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM487790&form=text

=cut

  my $args            =   shift;

  $args->{GSMLIST}    //= [ qw(GSM487790 GSM117207) ];
  $args->{pgP}->{ GEOlink } //= 'http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=';

  my $tmpDir          =   $args->{ '-metaroot' }.'/tmp';
  mkdir $tmpDir;

  for my $i (0..$#{ $args->{GSMLIST} }) {

    my $gsm           =   $args->{GSMLIST}->[$i];
    my $url						=		$args->{pgP}->{ GEOlink }.$gsm.'&form=text';
    my $file					=		$tmpDir.'/'.$gsm.'.geometa.soft';

    if (! -f $file) {

  		_d('trying '.$gsm.' ('.($i+1).'/'.@{ $args->{GSMLIST} }.')');

  		my $status			=		getstore($url, $file);
  		_d("no file could be fetched") unless is_success($status);

  	}

    if (-f $file) {

  		my @metaLines		=		@{
														pgFile2list(
															%args,
															FILE		=>	$file,
														)
													};

      my $gse         =   ( grep{ /Sample_series_id \= GSE\d+/ } @metaLines )[0];
      $gse            =~  s/^.*(GSE\d+?)[^\d]*?$/\1/;

      my $gseDir      =   $tmpDir.'/'.$gsm;
      if ($gse =~ /^GSE\d+?$/) {

        $gseDir       =   $args->{ '-metaroot' }.'/'.$gse;
        mkdir $gseDir;

      }
      my  $gsmDir     =   $gseDir.'/'.$gsm;
      mkdir $gsmDir;
      copy($file, $gsmDir.'/geometa.soft');

  	} else {

      _d('no file could be loaded', $file);

    }

  	my $metaParsed		=		$sampleDir.'/meta.tab';

  }


}

1;
