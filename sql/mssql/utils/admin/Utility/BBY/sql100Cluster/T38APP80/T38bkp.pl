#!perl
#
# PVCS header information
# $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL80/T38bkp.pv_  $
# $Author: A645276 $
# $Date: 2011/02/08 17:12:20 $
# $Revision: 1.1 $
#
#* Purpose: Database or tran dump.  You can specify one particular database (-d) and or server (-S) 
#*          and -c cfgfile name for logshipping, -b dump type  -a number of archive log files default 7
#*
#* Summary:
#*   1. Dump database to their db devices.
#*   2. If a database is log ship enable and the dump is on the 
#*      destination server then skip the database dump.
#*   3. Dump tran to their log devices.
#*   4. If database is log ship enable then dump the log to a file
#*      with the time stamp. File name is dbname_log_yyymmddhhmn.bkp
#*   Where 
#*      databasename is the name of the database
#*      log is constant
#*      yyyy four digit year
#*      mm two digits month, January (01) to December (12)
#*      dd two digits calendar date of the month (01 - 31)
#*      hh two digits hour (00 - 23)
#*      mn two digits minutes after the hour (00 - 59)
#*
#* Program must be executed from within the directory it is located.
#*
#* SYNOPSIS
#* T38bkp.pl -h | -S server name | -d database name | -c cfgfile name | -b dump type | -a number
#*
#* Command line:
#*
#* -h  Writes help screen on standard output, then exits.
#* -c  cfg file name for log shipping, optional cfg file name
#* -S	server, optional server name
#* -d  database name, optional database name
#* -b  optional dump type (default db, for database dump, log for only log dump)
#* -a	number of log files archived default is 7
#* -l	log file directory suffix to allow running multiple backup jobs at the same time
#*
#* Example: 
#*   1. Not specifying any command line arguments
#*      perl T38bkp.pl
#*		
#*   2. Specifying the cfg file name and keep 3 previous log files as an archive
#*      perl T38bkp.pl -c T38ls.cfg  -a 3
#*	
#*   3. Specifying cfg file, server with database
#*      perl T38bkp.pl -c T38ls.cfg -S ServerName -d DatabaseName
#*	
#*   4. Specifying cfg file, server with database do only tran dump
#*      perl T38bkp.pl -c T38ls.cfg -S ServerName -d DatabaseName -b log
#*
#*   5. Dump only the log for all the databases keep 10 previous log files as an archive
#*      perl T38bkp.pl -b log -a 10
#*
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
use File::Basename;
use T38lib::Common;
use T38lib::t38cfgfile;
use File::DosGlob qw(glob);

#----------------------------------------------------------------
# Global Variables
#----------------------------------------------------------------
my ($gserverName,$gscript);
my ($gsqlVersion) = 7;
my ($gconfigFile, $glogShipEnabled, $gsrcServerName, $gdestServerName);
my ($glogFileName);
my ($gNetSrvr, $gInstName)	=	"";
my ($gNumHours) = (60);
#Hemanth: Declare the differential database array 
my (@gDBNames, @glogShipDBNames, @gDiffDBNames);

my $gscriptSuffix;
my ($gscriptName) = "";			# Base name of the current script.
my ($gscriptPath) = ".\\";		# Directory path to current script.

my ($gT38ERROR) = $T38lib::Common::T38ERROR;			
my ($gbackupType) = "db";

my ($gisql) = "osql -E -h-1 -n -w2048"; 

#Hemanth: Add new Key, Value pairs to the below hashes -START
my %gdeviceExt  = (	'db' => '_db_bkp', 
					'log' => '_log_bkp',
					'diff' => '_diff_bkp');
my %gdeviceType = (	'db' => 'db',
					'log' => 'log',
					'diff' => 'diff' );

my %gdumpCmd = ('db'    => 'BACKUP DATABASE ',
                'log'   => 'BACKUP TRANSACTION ',
				'diff' => 'WITH DIFFERENTIAL');
#Hemanth: Add new Key, Value pairs to the below hashes -END

#----------------------------------------------------------------
# List of database that will be excluded from db or tran dump
#----------------------------------------------------------------
my ($gfilterDB) = "model|tempdb|northwind|pubs";

#----------------------------------------------------------------
# Function declaration in alphabetical order
#----------------------------------------------------------------
sub buildDevice($$);
sub cleanupHistoryTable();
sub delFilesNHourOld($);
sub dumpDb($$$);
sub dumpDbDiff($$$);
sub dumpLog($$$);
sub getDevices($$);
sub getTimeStr();
sub mainControl();
sub setDboptions($);
sub showHelp();
sub zipORcompressFiles($);

#----------------------------------------------------------------
# Main program call the sub called mainControl, main driver of
# the program
#----------------------------------------------------------------
&mainControl();

#------------------------------------------------------------------------------
# 					***  SUBROUTINES ***
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#	Purpose:  Main driver of the program
#
#	Input Argument: None
#	Output:         None
#------------------------------------------------------------------------------
sub mainControl() {

	my ($mainStatus, $dbFound, $rtnStatus) = 0;
	my ($numArchive) = 7;
	my ($srvrName, $dumpDevice, $db, $diffdb,$cmdLineDBName, $logDirSuffix) = "";
	my ($trandumpLocation);
	my ($logStr) = $0;
	my @temp = ();
	my (%dbDevices);
	my $redoDbDevicesFlg = 0;
	my ($sqlVer, @sqlVersion);
	my ($base, $backupPath, $type);
	my (@includeList, @excludeList, $dblist);
	my ($i, $aref, $nvals);

	#----------------------------------------------------------------
	# Get the script path, name and suffix
	#----------------------------------------------------------------
	($gscriptPath, $gscriptName, $gscriptSuffix) = &T38lib::Common::parseProgramName();

	#----------------------------------------------------------------
	# check the command line arguments
	#----------------------------------------------------------------
	getopts('hvS:d:c:b:a:l:');

	#----------------------------------------------------------------
	# If -h command line option is given show help message
	#----------------------------------------------------------------
	if ($Getopt::Std::opt_h) {
		&showHelp();
		exit($mainStatus);	
	}

	BLOCK: {	# START OF BLOCK 
		#----------------------------------------------------------------
		# Check for command line option for number of log file to archive
		# range is from 1 to 100, default number is 7
		#----------------------------------------------------------------
		if ( ($Getopt::Std::opt_a) and ( $Getopt::Std::opt_a =~ /\d/) and 
			( ($Getopt::Std::opt_a < 101) and ($Getopt::Std::opt_a > 0) ) ) {
			$numArchive = $Getopt::Std::opt_a;
		}

		#----------------------------------------------------------------
		# Check for command line option for backup type 
		# -b db default 	(Do the database dump and init the log )
		# -b log optional	(Do tran dump/ NO DATABASE DUMP)
		#----------------------------------------------------------------
		if($Getopt::Std::opt_b) {
			$gbackupType = lc($Getopt::Std::opt_b);
			if ($gbackupType =~ /log/i ) {
				$logStr = $logStr . " -b $gbackupType";
				$glogFileName = $gscriptName . $gdeviceType{log};
			}
			elsif ($gbackupType =~ /db/i ) {
				$logStr = $logStr . " -b $gbackupType";
				$glogFileName = $gscriptName . $gdeviceType{db};
			}
			#Hemanth: Adding the differential parameters to the options -START
			elsif ( $gbackupType =~ /diff/i ) {
				$logStr = $logStr . " -b $gbackupType";
				$glogFileName = $gscriptName . $gdeviceType{diff};
			}
			#Hemanth: Adding the differential parameters to the options -END
			else {
				&T38lib::Common::errme("Wrong option value -b $gbackupType");
				$mainStatus = 1;
				last BLOCK;
			}
		}
		else {
			$glogFileName= $gscriptName . $gdeviceType{db};
		}

		#----------------------------------------------------------------
		# Append the log file directory suffix if it was supplied 
		#----------------------------------------------------------------
		if($Getopt::Std::opt_l) {
			$logDirSuffix = $Getopt::Std::opt_l;
			$glogFileName= $glogFileName . $logDirSuffix;
		}

		unless (&T38lib::Common::setLogFileDir("${gscriptPath}T38LOG\\$glogFileName")) {
			&T38lib::Common::errme("Can not set up the log file directory.");
			$mainStatus = 1;
			last BLOCK;
		}


  		#----------------------------------------------------------------
		# Archive the log file.  Keep last three run archive.
		#----------------------------------------------------------------
		&T38lib::Common::archiveLogFile($numArchive);

		&T38lib::Common::logme("$gscriptName STARTED");

		#----------------------------------------------------------------
		# Check the command line option for server name or
		# if server name is given as . then change it to local host name
		#----------------------------------------------------------------
		$gserverName = uc(Win32::NodeName());		# get the server name
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

		#----------------------------------------------------------------
		# If database version is 6.5 then set to use isql and 
		# dump commands else use osql and backup command.
		#----------------------------------------------------------------
		$sqlVer = &T38lib::Common::getSqlVerReg($gNetSrvr, $gInstName);
		if ($sqlVer != 0 ) {
			@sqlVersion = split (/\./, $sqlVer);
			$gsqlVersion = $sqlVersion[0];
			
			&T38lib::Common::notifyWSub("SQL Version is $gsqlVersion");
			if ($gsqlVersion < 7) {
				%gdumpCmd = ('db'    => 'DUMP DATABASE ', 'log'   => 'DUMP TRANSACTION ', 'diff' => ' WITH DIFFERENTIAL' );
				$gisql =~ s/osql/isql/; 
				&T38lib::Common::setIsqlBin("isql");
			}
			if ($gsqlVersion == 8) {
				%gdumpCmd = ('db'    => 'BACKUP DATABASE ', 'log'   => 'BACKUP LOG ', 'diff' => ' WITH DIFFERENTIAL' );
				$gisql =~ s/osql/osql/; 
				&T38lib::Common::setIsqlBin("osql");
			}
			if ($gsqlVersion >= 9) {
				%gdumpCmd = ('db'    => 'BACKUP DATABASE ', 'log'   => 'BACKUP LOG ', 'diff' => ' WITH DIFFERENTIAL' );
				$gisql =~ s/osql/sqlcmd/; 
				&T38lib::Common::setIsqlBin("sqlcmd");
			}
		}
		else {
			&T38lib::Common::warnme("Call to &T38lib::Common::getSqlVerReg($gNetSrvr, $gInstName) failed");
			&T38lib::Common::notifyWSub("** WARN ** Call to &T38lib::Common::getSqlVerReg($gNetSrvr, $gInstName) failed");
			&T38lib::Common::notifyWSub("** WARN ** Can not get sql version using default $gsqlVersion");
		}

		#----------------------------------------------------------------
		# get all the databases name from the server system tables.
		#----------------------------------------------------------------
		@gDBNames=&T38lib::Common::getDBNames($gserverName);
		if ( $gDBNames[0] eq "$gT38ERROR" ) {
			&T38lib::Common::errme("Call to &T38lib::Common::getDBNames($gserverName) failed.");
			$mainStatus = 1;
			last BLOCK;
		}

		#----------------------------------------------------------------
		# If -d command line database name is provided check this name 
		# with the database name on the server. If command line database
		# name is not found on the server database name list, display 
		# error and quit block to go to the end of the program.
		#----------------------------------------------------------------
		if($Getopt::Std::opt_d) {
			$cmdLineDBName = $Getopt::Std::opt_d;
			foreach $db (@gDBNames) {
				if ( $db eq $cmdLineDBName ) {
					$dbFound = 1;
					last;
				}
			}
			if ( $dbFound == 0 ) {
				&T38lib::Common::errme("Command Line database $cmdLineDBName not found on server $gserverName");
				$mainStatus = 1;
				last BLOCK;
			}
			
			@gDBNames = $Getopt::Std::opt_d;
			$logStr = $logStr . " -d $gDBNames[0]";
		}

		#----------------------------------------------------------------
		# Filter database that we don't want to do dump
		# example tempdb, model ....
		#----------------------------------------------------------------
		foreach $db (@gDBNames) {	
			unless ($db =~ /^($gfilterDB)$/i ) {
				push (@temp, $db);
			}
		}
		
		#----------------------------------------------------------------
		# Assign the filter database array to orignal database array
		#----------------------------------------------------------------
		@gDBNames = @temp;

		if ( $#gDBNames == -1 ) {
				&T38lib::Common::errme("There is no database(s) to perform dump");
				&T38lib::Common::errme("List of the databases on which we do not perlform dump is $gfilterDB ");
				$mainStatus = 1;
				last BLOCK;
		}
		
		
		#----------------------------------------------------------------
		# Check for command line option config file and
		# read the config file.
		#----------------------------------------------------------------
		if($Getopt::Std::opt_c) {
			$gconfigFile = $Getopt::Std::opt_c;
			$logStr = $logStr . " -c $gconfigFile";
			if ( (&T38lib::t38cfgfile::readConfigFile($gconfigFile)) == 0 ) {
				&T38lib::Common::errme("Can not read cfg file: $gconfigFile");
				$mainStatus = 1;
				last BLOCK;
			}
			elsif ( uc($T38lib::t38cfgfile::gConfigValues{LogShipEnabledFlg}) eq "Y")  {
				$glogShipEnabled = 1;
				#----------------------------------------------------------------
				# Get source server name from cfg file for log shipping
				#----------------------------------------------------------------
	  			$gsrcServerName = uc($T38lib::t38cfgfile::gConfigValues{LogShipSrcServer});
				if (!($T38lib::t38cfgfile::gConfigValues{LogShipSrcInstance} eq "") ) {
			  		$gsrcServerName = $gsrcServerName . "\\" . uc($T38lib::t38cfgfile::gConfigValues{LogShipSrcInstance});
				}
				#----------------------------------------------------------------
				# Get destination server name from cfg file for log shipping
				#----------------------------------------------------------------
	  			$gdestServerName = uc($T38lib::t38cfgfile::gConfigValues{LogShipDestServer});
				if (!($T38lib::t38cfgfile::gConfigValues{LogShipDestInstance} eq "") ) {
			  		$gdestServerName = $gdestServerName . "\\" . uc($T38lib::t38cfgfile::gConfigValues{LogShipDestInstance});
				}
				@glogShipDBNames = split /[\s,]+/, $T38lib::t38cfgfile::gConfigValues{LogShipDatabases};
	
				if ( ($gserverName ne $gsrcServerName) and ($gserverName ne $gdestServerName) ) {
					&T38lib::Common::sendMsg2Monitor(2,"$gscript","$gserverName does not have an entry in the $gconfigFile file as a source or destination server.");
					&T38lib::Common::warnme("$gserverName does not have an entry in the cfg file as a source or destination server.");
					&T38lib::Common::notifyWSub("** WARN ** Disabling log shipping.");
					$glogShipEnabled = 0;
				}
			}
		}

		&T38lib::Common::notifyWSub("Command line: $logStr");

		#----------------------------------------------------------------
		# Get all the backup and log devices names for the given server.
		#----------------------------------------------------------------
		$rtnStatus=&getDevices(\%dbDevices, $gserverName);
		if ( $rtnStatus == 0 ) {
			&T38lib::Common::sendMsg2Monitor(0, "$gscript", "Can not get devices from server $gserverName.");
			&T38lib::Common::errme("Call to sub getDevices failed.");
			$mainStatus = 1;
			last BLOCK;
		}

		#----------------------------------------------------------------
		# If we have include backup database list then make sure these 
		# databases are on the servers and make this list as backup 
		# database list.  The database that are not on the server will
		# be ignored.
		#----------------------------------------------------------------
		$dblist = "";
		@temp = ();
		if (defined($T38lib::t38cfgfile::gConfigValues{'T38LIST:BKPIncludeDBName'})) {
			$aref = $T38lib::t38cfgfile::gConfigValues{'T38LIST:BKPIncludeDBName'};
			$nvals = scalar @{$aref};

			for $i (0..$nvals-1) {
				$includeList[$i] = $$aref[$i];
			}
			
			&T38lib::Common::notifyWSub("Include List @includeList");
			foreach $db (@gDBNames) {	
				$dblist = $dblist . $db . "|";
			}

			foreach $db (@includeList) {	
				if ($db =~ /^($dblist)$/i ) {
					push (@temp, $db);
				}
				else {
					$mainStatus = 1;
					&T38lib::Common::warnme("Include database name $db is not a database on SQL server $gserverName.");
					&T38lib::Common::warnme(" This database is ignored for backup");
				}

			}
			@gDBNames = @temp;
		}
		#Hemanth: Read the config files to get the databases for which we need to take differential backup -START
		$dblist = "";
		@temp = ();
		if (defined($T38lib::t38cfgfile::gConfigValues{'T38LIST:BKPIncludeDiffDBName'})) {
			$aref = $T38lib::t38cfgfile::gConfigValues{'T38LIST:BKPIncludeDiffDBName'};
			$nvals = scalar @{$aref};

			for $i (0..$nvals-1) {
				$includeList[$i] = $$aref[$i];
			}
			
			&T38lib::Common::notifyWSub("Include List @includeList");
			foreach $db (@gDBNames) {	
				$dblist = $dblist . $db . "|";
			}

			foreach $db (@includeList) {	
				if ($db =~ /^($dblist)$/i ) {
					push (@temp, $db);
				}
				else {
					$mainStatus = 1;
					&T38lib::Common::warnme("Include database name $db is not a database on SQL server $gserverName.");
					&T38lib::Common::warnme(" This database is ignored for backup");
				}

			}
			@gDiffDBNames = @temp;
		}
		#Hemanth: Read the config files to get the databases for which we need to take differential backup -END
		#----------------------------------------------------------------
		# Make sure all the databases have their respective log and 
		# backup devices, if not build these devices.
		#----------------------------------------------------------------
		
		foreach $db (@gDBNames) {
			$dumpDevice = $db . $gdeviceExt{db};
			
			unless ( defined $dbDevices{$dumpDevice} ) {
				$redoDbDevicesFlg = 1;
				$rtnStatus = &buildDevice($db, $gdeviceType{db});
				if ( $rtnStatus == 0 ) {
					&T38lib::Common::sendMsg2Monitor(0, "$gscript", "Can not create DB device for database $db");
					&T38lib::Common::errme("Call to sub buildDevice failed.");
					$mainStatus = 1;
					last BLOCK;
				}
			}
			$dumpDevice = $db . $gdeviceExt{log};
			unless ( defined $dbDevices{$dumpDevice} ) {
				$redoDbDevicesFlg = 1;
				$rtnStatus = &buildDevice($db, $gdeviceType{log});
				if ( $rtnStatus == 0 ) {
					&T38lib::Common::sendMsg2Monitor(0, "$gscript", "Can not create LOG device for database $db");
					&T38lib::Common::errme("Call to sub buildDevice failed.");
					$mainStatus = 1;
					last BLOCK;
				}
			}
		}
		#Hemanth:Build the differential backup device if not already built. -START
		foreach $db (@gDiffDBNames) {
			$dumpDevice = $db . $gdeviceExt{diff};
			unless ( defined $dbDevices{$dumpDevice} ) {
				$redoDbDevicesFlg = 1;
				$rtnStatus = &buildDevice($db, $gdeviceType{diff});
				if ( $rtnStatus == 0 ) {
					&T38lib::Common::sendMsg2Monitor(0, "$gscript", "Can not create Differential backup device for database $db");
					&T38lib::Common::errme("Call to sub buildDevice failed.");
					$mainStatus = 1;
					last BLOCK;
				}
			}
		}
		#Hemanth:Build the differential backup device if not already built. -END
		if ($redoDbDevicesFlg) {
			#----------------------------------------------------------------
			# Some new devices are created, refresh the dbDevices hash.
			#----------------------------------------------------------------
			$rtnStatus=&getDevices(\%dbDevices, $gserverName);
			if ( $rtnStatus == 0 ) {
				&T38lib::Common::sendMsg2Monitor(0, "$gscript", "Can not get devices from server $gserverName.");
				&T38lib::Common::errme("Call to sub getDevices failed.");
				$mainStatus = 1;
				last BLOCK;
			}
		}

		#----------------------------------------------------------------
		# If we have exclude backup database list then remove these 
		# servers from the backup database list
		#----------------------------------------------------------------
		$dblist = "";
		@temp = ();
		if (defined($T38lib::t38cfgfile::gConfigValues{'T38LIST:BKPExcludeDBName'})) {

			$aref = $T38lib::t38cfgfile::gConfigValues{'T38LIST:BKPExcludeDBName'};
			$nvals = scalar @{$aref};

			for $i (0..$nvals-1) {
				$excludeList[$i] = $$aref[$i];
			}

			&T38lib::Common::notifyWSub("Exclude List @excludeList");

			foreach $db (@excludeList) {	
				$dblist = $dblist . $db . "|";
			}

			foreach $db (@gDBNames) {	
				unless ($db =~ /^($dblist)$/i ) {
					push (@temp, $db);
				}
			}

			@gDBNames = @temp;
		}
		#Hemanth: Exclude the database if exclude parameter is provided -START
		$dblist = "";
		@temp = ();
		if (defined($T38lib::t38cfgfile::gConfigValues{'T38LIST:BKPExcludeDiffDBName'}))
		{
			&T38lib::Common::notifyWSub("Entered Exclude DiffDB Loop");
			$aref = $T38lib::t38cfgfile::gConfigValues{'T38LIST:BKPExcludeDiffDBName'};
			$nvals = scalar @{$aref};
			for $i (0..$nvals-1) {
				$excludeList[$i] = $$aref[$i];
			}

			&T38lib::Common::notifyWSub("Exclude List @excludeList");
			foreach $db (@excludeList) {	
				$dblist = $dblist . $db . "|";
			}
			foreach $db (@gDiffDBNames) {	
				unless ($db =~ /^($dblist)$/i ) {
					push (@temp, $db);
				}
			}

			@gDiffDBNames = @temp;
			@gDBNames = @gDiffDBNames;
			#&T38lib::Common::errme("Excluded databases for differentialbackup: @exclude");
		}
	#Hemanth: Exclude the database if exclude parameter is provided -END
		if ( $gbackupType eq "diff" ){
				my ($gfilterDiffDB) = "master|msdb|model|tempdb|northwind|pubs";
				foreach $diffdb (@gDiffDBNames) {	
					unless ($diffdb =~ /^($gfilterDiffDB)$/i ) {
						push (@temp, $diffdb);
					}
				}
				@gDiffDBNames = @temp;
				@gDBNames = @gDiffDBNames;
				
				if ($#gDBNames == -1 ){
					&T38lib::Common::errme("There is no database(s) to perform dump");
					&T38lib::Common::errme("List of the databases on which we do not perlform differential dump is $gfilterDiffDB ");
					$mainStatus = 0;
					last BLOCK;
				}
		}
		# For debug to see include db and exclude db working properly
		#
		foreach $db (@gDBNames) {
			&T38lib::Common::notifyWSub("DB Name to backup $db");
		}

		#----------------------------------------------------------------
		# For all databases, run either tran log dump 
		# or run database backup.  If database backup
		# is done then dump the the log with init option.
		# This will initilize the log file for the next tran dump.
		# Hemanth: Re-Wrote to accomadate differential backups
		#----------------------------------------------------------------
		if ( defined(@gDiffDBNames) ){
			foreach $db (@gDiffDBNames) {
				$dumpDevice = $db . $gdeviceExt{diff};
				$rtnStatus = &dumpDbDiff($db, $dumpDevice, %dbDevices);
				if($rtnStatus == 0) {
					&T38lib::Common::sendMsg2Monitor(1, "$gscript", "Dump database differential failed for database $db");
					&T38lib::Common::errme("Dump database differential failed for database $db");
					$mainStatus = 1;
				}
				else {
					$dumpDevice = $db . $gdeviceExt{log};
					$rtnStatus = &dumpLog($db, $dumpDevice, %dbDevices);
					if($rtnStatus == 0) {
						&T38lib::Common::sendMsg2Monitor(1, "$gscript", "Dump tran failed for database $db");
						&T38lib::Common::errme("Dump tran failed for database $db");
						$mainStatus = 1;
					}
				}
			}
		}
		else{
				foreach $db (@gDBNames) {
					if ( $gbackupType eq "log") {
						$dumpDevice = $db . $gdeviceExt{log};
						$rtnStatus = &dumpLog($db, $dumpDevice, %dbDevices);
						if($rtnStatus == 0) {
							# Don't set db option any more let the job failed.
							# &setDboptions($db);
							&T38lib::Common::sendMsg2Monitor(1, "$gscript", "Transection dump failed for database $db");
							&T38lib::Common::errme("Dump tran failed, turn on bulkcopy and trunc log on chkpt");
							$mainStatus = 1;
						}
					}
					elsif ( $gbackupType eq "diff"){
						$dumpDevice = $db . $gdeviceExt{diff};
						$rtnStatus = &dumpDbDiff($db, $dumpDevice, %dbDevices);
						if($rtnStatus == 0) {
							&T38lib::Common::sendMsg2Monitor(1, "$gscript", "Dump database differential failed for database $db");
							&T38lib::Common::errme("Dump database differential failed for database $db");
							$mainStatus = 1;
						}
						else {
							$dumpDevice = $db . $gdeviceExt{log};
							$rtnStatus = &dumpLog($db, $dumpDevice, %dbDevices);
							if($rtnStatus == 0) {
								&T38lib::Common::sendMsg2Monitor(1, "$gscript", "Dump tran failed for database $db");
								&T38lib::Common::errme("Dump tran failed for database $db");
								$mainStatus = 1;
							}
						}
					}
					else {
						$dumpDevice = $db . $gdeviceExt{db};
						$rtnStatus = &dumpDb($db, $dumpDevice, %dbDevices);
						if($rtnStatus == 0) {
							&T38lib::Common::sendMsg2Monitor(1, "$gscript", "Dump database failed for database $db");
							&T38lib::Common::errme("Dump database failed for database $db");
							$mainStatus = 1;
						}
						else {
							$dumpDevice = $db . $gdeviceExt{log};
							$rtnStatus = &dumpLog($db, $dumpDevice, %dbDevices);
							if($rtnStatus == 0) {
								&T38lib::Common::sendMsg2Monitor(1, "$gscript", "Dump tran failed for database $db");
								&T38lib::Common::errme("Dump tran failed for database $db");
								$mainStatus = 1;
							}
						}
					}
				}
			}

		#----------------------------------------------------------------
		#  Clean up the history table in msdb
		#----------------------------------------------------------------
		&T38lib::Common::notifyWSub("Cleaning up backup history table");
		&cleanupHistoryTable();

		#----------------------------------------------------------------
		# Get the path by looking at the master device
		#----------------------------------------------------------------
		$dumpDevice = "master" . $gdeviceExt{log};
		$trandumpLocation = $dbDevices{$dumpDevice};
		
		#----------------------------------------------------------------
		# Parse the dump device for backup location
		#----------------------------------------------------------------
		fileparse_set_fstype("MSWin32");
		($base, $backupPath, $type) = fileparse($trandumpLocation, '\.[^\.]*');

		#----------------------------------------------------------------
		# Run the compress or zip for only log files, Do not do backup
		#----------------------------------------------------------------
		if ( defined ($T38lib::t38cfgfile::gConfigValues{ZipORCompEnable})) {
			if ( (uc($T38lib::t38cfgfile::gConfigValues{ZipORCompEnable}) eq "Y") && ($gbackupType eq "log") ) {
				&T38lib::Common::notifyWSub("Zip or Compress the files");
		
				&T38lib::Common::notifyWSub("for zip the path is $backupPath");
	
				unless ( &zipORcompressFiles($backupPath)) {
					&T38lib::Common::errme("zipORcompressFiles sub failed");
					$mainStatus = 1;
				}
			}
		}

		#----------------------------------------------------------------
		#  Clean up the older tran log files
		#----------------------------------------------------------------
		&T38lib::Common::notifyWSub("Cleaning up older tran log file");

		if (
			($gbackupType =~ /db/i) or 
			(
				(
					defined ($T38lib::t38cfgfile::gConfigValues{TranBkpDeleteFiles}) && 
					(uc($T38lib::t38cfgfile::gConfigValues{TranBkpDeleteFiles}) eq "Y") && 
					($gbackupType eq 'log')
				)
			)
		)
		{
 			&delFilesNHourOld("$backupPath");
		
		}


} # END OF BLOCK 

	#----------------------------------------------------------------
	# Log or errme depending on the mainstatus
	#----------------------------------------------------------------
	($mainStatus == 0 ) ? 
		&T38lib::Common::logme("Finished with status $mainStatus"):
		&T38lib::Common::errme("Finished with status $mainStatus");

	&T38lib::Common::notifyWSub("SUB DONE\n");

	exit($mainStatus);

} # End of mainControl

#------------------------------------------------------------------------------
# Purpose:	Get the names of all the devices in a SQL Server populate 
#				the hash with device name and phy device path
#
#	Input:		Ref to a hash (This hash is populated with the data 
#					if there is no error)	
#					SQLServer Name
#	Output:		Return status 1 OK, 0 Fail
#------------------------------------------------------------------------------
sub getDevices($$) {
	my ($hashRef, $serverName) = (@_);

	my ($subStatus) = 1;
	my ($runSQLStatus) = 0; 
	my ($cmd) = ""; 
	my (@temp) = ();
	my ($getDeviceSQL) = "getdevice.sql";
	my ($getDeviceOUT) = "getdevice.out";
	my ($logFileName, $base, $logFilePath, $type);

	&T38lib::Common::notifyWSub("SUB STARTED");
			
	# get the log file name which will give us the directory 
	# where log file is and use that directory to create
	# any temp files

	$logFileName = &T38lib::Common::getLogFileName($0);
	fileparse_set_fstype("MSWin32");
	($base, $logFilePath, $type) = fileparse($logFileName, '\.[^\.]*');
			
	# Set the output file name using -o option
	#
	$getDeviceSQL = $logFilePath . "$getDeviceSQL";

	BLOCK: {
		#----------------------------------------------------------------
		# Open a temp file 
		#----------------------------------------------------------------
		unless (open(SQLdevice,"> $getDeviceSQL")) {
			&T38lib::Common::notifyMe("** ERROR ** Cannot open file $getDeviceSQL: $!");
			$subStatus = 0 
		}

		#----------------------------------------------------------------
		# Write the SQL to get the dbnames
		#----------------------------------------------------------------
		print SQLdevice << '		EOF';
		set nocount on
		go
		select name ' ', phyname ' ' from master..sysdevices where status = 16 and cntrltype = 2 order by name
		go
		EOF
		close(SQLdevice);

		$runSQLStatus = &T38lib::Common::runSQLChk4Err($getDeviceSQL, $serverName, "", $getDeviceOUT, "", "", "", "");

		if ( $runSQLStatus == 0 ) {
			
	
			# Set the output file name using -o option
			#
			$getDeviceOUT = $logFilePath . "$getDeviceOUT";

			unless (open(OUTdevice,"< $getDeviceOUT")) {
				&T38lib::Common::errme (" Cannot open file $getDeviceOUT: $!");
				$subStatus = 0;
				last BLOCK;
			}
		}
		else {
			&T38lib::Common::errme ("Error running SQL in file $getDeviceSQL, Check output in $getDeviceOUT: $!");
			$subStatus = 0;
			last BLOCK;
		}

		#----------------------------------------------------------------
		# Read the output file created by SQL command and look for 
		# device names and physical path and assign it to a hash
		# ref passed to this sub. 
		#----------------------------------------------------------------
		while (<OUTdevice>) {
			chomp;
			if ( (/\w+/) ) {
				$_ = &T38lib::Common::stripWhitespace($_);
				s/[\s]+/ /g;
				@temp = split /[\s]/, $_;
				$hashRef->{$temp[0]} = "$temp[1]";
			}
		}
		close(OUTdevice);

		unlink($getDeviceSQL);
		unlink($getDeviceOUT);

	} # End of BLOCK

	&T38lib::Common::notifyWSub("SUB DONE\n");

	#----------------------------------------------------------------
	# Return status
	#----------------------------------------------------------------
	return ($subStatus);

} # End of getDevices

#------------------------------------------------------------------------------
#	Purpose: Dump database 
#
#	Input Argument: Database Name, Dump device name, list of dump devices
#	Output:         Return dumpStatus, 1 OK, 0 Failed
#------------------------------------------------------------------------------
sub dumpDb($$$) {
	my($databasenamedump, $dumpdevice, %devices) = (@_);

	my($isqlOut,$startdump);
	my($rtnStatus, $lsDBFound, $lsDB, $timeStr);
	my($trandumpLocation, $dumpDevice, $cmd, $rtnCode);
	my ($dumpStatus) = 1;
	my ($trunclog, $dumpdbRun65, $dumpdbRun70) = 0;
	my ($dumpOption) = "with init, stats=10";
	my $nBkpFiles = 0;
	my $dbdumpLocation = '';
	my $dumpExt = '';
	my $filename = '';
	my $i = 0;

	&T38lib::Common::notifyWSub("SUB STARTED");

	#----------------------------------------------------------------
	# A block has been defined called SUB.  This block is created
	# so we can exit out from the block in case of an error with out
	# executing rest of the block statements.
	# This way we reduce lot of checks using if/else conditions.
	#----------------------------------------------------------------
	SUB: {	# START OF BLOCK SUB
		#----------------------------------------------------------------
		# Don't dump database if another dump database is running
		#----------------------------------------------------------------
		$dumpdbRun65 =`$gisql -Q "select 1 from master..sysprocesses where dbid = db_id(\'$databasenamedump\') AND upper(cmd) like 'DUMP D%'"`;
		$dumpdbRun70 =`$gisql -Q "select 1 from master..sysprocesses where dbid = db_id(\'$databasenamedump\') AND upper(cmd) like 'BACKUP D%'"`;

		if ( ($dumpdbRun65 =~ 1) or ($dumpdbRun70 =~ 1) ) {
			$rtnStatus = &T38lib::Common::sendMsg2Monitor(3, '$gscript db', 'Dump database or back database is running on $databasenamedump');	
			&T38lib::Common::warnme("DUMP or BACKUP DATABASE is running on database $databasenamedump, can not perform a dump");
			last SUB;
		}

		#----------------------------------------------------------------
		# Don't dump db IF database is in readonly mode
		#----------------------------------------------------------------
		$trunclog =`$gisql -Q "select 1 from master..sysdatabases where name = \'$databasenamedump\' AND status & 1024 > 0"`;
		if ($trunclog =~ 1){
			$rtnStatus = &T38lib::Common::sendMsg2Monitor(3, '$gscript', 'readonly mode enabled for database: $databasenamedump');	
			&T38lib::Common::warnme ("$databasenamedump is in readonly mode, can not perform a dump");
			last SUB;
		}

		#----------------------------------------------------------------
		# Don't dump db IF database is in singleuser mode
		#----------------------------------------------------------------
		$trunclog =`$gisql -Q "select 1 from master..sysdatabases where name = \'$databasenamedump\' AND status & 4096 > 0"`;
		if ($trunclog =~ 1){
			$rtnStatus = &T38lib::Common::sendMsg2Monitor(3, '$gscript', 'singleuser mode enabled for database: $databasenamedump');	
			&T38lib::Common::warnme ("$databasenamedump is in single user mode, can not perform a dump");
			last SUB;
		}
		$lsDBFound = 0;
		#----------------------------------------------------------------
		# Check to if we have log shipping enabled and 
		# we found a log shipping database.
		#----------------------------------------------------------------
		if ($glogShipEnabled) {
			foreach $lsDB (@glogShipDBNames) {
				if ($lsDB eq $databasenamedump ) {
					$lsDBFound = 1;
					last;
				}
			}
		}

		#----------------------------------------------------------------
		# If a log shipping database is found then dump the database
		# to a disk file with current date and time stamp.
		#----------------------------------------------------------------
		if ( $lsDBFound ) {
		#----------------------------------------------------------------
		# Skip database dump of a log ship enabled database if it is on 
		# log ship destination server.
		#----------------------------------------------------------------
			if ( $gserverName eq $gdestServerName) {
				&T38lib::Common::notifyWSub("** WARN ** Database dump skip for database $databasenamedump");
				&T38lib::Common::notifyWSub("** WARN ** $databasenamedump is log ship enabled and on the destination server");
				last SUB;
			}
		}

		#----------------------------------------------------------------
		# Dump databases 
		#----------------------------------------------------------------

		if (defined($T38lib::t38cfgfile::gConfigValues{"BKPDBNFILES:$databasenamedump"}) &&
			($nBkpFiles = $T38lib::t38cfgfile::gConfigValues{"BKPDBNFILES:$databasenamedump"}) > 0) {

			if ($nBkpFiles > 999) {
				&T38lib::Common::errme("Cannot do database dump to more then 999 files for $databasenamedump database. The BKPDBNFILES:$databasenamedump parameter is $nBkpFiles.");
				$dumpStatus = 0;
				last SUB;
			}

			# If we are requested to backup to multiple files, get default path 
			# for backup device.
			
			$dbdumpLocation = $devices{$dumpdevice};
			$dumpExt = '';
			if ($dbdumpLocation =~ s/\.([^:;\\\/\.]+)$//) {
				$dumpExt = "\.$1";
			}
			
			&T38lib::Common::notifyWSub("START DATABASE DUMP on [$databasenamedump], using option $dumpOption to $nBkpFiles files $dbdumpLocation");

			$cmd = "$gdumpCmd{db} $databasenamedump to ";
			foreach $i (1..$nBkpFiles-1) {
				$filename = sprintf("${dbdumpLocation}\.%03d$dumpExt", $i);
				$cmd .= "disk = '$filename', ";
			}
			$filename = sprintf("${dbdumpLocation}\.%03d$dumpExt", $nBkpFiles);
			$cmd .= "disk = '$filename' $dumpOption";

		} else {
			&T38lib::Common::notifyWSub("START DATABASE DUMP on [$databasenamedump], using device $dumpdevice option $dumpOption");
			$cmd = "$gdumpCmd{db} [$databasenamedump] to [$dumpdevice] $dumpOption";
		}
		$rtnCode = &T38lib::Common::runSQLChk4Err($cmd, $gserverName);

		if ($rtnCode == 0) {
			&T38lib::Common::notifyWSub ("GOOD DATABASE DUMP using the following command");
			&T38lib::Common::notifyWSub ("$cmd");
			last SUB;
		}

		#----------------------------------------------------------------
		# In case dump failed notify and exit SUB
		#----------------------------------------------------------------
		&T38lib::Common::errme("FAILED DATABASE DUMP using the following command");
		&T38lib::Common::notifyWSub ("$cmd");
		&T38lib::Common::notifyWSub ("Check log file called tmpDDDD.out where DDDD are number from 0-9");
		$dumpStatus = 0;
		last SUB;

	} # END OF BLOCK SUB 

	&T38lib::Common::notifyWSub("SUB DONE\n");

	#----------------------------------------------------------------
	# Return dump db status
	#----------------------------------------------------------------
	return $dumpStatus;

} # End of dumpDb

#Hemanth: dumpDbDiff() -START
#------------------------------------------------------------------------------
#	Purpose: Backup database with differential option
#
#	Input Argument: Database Name, Dump device name, list of dump devices
#	Output:         Return dumpStatus, 1 OK, 0 Failed
#------------------------------------------------------------------------------
sub dumpDbDiff($$$) {
	my($databasenamedump, $dumpdevice, %devices) = (@_);

	my($isqlOut,$startdump);
	my($rtnStatus, $lsDBFound, $lsDB, $timeStr);
	my($trandumpLocation, $dumpDevice, $cmd, $rtnCode);
	my ($dumpStatus) = 1;
	my ($trunclog, $dumpdbRun65, $dumpdbRun70) = 0;
	my ($dumpOption) = $gdumpCmd{diff} . " ,init, stats=10";
	my $nBkpFiles = 0;
	my $dbdumpLocation = '';
	my $dumpExt = '';
	my $filename = '';
	my $i = 0;
	
	&T38lib::Common::notifyWSub("SUB STARTED");

	#----------------------------------------------------------------
	# A block has been defined called SUB.  This block is created
	# so we can exit out from the block in case of an error with out
	# executing rest of the block statements.
	# This way we reduce lot of checks using if/else conditions.
	#----------------------------------------------------------------
	SUB: {	# START OF BLOCK SUB
		#----------------------------------------------------------------
		# Don't dump database if another dump database is running
		#----------------------------------------------------------------
		$dumpdbRun65 =`$gisql -Q "select 1 from master..sysprocesses where dbid = db_id(\'$databasenamedump\') AND upper(cmd) like 'DUMP D%'"`;
		$dumpdbRun70 =`$gisql -Q "select 1 from master..sysprocesses where dbid = db_id(\'$databasenamedump\') AND upper(cmd) like 'BACKUP D%'"`;

		if ( ($dumpdbRun65 =~ 1) or ($dumpdbRun70 =~ 1) ) {
			$rtnStatus = &T38lib::Common::sendMsg2Monitor(3, '$gscript db', 'Dump database or backup database is running on $databasenamedump');	
			&T38lib::Common::warnme("DUMP or BACKUP WITH DIFFERENTIAL is running on database $databasenamedump, can not perform a dump");
			last SUB;
		}

		#----------------------------------------------------------------
		# Don't dump db IF database is in readonly mode
		#----------------------------------------------------------------
		$trunclog =`$gisql -Q "select 1 from master..sysdatabases where name = \'$databasenamedump\' AND status & 1024 > 0"`;
		if ($trunclog =~ 1){
			$rtnStatus = &T38lib::Common::sendMsg2Monitor(3, '$gscript', 'readonly mode enabled for database: $databasenamedump');	
			&T38lib::Common::warnme ("$databasenamedump is in readonly mode, can not perform a dump");
			last SUB;
		}

		#----------------------------------------------------------------
		# Don't dump db IF database is in singleuser mode
		#----------------------------------------------------------------
		$trunclog =`$gisql -Q "select 1 from master..sysdatabases where name = \'$databasenamedump\' AND status & 4096 > 0"`;
		if ($trunclog =~ 1){
			$rtnStatus = &T38lib::Common::sendMsg2Monitor(3, '$gscript', 'singleuser mode enabled for database: $databasenamedump');	
			&T38lib::Common::warnme ("$databasenamedump is in single user mode, can not perform a dump");
			last SUB;
		}
		$lsDBFound = 0;
		#----------------------------------------------------------------
		# Check to if we have log shipping enabled and 
		# we found a log shipping database.
		#----------------------------------------------------------------
		if ($glogShipEnabled) {
			foreach $lsDB (@glogShipDBNames) {
				if ($lsDB eq $databasenamedump ) {
					$lsDBFound = 1;
					last;
				}
			}
		}

		#----------------------------------------------------------------
		# If a log shipping database is found then dump the database
		# to a disk file with current date and time stamp.
		#----------------------------------------------------------------
		if ( $lsDBFound ) {
		#----------------------------------------------------------------
		# Skip database dump of a log ship enabled database if it is on 
		# log ship destination server.
		#----------------------------------------------------------------
			if ( $gserverName eq $gdestServerName) {
				&T38lib::Common::notifyWSub("** WARN ** Database dump skip for database $databasenamedump");
				&T38lib::Common::notifyWSub("** WARN ** $databasenamedump is log ship enabled and on the destination server");
				last SUB;
			}
		}

		#----------------------------------------------------------------
		# Dump databases 
		#----------------------------------------------------------------

		if (defined($T38lib::t38cfgfile::gConfigValues{"BKPDBNFILES:$databasenamedump"}) &&
			($nBkpFiles = $T38lib::t38cfgfile::gConfigValues{"BKPDBNFILES:$databasenamedump"}) > 0) {

			if ($nBkpFiles > 999) {
				&T38lib::Common::errme("Cannot do database dump to more then 999 files for $databasenamedump database. The BKPDBNFILES:$databasenamedump parameter is $nBkpFiles.");
				$dumpStatus = 0;
				last SUB;
			}

			# If we are requested to backup to multiple files, get default path 
			# for backup device.
			
			$dbdumpLocation = $devices{$dumpdevice};
			$dumpExt = '';
			if ($dbdumpLocation =~ s/\.([^:;\\\/\.]+)$//) {
				$dumpExt = "\.$1";
			}
			
			&T38lib::Common::notifyWSub("START DATABASE DUMP on [$databasenamedump], using option $dumpOption to $nBkpFiles files $dbdumpLocation");

			$cmd = "$gdumpCmd{db} $databasenamedump to ";
			foreach $i (1..$nBkpFiles-1) {
				$filename = sprintf("${dbdumpLocation}\.%03d$dumpExt", $i);
				$cmd .= "disk = '$filename', ";
			}
			$filename = sprintf("${dbdumpLocation}\.%03d$dumpExt", $nBkpFiles);
			$cmd .= "disk = '$filename' $dumpOption";

		} else {
			&T38lib::Common::notifyWSub("START DATABASE DUMP on [$databasenamedump], using device $dumpdevice option $dumpOption");
			$cmd = "$gdumpCmd{db} [$databasenamedump] to [$dumpdevice] $dumpOption";
		}
		$rtnCode = &T38lib::Common::runSQLChk4Err($cmd, $gserverName);

		if ($rtnCode == 0) {
			&T38lib::Common::notifyWSub ("GOOD DATABASE DUMP using the following command");
			&T38lib::Common::notifyWSub ("$cmd");
			last SUB;
		}

		#----------------------------------------------------------------
		# In case dump failed notify and exit SUB
		#----------------------------------------------------------------
		&T38lib::Common::errme("FAILED DATABASE DUMP using the following command");
		&T38lib::Common::notifyWSub ("$cmd");
		&T38lib::Common::notifyWSub ("Check log file called tmpDDDD.out where DDDD are number from 0-9");
		$dumpStatus = 0;
		last SUB;

	} # END OF BLOCK SUB 

	&T38lib::Common::notifyWSub("SUB DONE\n");

	#----------------------------------------------------------------
	# Return dump db status
	#----------------------------------------------------------------
	return $dumpStatus;

} # End of dumpDbDiff
#Hemanth: dumpDbDiff() -END

#------------------------------------------------------------------------------
#	Purpose: Dump transaction log
#
#	Input Argument: Database Name, Dump device name
#	Output:         Return dumpStatus, 1 OK, 0 Failed
#------------------------------------------------------------------------------
sub dumpLog($$$) {
	my($databasenamedump, $dumpdevice, %devices) = (@_);

	my($isqlOut,$startdump);
	my($bulkerror, $rtnStatus, $lsDBFound, $lsDB, $timeStr);
	my($trandumpLocation, $dumpDevice, $cmd, $rtnCode);
	my ($dumpStatus) = 1;
	my ($trunclog, $dumplogRun65, $dumplogRun70) = 0;
	my ($dumpOption) = "with init";

	&T38lib::Common::notifyWSub("SUB STARTED");

	if ( $gbackupType eq "log") {
		$dumpOption = "with noinit";
	}
	#----------------------------------------------------------------
	# A block has been defined called SUB.  This block is created
	# so we can exit out from the block in case of an error with out
	# executing rest of the block statements.
	# This way we reduce lot of checks using if/else conditions.
	#----------------------------------------------------------------
	SUB: {	# START OF BLOCK SUB
		#----------------------------------------------------------------
		# Don't dump transaction IF trunc.. log on chkpt is set
		#----------------------------------------------------------------
		$trunclog =`$gisql -Q "select 1 from master..sysdatabases where name = \'$databasenamedump\' AND status & 8 > 0"`;
		if ($trunclog =~ 1) {
			#$rtnStatus = &T38lib::Common::sendMsg2Monitor(3, '$gscript', 'Truncate log on chkpt enabled for database $databasenamedump');	
			&T38lib::Common::warnme ("$databasenamedump trunc. log on chkpt is enabled, can not perform a dump");
			last SUB;
		}

		#----------------------------------------------------------------
		# Don't dump transaction IF database is in readonly mode
		#----------------------------------------------------------------
		$trunclog =`$gisql -Q "select 1 from master..sysdatabases where name = \'$databasenamedump\' AND status & 1024 > 0"`;
		if ($trunclog =~ 1) {
			$rtnStatus = &T38lib::Common::sendMsg2Monitor(3, '$gscript', 'readonly mode enabled for database $databasenamedump');	
			&T38lib::Common::warnme ("$databasenamedump is in readonly mode, can not perform a dump");
			last SUB;
		}

		#----------------------------------------------------------------
		# Don't dump transaction IF database is in singleuser mode
		#----------------------------------------------------------------
		$trunclog =`$gisql -Q "select 1 from master..sysdatabases where name = \'$databasenamedump\' AND status & 4096 > 0"`;
		if ($trunclog =~ 1) {
			$rtnStatus = &T38lib::Common::sendMsg2Monitor(3, '$gscript', 'singleuser mode enabled for database $databasenamedump');	
			&T38lib::Common::warnme ("$databasenamedump is in singleuser mode, can not perform a dump");
			last SUB;
		}

		#----------------------------------------------------------------
		# Don't dump transaction if another dump tran is running
		#----------------------------------------------------------------
		$dumplogRun65 =`$gisql -Q "select 1 from master..sysprocesses where dbid = db_id(\'$databasenamedump\') AND upper(cmd) like 'DUMP T%'"`;
		$dumplogRun70 =`$gisql -Q "select 1 from master..sysprocesses where dbid = db_id(\'$databasenamedump\') AND upper(cmd) like 'BACKUP L%'"`;
	
		if ( ($dumplogRun65 =~ 1) or ($dumplogRun70 =~ 1) ) {
			$rtnStatus = &T38lib::Common::sendMsg2Monitor(3, '$gscript', 'Dump tran or backup log is running for database $databasenamedump');	
			&T38lib::Common::warnme("DUMP or BACKUP LOG is running on database $databasenamedump, another dump will not work");
			last SUB;
		}

		#$lsDBFound = 0;
		#----------------------------------------------------------------
		# Check to if we have log shipping enabled and 
		# we found a log shipping database.
		#----------------------------------------------------------------
		#if ($glogShipEnabled) {
		#	foreach $lsDB (@glogShipDBNames) {
		#		if ($lsDB eq $databasenamedump ) {
		#			$lsDBFound = 1;
		#			last;
	    #		}
		#	}
		#}

		#----------------------------------------------------------------
		# Change the tran log dump so it create a new file for each dump just like
		# log shipping option
		#
		#----------------------------------------------------------------
		$lsDBFound = 1;

		#----------------------------------------------------------------
		# If a log shipping database is found then dump the log
		# to a disk file with current date and time stamp.
		#----------------------------------------------------------------
		if ( $lsDBFound ) {
			
			#----------------------------------------------------------------
			# Skip log dump of a log ship enabled database if it is on 
			# log ship destination server.
			#----------------------------------------------------------------
			if ( $gserverName eq $gdestServerName) {
				&T38lib::Common::notifyWSub("** WARN ** Log dump skip for database $databasenamedump");
				&T38lib::Common::notifyWSub("** WARN ** $databasenamedump is log ship enabled and on the destination server");
				last SUB;
			}

			$timeStr = &getTimeStr;
			$dumpDevice = $databasenamedump . $gdeviceExt{log};
			$trandumpLocation = $devices{$dumpDevice};
			$trandumpLocation =~ s/\./_$timeStr\./;

			&T38lib::Common::notifyWSub ("START TRANS DUMP FOR LOG SHIPPING: database = $databasenamedump to disk = $trandumpLocation");
			$cmd = "$gdumpCmd{log} [$databasenamedump] to disk = '$trandumpLocation'";
			$rtnCode = &T38lib::Common::runSQLChk4Err($cmd, $gserverName);

			#----------------------------------------------------------------
			# IF successful dump then notify and exit the SUB
			#----------------------------------------------------------------
			if ($rtnCode == 0) {
				&T38lib::Common::notifyWSub ("GOOD TRAN DUMP using the following command");
				&T38lib::Common::notifyWSub ("$cmd");
				last SUB;
	    	}

			#----------------------------------------------------------------
			# In case dump failed notify and exit SUB
			#----------------------------------------------------------------
			&T38lib::Common::errme("TRAN DUMP FAILED using the following command");
			&T38lib::Common::notifyWSub ("$cmd");
			&T38lib::Common::notifyWSub ("Check log file called tmpDDDD.out where DDDD are number from 0-9");
			$dumpStatus = 0;
			last SUB;
		}

		#----------------------------------------------------------------
		# (Don't need this code now)
		#
		# Dump log of databases which are NOT enabled for log shipping (Don't need this now)
		#----------------------------------------------------------------
		#&T38lib::Common::notifyWSub ("START TRAN DUMP on $databasenamedump, using device $dumpdevice option $dumpOption");
		#$cmd = "$gdumpCmd{log} [$databasenamedump] to $dumpdevice $dumpOption";
		#$rtnCode = &T38lib::Common::runSQLChk4Err($cmd, $gserverName);

		#if ($rtnCode == 0) {
		#	&T38lib::Common::notifyWSub ("GOOD TRAN DUMP using the following command");
		#	&T38lib::Common::notifyWSub ("$cmd");
		#	last SUB;
		#}

		#----------------------------------------------------------------
		# In case dump failed notify and exit SUB
		#----------------------------------------------------------------
		&T38lib::Common::errme("TRAN DUMP FAILED using the following command");
		&T38lib::Common::notifyWSub ("$cmd");
		&T38lib::Common::notifyWSub ("Check log file called tmpDDDD.out where DDDD are number from 0-9");
		$dumpStatus = 0;
		last SUB;

	} # END OF BLOCK SUB 

	&T38lib::Common::notifyWSub("SUB DONE\n");

	#----------------------------------------------------------------
	# Return dump log status
	#----------------------------------------------------------------
	return $dumpStatus;

} # End of dumpLog

#------------------------------------------------------------------------------
#	Purpose: Build the log device by calling sp_T38CRBKP store procedure
#
#	Input Argument: Database Name
#	Output:         Return 1 OK, 0 Failed
#------------------------------------------------------------------------------
sub buildDevice($$) {
	my($databasenamebuild, $deviceType)= (@_); 

	my($baddbbuild, $badlogbuild) = ();
	my ($logbuild, $dumpdevice);
	my ($rtnCode) = 1;

	&T38lib::Common::notifyWSub("SUB STARTED");

	&T38lib::Common::notifyWSub("Building $deviceType device for $databasenamebuild");
	$logbuild =`$gisql -Q "Exec sp_T38CRBKP [$databasenamebuild], $deviceType"`;

	if ($logbuild =~ /device added/i) {
		&T38lib::Common::notifyWSub("Device $deviceType build for $databasenamebuild");
	}
	else {
		&T38lib::Common::errme("Building device failed for database $databasenamebuild, device type $deviceType");
		$rtnCode = 0;
	}

	&T38lib::Common::notifyWSub("SUB DONE\n");

	#----------------------------------------------------------------
	# Return status
	#----------------------------------------------------------------
	return ($rtnCode);

} # End of buildDevice

#------------------------------------------------------------------------------
#	Purpose: Get the time string in the following format
#				YYYY	Four digit for year
#				MM		Two digit month zero filled jan(01) to Dec (12)
#				DD		Two digit calendar date zero filled of the month ( 01 - 31)
#				HH		Two digit hour zero filled (00 - 23)
#				MN		Tow digit minutes zero filled after the hour (00-59)
#	
#	Input Argument: None
#	Output:         String format YYYYMMDDHHMN
#------------------------------------------------------------------------------
sub getTimeStr() {

	my $cur_time=time();
	my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($cur_time);

	&T38lib::Common::notifyWSub("SUB STARTED");

	$year += 1900;
	$mon += 1;

	&T38lib::Common::notifyWSub("SUB DONE\n");

	return ( sprintf("%04d%02d%02d%02d%02d", $year, $mon, $mday, $hour, $min) );

} # End of getTimeStr

#------------------------------------------------------------------------------
# Purpose:		Set dboption, bulkcopy, and trunc log on chkpt on
#
#	Input:		Database Name	
#	Output:		Status 1 OK, 0 Failed	
#
#------------------------------------------------------------------------------
sub setDboptions($) {
	my ($databaseName) = shift(@_); 

	my ($rtnCode) = 0;
	my ($subStatus) = 1;
	my ($cmd) = "";

	&T38lib::Common::notifyWSub("SUB STARTED");

	$cmd = "Exec sp_dboption $databaseName, \'select into\/bulkcopy\', TRUE";
	$rtnCode = &T38lib::Common::runSQLChk4Err($cmd, $gserverName);
	if ($rtnCode == 1 ) {
		&T38lib::Common::warnme("$cmd failed...");
		$subStatus = 0;
	}

	$cmd = "Exec sp_dboption $databaseName,\'trunc. log on Chkpt.\', TRUE";
	$rtnCode = &T38lib::Common::runSQLChk4Err($cmd, $gserverName);
	if ($rtnCode == 1 ) {
		&T38lib::Common::warnme("$cmd failed...");
		$subStatus = 0;
	}

	&T38lib::Common::notifyWSub("SUB DONE\n");

	#----------------------------------------------------------------
	# Return status
	#----------------------------------------------------------------
	return ($subStatus);

} # End of setDboptions

#------------------------------------------------------------------------------
# Purpose:		Clean up history table in database msdb
#
#	Input:		None	
#	Output:		None
#
#------------------------------------------------------------------------------
sub cleanupHistoryTable() {

	my ($rtnCode) = 1; 
	my (@temp) = ();
	my ($tmpSQLFile) = "cleanupHist.sql";
	my ($tmpOUTFile) = "cleanupHist.out";
	my ($logFileName, $base, $logFilePath, $type);

	&T38lib::Common::notifyWSub("SUB STARTED");

	$logFileName = &T38lib::Common::getLogFileName($0);
	fileparse_set_fstype("MSWin32");
	($base, $logFilePath, $type) = fileparse($logFileName, '\.[^\.]*');

	$tmpSQLFile = $logFilePath . "$tmpSQLFile";

	BLOCK: {
		#----------------------------------------------------------------
		# Open a temp file 
		#----------------------------------------------------------------
		unless (open(CLEANUPSQL,">$tmpSQLFile")) {
			&T38lib::Common::errme("Cannot open file $tmpSQLFile");
			&T38lib::Common::notifyWSub("Fail to cleanup History table in database msdb");
			last BLOCK;
		}

		#----------------------------------------------------------------
		# Write the SQL to the temp file to  clean up backup history 
		# table in database msdb
		#----------------------------------------------------------------
		if ( $gsqlVersion < 7 ) {
			print CLEANUPSQL << '			EOF';
			exec master..sp_sysbackuphistory_limiter 5000, 200
			go
			EOF
		}
		else {
			print CLEANUPSQL << '			EOF';
			declare @targetDate datetime
			set @targetDate = dateadd(Month, -3, getdate())
			exec msdb..sp_delete_backuphistory @oldest_date = @targetDate
			go
			EOF
		}
		close(CLEANUPSQL);

		#----------------------------------------------------------------
		# Run the SQL and check for the return status
		#----------------------------------------------------------------
		$rtnCode = &T38lib::Common::runSQLChk4Err($tmpSQLFile, $gserverName, "", $tmpOUTFile, "", "", "", "");
		
	
		# Set the output file name using -o option
		#
		$tmpOUTFile = $logFilePath . "$tmpOUTFile";

		if ($rtnCode == 1 ) {
			&T38lib::Common::warnme("Error running SQL in file $tmpSQLFile, Check output in $tmpOUTFile");
			last BLOCK
		}

		unlink("$tmpSQLFile");
		unlink("$tmpOUTFile");

	} # End of BLOCK

	&T38lib::Common::notifyWSub("SUB DONE\n");

} # End of cleanupHistoryTable

# ----------------------------------------------------------------------
#	delFilesNHourOld	delete files, older than specified number of hours
# ----------------------------------------------------------------------
#	arguments:
#		filepath	Path where to delete old files
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
sub delFilesNHourOld($) {
	my $filepath	= shift;
	my @filelist	= ();
	my $filename	= '';
	my $tempath 	= "";
	my $filePattern = "";
	my $deltime		= 0;		# Delete date converted to seconds since epoch.

	#----------------------------------------------------------------
	# File stat function call results.
	#----------------------------------------------------------------
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks);	
	my $status	= 1;
	my $pstr = '';

	&T38lib::Common::notifyWSub("SUB STARTED");

	if (defined($T38lib::t38cfgfile::gConfigValues{TranBKPHoursToHold}) && 
	            ($T38lib::t38cfgfile::gConfigValues{TranBKPHoursToHold}) > 0) {
		$gNumHours = $T38lib::t38cfgfile::gConfigValues{TranBKPHoursToHold};
	}

	SUB:
	{
		# If command line server name is given then
		# change the drive letter to the server name drive $sign
		# This is done so it can work properly on cluster 
		#
		if ($Getopt::Std::opt_S) {
			($tempath = $filepath) =~ s/^([A-Z]):/\\\\$gNetSrvr\\$1\$/i;
			$filepath = $tempath;
		}

		$deltime = time - ($gNumHours*60*60);
		$filePattern =  $filepath . "*_log_*";

		# Show in the log file where the program is looking for
		# old log files.
		#
		&T38lib::Common::notifyWSub("Process directory for old files: $filePattern");

		@filelist = glob($filePattern);
		foreach $filename (@filelist) {
			if ( ($filename =~ /.+_log_\d{12}\.bkp/i) or ($filename =~ /.+_log_\d{12}\.bk_/i) or ($filename =~ /.+_log_\d{12}\.zip/i) ) {
				($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);
				if ($mtime < $deltime) {
					$pstr	= '';
					$pstr = sprintf "Delete %s, mtime: %s, size: %s,", $filename, scalar localtime $mtime, $size;
					&T38lib::Common::notifyMe($pstr);
					unlink ($filename);
					&T38lib::Common::notifyWSub("File Deleted $filename");
				}
			}
		}

		last SUB;
	}	# SUB
	# ExitPoint:

	&T38lib::Common::notifyWSub("SUB DONE\n");

	return($status);

}	# delFilesNHourOld

#------------------------------------------------------------------------------
# Purpose:		Compress files
#
#	Input:		filepath: File path where the files are that to be compress 
#	                      or zipped
#	Output:		Status 1 OK, 0 Failed	
#------------------------------------------------------------------------------
sub zipORcompressFiles($) {
	my $filepath = shift; 

	my ($compressFlag, $compressFile) = ("", "compress.exe");	
	my ($zipFlag, $zipFile) = ("", "zip.exe");	
	my ($cmd, $filename, @filelist, $backupPathFiles, $timeStr);
	my ($subStatus) = 1;
	my ($zipFileName) = ("tranzip_log.zip");

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {


		#----------------------------------------------------------------
		# Make sure that the perl program can access the compress program
		# by checking that the directory is in the path variable.
		#----------------------------------------------------------------
		$compressFlag = &T38lib::Common::whence($compressFile);
		unless ($compressFlag) {
			&T38lib::Common::warnme("Can NOT find $compressFile.");
			&T38lib::Common::warnme("Make sure $compressFile file directory is in path variable.");

			#----------------------------------------------------------------
			# If compress is not found then try for zip
			#----------------------------------------------------------------
			$zipFlag = &T38lib::Common::whence($zipFile);
			unless ($zipFlag) {
				&T38lib::Common::warnme("Can NOT find $zipFile.");
				&T38lib::Common::warnme("Make sure $zipFile file directory is in path variable.");
				$subStatus = 0;
				last BLOCK;
			}
		}

		$backupPathFiles = $filepath . "\\";
		$backupPathFiles = $backupPathFiles . "*_log_20*.bkp";

		@filelist = glob($backupPathFiles);

		#----------------------------------------------------------------
		# If compress found then do the compress of log file
		#----------------------------------------------------------------
		if ( $compressFlag) {		
			foreach $filename (@filelist) {
				$cmd = "compress -r -zx $filename ";
				&T38lib::Common::notifyWSub("$cmd");

				unless (system("cmd /C \"$cmd\"") == 0) {
					&T38lib::Common::warnme("Problems with $cmd");
					$subStatus = 0; 
					next;
				}

				#----------------------------------------------------------------
				# If compress is OK delete the log file
				#----------------------------------------------------------------
				unlink ($filename);
				&T38lib::Common::notifyWSub("File Deleted $filename");
			}
		}

		# If compress not found but we have zip program
		# Then do the zip of log files
		#

		$cmd = "";
		if ($zipFlag) {		

			$timeStr = &getTimeStr;
			$zipFileName =~ s/\./_$timeStr\./;

			#----------------------------------------------------------------
			# Create the zip command line to zip the file
			#----------------------------------------------------------------
			$cmd = "zip -q -T ";
			$cmd = $cmd . $filepath . "\\";
			$cmd = $cmd . $zipFileName . " ";
			$cmd = $cmd . $backupPathFiles . " ";

			&T38lib::Common::notifyWSub("$cmd");

			#----------------------------------------------------------------
			# Run the ZIP command to zip all the file in the source directory
			#----------------------------------------------------------------
			if ( system($cmd) != 0 ) {	
				&T38lib::Common::notifyWSub("$cmd failed");
				$subStatus = 0; 
				last BLOCK;
			}

		}

	} # End of BLOCK

	&T38lib::Common::notifyWSub("SUB DONE\n");

	#----------------------------------------------------------------
	# Return status
	#----------------------------------------------------------------
	return ($subStatus);

}

#------------------------------------------------------------------------------
#	Purpose:  Print a help screen on std out.
#
#	Input Argument: None
#	Output:         None
#------------------------------------------------------------------------------
sub showHelp() {

print << 'EOT';
#* Purpose:  Database or tran dump.  You can specify one particular database (-d) and or server (-S) 
#*           and -c cfgfile name for logshipping, -b dump type
#*
#* Program must be executed from within the directory it is located.
#*
#* PVCS header information
#* $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL80/T38bkp.pv_  $
#* $Author: A645276 $
#* $Date: 2011/02/08 17:12:20 $
#* $Revision: 1.1 $
#*
#* SYNOPSIS
#* T38bkp.pl -h | -S server name | -d database name | -c cfgfile name | -b dump type | -a number
#*
#* Command line:
#*
#* -h  Writes help screen on standard output, then exits.
#* -c  cfg file name for log shipping, optional cfg file name
#* -S	server, optional server name
#* -d  database name, optional database name
#* -b  optional dump type (default db, for database dump, log for only log dump,
#*							diff for only differential backup)
#* -a	number of log files archived default is 7
#* -l	log file directory suffix to allow running multiple backup jobs at the same time
#*
#* Example: 
#*   1. Not specifying any command line arguments
#*      perl T38bkp.pl
#*		
#*   2. Specifying the cfg file name and keep 3 previous log files as an archive
#*      perl T38bkp.pl -c T38ls.cfg  -a 3
#*	
#*   3. Specifying cfg file, server with database
#*      perl T38bkp.pl -c T38ls.cfg -S ServerName -d DatabaseName
#*	
#*   4. Specifying cfg file, server with database do only tran dump
#*      perl T38bkp.pl -c T38ls.cfg -S ServerName -d DatabaseName -b log
#*
#*   5. Specifying cfg file, server with database do only differentail dump
#*      perl T38bkp.pl -c T38ls.cfg -S ServerName -d DatabaseName -b diff
#*
#*   6. Dump only the log for all the databases keep 10 previous log files as an archive
#*      perl T38bkp.pl -b log -a 10
#*	
#*
#***
EOT

} # End of showHelp


__END__

=pod

=head1 T38bkp.pl

T38bkp.pl - Perform Database or tran Dump with logshipping

=head1 SYNOPSIS

perl T38bkp.pl -h or -S Server Name and/or -d Database Name -c Cfg File Name (logshipping)  -b db (default) or log

=head2 OPTIONS

I<T38bkp.pl> accepts the following options:

=over 4

=item -h 		(Optional)

Print out a short help message, then exit.

=item -S Server Name

-S option to provide Server Name

=item -d Database Name

-d option to provide Database Name

=item -c Cfg File Name for log shipping

-c cfg file name 

=item -b dump type 

-b db (default option to do database dump and initialize the tran)

-b log (dump the log/ NO DATABASE DUMP)

=back

=head1 DESCRIPTION


=head1 EXAMPLE

	perl T38bkp.pl
	Not specifying any command line arguments

	perl T38bkp.pl -c T38ls.cfg 
	Specifying the cfg file name

	perl T38bkp.pl -c T38ls.cfg -S ServerName -d DatabaseName 
	Specifying cfg file, server with database

	perl T38bkp.pl -c T38ls.cfg -S ServerName -d DatabaseName -b log 
	Specifying cfg file, server with database and do only trna dump

	perl T38bkp.pl -b log
	Perform tran dump for all the databases on the current server

=head2 Notes

 DB Dump

 Do not dump database and notify the the event if the following 
 condition is true

 If another db dump is running.
 If database is in readonly mode.
 If database is in singleuser mode
 If log shipping is enable and we are on destination server
 then skip db dump of log ship databases.
 After the db dump initialize the log file with init option.

 TRANSACTION Dump

 Do not dump tran and notify the event if the following 
 condition is true

 If trunc. log on chkpt is set.
 If another dump tran is running.
 If database is in readonly mode.
 If database is in singleuser mode
 Do the tran dump with noinit option

 For logshipping databases dump the tran log to specific file
 named

	databaseneme_log_yyyymmddhhmn.bkp

 Where 
	databasename is the name of the database
	log is constant
	yyyy four digit year
	mm two digits month, January (01) to December (12)
	dd two digits calendar date of the month (01 - 31)
	hh two digits hour (00 - 23)
	mn two digits minutes after the hour (00 - 59)

=head1 BUGS

I<T38bkp.pl> has no known bugs.

=head1 REVISION HISTORY

$Revision: 1.1 $

=head1 AUTHOR

Asif Kaleem, Asif.Kaleem@bestbuy.com

=head1 SEE ALSO

Common.pm
t38cfgfile.pm

=head1 COPYRIGHT and LICENSE

This program is copyright by Best Buy Inc.

=cut
