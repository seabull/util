#!perl 
#------------------------------------------------------------------------------
# PVCS info
#
# $Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/Utilities/T38lib/copymod.pv_  $
# $Author: A645276 $
# $Date: 2011/02/08 17:25:26 $
# $Revision: 1.1 $
#------------------------------------------------------------------------------
#
# Script Name:	copymod.pl
# Date:			May 29, 2002
# Location: 	\\Ds01adbi\dbaiutil\dbinst\sql80\sql80
# Permissions:
# Purpose:      Copy module(s) into to perl lib under T38lib directory.
# Input:        no input or *.pm, or filename.pm or -h
#					 if no input is given then it copy all the *.pm from current
#					 directory to the perl lib directory under T38lib
#
# History:
#   Initials  Date             Description of change
#
#------------------------------------------------------------------------------

#-- Start of Main Program

use strict;

# Function prototypes in alphabetical order
sub globbing(\@);
sub mkdir($); 
sub usage();

# Modules used.
use Getopt::Std;
use Cwd;
use File::Basename;

my ($T38ERROR)="__T38ERROR__";
my ($libdir) = "T38lib";
my ($glibPath, $gext, $gname, $gpath);

my (@gArg) = ();

# Check command line argument
#
getopts('h');

if ( $Getopt::Std::opt_h ) {
	&usage();
}

if ( $#ARGV == -1) {
	$ARGV[0] = "*.pm";
}

# Copy T38lib libraries to default perl lib directory
# Get the Perl lib path from global variable @INC 
# Create a directory under Perl lib path call T38lib
# Copy all the module file(s) under T38lib
#

@gArg = &globbing(@ARGV);

# Check for module file exists.
#
if ( $gArg[0] ne $T38ERROR ) {
	foreach (@gArg) {
		unless (-s "$_" ) {
			print "[main] ** ERROR ** Cannot find file $_";
			exit 1;
		}
	}
}
else {
	print "No module file file(s) found in the current directory\n";
	exit;
}

# Find the perl lib path
#
foreach (@INC) {
	$glibPath=$_;
	last if ( /site/i )
}

# Create the directory T38lib
#
$glibPath =~ s|/|\\|g;				# Change unix like path to windows path

&mkdir("$glibPath\\$libdir");

foreach (@gArg) {
 	($gname, $gpath) = fileparse($_);
	($gext = $gname) =~ s/^\w*\.//;
	$gext = lc($gext);

	if ( $gext eq "pm") {
		if (system("cmd /C xcopy /Y $_  \"$glibPath\\$libdir\"") != 0) { 
			print "[main] cmd /C xcopy /Y $_  \"$glibPath\\$libdir\"";
			print "[main] copy T38lib libraries files failed";
		}
	}
	else {
		print "[main] Not a module file: $_\n";
	}
}

#-------------------
# SUBROUTINES
#-------------------

#------------------------------------------------------------------------------
#	Purpose: Expand command line arguments
#
#	Input: 	Command line argument as an array
#	Output: Expand command line argument and an array of the expanded 
#			command line arguments
#			If globbing expand to nothing then return $T38ERROR="__T38ERROR__"
#			
#------------------------------------------------------------------------------
sub globbing(\@) {
	my @cmdLine = @_;				# Get the input parameters

	my @argv= ();					# Variable to hold all the globbing results

	foreach (@cmdLine) {
    	if (/^['"](.*)["']$/) {
        	push @argv, $1;
    	} elsif (!/[*?]/) {
        	push @argv, $_;
    	} else {
        	push @argv, glob $_;
    	}
	}
	
	if ( defined (@argv) ) {		# if globbing produce any result then
		return @argv;				# the result
	}
	else {
		$argv[0]=$T38ERROR;			# No result from globbing
		return @argv;				# Return $T38ERROR
	}
}

#------------------------------------------------------------------------------
# Purpose: Disconnect a network drive
#
#	Input Arguments:	path with the drive letter, example c:\dbms\t38bkps
#	Return:				None
#------------------------------------------------------------------------------
sub mkdir($) {
  	my ($path) = shift;

	my ($string, $key);
	my (@mylist) = ();

	@mylist=split(/\\/,$path);

	$string = splice(@mylist,0,1);
	foreach $key (@mylist) {
		$string="$string\\$key";
		system("mkdir $string") unless ( -d $string);
	} 
	unless ( -d $string) {
		print "[mkdir] ** ERROR ** try to create $string directory failed.";
		exit 1;
	}

} # end sub mkdir

#------------------------------------------------------------------------------
# Purpose: usage of the program
#------------------------------------------------------------------------------
sub usage() {
	print "\nusage: $0  module_file_name or -h\n\n";
	print "\tmodule_file_name is the name of the file with extension pm, which you want to copy\n";
	print "\tDefault is all the *.pm files in the current directory\n";
	print "\t-h Display help\n\n";
	print "\tCopy Common.pm module in perl lib directory under T38lib\n";
	print "\tThe module file has to be in the same directory where the source program is\n\n";
	print "\tExample to run the program\n";
	print "\t\t$0\n";
	print "\t\tCopy *.pm file to perl list under T38lib\n";
	print "\t\t$0 Common.pm\n";
	print "\t\tCopy Common.pm file to perl list under T38lib\n";
	print "\t\t$0 *.pm\n";
	print "\t\tCopy *.pm file to perl list under T38lib\n";
	exit;
 }

 __END__
