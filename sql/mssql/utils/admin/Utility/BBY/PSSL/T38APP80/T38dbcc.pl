#! perl
#
# PVCS header information
# $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL65/T38dbcc.pv_  $
# $Author: A645276 $
# $Date: 2011/02/09 22:51:59 $
# $Revision: 1.1 $
#*
#*
#*
#* Purpose:  T38dbcc.pl database consistency checker.  If it finds an error it exit with status code 1.
#* Program must be executed from within the directory it is located.
#*
#* SYNOPSIS
#*
#*	t38dbcc.pl -h | -S server name | -d Database Name
#*
#*	Command line:
#*
#*	-S	optional server name
#*	-d	optional database name
#*
#*
#*	Example: 
#*	1. Not specifying the server
#*		perl T38dbcc.pl
#*
#*		
#*	2. Specifying a server
#*       perl T38dbcc.pl -S ServerName
#
#*	3. Specifying a server
#*       perl T38dbcc.pl -S ServerName -d DatabaseName
#*	
#*	
#*
#***

use strict;

# Modules used.
use Win32::EventLog;
use Getopt::Std;

my ($gscript, $gserverName, $glogFile, $ghistoryFile, $gsqlver);
my ($gstat) = 0;
my ($gdbName, $gisql);
my (@gDBNames) = ();

# check the command line arguments
getopts('hS:d:');

if ($Getopt::Std::opt_h) {	 # exit if h option exists
	&showHelp;
    exit 0;	}

if($Getopt::Std::opt_S) {
  $gserverName = $Getopt::Std::opt_S;
  $gisql = "osql -E -S$gserverName -dmaster -n -w2048"; 
  # $gisql = "isql -E -S$gserverName -dmaster -n -w2048"; 
}
else {
  $gisql = "osql -E -dmaster -n -w2048"; 
  # $gisql = "isql -E -dmaster -n -w2048"; 
}

if($Getopt::Std::opt_d) {
	$gdbName = "";	
	$gdbName = $Getopt::Std::opt_d;
}

# Get the name of the program for log file
# Log file name is equal to name of the program.log
#
($gscript = $0)  =~ s/\.\w*$//;
$glogFile = "$gscript.log";
$ghistoryFile = "$gscript.out";

&archiveLogFile(7);

# Open log file 
unless (open(RunLog,">$glogFile")) {
	print ("** ERROR ** [main]: Cannot open file $glogFile");
	&logEvent("Error", "[main] Can not open file $glogFile");
	exit 1;
}

&notifyme ("Start dbcc");

BLOCK: {
	&setSQL65version;

	if ( $gstat == 1 ) {
		last BLOCK;
	}
	&dbcc;

	if ( $gstat == 1 ) {
		last BLOCK;
	}

	&chk4errs;

} # End of BLOCK


# If run is successfule delete the file, else
# leave the file to see what went wrong.
if ($gstat == 0 ) {
	unlink("$gscript.sql");
}


( $gstat == 0) ?
   &logme("Finished with status $gstat") :
   &warnme("Finished with status $gstat");

&notifyme ("Finish dbcc");
close(RunLog);

exit($gstat);
     
###   Subroutines  #######################################################################

#--------------------------------------------------
#     notifyme -- log a message
#-------------------------------------------------
sub notifyme {
	my($msg)  = @_;

	my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	print "$msg\n";
	printf RunLog ("%02d/%02d/%02d %02d:%02d - %s\n", $mon+1, $mday, $year+1900, $hour, $min, $msg);

} # END sub notifyme

#----------------------------------------------------------------------
#	showHelp -- show help information from the current perl script.
#----------------------------------------------------------------------
sub showHelp {

	my ($inhelp) = 0;

	unless (open(PLFILE, $0)) { errme("Cannot open $0: $!\n"); die "Died"; } 
	while (<PLFILE>) {
		$inhelp = 1 if (!$inhelp && /^#\*\s/);
		if ($inhelp) {
			if (/^#\*\s/) {
				s/^#\*//;
				print;
			} 
			else {
				last;
			}
		}
	}

	close(PLFILE);

} # End of showHelp

#----------------------------------------------------------------------
#	showHelp -- show help information from the current perl script.
#----------------------------------------------------------------------
sub setSQL65version {

	my ($output) = "";
	# Get the sql Version
	#
	$output =`$gisql -Q "select \@\@version"`;

	BLOCK: {
		if ( $output =~ /Unable to Connect/i ) {
			&notifyme ("** ERROR ** [setSQL65version]: Unable to connect to sql server");
			&notifyme ("** ERROR ** [setSQL65version]: $output");
			$gstat = 1;
			last BLOCK;
		}

		if ($output =~ /deadlocked/i) {
			&notifyme ("** ERROR ** [setSQL65version]: Deadlocked");
			&notifyme ("** ERROR ** [setSQL65version]: $output");
			$gstat = 1;
			last BLOCK;
		}

		if ($output =~ /6.5/) {
			$gsqlver = 6.5;
			last BLOCK;
		}
	} # End of BLOcK

} # End of setSQL65Version

#----------------------------------------------------------------------
#  Run DBcc
#----------------------------------------------------------------------
sub dbcc {

	my ($cmd, $status);
	my ($db);

	# Open a temp file 
	#
	unless (open(SQL,">$gscript.sql")) {
		&notifyme ("** ERROR ** [dbcc]: Cannot open file $gscript.sql: $!");
		$gstat = 1;
		return;
	}

	if ( $gdbName ne "") {
		print SQL "EXEC sp_T38LOGERROR 3, 'DB_CHKS', 'Started.'\n";
		print SQL "use master\n";
		print SQL "go\n";
 		print SQL "DBCC CHECKDB($gdbName)\n";
		print SQL "go\n";
 		print SQL "DBCC NEWALLOC($gdbName)\n";
		print SQL "go\n";
		if ($gsqlver =~ /6.5/) {
 			print SQL "DBCC CHECKCATALOG($gdbName)\n";
			print SQL "go\n";
		}
 		print SQL "EXEC sp_T38LOGERROR 3, 'DB_CHKS', 'Finished.' \n";

	}
	else {
		@gDBNames = &getDBNames;

		if ( lc($gDBNames[0]) eq "error") {
			&notifyme ("** ERROR ** [dbcc]: Can not get databases Names");
			$gstat = 1;
		}
		else {
			print SQL "EXEC sp_T38LOGERROR 3, 'DB_CHKS', 'Started.'\n";
			print SQL "use master\n";
			print SQL "go\n";

			foreach $db (@gDBNames) {
				if ( ($db =~ /tempdb/i) or ($db =~ /pubs/i) or ($db =~ /NorthWind/i) ) {
					next;
				}
 				print SQL "DBCC CHECKDB($db)\n";
				print SQL "go\n";
 				print SQL "DBCC NEWALLOC($db)\n";
				print SQL "go\n";

				if ($gsqlver =~ /6.5/) {
 					print SQL "DBCC CHECKCATALOG($db)\n";
					print SQL "go\n";
				}
			}
			print SQL "EXEC sp_T38LOGERROR 3, 'DB_CHKS', 'Finished.' \n";
		}
	}

	close(SQL);

	if ( $gstat == 0 ) {
		$cmd="$gisql -i $gscript.sql -o $gscript.out";
		# Run the SQL
		$status = system($cmd);

		if ( $status != 0 ) {
			&notifyme ("** ERROR ** [dbcc]: System command failed");
			&notifyme ("** ERROR ** [dbcc]: $cmd");
			$gstat = 1;
		}
	}
}

#------------------------------------------------------------------------------
#	Purpose: Stripe leading and trailing white spaces of a given string.
#
#	Input:  A string with trailing or leading spaces
#	Output: Retrun the string after removing all the trailing
#			  and leading spaces
#
# Use of regular expresion to search for spaces and remove them
# by using the subsitute command.
#------------------------------------------------------------------------------
sub stripWhitespace {
  my $str = shift;
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  return $str;
}

#----------------------------------------------------------------------
# Check for errors in logfile#
#----------------------------------------------------------------------
sub chk4errs {

################### Variables of errors to include/exclude ##########################
my $lowersev = 17;			# Lowest severity level that we will report on.
					# possible serverity values are
					#	 0 - 10 are informational
					#	11 - 16 are user generated
					#	17 - 19 are hardware issues
					#	20 - +  are system fatal errors

# errors we're not interested in
my %xErr = (219 => 219, 1104 => 1104, 2540 => 2540, 
		         15023 => 15023, 15024 => 15024, 15025 => 15025, 
					15026 => 15026, 15027 => 15027, 15028 => 15028, 
					15029 => 15029, 15030 => 15030, 15031 => 15031, 
					15032 => 15032, 15034 => 15034);	

# Error we always want to include regardless of sev. level.
my %iErr = (911  => 911,  2502 => 2502, 2503 => 2503, 2504 => 2504,
            2505 => 2505, 2506 => 2506, 2507 => 2507, 2508 => 2508,
            2509 => 2509, 2510 => 2510, 2511 => 2511, 2512 => 2512,
            2513 => 2513, 2514 => 2514, 2516 => 2516, 2517 => 2517,
            2521 => 2521, 2522 => 2522, 2523 => 2523, 2524 => 2524,
            2525 => 2525, 2529 => 2529, 2531 => 2531, 2532 => 2532,
            2533 => 2533, 2534 => 2534, 2535 => 2535, 2541 => 2541,
            2542 => 2542, 2543 => 2543, 2544 => 2544, 2545 => 2545,
            2546 => 2546, 2547 => 2547, 7930 => 7930, 7931 => 7931,
            2518 => 2518, 2519 => 2519 );

my ($err, $sev);

BLOCK: {
	unless (open(OUTFILE,"$gscript.out")) {
		print ("** ERROR ** [errorcheck]: Cannot open file $gscript.out: $!");
		$gstat = 1;
		last BLOCK;
	}

	foreach (<OUTFILE>)	{
		chomp();
		if ( /^$/) {
			next;
		}

		# Check for unable to connect
		#
		if ( /Unable to Connect/i ) {
			$gstat = 1;
			last BLOCK;
		}
				
		# Check for deadlocked condition
		#
		if (/deadlocked/i) {
			$gstat = 1;
			last BLOCK;
		}

		if (m/Msg\s* (\d+),\s* Level\s*(\d+),/i) {
			($err, $sev) = ($1, $2);
			if ( (($sev >= $lowersev) || (defined ($iErr{$err}))) and (!defined ($xErr{$err})) ) {
				$gstat = 1;
				last BLOCK;	
			} 
		}
	}
} # End of Block

close(OUTFILE);

}

#----------------------------------------------------------------------
# logme -- issue an informative message
#----------------------------------------------------------------------
sub logme {

   &notifyme("Finished with status $gstat");
   &logEvent("Info", $_[0]);

} # End of logme

#----------------------------------------------------------------------
# warnme -- issue a warning message
#----------------------------------------------------------------------
sub warnme {

   &notifyme("Finished with status $gstat");
	&logEvent("Warn", $_[0]);

} # End of warnme

#----------------------------------------------------------------------
#	errme -- issue a warning message
#----------------------------------------------------------------------
sub errme {

   &notifyme("Finished with status $gstat");
	&logEvent("Error", $_[0]);

} # End of errme

#----------------------------------------------------------------------
#	logEvent -- log an event in Windows NT Event Log.
#----------------------------------------------------------------------
sub logEvent {
	my ($errtype, $errmsg) = @_;

	my ($eventype, $EventLog, $badwrite, $perlv);
	my $appname = $gscript;
	my $data	= "";
   my $perlflag = 0;
	my (@perlv) = ();

	$eventype = ($errtype =~ m/Info/i) ? EVENTLOG_INFORMATION_TYPE :
			($errtype =~ m/Warn/i) ? EVENTLOG_WARNING_TYPE :
			EVENTLOG_ERROR_TYPE;

	my %event=(
		'Category',  undef,
		'Source', $appname,
		'Computer', '',
		'Length', length($data),
		'RecordNumber', undef,
		'TimeGenerated', undef,
		'Timewritten', undef,
		'EventID', 9000,
		'EventType', $eventype,
		'ClosingRecordNumber',undef,
		'Strings',$errmsg,
		'Data',$data,
	);

	@perlv = `perl -v`;
	foreach $perlv(@perlv) {
		if ($perlv =~ /110/) {
			Open Win32::EventLog($EventLog, '', "Application") || die "$! ";
 	   	if ( ! $EventLog->Report(\%event) ) {
				print "Warning *** Fail to write to Event Log\n";
	    	}

			$perlflag = 1;
			last;
			$perlflag = 1;
		} 
		elsif (($perlv =~ /613/) || ($perlv =~ /522/)) {
			Win32::EventLog::Open($EventLog, $appname, '') || die "$! ";
			if ( ! $EventLog->Report(\%event) ) {
				print "Warning *** Fail to write to Event Log\n";
			}             
			$perlflag = 1;
			last;
		}
	}

	if ($perlflag == 0) {
		print "This does not fit our standard for perl \n";
		$badwrite =`$gisql -Q "Exec sp_T38LOGERROR 2, \'t38dbcc\', \'Error can't write to Event Log because it can't interpret perl version, check problem\'"`;
	}

} # End of logEvent

#------------------------------------------------------------------------------
# Purpose: Archive Log files
#
#		Input Parameter: number of files to keep
#		Output Parameter: None
#------------------------------------------------------------------------------
sub archiveLogFile {
	my $nFiles		= shift;

	my ($logFileName, $logFileBase, $newName, $oldName);
	my $logSuffix	= "\.log";
	my $i				= 0;

	$logFileName = "$glogFile"; 
	($logFileBase = $logFileName) =~ s/$logSuffix$//i;

	$newName = sprintf("${logFileBase}\.%03d$logSuffix", $nFiles);
	for ($i = $nFiles - 1; $i > 0 ; $i-- ) {
		$oldName = sprintf("${logFileBase}\.%03d$logSuffix", $i);
		if (-f $oldName) {
			rename ($oldName, $newName);
		}
		$newName = $oldName;
	}

	if (-f $logFileName) {
		rename ($logFileName, $newName);
	}
} #	End of archiveBkpFile

#------------------------------------------------------------------------------
# Purpose:	Get the names of all the databases in a SQL Server 
#------------------------------------------------------------------------------
sub getDBNames {

	my ($cmd,$rtnCode); 
	my (@dbNames) = (); 

# Open a temp file to write the sql, in case of an error return $T38ERROR. 
	unless (open(TMPSQL,">dbnames.sql")) {			
		push (@dbNames, "Error");
		return (@dbNames);
	}

# Write the SQL to get the dbnames
	print TMPSQL "use master\n";
	print TMPSQL "go\n";
	print TMPSQL "set nocount on\n";
	print TMPSQL "go\n";
	print TMPSQL "select name from sysdatabases\n";
	print TMPSQL "go\n";

	close(TMPSQL);

	$cmd=$gisql . " -i dbnames.sql -o dbnames.out";
	$rtnCode  =  system($cmd);
	if ( $rtnCode != 0)  {
		push (@dbNames, "Error");
		return (@dbNames);
	}

# Open the output file to read, in case of error return $T38ERROR
	unless (open(TMP,"<dbnames.out"))  {
		push (@dbNames, "Error");
		return (@dbNames);
	}

# Read the output file created by SQL command and look for 
# databases names.
# In case of an error terminate the loop and return $T38ERROR
	while (<TMP>) {
		chomp;
		if ( /^$/) {
			next;
		}
		if ( /Unable to Connect/i ) {
			push (@dbNames, "Error");
			last;
		}

		if (/deadlocked/i) {
			push (@dbNames, "Error");
			last;
		}

		if ( (/\w+/) ) {
			$_ = &stripWhitespace($_);
			push (@dbNames,$_) if ( !/name/);			
		}
	}
	close(TMP);

# Delete temp files
if ( lc($dbNames[0]) ne "error" ) {
   unlink("dbnames.out");
	unlink("dbnames.sql");
}

# Sort and return the database names
	return (sort (@dbNames) );

}	# End of getDbNames
