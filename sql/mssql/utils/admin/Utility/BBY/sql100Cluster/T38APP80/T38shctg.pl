#!perl
#
# PVCS header information
# $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL80/InstallWithModule/T38APP80/T38shctg.pv_  $
# $Author: A645276 $
# $Date: 2011/02/08 17:12:21 $
# $Revision: 1.1 $
#
#* Purpose: 
#*
#* Summary:
#*
#* Program must be executed from within the directory it is located.
#*
#* SYNOPSIS
#* T38shctg.pl -c T38dba.cfg and/or -S server name  or -h
#*
#* Command line:
#*
#* -c T38dba.cfg is the name of the configuration file (Required)
#* -h  Writes help screen on standard output, then exits.
#* -S	server, optional server name
#*
#* Example: 
#*   1. Run T38shctg.pl using T38dba.cfg as input parameter on Server DST5DB
#*      perl T38shctg.pl -c T38dba.cfg -S DST5DB
#*		
#*   2. Run T38shctg.pl using T38dba.cfg as input parameter on local box
#*      perl T38shctg.pl -c T38dba.cfg
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
use T38lib::Common;
use T38lib::bbyado;
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);

#----------------------------------------------------------------
# Global Variables
#----------------------------------------------------------------
my ($gserverName,$gscript);
my ($gsqlVersion) = 7;
my ($glogFileName);
my ($gNetSrvr, $gInstName)	=	"";
my ($gconfigFileName);


my $gscriptSuffix;
my ($gscriptName) = "";			# Base name of the current script.
my ($gscriptPath) = ".\\";		# Directory path to current script.

my ($gSQLFileName);
my ($gspOutput);
my ($ginsertFileName);
my ($ginsertOutFN) = "insert.out";

my ($gT38ERROR) = $T38lib::Common::T38ERROR;		

# Global hash that hold all the parameter read from cfg files.
#
#my %gconfigValues= ();

my ($gisql) = "osql -E -h-1 -n -w1000"; 
my $cur_time=time();
my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($cur_time);
$year += 1900;
$mon += 1;

#----------------------------------------------------------------
# List of database that will be excluded 
#----------------------------------------------------------------
my ($excludeDB) = "'master', 'model', 'msdb', 'Northwind', 'pubs', 'AdventureWorks', 'tempdb'";

#----------------------------------------------------------------
# Function declaration in alphabetical order
#----------------------------------------------------------------
sub mainControl();
sub getCurTime();
sub process7();
sub processDMF();
sub process2000();
sub purgeRows();
sub runsp();
sub runspDMF();
sub showHelp();

#----------------------------------------------------------------
# Main program call the sub called mainControl, main driver of
# the program
#----------------------------------------------------------------

my ($gperlVersion);
$gperlVersion = &T38lib::Common::chkPerlVer();
if ( $gperlVersion != 1 ) { 
	&T38lib::Common::notifyMe("[main] Wrong version of Perl $gperlVersion");
	&T38lib::Common::notifyMe("[main] This program run on Perl version 5.005 and higher");
	&T38lib::Common::notifyMe("[main] Check the Perl version by runing perl -v on command line");
	&T38lib::Common::errorTrap();
}

&mainControl();

# 					***  SUBROUTINES ***

#------------------------------------------------------------------------------
#	Purpose:  Main driver of the program
#
#	Input Argument: None
#	Output:         None
#------------------------------------------------------------------------------
sub mainControl() {

	my ($mainStatus, $dbFound, $rtnStatus) = 0;
	my ($numArchive) = 3;
	my ($srvrName) = "";
	my ($logStr) = $0;
	my @temp = ();
	my (%dbDevices);
	my ($sqlVer, @sqlVersion, $delSQL);


	# If server name is not provided in the command line then show help
	# and abort.
	if ($#ARGV == -1) {
		&showHelp();
		exit($mainStatus);	
	}

	$gserverName = uc(Win32::NodeName());		# get the server name

	#----------------------------------------------------------------
	# Get the script path, name and suffix
	#----------------------------------------------------------------
	($gscriptPath, $gscriptName, $gscriptSuffix) = &T38lib::Common::parseProgramName();

	$gSQLFileName	 	= $gscriptPath . "runSP.sql";
	$gspOutput 			= $gscriptPath . "runSP.out";
	$ginsertFileName 	= $gscriptPath . "insert.sql";

	#----------------------------------------------------------------
	# check the command line arguments
	#----------------------------------------------------------------
	getopts('hc:S:');

	#----------------------------------------------------------------
	# If -h command line option is given show help message
	#----------------------------------------------------------------
	if ($Getopt::Std::opt_h) {
		&showHelp();
		exit($mainStatus);	
	}
	#----------------------------------------------------------------
	# Check the command line option for server name or
	# if server name is given as . then change it to local host name
	#----------------------------------------------------------------
	if($Getopt::Std::opt_c) {
		$gconfigFileName = $Getopt::Std::opt_c;
		$logStr = $logStr . " -c $gconfigFileName";
	}
	else {
		&showHelp();
		exit($mainStatus);	
	}

	if($Getopt::Std::opt_S) {
		$srvrName = $Getopt::Std::opt_S;
		$srvrName =~ s/^\./$gserverName/;
		$gserverName = uc($srvrName);
		($gNetSrvr, $gInstName)	=	split("\\\\", $gserverName); 
		$gInstName =~ s/^\s+//g; 
		$gInstName =~ s/\s+$//g;
		$logStr = $logStr . " -S $gserverName";
		$gisql = $gisql . " -S $gserverName";
	}
	else {
		$gNetSrvr = $gserverName;
	}

	unless (&T38lib::Common::setLogFileDir("${gscriptPath}T38LOG")) {
		&T38lib::Common::errme("Can not set up the log file directory.");
		$mainStatus = 1;
		last BLOCK;
	}

	#----------------------------------------------------------------
	# Archive the log file.  Keep last three run archive.
	#----------------------------------------------------------------
	&T38lib::Common::archiveLogFile($numArchive);

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {	# START OF BLOCK 

		unless(&readConfigFile($gconfigFileName)) { 
			&T38lib::Common::notifyWSub("** ERROR ** Can not read configuration file: $gconfigFileName");
			$mainStatus = 1;
			last BLOCK;
		}

		# For debug
		#my ($key,$value);
		#while (($key,$value) = each(%gConfigValues)) {
		#	print "key = $key  value = $value\n";
		#}

		# If ReposServerName is LocalSystem then change the 
		# repository server name to the local box
		#
		if ($T38lib::t38cfgfile::gConfigValues{RepoServerName} =~ /LocalSystem/i) {
			$T38lib::t38cfgfile::gConfigValues{RepoServerName} = $gserverName;
		}

		&T38lib::Common::logme("$gscriptName STARTED");
		&T38lib::Common::notifyWSub("Server Name: $gserverName"); 
		&T38lib::Common::notifyWSub("Repository Info: $T38lib::t38cfgfile::gConfigValues{RepoServerName}, $T38lib::t38cfgfile::gConfigValues{RepoDatabaseName}");

		if ($T38lib::t38cfgfile::gConfigValues{ShowContigEnable} =~ /y/i) {
			&T38lib::Common::notifyWSub("ShowCongig is enable");
		}
		else {
			&T38lib::Common::notifyWSub("ShowContig is NOT enable, check the $gconfigFileName");
			last BLOCK;
		}

		if ($T38lib::t38cfgfile::gConfigValues{RepoServerName} eq $gserverName ) {
			unless (&purgeRows()) {
				&T38lib::Common::notifyWSub("** ERROR ** Purging rows failed");
				$mainStatus = 1;
			}
		}


		$gsqlVersion = &T38lib::Common::getSqlCurVer($gInstName, $gNetSrvr);
		$gsqlVersion =~ s/\.\d+//g;

		if ( $gsqlVersion < 7 ) {
			&T38lib::Common::notifyWSub("** ERROR ** Can not run on SQL Version: $gsqlVersion server. Only run on 7.0 or 2000 servers");
			$mainStatus = 1;
			last BLOCK;
		}
		elsif ( $gsqlVersion == 7 ) {
			$gisql =~ s/osql/isql/;
			unless (&runsp()) {
				&T38lib::Common::notifyWSub("** ERROR ** Problem runing the store procesdure sp_T38SHOWCONTIG");
				$mainStatus = 1;
				last BLOCK;
			}
			unless (&process7()) {
				&T38lib::Common::notifyWSub("** ERROR ** Problem creating insert statement");
				$mainStatus = 1;
				last BLOCK;
			}
		}
		# Modified by DTZ on 1-Feb-2010 for 2005/08
		elsif ( $gsqlVersion >= 9) {
			&T38lib::Common::notifyWSub("SQL Version is $gsqlVersion");
			unless (&runspDMF()) {
				&T38lib::Common::notifyWSub("** ERROR ** Problem runing the store procedure sp_T38INDEX_FRAG_INFO");
				$mainStatus = 1;
				last BLOCK;

			}
			unless (&processDMF()) {
				&T38lib::Common::notifyWSub("** ERROR ** Problem creating insert statement");
				$mainStatus = 1;
				last BLOCK;
			}
			
		}
		elsif ( $gsqlVersion == 8) {
			unless (&runsp()) {
				&T38lib::Common::notifyWSub("** ERROR ** Problem runing the store procesdure sp_T38SHOWCONTIG");
				$mainStatus = 1;
				last BLOCK;

			}
			unless (&process7()) {
				&T38lib::Common::notifyWSub("** ERROR ** Problem creating insert statement");
				$mainStatus = 1;
				last BLOCK;
			}
			#&process2000();
		}
		else {
			&T38lib::Common::notifyWSub("** ERROR ** Not a valid SQL Version: $gsqlVersion. Only run on 7.0, 2000 and 2005 servers");
			$mainStatus = 1;
			last BLOCK;
		}

		if (&runInsert() == 1) {
			&T38lib::Common::notifyWSub("** ERROR ** Insert statements in $ginsertFileName failed");
			$mainStatus = 1;
			last BLOCK;
		}

		&T38lib::Common::notifyWSub("Command line: $logStr");

	} # END OF BLOCK 

	if ($mainStatus == 0 ) {
		unlink($gSQLFileName);
		unlink($gspOutput);
		unlink($ginsertFileName);
	#	$ginsertOutFN = $gscriptPath . "T38LOG\\" . $ginsertOutFN;
		unlink($ginsertOutFN);
	}

	#----------------------------------------------------------------
	# Log or errme depending on the main status
	#----------------------------------------------------------------
	($mainStatus == 0 ) ? 
		&T38lib::Common::logme("Finished with status $mainStatus"):
		&T38lib::Common::errme("Finished with status $mainStatus");

	&T38lib::Common::notifyWSub("SUB DONE");

	exit($mainStatus);

} # End of mainControl

#------------------------------------------------------------------------------
# Purpose:	Run the insert statement store in a file
#
#	Input:		None
#	Output:		Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub runInsert() {

	my ($subStatus) = 0;

	&T38lib::Common::notifyWSub("SUB STARTED");

	$subStatus = &T38lib::Common::runSQLChk4Err($ginsertFileName, 
	                                            $T38lib::t38cfgfile::gConfigValues{RepoServerName}, 
											    $T38lib::t38cfgfile::gConfigValues{RepoDatabaseName}, 
											    "$ginsertOutFN", "", "", "", "");
	&T38lib::Common::notifyWSub("SUB DONE");

	return($subStatus);

}

#------------------------------------------------------------------------------
# Purpose:	Run the Store procedure sp_T38Index_frag_info using DMF, which will produce an 
# 				output file which will be procesed to get the insert statements
# 				for repository database.
#
#	Input:		None
#	Output:		Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub runspDMF() {

	my ($subStatus) = 1;
	my ($cmd);
	my ($ctmp);
	my ($showCntgLmtCount);
	my ($scanmode)='LIMITED';
	my ($rtnCode) = 0;
	my ($aref, $nvals, $i);

	&getCurTime();

	&T38lib::Common::notifyWSub("SUB STARTED at $mon/$mday/$year $hour:$min:$sec");

	if (defined($T38lib::t38cfgfile::gConfigValues{'T38LIST:SHWCTGExcludeDBName'})) {
		$aref = $T38lib::t38cfgfile::gConfigValues{'T38LIST:SHWCTGExcludeDBName'};
		$nvals = scalar @{$aref};
		for $i (0..$nvals-1) {
			$excludeDB = $excludeDB . ",'" . $$aref[$i] . "'";
		}
		&T38lib::Common::notifyWSub("Database Exclude List = $excludeDB");
	}

	# Changed on 1-Feb-2010 by DTZ
	$scanmode = $gConfigValues{CheckIndexFragmentationScanMode} ;
	
	if ($scanmode eq ""){
		&T38lib::Common::notifyWSub("Scanmode is not mentioned in the Config file. Defaulting to default mode LIMITED");
		$scanmode = "LIMITED" ;
	}

	$ctmp = $T38lib::t38cfgfile::gConfigValues{RepoDatabaseName} . ".." . $T38lib::t38cfgfile::gConfigValues{RepoTableName};
	
	#Validate if the show contig page limit parameter is defined.
	if(defined($T38lib::t38cfgfile::gConfigValues{ShowContigLimitCount})){
		$showCntgLmtCount = $gConfigValues{ShowContigLimitCount};
	}else{
		&T38lib::Common::notifyMe("** WARNING ** ShowContigLimitCount not defined using default value of 1");
		$showCntgLmtCount = 1;
	}
	
	&T38lib::Common::notifyWSub("Index Scan Mode is $scanmode and Repository Tablename is $ctmp");

	# $cmd = "exec sp_T38DBCURSOR \@cmd= \'EXEC sp_T38SHOWCONTIG\'\, \@dbnotin \= ";
	$cmd = "exec sp_T38DBCURSOR \@EXCLUDE_SNAPSHOTS ='Y',\@cmd= \"EXEC sp_T38INDEX_FRAG_INFO \@scanmode='$scanmode',\@printonly='N',\@cRepoDBTable='$ctmp'\,\@showCntgLmtCount='$showCntgLmtCount'\"\, \@dbnotin \= ";

	$cmd = $cmd . "\"$excludeDB\"";
	
	&T38lib::Common::notifyWSub("$cmd");

	unless (open(OUTPUTFILE,">$gSQLFileName")) {
		&T38lib::Common::notifyMe("** ERROR ** Can not open file $gSQLFileName");
		$subStatus = 0;
	}

	print OUTPUTFILE "$cmd\n";
	print OUTPUTFILE "go";
	close(OUTPUTFILE);
	
	$gisql = $gisql . " -i $gSQLFileName -o $gspOutput";

	$rtnCode = system ($gisql);

	BLOCK: {	# Start of BLOCK

		if ( $rtnCode != 0 ) {
			&T38lib::Common::notifyMe("** ERROR ** $gisql failed");
			$subStatus = 0;
			last BLOCK;
		}
		else {
			unless (open(ERRFILE, $gspOutput)) { 
				print "Can not open file $gspOutput"; 
				$subStatus = 0;
				last BLOCK;	
			}
			# Parse the file to see for any sql generated errors.
			#
			foreach (<ERRFILE>)	{
				chomp();
				if ( /^$/) {
					next;
				}
				
				# Check for deadlocked condition
				#
				if (/deadlocked/i) {
					$subStatus = 0;
					last BLOCK;
				}

				# check to if we can not connect to sql server
				if ( /ConnectionOpen/i ) {
					$subStatus = 0;
					last BLOCK;
				}

				# Check for Msg messages and evaluate with exclude
				if (m/Msg\s* (\d+),\s* Level\s*(\d+),/i) {
					&T38lib::Common::notifyWSub("Errors detected in  $gspOutput");
					$subStatus = 0;
					last BLOCK;	
				}
				# Check for **Error messages and evaluate with exclude
				if (/\*\*Error/i) {
					&T38lib::Common::notifyWSub("'**Errors' detected in  $gspOutput");
					$subStatus = 0;
					last BLOCK;	
				}
			}
		}	
	} # End of BLOCK

	&getCurTime();

	&T38lib::Common::notifyWSub("SUB DONE at $mon/$mday/$year $hour:$min:$sec");

	close(ERRFILE);
	return ($subStatus);

} # End of runspDMF
#------------------------------------------------------------------------------
# Purpose:	Run the Store procedure sp_T38SHOWCONTIG, which will produce an 
# 				output file which will be process to get the insert statements
# 				for reporsitory database.
#
#	Input:		None
#	Output:		Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub runsp() {

	my ($subStatus) = 1;
	my ($cmd);
	my ($scanmode)='LIMITED';
	my ($rtnCode) = 0;
	my ($aref, $nvals, $i);

	&getCurTime();

	&T38lib::Common::notifyWSub("SUB STARTED at $mon/$mday/$year $hour:$min:$sec");

	if (defined($T38lib::t38cfgfile::gConfigValues{'T38LIST:SHWCTGExcludeDBName'})) {
		$aref = $T38lib::t38cfgfile::gConfigValues{'T38LIST:SHWCTGExcludeDBName'};
		$nvals = scalar @{$aref};
		for $i (0..$nvals-1) {
			$excludeDB = $excludeDB . ",'" . $$aref[$i] . "'";
		}
		&T38lib::Common::notifyWSub("Database Exclude List = $excludeDB");
	}

		
	$cmd = "exec sp_T38DBCURSOR \@cmd= \'EXEC sp_T38SHOWCONTIG\'\, \@dbnotin \= ";
	
	$cmd = $cmd . "\"$excludeDB\"";
	
	&T38lib::Common::notifyWSub("$cmd");

	unless (open(OUTPUTFILE,">$gSQLFileName")) {
		&T38lib::Common::notifyMe("** ERROR ** Can not open file $gSQLFileName");
		$subStatus = 0;
	}

	print OUTPUTFILE "$cmd\n";
	print OUTPUTFILE "go";
	close(OUTPUTFILE);
	
	$gisql = $gisql . " -i $gSQLFileName -o $gspOutput";

	$rtnCode = system ($gisql);

	BLOCK: {	# Start of BLOCK

		if ( $rtnCode != 0 ) {
			&T38lib::Common::notifyMe("** ERROR ** $gisql failed");
			$subStatus = 0;
			last BLOCK;
		}
		else {
			unless (open(ERRFILE, $gspOutput)) { 
				print "Can not open file $gspOutput"; 
				$subStatus = 0;
				last BLOCK;	
			}
			# Parse the file to see for any sql generated errors.
			#
			foreach (<ERRFILE>)	{
				chomp();
				if ( /^$/) {
					next;
				}
				
				# Check for deadlocked condition
				#
				if (/deadlocked/i) {
					$subStatus = 0;
					last BLOCK;
				}

				# check to if we can not connect to sql server
				if ( /ConnectionOpen/i ) {
					$subStatus = 0;
					last BLOCK;
				}

				# Check for Msg messages and evaluate with exclude
				if (m/Msg\s* (\d+),\s* Level\s*(\d+),/i) {
					$subStatus = 0;
					last BLOCK;	
				}
			}
		}	
	} # End of BLOCK

	&getCurTime();

	&T38lib::Common::notifyWSub("SUB DONE at $mon/$mday/$year $hour:$min:$sec");

	close(ERRFILE);

	return ($subStatus);

} # End of runsp

#------------------------------------------------------------------------------
# Purpose:	Process the output file to create
# 				insert statement for history table
#
#	Input:		None
#	Output:		Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub processDMF() {

	my ($subStatus) = 1;

	my ($colNum) = 0;
	my (@inputLines, @columns);
	my ($tmp, $rtnCode, $col,$line, $insertSQL);


	&getCurTime();
	&T38lib::Common::notifyWSub("INSERT SUB STARTED at $mon/$mday/$year $hour:$min:$sec");

	
	#----------------------------------------------------------------
	# COPIES CONTENT OF runsp.out to INSERT.SQL
	#----------------------------------------------------------------
	BLOCK: {
		# Open the input file, if fail display message and exit the block
		unless (open(INPUTFILE,"<$gspOutput")) {
			&T38lib::Common::notifyMe("** ERROR ** Can not open file $gspOutput");
			$subStatus = 0;
			last block;
		}

		# If file is open then read the whole file and store the info
		# into an array. 
		while (<INPUTFILE>) {
			chomp();
			push (@inputLines, $_);
		}
		# Close the file
		close(INPUTFILE);

		unless (open(OUTPUTFILE,">$ginsertFileName")) {
			&T38lib::Common::notifyMe("** ERROR ** Can not open file $ginsertFileName");
			$subStatus = 0;
			last block;
		}
	
		# Go through the each array values and split the column 
		# and display this info
		foreach $line (@inputLines) {

			print OUTPUTFILE "$line\n";
		}
		print OUTPUTFILE "go\n";
		close(OUTPUTFILE)
	} # End of BLOCK

	print OUTPUTFILE "go\n";
	close(OUTPUTFILE);

	&getCurTime();
	&T38lib::Common::notifyWSub("INSERT SUB DONE $mon/$mday/$year $hour:$min:$sec");

	# Bug fix - The below code is redundant
	# $rtnCode = system ($gisql);

	return ($subStatus);

} # End of processDMF
#------------------------------------------------------------------------------
# Purpose:	Run the store procedures and process the output file to create
# 				insert statement for history table
#
#	Input:		None
#	Output:		Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub process7() {

	my ($subStatus) = 1;

	my ($colNum) = 0;
	my (@inputLines, @columns);
	my ($tmp, $rtnCode, $col,$line, $insertSQL);

	my ($loc_srvr_nm) = "";
	my ($loc_srvr_dbinst_nm) = "";
	my ($loc_srvr_dbinst_db_nm) = "";
	my ($db_tabl_indx_nm) = "";
	my ($db_tabl_nm) = "";
	my ($db_tabl_id) = "";
	my ($db_tabl_indx_id) = "";
	my ($loc_srvr_dbinst_db_id) = "";
	my ($dta_pg_qty ) = "";
	my ($extnt_sw_qty) = "";
	my ($scan_dens_pct) = "";
	my ($scan_best_cnt) = "";
	my ($scan_actl_cnt) = "";
	my ($db_tabl_row_count) = "";

	&T38lib::Common::notifyWSub("SUB STARTED");
	
	#----------------------------------------------------------------
	# 
	#----------------------------------------------------------------
	BLOCK: {
		# Open the input file, if fail display message and exit the block
		unless (open(INPUTFILE,"<$gspOutput")) {
			&T38lib::Common::notifyMe("** ERROR ** Can not open file $gspOutput");
			$subStatus = 0;
			last block;
		}

		# If file is open then read the whole file and store the info
		# into an array. 
		while (<INPUTFILE>) {
			chomp();
			push (@inputLines, $_);
		}
		# Close the file
		close(INPUTFILE);

		unless (open(OUTPUTFILE,">$ginsertFileName")) {
			&T38lib::Common::notifyMe("** ERROR ** Can not open file $ginsertFileName");
			$subStatus = 0;
			last block;
		}
	
		# Go through the each array values and split the column 
		# and display this info
		foreach $line (@inputLines) {

#			print "$line\n";

			if ( $line =~ /^\d\>/ ) {
				next;
			}

			if ( $line =~ /DBCC FOR DB:/i ) {
				@columns = split (/'/i, $line);
				($loc_srvr_nm, $loc_srvr_dbinst_nm)	=split("\\\\", $columns[7]); 

				if ($loc_srvr_dbinst_nm eq "") {
					$loc_srvr_dbinst_nm = "MSSQLServer";
				}
					
				$loc_srvr_dbinst_db_nm = $columns[1];
				$db_tabl_indx_nm = $columns[3];
				$db_tabl_row_count = $columns[5];
			}

			if ( $line =~ /^TABLE:/i ) {
				@columns = split (/'/i, $line);
				$db_tabl_nm = $columns[1];

				$line = $columns[2];

				$line =~ s/\s+/ /g;
				@columns = split (/\s/i, $line);

				$columns[1] =~ s/\(|\)|\;//g;
				$db_tabl_id = $columns[1];

				$columns[4] =~ s/\,//g;
				$db_tabl_indx_id = $columns[4];
				$loc_srvr_dbinst_db_id = $columns[7];
			}

			if ( $line =~ /^- Pages Scanned/i ) {
				$line =~ s/\s+/ /g;
				$line =~ s/\.+//g;
				@columns = split (/\s/i, $line);
				$dta_pg_qty = $columns[3];
			}

			if ( $line =~ /^- Extent Switches/i ) {
				$line =~ s/\s+/ /g;
				$line =~ s/\.+//g;
				@columns = split (/\s/i, $line);
				$extnt_sw_qty = $columns[3];
			}
			
			if ( $line =~ /^- Scan Density/i ) {
				$line =~ s/\s+/ /g;
				$line =~ s/]\.+://g;
				@columns = split (/\s/i, $line);
				$scan_dens_pct= $columns[6];
				$scan_dens_pct =~ s/\.\d\d\%//g;
				$columns[7] =~ s/\[|\]//g;
				($scan_best_cnt, $scan_actl_cnt) = split(":", $columns[7]);
			}

			# print the insert statement
			#
			if ( $line =~ /DBCC execution completed\./i ) {

				$insertSQL = "insert into $T38lib::t38cfgfile::gConfigValues{RepoTableName} (";

				$insertSQL = $insertSQL . "LOC_SRVR_NM, ";
				$insertSQL = $insertSQL .  "LOC_SRVR_DBINST_NM, ";
				$insertSQL = $insertSQL .  "LOC_SRVR_DBINST_DB_NM, ";
				$insertSQL = $insertSQL .  "LOC_SRVR_DBINST_DB_ID, ";
				$insertSQL = $insertSQL .  "DB_TABL_CNTIG_TS, ";
				$insertSQL = $insertSQL .  "DB_TABL_NM, ";
				$insertSQL = $insertSQL .  "DB_TABL_ID, ";
				$insertSQL = $insertSQL .  "DB_TABL_INDX_NM, ";
				$insertSQL = $insertSQL .  "DB_TABL_INDX_ID, ";
				$insertSQL = $insertSQL .  "DTA_PG_QTY, ";
				$insertSQL = $insertSQL .  "EXTNT_SW_QTY, ";
				$insertSQL = $insertSQL .  "SCAN_DENS_PCT, ";
				$insertSQL = $insertSQL .  "SCAN_BEST_CNT, ";
				$insertSQL = $insertSQL .  "SCAN_ACTL_CNT, ";
				$insertSQL = $insertSQL .  "LOGL_FRAG_PCT, ";
				$insertSQL = $insertSQL .  "DB_TABL_ROW_CNT) "; 

				$insertSQL = $insertSQL . "values (";

				$insertSQL = $insertSQL . "'" . $loc_srvr_nm . "',";

				$insertSQL = $insertSQL . "'" . $loc_srvr_dbinst_nm . "',";

				$insertSQL = $insertSQL . "'" . $loc_srvr_dbinst_db_nm . "',";

				$insertSQL = $insertSQL . $loc_srvr_dbinst_db_id . ",";

				$insertSQL = $insertSQL . "getdate()" . ",";

				$insertSQL = $insertSQL . "'" . $db_tabl_nm . "',";

				$insertSQL = $insertSQL . $db_tabl_id . ",";

				$insertSQL = $insertSQL . "'" . $db_tabl_indx_nm . "',";

				$insertSQL = $insertSQL . $db_tabl_indx_id . ",";

				$insertSQL = $insertSQL . $dta_pg_qty . ",";

				$insertSQL = $insertSQL . $extnt_sw_qty . ",";

				$insertSQL = $insertSQL . $scan_dens_pct . ",";

				$insertSQL = $insertSQL . $scan_best_cnt . ",";

				$insertSQL = $insertSQL . $scan_actl_cnt . ",";

				$insertSQL = $insertSQL . "NULL" . ",";

				$insertSQL = $insertSQL . $db_tabl_row_count . ")";
				
				print OUTPUTFILE "$insertSQL\n";
			}
		}
	} # End of BLOCK

	print OUTPUTFILE "go\n";
	close(OUTPUTFILE);
	&T38lib::Common::notifyWSub("SUB DONE");

	return ($subStatus);

} # End of process7

#------------------------------------------------------------------------------
# Purpose:	Run the store procedures and process the output file to create
# 				insert statement for history table
#
#	Input:		None
#	Output:		Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub process2000() {

	my ($subStatus) = 1;
	my ($colNum) = 0;
	my (@inputLines, @columns);
	my ($tmp, $rtnCode, $col,$line, $insertSQL);

	my ($loc_srvr_nm) 				= "";
	my ($loc_srvr_dbinst_nm) 		= "";
	my ($loc_srvr_dbinst_db_nm) 	= "";
	my ($db_tabl_indx_nm) 			= "";
	my ($db_tabl_cntig_ts) 			= "";
	my ($db_tabl_nm) 					= "";
	my	($db_tabl_id) 					= "";
	my	($db_tabl_indx_id) 			= "";
	my	($loc_srvr_dbinst_db_id)	= "";
	my ($dta_pg_qty ) 				= "";
	my ($extnt_sw_qty) 				= "";
	my ($scan_dens_pct) 				= "";
	my ($scan_best_cnt) 				= "";
	my ($scan_actl_cnt) 				= "";
	my ($logl_frang_pct)				= "";

	&T38lib::Common::notifyWSub("SUB STARTED");
	
	#----------------------------------------------------------------
	# 
	#----------------------------------------------------------------
	BLOCK: {
		# Open the input file, if fail display message and exit the block
		unless (open(INPUTFILE,"<$gspOutput")) {
			&T38lib::Common::notifyMe("** ERROR ** Can not open file $gspOutput");
			$subStatus = 0;
			last block;
		}

		# If file is open then read the whole file and store the info
		# into an array. 
		while (<INPUTFILE>) {
			chomp();
			push (@inputLines, $_);
		}
		# Close the file
		close(INPUTFILE);

		unless (open(OUTPUTFILE,">$ginsertFileName")) {
			&T38lib::Common::notifyMe("** ERROR ** Can not open file $ginsertFileName");
			$subStatus = 0;
			last block;
		}
	
		# Go through the each array values and split the column 
		# and display this info
		foreach $line (@inputLines) {
			if ( $line =~ /$gserverName/i ) {

				$line =~ s/\s+/ /g;
				@columns = split (/reindexI/i, $line);

				foreach $col (@columns) {
					if ($col =~ /\w/) {
						$col =~ s/^\s+//;		# Remove leading white spaces
  						$col =~ s/\s+$//;		# Remove trailing white spaces
					}
				}

				($loc_srvr_nm, $loc_srvr_dbinst_nm)	=split("\\\\", $columns[0]); 
				if ($loc_srvr_dbinst_nm eq "") {
					$loc_srvr_dbinst_nm = "MSSQLSERVER";
				}

				$loc_srvr_dbinst_db_nm 	= $columns[1];
				$loc_srvr_dbinst_db_id  = $columns[2];
				$db_tabl_cntig_ts 		= $columns[3];
				$db_tabl_nm 				= $columns[4];
				$db_tabl_id 				= $columns[5];
				$db_tabl_indx_nm 			= $columns[6];
				$db_tabl_indx_id 			= $columns[7];
				$dta_pg_qty 				= $columns[8];
				$extnt_sw_qty 				= $columns[9];
				$scan_dens_pct 			= $columns[10];
				$scan_best_cnt 			= $columns[11];
				$scan_actl_cnt 			= $columns[12];
				$logl_frang_pct			= $columns[13];

				$insertSQL = "insert into $T38lib::t38cfgfile::gConfigValues{RepoTableName} values (";

				$insertSQL = $insertSQL . "'" . $loc_srvr_nm					. "',";

				$insertSQL = $insertSQL . "'" . $loc_srvr_dbinst_nm 		. "',";

				$insertSQL = $insertSQL . "'" . $loc_srvr_dbinst_db_nm	. "',";

				$insertSQL = $insertSQL .       $loc_srvr_dbinst_db_id	. ",";

				$insertSQL = $insertSQL . "'" . $db_tabl_cntig_ts 			. "',";

				$insertSQL = $insertSQL . "'" . $db_tabl_nm 					. "',";

				$insertSQL = $insertSQL . 		  $db_tabl_id 					. ",";

				$insertSQL = $insertSQL . "'" . $db_tabl_indx_nm 			. "',";

				$insertSQL = $insertSQL .       $db_tabl_indx_id 			. ",";

				$insertSQL = $insertSQL .	     $dta_pg_qty 					. ",";

				$insertSQL = $insertSQL .       $extnt_sw_qty 				. ",";

				$insertSQL = $insertSQL .       $scan_dens_pct 				. ",";

				$insertSQL = $insertSQL .       $scan_best_cnt 				. ",";

				$insertSQL = $insertSQL .       $scan_actl_cnt 				. ",";

				$insertSQL = $insertSQL .       $logl_frang_pct          . ")";

				print OUTPUTFILE "$insertSQL\n"; 
	 		} 
	 	}
	} # End of BLOCK

	print OUTPUTFILE "go\n";
	close(OUTPUTFILE);

	&T38lib::Common::notifyWSub("SUB DONE");

	return ($subStatus);

} # End of process2000


#------------------------------------------------------------------------------
#	Purpose:  Get current time and store in global variable
#
#	Input Argument: None
#	Output:         None
#------------------------------------------------------------------------------
sub getCurTime() {

	&T38lib::Common::notifyWSub("SUB STARTED");

	$cur_time=time();
	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($cur_time);

	$year += 1900;
	$mon += 1;

	&T38lib::Common::notifyWSub("SUB DONE");
}

#------------------------------------------------------------------------------
#	Purpose:  Print a help screen on std out.
#
#	Input Argument: None
#	Output:         None
#------------------------------------------------------------------------------
sub showHelp() {

print << 'EOT';
# PVCS header information
# $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL80/InstallWithModule/T38APP80/T38shctg.pv_  $
# $Author: A645276 $
# $Date: 2011/02/08 17:12:21 $
# $Revision: 1.1 $
#
#* Purpose: 
#		Run dbcc showcontig and parse information so it can be inserted to repository table
#*
#* Summary:
#*
#* Program must be executed from within the directory it is located.
#*
#* SYNOPSIS
#* T38shctg.pl -c T38dba.cfg and/or -S server name  or -h
#*
#* Command line:
#*
#* -c T38dba.cfg is the name of the configuration file (Required)
#* -h  Writes help screen on standard output, then exits.
#* -S	server, optional server name
#*
#* Example: 
#*   1. Run T38shctg.pl using T38dba.cfg as input parameter on Server DST5DB
#*      perl T38shctg.pl -c T38dba.cfg -S DST5DB
#*		
#*   2. Run T38shctg.pl using T38dba.cfg as input parameter on local box
#*      perl T38shctg.pl -c T38dba.cfg
#*		
#***
EOT

} # End of showHelp

#------------------------------------------------------------------------------
#	Purpose: Purge rows from table that have fragmentation information
#			 only if the repository is the local server
#
#	Input:		None
#	Output:		Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub purgeRows() {

	my ($subStatus) = 1;
	my ($SQLCmd);

	&T38lib::Common::notifyWSub("SUB STARTED");

	# Delete rows from repository table if the repository is on local box 
	# Only delete row older than 30 days from current date.

	$SQLCmd = "delete " . $T38lib::t38cfgfile::gConfigValues{RepoDatabaseName} . ".." . $T38lib::t38cfgfile::gConfigValues{RepoTableName}; 
	$SQLCmd = $SQLCmd . " where DB_TABL_CNTIG_TS < DATEADD(dd, -$T38lib::t38cfgfile::gConfigValues{NoOfDaysRowsKept}, getdate())";

	$subStatus = &T38lib::bbyado::execSQL($gserverName, $T38lib::t38cfgfile::gConfigValues{RepoDatabaseName}, $SQLCmd);

	if ($subStatus == 0) {
		&T38lib::Common::errme("$SQLCmd Failed");
	}

	&T38lib::Common::notifyWSub("SUB DONE");

	return($subStatus);
}

__END__

=pod

=head1 T38shctg.pl

T38shctg.pl - Run dbcc showcontig and parse information so it can be inserted to repository table

=head1 SYNOPSIS

perl T38shctg.pl -h or -c T38dba.cfg and/or -S Server Name 

=head2 OPTIONS

I<T38shctg.pl> accepts the following options:

=over 4

=item -h 		(Optional)

Print out a short help message, then exit.

=item -S Server Name

-S option to provide Server Name

=item -c Cfg File Name Required

-c cfg file name 

=back

=head1 DESCRIPTION

=head1 EXAMPLE

	perl T38shctg.pl -c T38dba.cfg
   Run T38shctg.pl on local server using T38dba.cfg configuration file	

	perl T38shctg.pl -c T38dba.cfg -S HST6db
   Run T38shctg.pl using T38.cfg configuration file on server HST6DB

=head1 BUGS

I<T38shctg.pl> has no known bugs.

=head1 REVISION HISTORY

$Revision: 1.1 $

=head1 AUTHOR

Asif Kaleem, Asif.Kaleem@bestbuy.com

=head1 SEE ALSO

Common.pm

=head1 COPYRIGHT and LICENSE

This program is copyright by Best Buy Inc.

=cut
