#!/usr/local/bin/perl -w
#------------------------------------------------------------------------------

use Getopt::Std ;

use POSIX qw( tmpnam ) ;

use IO::File ;

#------------------------------------------------------------------------------

use strict ;

use vars qw ( %words ) ;

#------------------------------------------------------------------------------

main:
{
  local $/ ;	# undefine record separator

  foreach my $file ( @ARGV )
  {
    parse_word_file ( $file ) ;
  }

  foreach my $key ( sort keys %words )
  {
    print $words{$key} . "\n" ;
  }
}

#------------------------------------------------------------------------------

sub parse_word_file
{
  my $file = $_[0] ;

  ( my $in = new IO::File ( $file, "r" ) )
    or usage("unable to open '%s' - %s",$file,$!) ;

  my $text = <$in> ;

  $in->close() ;

  my $match = q{ ("[^"\\]*(?:\\.[^"\\]*)*")		# 1 - quoted string	"..."
                | ('[^'\\]*(?:\\.[^'\\]*)*')		# 2 - quoted string	'...'
                | ([-][-][^\n]*)			# 3 - SQL comment	-- ...
                | ([Rr][Ee][Mm][ \t][^\n]*)		# 4 - SQL comment	REM ...
                | (/\*[^*]*\*+(?:[^/*][^*]*\*+)*/)	# 5 - C style comment	/* ... */
                | ([0-9][\w_]*)				# 6 - word starting with numeric
                | ([\w_]+)				# 7 - word starting with alpha or '_'
                | (.)					# 8 - non-word
                | ([\n])				# 9 - newline
               } ;

  print STDERR "               $match\n" ;

  my $double		= qq{ ("[^"\\]*(?:\\.[^"\\]*)*") } ;

  my $single		= qq{ ('[^'\\]*(?:\\.[^'\\]*)*') } ;

  my $sql_comment	= qq{ ([-][-][^\n]*) | ([Rr][Ee][Mm][ \t][^\n]*) } ;

  my $c_comment		= qq{ (/\*[^*]*\*+(?:[^/*][^*]*\*+)*/) } ;

  my $num_word		= qq{ ([0-9][\w_]*) } ;

  my $word		= qq{ ([\w_]+) } ;

  my $non_word		= qq{ (.) } ;

  my $newline		= qq{ ([\n]) } ;

  $match = "(?:$double|$single|$sql_comment|$c_comment|$num_word|$word|$non_word|$newline)" ;

  print STDERR "$match\n" ;

  while ( $text =~ m{$match}gx )
  {
    defined ( $7 ) && ( length($+) > 1 ) &&
      ( $words{ lc($+) } = $+ ) ;
  }
}

#------------------------------------------------------------------------------
 
sub usage
{
  printf STDERR "\n" ;
  printf STDERR "Error:  " . shift(@_) . "\n", @_ ;
  printf STDERR "\n" ;

  printf STDERR "Usage:  sql-list-words <file> [ ... ]\n" ;
  printf STDERR "\n" ;
  printf STDERR "- Reads words from <file>(s) and lists last occurance of\n" ;
  printf STDERR "  each word to stdout.\n" ;
  printf STDERR "\n" ;
  printf STDERR "- Comparisions are case-insensitive, output case-sensistive.\n" ;
  printf STDERR "\n" ;

  exit -1 ;

  exit ( -1 ) ;
}

#------------------------------------------------------------------------------
