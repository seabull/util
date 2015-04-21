#!/usr/local/bin/perl -w
#------------------------------------------------------------------------------

use FileHandle ;

# use GetOptions ;

use Getopt::Std ;

#------------------------------------------------------------------------------

use strict ;

use vars qw ( %options $output $out_fh $c_comments $sql_comments ) ;

#------------------------------------------------------------------------------

main:
{
  $/ = undef ;

# %options = ( o => \$output, c => \$c_comments, sql => $sql_comments ) ;
# &GetOptions( %options, "o=s", "c", "sql" ) ;

  if ( defined ( $output ) )
  {
    $out_fh = new FileHandle ( $options{o}, "w" ) ;

    *STDOUT = $out_fh ;
  }

  if ( @ARGV == 0 )
  {
    list_words ( <STDIN> ) ;

    exit ( 0 ) ;
  }

  foreach my $file ( @ARGV )
  {
    ( my $fh = new FileHandle ( $file, "r" ) )
      or usage("unable to open '%s' - %s",$file,$!) ;
    

    list_words ( <$fh> ) ;

    $fh->close() ;
  }

  defined ( $output ) &&
    ( $out_fh->close() ) ;
}

#------------------------------------------------------------------------------

sub list_words
{
  my $text = $_[0] ;

#  $text =~ s{
#([^"

  foreach my $word ( split ( /[\W][\W]*/, $text ) )
  {
    ( length($word) > 0 ) && ( $word !~ m/[0-9][0-9]*/ ) &&
      print $word . "\n" ;
  }

# my ( $line, $word ) ;
#
# while ( $line = <$fh> )
# {
#   defined ( $c_line ) &&
#     ( $line ~= s/// ) ;
# }
}
 
#------------------------------------------------------------------------------
 
sub usage
{
  printf STDERR "\n" ;
  printf STDERR "Error:  " . shift(@_) . "\n", @_ ;
  printf STDERR "\n" ;

  printf STDERR "Usage:  list-words [options] [ <file> ... ]\n" ;
  printf STDERR "\n" ;
  printf STDERR "List all words (identifiers) in the files to standard output,\n" ;
  printf STDERR "one word per line.\n" ;
  printf STDERR "\n" ;
  printf STDERR "If no files specified then standard input is read.\n" ;
  printf STDERR "\n" ;
  printf STDERR "Options:\n" ;
  printf STDERR "\n" ;
  printf STDERR "  -o <output>       Output to specified file instead of stdout.\n" ;
  printf STDERR "\n" ;
  printf STDERR "  -sql              Skips words in SQL comments: '-- ...'\n" ;
  printf STDERR "\n" ;
  printf STDERR "  -c                Skips words in C comments:  '/* ... */' & '// ...'\n" ;
  printf STDERR "\n" ;

  exit ( -1 ) ;
}

#------------------------------------------------------------------------------
