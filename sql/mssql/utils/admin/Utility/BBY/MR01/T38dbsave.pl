#!perl
#
# PVCS header information
# $Archive:   //cs01pvcs/pvcs/cm/Database/archives/SERVERS/STORE/MLGSTORE/MR01/T38dbsave.pv_  $
# $Author: A645276 $
# $Date: 2011/02/09 22:54:03 $ 
# $Revision: 1.1 $
#
#* Purpose:  Zip all the database backup files on MR01 and copy the zip file to MR04 server. 
#*
#* Summary:
#* 		 1. Take all the database backup file on MR01, zip these file and copy it to MR04 server.
#*
#* Program must be executed from within the directory it is located.
#*
#* SYNOPSIS
#*
#*	T38dbsave.pl -h | -a number
#*
#*	Command line:
#*
#*	-h  Writes help screen on standard output, then exits.
#*	-a	number of backup files archived, default is 1 
#*
#*	Examples: 
#*	1. Not specifying any command line arguments
#*		perl T38dbsave.pl
#*		
#*	2. Keep last 10 archive of the backup.zip file
#*       perl T38bkp.pl -a 10
#*	
#***

#----------------------------------------------------------------
# Turn on strict
#----------------------------------------------------------------
use strict;

#----------------------------------------------------------------
# Modules used.
#----------------------------------------------------------------
use Getopt::Std;

#----------------------------------------------------------------
# Global Variables
#----------------------------------------------------------------
my ($glogFileName, $gscript, $gdesDir) = "";
my ($gdesFileName) = "backups.zip";
my ($gstatus) = 0;
my ($gnumArchive) = 1;

#----------------------------------------------------------------
# Parse the program name to create the log file name
#----------------------------------------------------------------
($gscript = $0) =~ s/\.\w*$//;
# $gscript   =~ s/^.*[\\\/]([^\\\/]+)$/$1/; # To strip the path information 
$glogFileName = $gscript . ".log";

#----------------------------------------------------------------
# check the command line arguments
# 	-h to show help
# 	-a number of backup files to archive Range [1-10]
#----------------------------------------------------------------
getopts('ha:');
	
#----------------------------------------------------------------
# If -h command line option is given show help message, and exit
#----------------------------------------------------------------
if ($Getopt::Std::opt_h) {
	&showHelp();
	exit($gstatus);
}

#----------------------------------------------------------------
# open the log file
#----------------------------------------------------------------
unless (open(LOG,">$glogFileName"))
{
   print ("** ERROR ** [main] Cannot open file $glogFileName: $!");
	exit(1);
}

&notifyMe("[main] START OF MAIN PROGRAM");

#----------------------------------------------------------------
# If -a num command line option is given, set the variable with
# the number of backup archive to keep
# Archive range is [1-10], default number is 1 
#----------------------------------------------------------------
if($Getopt::Std::opt_a) {
	if ( $Getopt::Std::opt_a =~ /\d/) {
		if ( ($Getopt::Std::opt_a < 11) and ($Getopt::Std::opt_a > 0) ) {
			$gnumArchive = $Getopt::Std::opt_a;
		}
		else {
			&notifyMe("[main] ** WARN ** -a value is out of range, range is 1-10, Default 1 is used");
		}
	}
	else {
		&notifyMe("[main] ** WARN ** wrong value for -a option, Default 1 is used");
	}
}

#----------------------------------------------------------------
# Call the mainProcess sub to archive, zip and copy the backup
# file. Check and report the status.
#----------------------------------------------------------------
$gstatus = &mainProcess();
if ($gstatus == 0 ) {
	&notifyMe("[main] ** INFO ** Successful run, Status = $gstatus"); 
}
else {
	&notifyMe("[main] ** ERROR ** Status = $gstatus, check the log file $glogFileName"); 
}

&notifyMe("[main] END OF MAIN PROGRAM");
close(LOG);

#----------------------------------------------------------------
# Exit with the status code so the Maestro know about the 
# success or failer of this run
#----------------------------------------------------------------
exit($gstatus);


#***  SUBROUTINES ***

#------------------------------------------------------------------------------
# Purpose: Set up source and destination directory, zip and copy the zip
#
#		Input Parameter:  None
#		Output Parameter: Status code 0 OK, 1 Failed.
#------------------------------------------------------------------------------
sub mainProcess {

	my ($rtnCode) = 0;
	my ($srcDir) = "D:\\dbms\\t38bkp";
	my ($cmd) = "";

	&notifyMe("[mainProcess] START OF SUB");

	BLOCK: {  # Start of BLOCK

		if (defined($ENV{locationnum})) {
			$gdesDir = "\\\\MR04$ENV{locationnum}\\c\$\\DBMS\\MR01";
		}
		else {
			&notifyMe("[mainContral] ** ERROR ** Environment variable locationnum is not set");
			$rtnCode = 1;
			last BLOCK;
		}

		&notifyMe("[mainProcess] ** INFO ** Source Directory                $srcDir");
		&notifyMe("[mainProcess] ** INFO ** Destination directory           $gdesDir");
		&notifyMe("[mainProcess] ** INFO ** Number of archive files to keep $gnumArchive");

		&archiveBkpFile($gnumArchive);

		$cmd = "zip -q $gdesFileName $srcDir\\*.bkp";
		&notifyMe("[mainProcess] ** INFO ** Start the command: $cmd");
		if ( system($cmd) != 0 ) {	
			&notifyMe("[mainProcess] ** ERROR ** Command failed '$cmd'");
			$rtnCode = 1;
			last BLOCK;
		}

		$cmd = "xcopy /Q /V *.zip $gdesDir";
		&notifyMe("[mainProcess] ** INFO ** Start the command: $cmd");
		if ( system($cmd) != 0 ) {	
			&notifyMe("[mainProcess] ** ERROR ** Command failed '$cmd'");
			$rtnCode = 1;
			last BLOCK;
		}

	} # End BLOCK

	notifyMe("[mainProcess] END OF SUB");
	return ($rtnCode);

}  # End of mainProcess 

#------------------------------------------------------------------------------
# Purpose: Archive backup files
#
#		Input Parameter: number of files to keep
#		Output Parameter: None
#------------------------------------------------------------------------------
sub archiveBkpFile {
	my $nFiles		= shift;

	my ($logFileName, $logFileBase, $newName, $oldName)	= '';
	my $logSuffix	= "\.zip";
	my $i				= 0;

	&notifyMe("[archiveBkpFile] START OF SUB");

	$logFileName = "$gdesDir\\$gdesFileName"; 
	($logFileBase = $logFileName) =~ s/$logSuffix$//i;

	$newName = sprintf("${logFileBase}\.%03d$logSuffix", $nFiles);
	for ($i = $nFiles - 1; $i > 0 ; $i-- ) {
		$oldName = sprintf("${logFileBase}\.%03d$logSuffix", $i);
		if (-f $oldName) {
			&notifyMe("[archiveBkpFile] ** INFO ** rename $oldName $newName");
			rename ($oldName, $newName);
		}
		$newName = $oldName;
	}

	if (-f $logFileName) {
		 &notifyMe ("[archiveBkpFile] ** INFO ** rename $logFileName $newName");
		rename ($logFileName, $newName);
	}

	&notifyMe("[archiveBkpFile] END OF SUB ");

} #	End of archiveBkpFile

#------------------------------------------------------------------------------
# Purpose: 	Log messages to a log file.  Log file name is the name of the 
#				program with an extension of log.
#			Example:
#					Program Name: 	T38instl.pl
#					Log File Name:	T38instl.log
#
#		Input Parameter: Message
#		Output Parameter: None
#------------------------------------------------------------------------------
sub notifyMe {
	my ($msg) = shift;			# Get the input parameter

  	my ($msgWithDate);
	my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);

	print "$msg\n";
	$msgWithDate = sprintf ("%02d/%02d/%04d %02d:%02d - %s\n", $mon+1, $mday, $year+1900, $hour, $min, $msg);
	print LOG $msgWithDate;

}	# End of notifyMe


#------------------------------------------------------------------------------
#	Purpose:  Print a help screen on std out.
#
#	Input Argument: None
#	Output:         None
#------------------------------------------------------------------------------
sub showHelp {

print "#";
print "#* Purpose:  Zip all the database backup files on MR01 and copy the zip file to MR04 server. ";
print "#*";
print "#* Summary:";
print "#* 		 1. Take all the database backup file on MR01, zip these file and copy it to MR04 server.";
print "#*";
print "#* Program must be executed from within the directory it is located.";
print "#*";
print "#* SYNOPSIS";
print "#*";
print "#*	T38dbsave.pl -h | -a number";
print "#*";
print "#*	Command line:";
print "#*";
print "#*	-h  Writes help screen on standard output, then exits.";
print "#*	-a	number of backup files archived, default is 1 ";
print "#*";
print "#*	Examples: ";
print "#*	1. Not specifying any command line arguments";
print "#*		perl T38dbsave.pl";
print "#*";
print "#*	2. Keep last 10 archive of the backup.zip file";
print "#*       perl T38bkp.pl -a 10";
print "#*";
print "#***";

} # End of showHelp

__END__

