#!perl
#
# PVCS header information
# $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38DFrag.pv_  $
# $Author: A645276 $
# $Date: 2011/02/08 17:12:20 $
# $Revision: 1.1 $
#
#* Purpose: 
#*
#* Summary:
#*
#* Program must be executed from within the directory it is located.
#*
#* SYNOPSIS
#* T38DFrag.pl -h | -a 10 -S serverName -i -t -c T38dba.cfg [configFileList]
#*
#* Command line:
#*
#* -a Number of log file archived, default is 7
#* -c T38DBA.cfg is the name of the configuration file (Required)
#* -S server, optional server name (optional)
#* -i Run DBCC INDEXDEFRAG, default is to run DBCC DBREINDEX
#* -h  Writes help screen on standard output, then exits.
#* -t Process only tables, provided by T38LIST:ReindexIncludeTblNm
#*    parameter in configuration files.
#* configFileList list of configuration files to process, in addition
#*		to file, provided with -c switch. These files are read after
#*		parameters from the file, provided by -c switch, are read. 
#*
#* Example: 
#*   1. Run T38DFrag.pl using T38dba.cfg as input parameter on current box
#*      perl T38DFrag.pl -c T38dba.cfg
#*		
#*   2. Run T38DFrag.pl using T38dba.cfg and t38dfragSTSTables.cfg as input
#*      parameter on current box. Process only tables, provided in
#*      configuration files and do not read any tables from repository.
#*      perl T38DFrag.pl -t -c T38dba.cfg t38dfragSTSTables.cfg
#*
#***

#------------------------------------------------------------------------------------------
# Turn on strict, a must for every perl program in production
#------------------------------------------------------------------------------------------
use strict;

#------------------------------------------------------------------------------------------
# Modules used.
#------------------------------------------------------------------------------------------
use Getopt::Std;
use File::Basename;
use T38lib::Common;
# use T38lib::t38cfgfile;
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use T38lib::bbyado qw(:BBYADO_SUBS :BBYADO_VARS);

#------------------------------------------------------------------------------------------
# Function declaration in alphabetical order
#------------------------------------------------------------------------------------------
sub mainControl();
sub getIncludeExcludeTables ();
sub showHelp();
sub readparmfile($\%);
sub testConfigParm(%);
sub runDbReindex($$$);
sub runIndexReorganize($$$$);
sub runAlterIndex($$$$$);
sub runIndexDefrag($$$$);
sub getCurTime();
sub updateRepository($$;$;$);
sub findObjOwner($$);

#------------------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------------------

my @gIncludeTables	= ();
my @gExcludeTables	= ();
my ($cur_time);
my ($sec, $min, $hour, $mday, $month, $year, $wday, $yday, $isdst);

my ($gserverName,$gscript, $gconfigFileName, $exitStatus);
my ($glogFileName, $gnetSrvr, $gInstName, $gresDate) = ("","","");
my ($gindexDefragFlag) = 0;		# Do not run DBCC INDEXDEFRAG, 
# New Code TSMRXM
my ($gOnlineIndexFlag) = 0;		# Use online Index rebuilds, 

my ($gIndexRebuildFlag) = 0;		# REBUILD INDEX

# End of New Code

my $gignoreRepoFlag = 0;		# Process only tables, explicitly provided in configuration file.
								# Ignore tables from repository.

my ($gscriptSuffix,$gscriptName) = ("","");	# Base name of the current script.
my ($gscriptPath) = ".\\";		        			# Directory path to current script.

# Set from cfg file
my ($gadPath, $gsqlType, $gfilterDB);

my ($gT38ERROR) = $T38lib::Common::T38ERROR;			
my ($gisql) = "osql -E -h-1 -n -w2048"; 

#New code add Milind
my $gSqlVersionMajor = 0;
#New code add end

#------------------------------------------------------------------------------------------
# Global Constant
#------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------
# Main program call the sub called mainControl, main driver of
# the program
#------------------------------------------------------------------------------------------
$exitStatus = &mainControl();

#------------------------------------------------------------------------------------------
# Log or errme depending on the exit Status
#------------------------------------------------------------------------------------------
($exitStatus == 0 ) ? 
	&T38lib::Common::logme("Program Finished with status $exitStatus, OK"):
	&T38lib::Common::errme("Program Finished with status $exitStatus, FAILED");

exit ($exitStatus); 	# 0 is OK, 1 Failed

# End of Main Program

#------------------------------------------------------------------------------------------
# 						***  SUBROUTINES ***
#------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------
#	Purpose:  Main driver of the program
#
#	Input Argument:  None
#	Output:  0 OK, 1 Failed
#------------------------------------------------------------------------------------------
sub mainControl() {

	my ($mainStatus) = 0;
	my ($numArchive) = 7;
	my ($hrsToSec) = 3600;
	my ($logStr) = $0;
	my ($cmdSrvrName) = ("");
	my @cmdargs	= ();
	my $cfgfile	= '';
	my ($sql, $isql) = ("", "");
	my ($comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted);
	my ($DBHandle, $dbName, $sqlVersion);
	my (@dbToProcess, @repoData, @sqlVer);
	my @dbToExclude	= ();
	my ($DbName, $TblName, $IdexName, $i, $TblToProcess);
	my $ownerName	= 0;
	my ($startTime, $startTimestamp, $endTimestamp, $resDate, $temp);
	my $rtnStatus = 0;
	my $IndexFragPct = 20;
	my $IndexPageCnt = 1000;

# New Code TSMRXM
	my($processID, $tmpFN, $outfile, $err, $sev, $logFileName, $base, $logFilePath, $type);
# End of New Code


	#------------------------------------------------------------------------------------------
	# Get the script path, name and suffix
	#------------------------------------------------------------------------------------------
	($gscriptPath, $gscriptName, $gscriptSuffix) = &T38lib::Common::parseProgramName();
	
	if ( $#ARGV < 1 ) {
		&showHelp();
		exit($mainStatus);	
	}
	#------------------------------------------------------------------------------------------
	# check the command line arguments
	#------------------------------------------------------------------------------------------
	getopts('ha:itS:c:');
	if ($#ARGV >= 0 ) {
		# Expand command line arguments, perform globbing.
		# If command line contain any wild characters then expand 
		#
		@cmdargs = &T38lib::Common::globbing(@ARGV);
		if ( $cmdargs[0] ne $gT38ERROR ) {
			@ARGV = @cmdargs;
		} else {
			@cmdargs = ();
		}
	}

	#------------------------------------------------------------------------------------------
	# If -h command line option is given show help message
	#------------------------------------------------------------------------------------------

	if ( $Getopt::Std::opt_h ) {
		&showHelp();
		exit($mainStatus);	
	}

	BLOCK: {	# START OF BLOCK 

		unless (&T38lib::Common::setLogFileDir("${gscriptPath}T38LOG")) {
			&T38lib::Common::errme("Can NOT set up the log file directory.");
			$mainStatus = 1;
			last BLOCK;
		}

		#------------------------------------------------------------------------------------------
		# Archive the log file.  Keep last three run archive.
		#------------------------------------------------------------------------------------------

		if($Getopt::Std::opt_a) {
			$logStr = $logStr . " -a $Getopt::Std::opt_a";
			if ( $Getopt::Std::opt_a =~ /\d/) {
				if ( ($Getopt::Std::opt_a < 101) and ($Getopt::Std::opt_a > 0) ) {
					$numArchive = $Getopt::Std::opt_a;
				}
			}
		}
		&T38lib::Common::archiveLogFile($numArchive);

		&T38lib::Common::notifyWSub("SUB STARTED");

		if ($Getopt::Std::opt_c) {
			$gconfigFileName = $Getopt::Std::opt_c;
			$logStr = $logStr . " -c $gconfigFileName";
			
			# Clear the %gConfigValues hash.
			&T38lib::t38cfgfile::delConfigValues();

			# if ( (&readParmFile($gconfigFileName, \%gconfigValues )) == 0 ) {
			if ( (&readConfigFile($gconfigFileName )) == 0 ) {
				&T38lib::Common::errme("Can NOT read cfg file: $gconfigFileName");
				$mainStatus = 1;
				last BLOCK;
			}

			# Check if more parameter files are created on command line.			
			foreach $cfgfile (@cmdargs) {
				if (&readConfigFile($cfgfile) == 0) { 
					&T38lib::Common::errme("Can NOT read cfg file: $cfgfile");
					$mainStatus = 1;
					last BLOCK;
				}
			}

			unless (&testConfigParm(%gConfigValues)) {
				&T38lib::Common::errme("Can NOT validate parameter in cfg file: $gconfigFileName");
				$mainStatus = 1;
				last BLOCK;
			}

			unless (&getIncludeExcludeTables()) {
				&T38lib::Common::errme("Problem with Include/Exclude table list in cfg file: $gconfigFileName");
				$mainStatus = 1;
				last BLOCK;
			}
		}
		else {
			&T38lib::Common::errme("Command line argument -c CFGFILENAME missing");
			$mainStatus = 1;
			last BLOCK;
		}
		
		# Uncomment this for testing.
		# &printConfigValues();

		if ($gConfigValues{DfragEnable} =~ /y/i) {
			&T38lib::Common::notifyWSub("DFrag is enable");
		}
		else {
			&T38lib::Common::notifyWSub("DFrag is NOT enable, check the $gconfigFileName");
			last BLOCK;
		}


		#------------------------------------------------------------------------------------------
		# Check the command line option for server name or
		# if server name is given as . then change it to local host name
		#------------------------------------------------------------------------------------------
		$gserverName = uc(Win32::NodeName());		# get the server name

		if($Getopt::Std::opt_S) {
			$cmdSrvrName = $Getopt::Std::opt_S;
			$cmdSrvrName =~ s/^\./$gserverName/;
			$gserverName = uc($cmdSrvrName);

			($gnetSrvr, $gInstName)	=	split("\\\\", $gserverName); 

			$sqlVersion = &T38lib::Common::getSqlVerReg($gnetSrvr,$gInstName);

			$logStr = $logStr . " -S $gserverName";
			$gisql = $gisql . " -S $gserverName";
		}
		else {
			$gnetSrvr = $gserverName;
			$sqlVersion = &T38lib::Common::getSqlVerReg($gnetSrvr);
			$gisql = $gisql . " -S $gserverName";
		}

		# If ReposServerName is LocalSystem then change the 
		# repository server name to the local box
		#
		if ($gConfigValues{RepoServerName} =~ /LocalSystem/i) {
			$gConfigValues{RepoServerName} = $gserverName;
		}

		# Make sure that -i flag is set if the sql version is 8.0 or higher
		@sqlVer = 	split (/\./, $sqlVersion);

		#New code Milind
		$gSqlVersionMajor = $sqlVer[0];
		#New code end

		if ($Getopt::Std::opt_i) {
			if ( $sqlVer[0] < 8) {
				&T38lib::Common::notifyWSub("Command line argument -i is ignored.  This flag is only valid for SQL version 8.0 or higher");
			}
			else {
				$gindexDefragFlag = 1;		
				$logStr = $logStr . " -i ";
			}
		}          
		#  New Code TSMRXM /a413061
		#  New Code to check for SQL 2005 and Set Indexing/defrag flags
		  
		if ($sqlVer[0] >= 9) {
				&T38lib::Common::setIsqlBin("sqlcmd");
		}
		$gIndexRebuildFlag = 0; 
		$gOnlineIndexFlag =  0;

		# if -i paramter is passed command line argument, Index option as in t38dba.cfg are ignored 

		if ($gindexDefragFlag == 1) {
			&T38lib::Common::notifyWSub("Index Defrag Option enabled via command - CFG paramters will be ignored");
		}
		else {
			$gindexDefragFlag = 1;
			if ($gConfigValues{IndexRebuildEnable}=~/Y/i  ) {
				&T38lib::Common::notifyWSub("Index Rebuild  is enabled");
				$gIndexRebuildFlag = 1; 
				$gindexDefragFlag = 0;		
			}

			if ($sqlVer[0] >= 9) {
				if ($gConfigValues{IndexRebuildOnline}=~/Y/i  ) {
					&T38lib::Common::notifyWSub("Online Index Rebuild is enabled");
					$gOnlineIndexFlag = 1;
				}
			}	
			
		}		

 		&T38lib::Common::notifyWSub("Online Index flag $gOnlineIndexFlag ,Index Rebuild Option $gIndexRebuildFlag, Defrag Option $gindexDefragFlag");
		
		#  End of new code			
		if ($Getopt::Std::opt_t) {
			$gignoreRepoFlag = 1;
			$logStr = $logStr . " -t ";
		}

		&T38lib::Common::notifyWSub("Command line: $logStr " . join(' ' , @cmdargs));

		if ($gConfigValues{WhichDB} !~ /^(DBALL)$/i ) {
			@dbToProcess = 	split (/,/, $gConfigValues{WhichDB});
		}
		else {
			$dbToProcess[0] = "DBALL";
		}

		for $i (0..$#dbToProcess) {
			$dbToProcess[$i] = &T38lib::Common::stripWhitespace($dbToProcess[$i]);
		}

		if ( defined($gConfigValues{ReindexExcludeDB}) ) {
			@dbToExclude = 	split (/,/, $gConfigValues{ReindexExcludeDB});
		}

		for $i (0..$#dbToExclude) {
			$dbToExclude[$i] = &T38lib::Common::stripWhitespace($dbToExclude[$i]);
		}

		# Remove exclude databases from all known lists at this point to reduce number of 
		# tables to process.

		foreach $dbName (@dbToExclude) {
			if ($dbName eq 'DBALL') {
				&T38lib::Common::warnme("Check ReindexExcludeDB parameter in configuration file. Cannot use 'DBALL' for database name in exclude list .");
				next;
			}
			for ($i = 0; $i < scalar @dbToProcess;) {
				($dbToProcess[$i] eq $dbName) ? splice (@dbToProcess, $i, 1) : $i++;
			}

			# Ensure table is not included.
			for ($i = 0; $i < scalar @gIncludeTables;) {
				($gIncludeTables[$i]{LOC_SRVR_DBINST_DB_NM} eq $dbName) ? splice (@gIncludeTables, $i, 1) : $i++;
			}

			# There is no point of excluding tables if database is excluded.
			for ($i = 0; $i < scalar @gExcludeTables;) {
				($gExcludeTables[$i]{LOC_SRVR_DBINST_DB_NM} eq $dbName) ? splice (@gExcludeTables, $i, 1) : $i++;
			}
		}

		&printIncExcTables ();

		$startTime = &getCurTime();
		$startTimestamp	= time;

		# This date is used to get the rows from repository.
		#
		$temp = $wday + 1;
		$isql = $gisql;
		$isql = $isql . " -Q ";
		$isql = $isql . " \"set nocount on; select DATEADD(dd, -$temp, '$startTime')\" ";
		&T38lib::Common::notifyWSub("$isql");
		$resDate = `$isql`;
		chomp($resDate);
		$resDate =~ s/^\s+//;		# Remove leading white spaces
		$resDate =~ s/\s+$//;		# Remove trailing white spaces

		if ( ($resDate =~ /Msg/i) or ($resDate =~ /ConnectionOpen/i) ) {
			&T38lib::Common::errme("SQL command Failed");
			&T38lib::Common::errme("$isql");
			&T38lib::Common::errme("$resDate");
			$mainStatus = 1;
			last BLOCK;
		}


		&T38lib::Common::notifyWSub("$resDate");
		$gresDate = $resDate;

		$temp = &getCurTime();
		$temp = $temp - $startTime;

		#------------------------------------------------------------------------------------------
		# Run pre-dfrag script if specified
		#------------------------------------------------------------------------------------------

		if ($gConfigValues{DefragPreRunScript}) {
			&T38lib::Common::notifyWSub("Running Defrag Preprocessing script $gConfigValues{DefragPreRunScript}");

			$rtnStatus = &T38lib::Common::runSQLChk4Err($gConfigValues{DefragPreRunScript}, $gserverName, "", "DefragPreRunScript.out", "", "", "", "");

			if ($rtnStatus != 0) {
				&T38lib::Common::warnme("Pre Processing script failed");
			}

	    }

		# New Code TSMRXM
		#  New Code for to get log file name for text field error check
		$processID = $$;
		$tmpFN = "tmp$processID.out";
		while ( -s $tmpFN ) {
			$processID += 1;
			$tmpFN = "tmp$processID.out";
		}
		$outfile = $tmpFN;
		if ($outfile !~ /^\\|.:/) { 
			$logFileName = &T38lib::Common::getLogFileName($0);
			fileparse_set_fstype("MSWin32");
			($base, $logFilePath, $type) = fileparse($logFileName, '\.[^\.]*');
		
			# Set the output file name using -o option
			#
			$outfile = $logFilePath . "$outfile";
		}
		#  End of new code
		
		

		foreach $dbName (@dbToProcess) {
			$dbName = &T38lib::Common::stripWhitespace($dbName);

			if (!$gignoreRepoFlag) {
				# Build the select statement and execute 
				# New code for SQL 2005 by DTZ on 15-Feb-2010
				if ($gSqlVersionMajor >= 9) {
					
					if ( defined($gConfigValues{IndexFragPct}) ) {
						$IndexFragPct = $gConfigValues{IndexFragPct}
					}
					if ( defined($gConfigValues{IndexPageCnt}) ) {
						$IndexPageCnt = $gConfigValues{IndexPageCnt}
					}

					$sql = "SELECT LOC_SRVR_DBINST_DB_NM, SCHEMA_NM,DB_TABL_NM, DB_TABL_INDX_NM FROM ";
					$sql = $sql . $gConfigValues{RepoDatabaseName} . ".." . $gConfigValues{RepoTableName};
					
					if ( $gInstName ne "") {
						$sql = $sql . " WHERE LOC_SRVR_NM = '" . $gnetSrvr . "'";
						$sql = $sql . " AND LOC_SRVR_DBINST_NM = '" . $gInstName . "'";
						$sql = $sql . " AND INDX_DISALLOW_PAGE_LOCKS = 0";
					}
					else {
						$sql = $sql . " WHERE LOC_SRVR_NM = '" . $gserverName . "'";
						$sql = $sql . " AND LOC_SRVR_DBINST_NM = 'MSSQLServer'";
						$sql = $sql . " AND INDX_DISALLOW_PAGE_LOCKS = 0";
					}

					$sql = $sql . " AND DB_TBL_INDX_ID > 0";
					$sql = $sql . " AND DB_TBL_INDX_ID < 255";
	
					$sql = $sql . " AND DB_TABL_CNTIG_TS > '" . $resDate . "'";
					$sql = $sql . " AND LAST_INDX_DEFRAG_TS IS NULL ";
	
					$sql = $sql . " AND ((AVG_FRAG_PCT >= " . $IndexFragPct . ")"; 
					$sql = $sql . " AND (PG_CNT >= " . $IndexPageCnt; 

				
					if ($gConfigValues{MaxRowCount} != 0 ) {
						$sql = $sql . " OR REC_CNT > " . $gConfigValues{MaxRowCount} . "))";
					}
	
					if ($dbName !~ /^(DBALL)$/i ) {
						$sql = $sql . " AND LOC_SRVR_DBINST_DB_NM = '" . $dbName . "'";
					}

					$sql = $sql . " ORDER BY PG_CNT DESC";
					

				}
				# End of New code for SQL 2005
				else {
					$sql = "select LOC_SRVR_DBINST_DB_NM, DB_TABL_NM, DB_TABL_INDX_NM from ";
					$sql = $sql . $gConfigValues{RepoDatabaseName} . ".." . $gConfigValues{RepoTableName};

					if ( $gInstName ne "") {
						$sql = $sql . " Where LOC_SRVR_NM = '" . $gnetSrvr . "'";
						$sql = $sql . " AND LOC_SRVR_DBINST_NM = '" . $gInstName . "'";
					}
					else {
						$sql = $sql . " Where LOC_SRVR_NM = '" . $gserverName . "'";
						$sql = $sql . " AND LOC_SRVR_DBINST_NM = 'MSSQLServer'";
					}
	
					$sql = $sql . " AND DB_TABL_INDX_ID > 0";
					$sql = $sql . " AND DB_TABL_INDX_ID < 255";
	
					$sql = $sql . " AND DB_TABL_CNTIG_TS > '" . $resDate . "'";
					$sql = $sql . " AND LAST_INDX_DEFRAG_TS IS NULL ";
	
					if ($gConfigValues{ScanDensity} != 0 ) {
						$sql = $sql . " AND SCAN_DENS_PCT < " . $gConfigValues{ScanDensity}; 
					}
	
					if ($dbName !~ /^(DBALL)$/i ) {
						$sql = $sql . " AND LOC_SRVR_DBINST_DB_NM = '" . $dbName . "'";
					}

					if ($gConfigValues{MaxRowCount} != 0 ) {
						$sql = $sql . " AND DB_TABL_ROW_CNT > " . $gConfigValues{MaxRowCount};
						$sql = $sql . " ORDER BY DB_TABL_ROW_CNT ";
					}
				}
				
				&T38lib::Common::notifyWSub("$sql");


				#------------------------------------------------------------------------------------------
				# Get a connection handle to the given SQL Server
				#------------------------------------------------------------------------------------------
				if ( ($DBHandle = &adoConnect($gConfigValues{RepoServerName}, $gConfigValues{RepoDatabaseName})) == 0 ) {
					&T38lib::Common::errme("Can NOT get a connection to $gConfigValues{RepoServerName}");
					$mainStatus = 1;
					last BLOCK;
				}

				# Get rows from repository table which has show contig info
				#
				unless (execSQL2Arr($DBHandle, $sql, \@repoData)) {
					&T38lib::Common::errme("Call to execSQL2Arr failed.");
					$mainStatus = 1;

					if ( $DBHandle ) {
						$DBHandle->Close();
						$DBHandle = 0;

					}
					last BLOCK;
				}
				
				# Close the connection to the SQL server
				#
				if ( $DBHandle ) {
					$DBHandle->Close();
					$DBHandle = 0;
				}
			} # end if !$gignoreRepoFlag

			# Add and remove tables, as provided by cofiguration parameters.

			# Debug code:
			# &printRS(\@repoData);
			# Debug code end:
			
			if ($gSqlVersionMajor >= 9) {
				&removeDuplicateRS2005(\@repoData);
			}
			else {
				&removeDuplicateRS(\@repoData);
			}
			&addRequired2TblLst($dbName, \@repoData);
			&removeExcludedTables(\@dbToExclude, \@repoData);


			# Debug code:
			
			# Debug code end:

			# Make sure we have rows to process
			#
			if ($#repoData < 0) {
				&T38lib::Common::notifyWSub("No rows found in the Repository to process");
			}
			else {
				$i = $#repoData + 1;
				&T38lib::Common::notifyWSub("Number of objects to process: $i");
				$i=0;

				if ( ($gConfigValues{TblToProcess} != 0) 
					and ($gConfigValues{TblToProcess} < $#repoData) ) {
					$TblToProcess =  $gConfigValues{TblToProcess} - 1;
				}
				else {
					$TblToProcess =  $#repoData;
				}
				for $i (0..$TblToProcess) {
					$DbName = $repoData[$i]{LOC_SRVR_DBINST_DB_NM};
					$TblName = $repoData[$i]{DB_TABL_NM};
					$IdexName = (defined($repoData[$i]{DB_TABL_INDX_NM})) ?  $repoData[$i]{DB_TABL_INDX_NM} : 0;
					$ownerName = (defined($repoData[$i]{SCHEMA_NM})) ? $repoData[$i]{SCHEMA_NM} : 0;

					# New Code - Check if $outfile already exists or Not - a413061
					# if file exists then generate new out file		 
					while ( -s  $outfile ) {
						&T38lib::Common::notifyWSub("Out file File exists. Generating new File ...");	
						$processID += 1;
						$tmpFN = $logFilePath . "tmp$processID.out";
						$outfile = $tmpFN;
					}

					&T38lib::Common::notifyWSub("Outfile name  $outfile");

					if ($gindexDefragFlag == 1) {
						if ($gSqlVersionMajor >= 9) {
							# new code here1
							unless (&runIndexReorganize($DbName, $TblName, $IdexName, $ownerName) ) {
								&T38lib::Common::errme("sub runIndexReorganize failed");
								$mainStatus = 1;
							    }

						   }
						else {
							unless (&runIndexDefrag($DbName, $TblName, $IdexName, $ownerName) ) {
								&T38lib::Common::errme("sub runIndexDefrag failed");
								$mainStatus = 1;
							    }
						       }
					}
					else {
						# New Code TSMRXM - a413061
						# New Code to run Online Index Rebuild
						if ($gOnlineIndexFlag == 1) {
 							unless (&runAlterIndex($DbName, $TblName, $ownerName,$IdexName,1) ) {
								#New Code for text field error check
								&T38lib::Common::errme("sub runAlterIndex Online Failed !!");
								#	unlink ($outfile);
								# Open the output file to check for errors
								#
								
								unless (open(ERRFILE, $outfile)) { 
									&T38lib::Common::notifyWSub("Can not open file : $outfile");
									$mainStatus = 1;
									last BLOCK;	
								}
									# Parse the file to see for any sql generated errors.
									#
									foreach (<ERRFILE>)	{
										chomp();
										if ( /^$/) {
											next;
										}
										# Check for Msg messages  
										# Set status accordingly.
										#	
										if (m/Msg\s* (\d+),\s* Level\s*(\d+),/i) {
											($err, $sev) = ($1, $2);
											#Is there a text field in table.
											if ($err == 2725 ) {
											     # new code here - Online reindex has failed with 2725 error so reindex Offline mode
     											      &T38lib::Common::notifyWSub("Error 2725 encountered.Reindex will be executed in Offline mode now !!");
                               								      unless (&runAlterIndex($DbName, $TblName, $ownerName,$IdexName,0)) {
											      &T38lib::Common::errme("sub runAlterIndex Offline failed");
											      $mainStatus = 1;
											     }
											   } 
											else  {
												&T38lib::Common::notifyWSub("Online Reindex Failed with SQL error:$err level:$sev !!");
												$mainStatus = 1;
											      }
										}
									}
							
								 close(ERRFILE);
								#  End of new code
							}
						 }
						else {
							if ($gSqlVersionMajor >= 9) {
								# new code a413061
								# Rebuild index offline
								unless (&runAlterIndex($DbName, $TblName, $ownerName,$IdexName,0)){
									&T38lib::Common::errme("sub runAlterIndex ->Index Rebuild Offline failed");
									$mainStatus = 1;
							   	  }
							}
							else {		# not a SQL 2005 system
								unless (&runDbReindex($DbName, $TblName, $ownerName) ) {
								&T38lib::Common::errme("sub runDbReindex failed");
								$mainStatus = 1;
							}
						      }
						   }
					}

					$endTimestamp = time;
					if ( $gConfigValues{HowLongToRun} != 0 ) {
						# Check if it is time to quit.
						if ( ($endTimestamp - $startTimestamp) >= ($gConfigValues{HowLongToRun}*$hrsToSec) ) {
							&T38lib::Common::errme("Max time allowed to run has passed, Quiting the program");
							last BLOCK;
						}
					}
				}
			}
			@repoData = ();
		}
	} # END OF BLOCK 

 	#------------------------------------------------------------------------------------------
	# Run post-dfrag script if specified
	#------------------------------------------------------------------------------------------

	if ($gConfigValues{DefragPostRunScript}) {
		&T38lib::Common::notifyWSub("Running Defrag PostProcessing script $gConfigValues{DefragPostRunScript}");

		$rtnStatus = &T38lib::Common::runSQLChk4Err($gConfigValues{DefragPostRunScript}, $gserverName, "", "DefragPostRunScript.out", "", "", "", "");

		if ($rtnStatus != 0) {
			&T38lib::Common::errme("Post Processing script failed");
			$mainStatus = 1;
		}

    }

	($mainStatus == 0 ) ? 
		&T38lib::Common::notifyWSub("Sub Status $mainStatus, OK"):
		&T38lib::Common::notifyWSub("Sub Status $mainStatus, FAILED");

	&T38lib::Common::notifyWSub("SUB DONE");

	return ($mainStatus);

} # End of mainControl


# ----------------------------------------------------------------------
#	getIncludeExcludeTables		get include/exclude tables from configuration parameters.
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	get include/exclude tables from configuration parameters.
# ----------------------------------------------------------------------

sub getIncludeExcludeTables () {
	my $key		= 0;
	my $aref	= 0;
	my $nvals	= 0;
	my ($i, $j)	= (0, 0);
	my $status	= 1;
	my %tbrec	= 0;
SUB:
{
	&T38lib::Common::notifyWSub("Started.");

	# Verify all data in table lists is valid.

	foreach $key (('T38LIST:ReindexIncludeTblNm', 'T38LIST:ReindexExcludeTblNm')) {
		if (defined ($gConfigValues{$key})) {
			$aref	= $gConfigValues{$key};
			$nvals	= scalar @ { $aref };
			for $i (0..$nvals-1) {
				if ($$aref[$i] =~ /^\[([^\[\]]+)\]\.\[([^\[\]]+)\]\.\[([^\[\]]+)\]$/) {
					$tbrec{LOC_SRVR_DBINST_DB_NM}	= &T38lib::Common::stripWhitespace($1);
					$tbrec{TABL_OWNER_NM}			= &T38lib::Common::stripWhitespace($2);
					$tbrec{DB_TABL_NM}				= &T38lib::Common::stripWhitespace($3);
				} else {
					&T38lib::Common::warnme("Invalid configuration parameter $key = $$aref[$i].");
					$status = 0;
					last SUB;
				}
				if ($key eq 'T38LIST:ReindexIncludeTblNm') {
					$gIncludeTables[$#gIncludeTables+1]{LOC_SRVR_DBINST_DB_NM}	= $tbrec{LOC_SRVR_DBINST_DB_NM};
					$gIncludeTables[$#gIncludeTables]{TABL_OWNER_NM}			= $tbrec{TABL_OWNER_NM};
					$gIncludeTables[$#gIncludeTables]{DB_TABL_NM}				= $tbrec{DB_TABL_NM};
				} else {
					$gExcludeTables[$#gExcludeTables+1]{LOC_SRVR_DBINST_DB_NM}	= $tbrec{LOC_SRVR_DBINST_DB_NM};
					$gExcludeTables[$#gExcludeTables]{TABL_OWNER_NM}			= $tbrec{TABL_OWNER_NM};
					$gExcludeTables[$#gExcludeTables]{DB_TABL_NM}				= $tbrec{DB_TABL_NM};
				}
			}
		}
	}

	# Remove exclude tables from include tables list.
	for $i (0..$#gExcludeTables) {
		for ($j = 0; $j < scalar @gIncludeTables;) {
			(
				$gIncludeTables[$j]{LOC_SRVR_DBINST_DB_NM} eq $gExcludeTables[$i]{LOC_SRVR_DBINST_DB_NM} &&
				$gIncludeTables[$j]{TABL_OWNER_NM} eq $gExcludeTables[$i]{TABL_OWNER_NM} &&
				$gIncludeTables[$j]{DB_TABL_NM} eq $gExcludeTables[$i]{DB_TABL_NM}
			) ? splice (@gIncludeTables, $j, 1) : $j++;
		}
	}

	# Debug Code
	# &printIncExcTables();
	# Debug Code End

	last SUB;
}	# SUB
# ExitPoint:
	&T38lib::Common::notifyWSub("Done. Status: $status.");
	return($status);
}	# getIncludeExcludeTables


# ----------------------------------------------------------------------
#	printIncExcTables		print list of tables from include/exclude parameters
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	print list of tables from include/exclude parameters
# ----------------------------------------------------------------------

sub printIncExcTables () {
	my $status	= 1;
	my $key		= 0;
SUB:
{
	&T38lib::Common::notifyWSub("Started.");
	&T38lib::Common::notifyMe("Include Tables:");
	for $key (0..$#gIncludeTables) {
		&T38lib::Common::notifyMe("[$key]: DB_NM: $gIncludeTables[$key]{LOC_SRVR_DBINST_DB_NM}, OWNER_NM: $gIncludeTables[$key]{TABL_OWNER_NM}, TABL_NM: $gIncludeTables[$key]{DB_TABL_NM}.");
	}

	&T38lib::Common::notifyMe("Exclude Tables:");
	for $key (0..$#gExcludeTables) {
		&T38lib::Common::notifyMe("[$key]: DB_NM: $gExcludeTables[$key]{LOC_SRVR_DBINST_DB_NM}, OWNER_NM: $gExcludeTables[$key]{TABL_OWNER_NM}, TABL_NM: $gExcludeTables[$key]{DB_TABL_NM}.");
	}

	last SUB;
}	# SUB
# ExitPoint:
	&T38lib::Common::notifyWSub("Done. Status: $status.");
	return($status);
}	# printIncExcTables

# ----------------------------------------------------------------------
#	printRS		print result set array
# ----------------------------------------------------------------------
#	arguments:
#		$rTblLst	list of tables
#	return:
#		none
# ----------------------------------------------------------------------
#	print result set array
# ----------------------------------------------------------------------

sub printRS ($) {
	my ($rTblLst)	= @_;
	my $i		= 0;
	my $key		= '';
	my $outline	= '';
	my $status	= 1;
SUB:
{
	&T38lib::Common::notifyWSub("Started.");
	for ($i = 0; $i <= $#{$rTblLst}; $i++) {
		$outline = "tables[$i]: ";
		foreach $key (keys (%{$$rTblLst[$i]}) ) {
			$outline .= "$key = $$rTblLst[$i]{$key}; ";
		}
		&T38lib::Common::notifyMe($outline);
	}

	last SUB;
}	# SUB
# ExitPoint:
	&T38lib::Common::notifyWSub("Done. Status: $status.");
	return($status);
}	# printRS




# ----------------------------------------------------------------------
#	addRequired2TblLst		add tables required by config file to list of tables to process
# ----------------------------------------------------------------------
#	arguments:
#		dbName	database name to work with or DBALL for all databases.
#		rTblLst	reference to array with list of tables to process.
#	return:
#		none
# ----------------------------------------------------------------------
#	add tables required by config file to list of tables to process
# ----------------------------------------------------------------------

sub addRequired2TblLst ($$) {
	my ($dbName, $rTblLst)	= @_;
	my $status	= 1;
	my ($i, $j)	= (0, 0);
SUB:
{
	&T38lib::Common::notifyWSub("Started.");

	# If table is requested to be processed, first remove it from list of
	# tables, returned from repository.
	for $i (0..$#gIncludeTables) {
		next if ($dbName ne 'DBALL' && $dbName ne $gIncludeTables[$i]{LOC_SRVR_DBINST_DB_NM});
		for ($j = 0; $j < scalar @$rTblLst;) {
			(
				$gIncludeTables[$i]{LOC_SRVR_DBINST_DB_NM} eq $$rTblLst[$j]{LOC_SRVR_DBINST_DB_NM} &&
				$gIncludeTables[$i]{DB_TABL_NM} eq $$rTblLst[$j]{DB_TABL_NM}
			) ? splice (@$rTblLst, $j, 1) : $j++;
		}
	}

	# Now add all requested tables to the top of the list.
	for ($i = $#gIncludeTables; $i >= 0; $i--) {
		next if ($dbName ne 'DBALL' && $dbName ne $gIncludeTables[$i]{LOC_SRVR_DBINST_DB_NM});
		# Add reference to anonymous hash.
		unshift (@$rTblLst, 
			{
				LOC_SRVR_DBINST_DB_NM	=> $gIncludeTables[$i]{LOC_SRVR_DBINST_DB_NM},
				TABL_OWNER_NM			=> $gIncludeTables[$i]{TABL_OWNER_NM},
				DB_TABL_NM				=> $gIncludeTables[$i]{DB_TABL_NM}
			}
		);
	}

	last SUB;
}	# SUB
# ExitPoint:
	&T38lib::Common::notifyWSub("Done. Status: $status.");
	return($status);
}	# addRequired2TblLst


# ----------------------------------------------------------------------
#	removeExcludedTables		Remove tables requested to be excluded from list of tables to process
# ----------------------------------------------------------------------
#	arguments:
#		rDbExclude	reference to exclude database list.
#		rTblLst	reference to array with list of tables to process.
#	return:
#		none
# ----------------------------------------------------------------------
#	Remove tables requested to be excluded from list of tables to process
# ----------------------------------------------------------------------

sub removeExcludedTables ($$) {
	my ($rDbExclude, $rTblLst)	= @_;
	my $status	= 1;
	my ($i, $j)	= (0, 0);
	my $dbName	= '';
SUB:
{
	&T38lib::Common::notifyWSub("Started.");

	# If WhichDB configuration parameter is set to DBALL, we may get some tables
	# from repository, that are on ReindexExcludeDB list. 
	# First remove all tables from databases on exclude db list.
	foreach $dbName (@$rDbExclude) {
		for ($j = 0; $j < scalar @$rTblLst;) {
			( $dbName eq $$rTblLst[$j]{LOC_SRVR_DBINST_DB_NM} ) ? splice (@$rTblLst, $j, 1) : $j++;
		}
	}

	# Now remove all tables that are on Exclude tables list.
	for ($i = 0; $i < scalar @gExcludeTables; $i++) {
		for ($j = 0; $j < scalar @$rTblLst;) {
			(
				$gExcludeTables[$i]{LOC_SRVR_DBINST_DB_NM} eq $$rTblLst[$j]{LOC_SRVR_DBINST_DB_NM} &&
				$gExcludeTables[$i]{DB_TABL_NM} eq $$rTblLst[$j]{DB_TABL_NM}
			) ? splice (@$rTblLst, $j, 1) : $j++;
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	&T38lib::Common::notifyWSub("Done. Status: $status.");
	return($status);
}	# removeExcludedTables

# ----------------------------------------------------------------------
#	removeDuplicateRS2005		remove duplicate rows from result set
# ----------------------------------------------------------------------
#	arguments:
#		rTblLst	reference to array with list of tables to process.
#	return:
#		none
# ----------------------------------------------------------------------
#	remove duplicate rows from result set
# ----------------------------------------------------------------------

sub removeDuplicateRS2005 () {
	my ($rTblLst)	= @_;
	my ($i, $j)	= (0, 0);
	my $status	= 1;
SUB:
{
	&T38lib::Common::notifyWSub("Started.");

	# Start from the first element in array, march down and find
	# all the duplicates, removing it from same array.

	for ($i = 0; $i < $#{$rTblLst}; $i++) {
		# Check if same element exists down in the array.
		for ($j = $i+1; $j < scalar @$rTblLst;) {
			# we need to check if same index for the table in database
			# has duplicates.
			(
					$$rTblLst[$j]{LOC_SRVR_DBINST_DB_NM} eq $$rTblLst[$i]{LOC_SRVR_DBINST_DB_NM} &&
					$$rTblLst[$j]{DB_TABL_NM} eq $$rTblLst[$i]{DB_TABL_NM} &&
					$$rTblLst[$j]{DB_TABL_INDX_NM} eq $$rTblLst[$i]{DB_TABL_INDX_NM}
				) ? splice(@$rTblLst, $j, 1) : $j++;
		}	# end for $j
	}	# end for $i

	last SUB;
}	# SUB
# ExitPoint:
	&T38lib::Common::notifyWSub("Done. Status: $status.");
	return($status);
}	# removeDuplicateRS2005

# ----------------------------------------------------------------------
#	removeDuplicateRS		remove duplicate rows from result set
# ----------------------------------------------------------------------
#	arguments:
#		rTblLst	reference to array with list of tables to process.
#	return:
#		none
# ----------------------------------------------------------------------
#	remove duplicate rows from result set
# ----------------------------------------------------------------------

sub removeDuplicateRS () {
	my ($rTblLst)	= @_;
	my ($i, $j)	= (0, 0);
	my $status	= 1;
SUB:
{
	&T38lib::Common::notifyWSub("Started.");

	# Start from the first element in array, march down and find
	# all the duplicates, removing it from same array.

	for ($i = 0; $i < $#{$rTblLst}; $i++) {
		# Check if same element exists down in the array.
		for ($j = $i+1; $j < scalar @$rTblLst;) {
			# If defrag flag is set, we need to check if same index for the table in database
			# has duplicates.
			# If reindexing, we only need to keep rows with unique database and table name.
			if ($gindexDefragFlag == 0) {
				(
					$$rTblLst[$j]{LOC_SRVR_DBINST_DB_NM} eq $$rTblLst[$i]{LOC_SRVR_DBINST_DB_NM} &&
					$$rTblLst[$j]{DB_TABL_NM} eq $$rTblLst[$i]{DB_TABL_NM} &&
					$$rTblLst[$j]{DB_TABL_INDX_NM} eq $$rTblLst[$i]{DB_TABL_INDX_NM}
				) ? splice(@$rTblLst, $j, 1) : $j++;
			} else {
				(
					$$rTblLst[$j]{LOC_SRVR_DBINST_DB_NM} eq $$rTblLst[$i]{LOC_SRVR_DBINST_DB_NM} &&
					$$rTblLst[$j]{DB_TABL_NM} eq $$rTblLst[$i]{DB_TABL_NM}
				) ? splice(@$rTblLst, $j, 1) : $j++;
			}
		}	# end for $j
	}	# end for $i

	last SUB;
}	# SUB
# ExitPoint:
	&T38lib::Common::notifyWSub("Done. Status: $status.");
	return($status);
}	# removeDuplicateRS

#------------------------------------------------------------------------------
# Purpose:	Run DBCC INDEXDEFRAG
#
#	Input:		Database Name, Table Name, Index Name, Table Owner Name
#	Output:		Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub runIndexDefrag($$$$) {
	my ($dbName, $tableName, $indexName, $ownerName) = @_;

	my ($subStatus) = 1;
	my ($cmd, $objOwner) = ("", "");
	my ($rtnStatus);
	my @rs			= ();
	my $sql			= '';
	my $DBHandle	= 0;
	my $i			= 0;
	my ($tmpOwnerName, $tmpTableName) = ('', '');
	my ($temp)	= '' ;
SUB:
{
	&T38lib::Common::notifyWSub("SUB STARTED: dbName = $dbName, tableName = $tableName, indexName = $indexName, ownerName = $ownerName");

	$objOwner = ($ownerName) ? $ownerName : &findObjOwner($dbName, $tableName);

	if ( $objOwner =~ /NULL/i ) {
		&T38lib::Common::notifyWSub("sub findObjOwner failed");
		$subStatus = 0;
	}
	elsif ( $objOwner =~ /OBJMISSING/i ) {
		&T38lib::Common::warnme("$tableName not FOUND in $dbName");
	}
	else {
		# Escape quotes for SQL Server.
		($tmpOwnerName = $objOwner) =~ s/'/''/g;
		($tmpTableName = $tableName) =~ s/'/''/g;

		if (!$indexName) {	# We don't have index name, get all indexes for the table.

			$sql = << "			EOT";
				select name, indid from sysindexes where id = object_id('$tmpOwnerName.$tmpTableName')
					and indid between 1 and 254
					and status & 32 = 0              /* hypothetical */
					and status & 64 = 0              /* statistics */
					and status & 8388608 = 0         /* auto create */
					and status & 16777216 = 0        /* stats no recompute */
			EOT
			if ( ($DBHandle = &adoConnect($gserverName, $dbName)) == 0 ) {
				&T38lib::Common::errme("Can NOT get a connection to $gConfigValues{RepoServerName}");
				$subStatus = 0;
				last SUB;
			}

			# Get rows from repository table which has show contig info
			#
			unless (execSQL2Arr($DBHandle, $sql, \@rs)) {
				&T38lib::Common::errme("Call to execSQL2Arr failed.");
				$subStatus = 0;
				last SUB;
			}
			if ( $DBHandle ) {
				$DBHandle->Close();
				$DBHandle = 0;

			}
		} else {
			$rs[0]{name} = $indexName;
		}

		for $i (0..$#rs) {
			$cmd = "DBCC INDEXDEFRAG([";
		    $cmd = $cmd	. $dbName . "], '";
		    $cmd = $cmd . $tmpOwnerName . ".";
		    $cmd = $cmd . $tmpTableName . "', [";
		    $cmd = $cmd . $rs[$i]{name} . "])";

			&T38lib::Common::notifyWSub("\n" . $cmd);
			$temp = &getCurTime();
			$rtnStatus = &T38lib::Common::runSQLChk4Err($cmd, $gserverName, "", "", "", "", "", "");

			if ($rtnStatus == 0) {
				# Always try to update the repository, even if -t flag is used.
				unless (&updateRepository($dbName, $tableName, $rs[$i]{name},$temp) ) {
					&T38lib::Common::errme("sub updateRepository failed");
					$subStatus = 0;
				}
			}
			else {
				&T38lib::Common::notifyWSub("DBCC INDEXDEFRAG failed");
				$subStatus = 0;
			}
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	if ( $DBHandle ) {
		$DBHandle->Close();
		$DBHandle = 0;

	}
	&T38lib::Common::notifyWSub("SUB DONE. Status: $subStatus.");
	return($subStatus);
}


#------------------------------------------------------------------------------
# Purpose:	Run ALTER INDEX ...with REORGANISE for SQL2005 and above
#
#	Input:		Database Name, Table Name, Index Name, schema name
#	Output:		Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub runIndexReorganize($$$$) {
	my ($dbName, $tableName, $indexName, $ownerName) = @_;

	my ($subStatus) = 1;
	my ($cmd, $objOwner) = ("", "");
	my ($rtnStatus);
	my @rs			= ();
	my $sql			= '';
	my $DBHandle	= 0;
	my $i			= 0;
	my ($tmpOwnerName, $tmpTableName) = ('', '');
	my $temp ='';
SUB:
{
	&T38lib::Common::notifyWSub("SUB STARTED: dbName = $dbName, tableName = $tableName, indexName = $indexName, ownerName = $ownerName");

	#$objOwner = ($ownerName) ? $ownerName : &findObjOwner($dbName, $tableName);

		# Escape quotes for SQL Server.
		($tmpOwnerName = $ownerName) =~ s/'/''/g;
		($tmpTableName = $tableName) =~ s/'/''/g;

		if (!$indexName) {	# We don't have index name, get all indexes for the table.

			$sql = << "			EOT";
				select name, indid from sysindexes where id = object_id('$tmpOwnerName.$tmpTableName')
					and indid between 1 and 254
					and status & 32 = 0              /* hypothetical */
					and status & 64 = 0              /* statistics */
					and status & 8388608 = 0         /* auto create */
					and status & 16777216 = 0        /* stats no recompute */
			EOT
			if ( ($DBHandle = &adoConnect($gserverName, $dbName)) == 0 ) {
				&T38lib::Common::errme("Can NOT get a connection to $gConfigValues{RepoServerName}");
				$subStatus = 0;
				last SUB;
			}

			# Get rows from repository table which has show contig info
			#
			unless (execSQL2Arr($DBHandle, $sql, \@rs)) {
				&T38lib::Common::errme("Call to execSQL2Arr failed.");
				$subStatus = 0;
				last SUB;
			}
			if ( $DBHandle ) {
				$DBHandle->Close();
				$DBHandle = 0;

			}
		} else {
			$rs[0]{name} = $indexName;
		}

		for $i (0..$#rs) {

		    $cmd = "ALTER INDEX [";
		    $cmd = $cmd . $rs[$i]{name} . "] ON ";
		    $cmd = $cmd	. "[" . $dbName . "].";
		    $cmd = $cmd . "[". $tmpOwnerName . "].";
		    $cmd = $cmd . "[". $tmpTableName . "]  REORGANIZE ";

			&T38lib::Common::notifyWSub("\n" . $cmd);
			$temp = &getCurTime();
			$rtnStatus = &T38lib::Common::runSQLChk4Err($cmd, $gserverName, "", "", "", "", "");

			if ($rtnStatus == 0) {
				# Always try to update the repository, even if -t flag is used.	
				unless (&updateRepository($dbName, $tableName, $rs[$i]{name},$temp) ) {
					&T38lib::Common::errme("sub updateRepository failed");
					$subStatus = 0;
				}
			}
			else {
				&T38lib::Common::notifyWSub("ALTER INDEX ...WITH REORGANIZE failed.");
				$subStatus = 0;
			}
		}
	

	last SUB;
}	# SUB
# ExitPoint:
	if ( $DBHandle ) {
		$DBHandle->Close();
		$DBHandle = 0;

	}
	&T38lib::Common::notifyWSub("SUB DONE. Status: $subStatus.");
	return($subStatus);
}

#------------------------------------------------------------------------------
# Purpose:	Update Repository table with the time stamp
#
#	Input:	Database Name, Table Name	
#	Output:	Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub updateRepository($$;$;$) {
	my ($dbName, $tblName, $indxName,$tmpStartDate) = @_;
	my $tmpDbName		= '';
	my $tmpTableName	= '';
	my $tmpIndxName		= '';
	
	my ($subStatus) = 1;
	my ($cmd) = "";
	my ($rtnStatus);

	# Escape quotes for SQL Server.
	($tmpDbName		= $dbName) =~ s/'/''/g;
	($tmpTableName	= $tblName) =~ s/'/''/g;
	($tmpIndxName	= $indxName) =~ s/'/''/g;
	if ($gSqlVersionMajor >= 9) {
		$cmd = "Update " . $gConfigValues{RepoTableName} . " set LAST_INDX_DEFRAG_TS = getdate(), TM_TAKEN_DEFRAG = datediff(ss,'" . $tmpStartDate . "',getdate()) ";
	}
	else {
		$cmd = "Update " . $gConfigValues{RepoTableName} . " set LAST_INDX_DEFRAG_TS = getdate() ";	
	}

	if ( $gInstName ne "") {
		$cmd = $cmd . " Where LOC_SRVR_NM = '" . $gnetSrvr . "'";
		$cmd = $cmd . " AND LOC_SRVR_DBINST_NM = '" . $gInstName . "'";
	} 
	else {
		$cmd = $cmd . " Where LOC_SRVR_NM = '" . $gserverName . "'";
	}

	if ( $indxName ne "") {
		$cmd = $cmd . " AND DB_TABL_INDX_NM = '" . $tmpIndxName . "'";
	}

	$cmd = $cmd . " AND DB_TABL_CNTIG_TS > '" . $gresDate . "'";
	$cmd = $cmd . " AND LOC_SRVR_DBINST_DB_NM = '" . $tmpDbName . "'";
	$cmd = $cmd . " AND DB_TABL_NM = '" . $tmpTableName . "'";
	$cmd = $cmd . " AND LAST_INDX_DEFRAG_TS IS NULL ";

#	&T38lib::Common::notifyWSub($cmd);
	$rtnStatus = &T38lib::Common::runSQLChk4Err($cmd, $gConfigValues{RepoServerName}, $gConfigValues{RepoDatabaseName}, "", "", "", "", "");

	if ($rtnStatus != 0 ) {
		$subStatus = 0;
	}

	&T38lib::Common::notifyWSub("SUB DONE");

	return($subStatus);
}

            
# New Code TSMRXM
#ALTER INDEX ALL ON Production.Product
#REBUILD WITH (ONLINE = ON);

#------------------------------------------------------------------------------
# Purpose:	Run ALTER INDEX REBUILD WITH ONLINE=ON
#
# Input:	Database Name, Table Name, Owner Name
# Output:	Return status 1 OK, 0 Fail 
# Currently this proceure is not used
#------------------------------------------------------------------------------
sub runReindexOnline($$$) {
	my ($dbName, $tableName, $ownerName) = @_;

	my ($subStatus) = 1;
	my ($cmd, $objOwner) = ("", "");
	my ($tmpDbName, $tmpOwnerName, $tmpTableName) = ("", "", "");
	my ($rtnStatus);

	&T38lib::Common::notifyWSub("SUB STARTED: dbName = $dbName, tableName = $tableName, ownerName = $ownerName");
	
	$objOwner = ($ownerName) ? $ownerName : &findObjOwner($dbName, $tableName);

	if ( $objOwner =~ /NULL/i ) {
		&T38lib::Common::notifyWSub("sub findObjOwner failed");
		$subStatus = 0;
	}
	elsif ( $objOwner =~ /OBJMISSING/i ) {
		&T38lib::Common::warnme("$tableName not FOUND in $dbName");
	}
	else {
		# Escape quotes for SQL Server string.
		($tmpDbName = $dbName) =~ s/'/''/g;
		($tmpOwnerName = $objOwner) =~ s/'/''/g;
		($tmpTableName = $tableName) =~ s/'/''/g;

		# Run reindex statement.

		$cmd = "SET ARITHABORT ON; SET QUOTED_IDENTIFIER ON; ALTER INDEX ALL ON ";
	    	$cmd = $cmd	. $tmpDbName . ".";
	    	$cmd = $cmd . $tmpOwnerName . ".";
	    	$cmd = $cmd . $tmpTableName . " REBUILD WITH (SORT_IN_TEMPDB = ON,ONLINE = ON)";
		&T38lib::Common::notifyWSub("\n" . $cmd);
		$rtnStatus = &T38lib::Common::runSQLChk4Err($cmd, $gserverName, "", "", "", "", "", "");

		if ($rtnStatus == 0) {
			unless (&updateRepository($dbName, $tableName) ) {
				&T38lib::Common::notifyWSub("sub updateRepository failed");
				$subStatus = 0;
			}
		}
		else {
			&T38lib::Common::notifyWSub("ALTER INDEX REBUILD ONLINE failed");
			$subStatus = 0;
		}
	}

	&T38lib::Common::notifyWSub("SUB DONE");

	return($subStatus);
}

# End of New Code

#------------------------------------------------------------------------------
# Purpose:	Run ALTER INDEX REBUILD WITH ONLINE=ON/OFF
#
# Input:	Database Name, Table Name, Owner Name,Index Name, Alter Index Mode
# Output:	Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub runAlterIndex($$$$$) {
	my ($dbName, $tableName, $ownerName,$indexName,$isOnline) = @_;

	my ($subStatus) = 1;
	my ($cmd, $objOwner) = ("", "");
	my ($tmpDbName, $tmpOwnerName, $tmpTableName) = ("", "", "");
	my ($rtnStatus);
	my ($temp) = '' ;

#	&T38lib::Common::notifyWSub("SUB STARTED: dbName = $dbName, tableName = $tableName, ownerName = $ownerName ,Index name = $indexName,Online = $isOnline");
	
#	$objOwner = ($ownerName) ? $ownerName : &findObjOwner($dbName, $tableName);

		# Escape quotes for SQL Server string.
		($tmpDbName = $dbName) =~ s/'/''/g;
		($tmpOwnerName = $ownerName) =~ s/'/''/g;
		($tmpTableName = $tableName) =~ s/'/''/g;

		# Run reindex statement.

		$cmd = "SET ARITHABORT ON; SET QUOTED_IDENTIFIER ON; ALTER INDEX [" . $indexName . "] ON ";
	   	$cmd = $cmd . "["	. $tmpDbName . "].";
	    	$cmd = $cmd ."[". $tmpOwnerName . "].[" . $tmpTableName . "]";
	   
		if ($isOnline==1) {
	        	$cmd = $cmd . " REBUILD WITH (SORT_IN_TEMPDB = ON,ONLINE = ON)";
		}
		else {
			$cmd = $cmd . " REBUILD WITH (SORT_IN_TEMPDB = OFF,ONLINE = OFF)";
		}
		
		$temp = &getCurTime();
		&T38lib::Common::notifyWSub("\n" . $cmd);
		$rtnStatus = &T38lib::Common::runSQLChk4Err($cmd, $gserverName, "", "", "", "", "", "");

		if ($rtnStatus == 0) {
			unless (&updateRepository($dbName, $tableName,$indexName,$temp ) ) {
				&T38lib::Common::notifyWSub("sub updateRepository failed.");
				$subStatus = 0;
			}
		}
		else {
			&T38lib::Common::notifyWSub("ALTER INDEX REBUILD ONLINE Failed.");
			$subStatus = 0;
		}
	

	&T38lib::Common::notifyWSub("SUB DONE");

	return($subStatus);
}

# End of New Code

#------------------------------------------------------------------------------
# Purpose:	Run DBCC DBREINDEX
#
# Input:	Database Name, Table Name, Owner Name
# Output:	Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub runDbReindex($$$) {
	my ($dbName, $tableName, $ownerName) = @_;

	my ($subStatus) = 1;
	my ($cmd, $objOwner) = ("", "");
	my ($tmpDbName, $tmpOwnerName, $tmpTableName) = ("", "", "");
	my ($rtnStatus);
	my ($temp) = '';
	&T38lib::Common::notifyWSub("SUB STARTED: dbName = $dbName, tableName = $tableName, ownerName = $ownerName");
	
	$objOwner = ($ownerName) ? $ownerName : &findObjOwner($dbName, $tableName);

	if ( $objOwner =~ /NULL/i ) {
		&T38lib::Common::notifyWSub("sub findObjOwner failed");
		$subStatus = 0;
	}
	elsif ( $objOwner =~ /OBJMISSING/i ) {
		&T38lib::Common::warnme("$tableName not FOUND in $dbName");
	}
	else {
		# Escape quotes for SQL Server string.
		($tmpDbName = $dbName) =~ s/'/''/g;
		($tmpOwnerName = $objOwner) =~ s/'/''/g;
		($tmpTableName = $tableName) =~ s/'/''/g;

		# Run reindex statement.

		$cmd = "SET ARITHABORT ON; SET QUOTED_IDENTIFIER ON; DBCC DBREINDEX('";
	   	 $cmd = $cmd	. $tmpDbName . ".";
	   	 $cmd = $cmd . $tmpOwnerName . ".";
	    	$cmd = $cmd . $tmpTableName . "','', 0)";
		&T38lib::Common::notifyWSub("\n" . $cmd);

		$temp = &getCurTime();

		$rtnStatus = &T38lib::Common::runSQLChk4Err($cmd, $gserverName, "", "", "", "", "", "");

		if ($rtnStatus == 0) {
			unless (&updateRepository($dbName, $tableName) ) {
				&T38lib::Common::notifyWSub("sub updateRepository failed");
				$subStatus = 0;
			}
		}
		else {
			&T38lib::Common::notifyWSub("DBCC DBREINDEX failed");
			$subStatus = 0;
		}
	}

	&T38lib::Common::notifyWSub("SUB DONE");

	return($subStatus);
}

#------------------------------------------------------------------------------
# Purpose:	Find the owner of the database objct
#
# Input:	Database Name, Table Name
# Output:	Return Object Owner or NULL to Fail 
#           or OBJMISSING if object not found in the database
#------------------------------------------------------------------------------
sub findObjOwner($$) {
	my ($dbName, $tableName) = @_;

	my ($objOwner) = "NULL";
	my ($cmd, $isql) = ("", "");

	&T38lib::Common::notifyWSub("SUB STARTED");

#New code Milind
	if ($gSqlVersionMajor >= 9) {
		$cmd = "use $dbName; set nocount on;";
		$cmd = $cmd . "select s.name from sys.objects o join sys.schemas s ";
		$cmd = $cmd . "on o.schema_id = s.schema_id ";
		$cmd = $cmd . "where o.name = '$tableName'";

	}
	else {
		$cmd = "use $dbName; set nocount on;";
		$cmd = $cmd . "select k.name from sysobjects j, sysusers k ";
		$cmd = $cmd . "where j.name = '$tableName' ";
		$cmd = $cmd . "and j.uid = k.uid";
	}
#New code end Milind
	

	$isql = $gisql;
	$isql = $isql . " -Q ";
	$isql = $isql . " \"$cmd\" ";
	&T38lib::Common::notifyWSub("$isql");

	$objOwner = `$isql`;
	chomp($objOwner);

	$objOwner =~ s/^\s+//;		# Remove leading white spaces
	$objOwner =~ s/\s+$//;		# Remove trailing white spaces

	if ( ($objOwner =~ /Msg/i) or ($objOwner =~ /ConnectionOpen/i) ) {
		&T38lib::Common::notifyWSub("SQL command Failed");
		&T38lib::Common::notifyWSub("$isql");
		&T38lib::Common::notifyWSub("$objOwner");
		$objOwner = "NULL";
	}

	if ( $objOwner eq "" ) {
		&T38lib::Common::notifyWSub("$tableName not found in database $dbName");
		&T38lib::Common::notifyWSub("$isql");
		&T38lib::Common::notifyWSub("No result set form the above SQl statement");
		$objOwner = "OBJMISSING";
	}

	&T38lib::Common::notifyWSub("SUB DONE");

	return($objOwner);
}

#------------------------------------------------------------------------------
#	Purpose: Get current time and store in global variable
#
#	Input:	None
#	Output:	Formatted Data and Time
#------------------------------------------------------------------------------
sub getCurTime() {

	my ($temp);

	&T38lib::Common::notifyWSub("SUB STARTED");

	$cur_time=time();
	($sec, $min, $hour, $mday, $month, $year, $wday, $yday, $isdst) = localtime($cur_time);
	$year += 1900;
	$month += 1;

	$temp = sprintf ("%04d-%02d-%02d %02d:%02d:%02d", $year,$month,$mday,$hour,$min,$sec);

	&T38lib::Common::notifyWSub("SUB DONE");

	return ($temp);
}

#------------------------------------------------------------------------------
#	Purpose:  Print a help screen on std out.
#
#	Input Argument: None
#	Output:         None
#------------------------------------------------------------------------------
sub showHelp() {

print << 'EOT';
#
# PVCS header information
# $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38DFrag.pv_  $
# $Author: A645276 $
# $Date: 2011/02/08 17:12:20 $
# $Revision: 1.1 $
#
#* Purpose: 
#*
#* Summary:
#*
#* Program must be executed from within the directory it is located.
#*
#* SYNOPSIS
#* T38DFrag.pl -h | -a 10 -S serverName -i -t -c T38dba.cfg [configFileList]
#*
#* Command line:
#*
#* -a Number of log file archived, default is 7
#* -c T38DBA.cfg is the name of the configuration file (Required)
#* -S server, optional server name (optional)
#* -i Run DBCC INDEXDEFRAG, default is to run DBCC DBREINDEX
#* -h  Writes help screen on standard output, then exits.
#* -t Process only tables, provided by T38LIST:ReindexIncludeTblNm
#*    parameter in configuration files.
#* configFileList list of configuration files to process, in addition
#*		to file, provided with -c switch. These files are read after
#*		parameters from the file, provided by -c switch, are read. 
#*
#* Example: 
#*   1. Run T38DFrag.pl using T38dba.cfg as input parameter on current box
#*      perl T38DFrag.pl -c T38dba.cfg
#*		
#*   2. Run T38DFrag.pl using T38dba.cfg and t38dfragSTSTables.cfg as input
#*      parameter on current box. Process only tables, provided in
#*      configuration files and do not read any tables from repository.
#*      perl T38DFrag.pl -t -c T38dba.cfg t38dfragSTSTables.cfg
#*		
#***
EOT

} # End of showHelp


#------------------------------------------------------------------------------
#	Purpose: Test all the configuration parameters to make sure they are there
#            Future processing relies on these parameters.
#
#	Input:		Hash to be verified
#	Output:		Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub testConfigParm(%) {
	my %hash = @_;

	my ($subStatus) = 1;
	my ($key, $value);

	&T38lib::Common::notifyWSub("SUB STARTED");

	while (($key,$value) = each(%hash)) {
		if ($hash{$key} eq "") {
			&T38lib::Common::notifyWSub ("** ERROR ** $key is not define in the cfg file.");
			$subStatus = 0;
		}
	}

	&T38lib::Common::notifyWSub("SUB DONE");

	return($subStatus);

} # end sub testConfigParm


__END__

=pod

=head1 NAME

T38DFrag.pl - Run Dbcc reindex on selected tables from Repository

=head1 SYNOPSIS

T38DFrag.pl -h | -a 10 -S serverName -i -t -c T38dba.cfg [configFileList]

=head2 OPTIONS

I<T38DFrag.pl> accepts the following options:

=over 4

=item -h 		(Optional)

Print out a short help message, then exit.

=item -a 10		(Optional)

-a Number of log file archived, default is 7

=item -S Server Name

-S to provide Server Name

=item -c Cfg File Name Required

-c cfg file name 

=item -i

-i  Run DBCC INDEXDEFRAG, only valid for SQL server version 2000 and up

=item -t

-t  Process only tables, provided by T38LIST:ReindexIncludeTblNm
    parameter in configuration files.

=item configFileList

configFileList list of configuration files to process, in addition 
to file, provided with -c switch. These files are read after 
parameters from the file, provided by -c switch, are read.

=back

=head2 Configuration file parameters

I<Configuration file> can use following parameters:

=over 4

=item DfragEnable

Flag to enable show contig and DeFrag scripts, default for 
both is Y (yes).  If you don't want these scripts to run on
any box then turn these flag to N
Possible values for these flag is (Y) or (N)

=item RepoServerName

RepoServerName is the repository server name.
To run this program on server where it can not connect to the 
central repository we will change the values to LocalSystem
This way it will be using LocalSystem repository to run T38Shctg.pl
and T38Dfrag.pl.  Default value for RepoServerName is production
repository server name, which is now DS02DBA

=item RepoDatabaseName

Repository Database name on RepoServerName

=item RepoTableName

Table name in RepoDatabaseName, used for reindexing (ADMT_DB_CNTIG_HIST)

=item WhichDB

DBALL, to doo all the database (Default)
write database names seperated by comma

=item ReindexExcludeDB

List of databases, which should not be reindexed/defragmented
Write database names seperated by comma
ReindexExcludeDB 		= SKUDB001, MERDB002, ACMDB001, MXHDB001, SVCDB001

=item ScanDensity

Default scan density is 50
Look for tables in the repository who has density equal to or lower
0 to ignore this parm

=item MaxRowCount

Look for tables in the repository that has given number of rows & higher
0 to ignore this parm, 10,000 is default

=item TblToProcess

Once we get the list of tables name from repository, 
then how many table you want to process
0 to ignore this parm (Default)

=item HowLongToRun

How long the perl program should run
0 to ignore this parm
1 hour (Default)

=item T38LIST:ReindexIncludeTblNm

List of table to force reindexing on.
List all tables to reindex using records in the following format:

C<T38LIST:ReindexIncludeTblNm = [DBName].[owner].[TableName1]>

C<T38LIST:ReindexIncludeTblNm = [DBName].[owner].[TableName2]>

...


I<Example:>

C<T38LIST:ReindexIncludeTblNm = [MXRDB001].[dbo].[This Isn't My, Test]>

C<T38LIST:ReindexIncludeTblNm = [MXRDB001].[dbo].[SQLTRACE]>


=item T38LIST:ReindexExcludeTblNm

List of tables to exclude from reindexing.
Use same format as for re-indexing, execpt key is T38LIST:ReindexExcludeTblNm.
NOTE: Since repository does not have table owner information, the owner part
in exclude table definition is ignored, when excluding tables from repository.
When excluding tables from the list of included tables (provided in configuration
file) the owner field will be used, since it is provided in configuration file.

C<T38LIST:ReindexExcludeTblNm = [DBName].[owner].[TableName1]>

C<T38LIST:ReindexExcludeTblNm = [DBName].[owner].[TableName2]>

...


I<Example:>

C<T38LIST:ReindexExcludeTblNm = [MXRDB001].[c3].[jj]>


=back

=head1 DESCRIPTION

=head1 EXAMPLE

	perl T38DFrag.pl -c T38DFrag.cfg
      Run T38DFrag.pl on local server using T38DFrag.cfg configuration file	

	perl T38DFrag.pl -c T38DFrag.cfg -S HST6db
      Run T38DFrag.pl using T38DFrag.cfg configuration file on server HST6DB

	perl T38DFrag.pl -t -c T38dba.cfg t38dfragSTSTables.cfg
     Run T38DFrag.pl using T38dba.cfg and t38dfragSTSTables.cfg as input
     parameter on current box. Process only tables, provided in
     configuration files and do not read any tables from repository.

=head1 BUGS

I<T38DFrag.pl> has no known bugs.

=head1 REVISION HISTORY

$Revision: 1.1 $

=head1 AUTHOR

Asif Kaleem, Asif.Kaleem@bestbuy.com

=head1 SEE ALSO

Common.pm

=head1 COPYRIGHT and LICENSE

This program is copyright by Best Buy Inc.

=cut
