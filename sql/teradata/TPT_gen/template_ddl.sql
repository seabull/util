Create Table { $table }
\{
{  
	my @cols = ();
	$pi_cols = '';
	foreach my $col (@columns) 
	{
	        push @cols, $col->{'Name'} . "\t" . $col->{'Type'} 
			. "\t" . '/*' . ( defined($col->{'PI'}) ? $col->{'PI'} : '' ) . '*/';
		$pi_cols .= $col->{'Name'} if(defined($col->{'PI'}) && $col->{'PI'} eq 'P');
	}
	$OUT = join ",\n\t", @cols;
} 
\} DISTRIBUTE ON ( {$pi_cols} );
