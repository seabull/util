#!perl

# $Archive:   //cs01pvcs/pvcs/cm/Database/archives/SERVERS/STORE/MLGSTORE/T38instl80.pv_  $
# $Author: A645276 $
# $Date: 2011/02/09 22:54:04 $
# $Revision: 1.1 $
#
# T38INSTL - Install of MS-SQL Server 2000 and/or instances.
# 
#################################################################################################
#                       																								#
#                                    START of Main Program													# 
#																																#
#################################################################################################

# Turn on strict
#
use strict;

# Modules used
#
use T38lib::Common;			# Use Common Module 
use Getopt::Std;				# Use standard command line Module 
use File::Basename;
use Cwd;
use File::Path;

# Function declaration in alphabetical order
#
sub buildMaster();						# Change master database properties
sub buildSQLDirs();						# Build directories needed for the install
sub buildSetup($$); 						# Build ISS file for unattended install
sub buildSharePoints();					# Create all the share points for support
sub buildUserDb();						# Generate SQL for any user database creation
sub changeSAPassword();					# Change sa password after the install
sub checkSystem();						# Check the box for SQL install
sub disconnectNetworkDrive($);		# Disconnect any network drives
sub installServicePack();				# Install service pack upgrade if necessary
sub installSQL();							# Install SQL 2000 and/or any instences
sub mapNetworkDrive($$);				# Map network drive for SQL binaries
sub mkdir($);								# User system command to create directory path
sub moveSQLScripts();					# Move any maintenance script to proper directory 
sub readConfigFile();					# Read the CFG files initial values
sub runScriptsDir($;$);					# Run a given script or all the scripts in a directory
sub testConfigParm();					# Test all the parameters read from CFG files
sub usage();								# Display usage of the program

# Check for Perl Version if perl version is 5.005 and above then start the install process
#
my ($gperlVersion);
$gperlVersion = &T38lib::Common::chkPerlVer();
if ( $gperlVersion != 1 ) { 
	&T38lib::Common::notifyMe("[main] Wrong version of Perl $gperlVersion");
	&T38lib::Common::notifyMe("[main] This program run on Perl version 5.005 and higher");
	&T38lib::Common::notifyMe("[main] Check the Perl version by running perl -v on command line");
	&T38lib::Common::errorTrap();
}

# Archive the log file.  Keep last ten run archive.
#
&T38lib::Common::archiveLogFile(10);

# Check for rmtshare.exe file in the path.  If this file is not found then
# exit the program with error. 
# This is a utility program came with NT Resource Kit which is needed for the
# Install program to work properly.
#
my $fileverexe	= &T38lib::Common::whence("rmtshare.exe");
unless ($fileverexe) {
	&T38lib::Common::notifyMe("[main] Can not find rmtshare.exe file.");
	&T38lib::Common::notifyMe("[main] Make sure rmtshare.exe file located in path variable directories.");
	&T38lib::Common::errorTrap();
}

# Check for sc.exe file in the path.  If this file is not found then
# exit the program with error. 
# This is a utility program came with NT Resource Kit which is needed for the
# T38pwchg80.exe program to work properly.
#
$fileverexe	= &T38lib::Common::whence("sc.exe");
unless ($fileverexe) {
	&T38lib::Common::notifyMe("[main] Can not find sc.exe file.");
	&T38lib::Common::notifyMe("[main] Make sure sc.exe file located in path variable directories.");
	&T38lib::Common::errorTrap();
}

my( $glibPath, $gscriptPath, @gsuffixList, $gscriptSuffix, $gscript);
my ($gscriptName,$gscriptPath,$gscriptExt); 
my ($T38ERROR) = $T38lib::Common::T38ERROR;			

# Global hash that hold all the parameter read from cfg files.
#
my %gConfigValues= ();

# Initilize the global array
#
$gConfigValues{EnvironmentType}		= "";

$gConfigValues{SQLSourceBox} 			= "hst2db";
$gConfigValues{SQLShare} 	 			= "dbaiutil";


$gConfigValues{DumpDevicesDrive}		= "";
$gConfigValues{MdfDrive} 				= "";
$gConfigValues{NdfDrive} 				= ""; 
$gConfigValues{LdfDrive} 				= "";
$gConfigValues{TrcDrive} 				= "";
$gConfigValues{TmpDrive} 				= "";
$gConfigValues{SQLDataRootDrive}		= "";
$gConfigValues{DBAUtilsDrive} 		= "";
$gConfigValues{SQLAppDrive} 			= ""; 
$gConfigValues{DumpDevicesSrvr}		= "";

$gConfigValues{SQLSrvrEdition}		= "enterprise";			# Server edition
$gConfigValues{SQLInstanceName}		= "";							# SQL instance Name

$gConfigValues{SortOrder} 				= "dictionary";			# Sort order
$gConfigValues{CharSet} 				= "ISO";						# Character set
$gConfigValues{CaseSensitive}			= "Y";						# Case sensitive
$gConfigValues{RebootFlag} 			= "N";						# Y reboot the box / N, do NOT reboot the box (default)

$gConfigValues{SQLMemory}				= "";							# Memory used by SQL Server

$gConfigValues{DumpDevicesPath}		= "\\DBMS\\t38bkp";
$gConfigValues{MdfPath}					= "\\DBMS\\t38mdf";
$gConfigValues{NdfPath}					= "\\DBMS\\t38ndf";
$gConfigValues{LdfPath}					= "\\DBMS\\t38ldf";
$gConfigValues{TrcPath}					= "\\DBMS\\t38trc";
$gConfigValues{TmpPath}					= "\\DBMS\\t38tmp";
$gConfigValues{SQLDataRootPath}		= "\\DBMS\\t38sys";
$gConfigValues{DBAUtilsPath}			= "\\DBMS\\T38app80";
$gConfigValues{SQLAppPath}				= "\\APPS\\SQL2000";

$gConfigValues{__SharePointDumpDevicesPath}		= "t38bkp";
$gConfigValues{__SharePointMdfPath}					= "t38mdf";
$gConfigValues{__SharePointNdfPath}					= "t38ndf";
$gConfigValues{__SharePointLdfPath}					= "t38ldf";
$gConfigValues{__SharePointLdfPath}					= "t38ldf";
$gConfigValues{__SharePointTrcPath}					= "t38trc";
$gConfigValues{__SharePointSQLDataRootPath}		= "t38sys";
$gConfigValues{__SharePointDBAUtilsPath}			= "t38app80";
$gConfigValues{__SharePointSQLAppPath}				= "t38sql80";

$gConfigValues{SQLInstallPath}		= "";
$gConfigValues{ServicesDown}		= "";

$gConfigValues{SQLServiceName}		= "";
$gConfigValues{SQLServiceVersion}	= "";
$gConfigValues{SQLAgentName}		= "";

$gConfigValues{SPVersion}			= "";
$gConfigValues{SPDirectory}			= "";

$gConfigValues{gIssCollationName}   = "";
$gConfigValues{gIssInstanceName} 	= "";
$gConfigValues{gIssTCPPort}	     	= 0;
$gConfigValues{gIssPipeName}		= "";
$gConfigValues{gSQLConnectName}	 	= ".";

# Databases information 
#
my (%SystemDb, %UserDb) = ();

# Domain, Account and Password variables
#
my ($SETUP_TIMEOUT, $gPgmRevision, $gServerName, $gfullPath, $gsqlInstallStatus, $gmapDrive, $gkey);
my ($dir, $lcdir, @alldir);
my %charSO = ();
my @gArg = ();

$SETUP_TIMEOUT   = 120;								# Time out value for setup the sql server
$gPgmRevision = '$Revision: 1.1 $';			# Program revision from PVCS
$gServerName = Win32::NodeName();				# get the server name

# Sort order for SQL install
#
$charSO {'binary'}     {'850'} {'Y'}	= "SQL_Latin1_General_Cp850_BIN";		# { SortId => 40
$charSO {'dictionary'} {'850'} {'Y'}	= "SQL_Latin1_General_Cp850_CS_AS";		# { SortId => 41
$charSO {'dictionary'} {'850'} {'N'}	= "SQL_Latin1_General_Cp850_CI_AS";		# { SortId => 42 
$charSO {'binary'}     {'ISO'} {'Y'}	= "SQL_Latin1_General_BIN";				# { SortId => 50
$charSO {'dictionary'} {'ISO'} {'Y'}	= "SQL_Latin1_General_CP1_CS_AS";		# { SortId => 51
$charSO {'dictionary'} {'ISO'} {'N'}	= "SQL_Latin1_General_CP1_CI_AS";		# { SortId => 52

# Check to command line argument and display usage
#
getopts('h');
if ($Getopt::Std::opt_h || ($#ARGV == -1) ) {
	&usage();
	exit;
}

&T38lib::Common::notifyMe("[main] START of main program: $0");

# Place program name path and extension information into global variables
#
($gscriptName,$gscriptPath,$gscriptExt) = fileparse("$0","\.pl");

# Get current working directory
#
$gscriptPath = getcwd();
$gscriptPath =~ s/\//\\/g; 				# Change unix like slash / to NT like back slash \

# if setup8iss.tpl file is not found display error and quit the program
#
unless (-s "$gscriptPath\\install\\setup8iss.tpl" ) {
	&T38lib::Common::notifyMe("[main] ** ERROR ** Cannot find file $gscriptPath\\install\\setup8iss.tpl" );
	&T38lib::Common::errorTrap();
}

# if setupsp8iss.tpl file is not found display error and quit the program
#
unless (-s "$gscriptPath\\install\\setupsp8iss.tpl" ) {
	&T38lib::Common::notifyMe("[main] ** ERROR ** Cannot find file $gscriptPath\\install\\setupsp8iss.tpl" );
	&T38lib::Common::errorTrap();
}

# Copy T38lib libraries to default perl lib directory
# Get the Perl lib path from global variable @INC 
# Create a directory under Perl lib path call T38lib
# Copy all the file under T38lib
#
foreach (@INC) {
	$glibPath=$_;
	last if ( /site/i )
}

unless ( mkpath("$glibPath/T38lib") ) {
	&T38lib::Common::notifyMe("[main] mkpath failed. $glibPath/T38lib");
	&T38lib::Common::notifyMe("[main] or directory is already there try copying the module file");
}

$glibPath =~ s|/|\\|g;		# Change unix like path to windows path
&T38lib::Common::notifyMe("[main] cmd /C xcopy /Y $gscriptPath\\T38lib\\*.pm  \"$glibPath\\T38lib\"");

if (system("cmd /C xcopy /Y $gscriptPath\\T38lib\\*.pm  \"$glibPath\\T38lib\"") != 0) { 
	&T38lib::Common::notifyMe("[main] copy T38lib libraries files failed");
}

# Expand command line arguments, perform globbing.
# If command line contain any wild characters then expand 
#
@gArg = &T38lib::Common::globbing(@ARGV);
if ( $gArg[0] ne $T38ERROR ) {
	@ARGV = @gArg;
}
else {
	&T38lib::Common::notifyMe("[main] Globbing of Command line argument failed");
	&T38lib::Common::errorTrap();
}

# Get path information from registry and set environment variable PATH
#
$gfullPath = &T38lib::Common::getEnvPathVar();
if ( ($gfullPath != -1) or ($gfullPath ne $T38ERROR) ) {
	$ENV{"PATH"} = $gfullPath;
}
else {
	&T38lib::Common::notifyMe("[main] Error getting the Full Path. fullPath = $gfullPath"); 
	&T38lib::Common::errorTrap();
}

# Start calling subs to perform the install
#
&readConfigFile();					# Read the cfg file(s) and assign values to global variables
&testConfigParm();					# Validate the configuration parameters

# Print all the values read from cfg file for Testing only
# my($k, $v);
# while ( ($k, $v) = each(%gConfigValues) ) {
#	print "$k = $v\n";
# }


# Copy all the path information to hash because these will change if we have
# an instance.  These path are used in creating share points.
#
$gConfigValues{shareDumpDevicesPath}	= $gConfigValues{DumpDevicesPath};
$gConfigValues{shareMdfPath}				= $gConfigValues{MdfPath};
$gConfigValues{shareNdfPath}				= $gConfigValues{NdfPath};
$gConfigValues{shareLdfPath}				= $gConfigValues{LdfPath};
$gConfigValues{shareTrcPath}		 		= $gConfigValues{TrcPath};
$gConfigValues{shareTmpPath}				= $gConfigValues{TmpPath};
$gConfigValues{shareSQLDataRootPath}	= $gConfigValues{SQLDataRootPath};
$gConfigValues{shareDBAUtilsPath}		= $gConfigValues{DBAUtilsPath};
$gConfigValues{shareSQLAppPath}			= $gConfigValues{SQLAppPath};

# if we are installing an instance add instance name to variable names.
# The $ sign between MSSQL and instance Name is part of the service name
#
if($gConfigValues{SQLInstanceName}) {
	$gConfigValues{SQLServiceName}  	= "MSSQL\$" . $gConfigValues{SQLInstanceName};
	$gConfigValues{gSQLConnectName}	= ".\\" . $gConfigValues{SQLInstanceName}; 
	$gConfigValues{SQLAgentName}		= "SQLAgent\$" . $gConfigValues{SQLInstanceName}; 

	$gConfigValues{DBAUtilsPath}		= "$gConfigValues{DBAUtilsPath}\\$gConfigValues{SQLInstanceName}";
	$gConfigValues{MdfPath}				= "$gConfigValues{MdfPath}\\$gConfigValues{SQLInstanceName}";
	$gConfigValues{NdfPath}				= "$gConfigValues{NdfPath}\\$gConfigValues{SQLInstanceName}";
	$gConfigValues{LdfPath}				= "$gConfigValues{LdfPath}\\$gConfigValues{SQLInstanceName}";
	$gConfigValues{DumpDevicesPath}	= "$gConfigValues{DumpDevicesPath}\\$gConfigValues{SQLInstanceName}";
}

&buildSQLDirs();
$gsqlInstallStatus = &checkSystem();

if ($gsqlInstallStatus == 0) { 							# install SQL Server
	&buildSetup("setup8iss.tpl", "setup.iss");		# build the setup.iss for an un-attend sql server installation
	&installSQL();												# install SQL Server software
	$gsqlInstallStatus = 1;									# Set the SQL install status, so the other part can be done
}

if ($gsqlInstallStatus == 1) { 							# SQL Server is installed
	&moveSQLScripts();
	&buildMaster();											# build the sql for the master database	
	&buildUserDb();											# build the sql 'dbcrsz' for the user databases
	&buildSetup("setupsp8iss.tpl", "setupsp.iss");	# build the setup.iss for an un-attend sql server installation
	&installServicePack;										# install service pack upgrade if necessary
	&runScriptsDir('install\\T38procs.sql');		
	&runScriptsDir("INSTALL00"); 							# Run any scripts defined to run before SQL Build.
	&runScriptsDir('\\INSTALLWRK\\master.sql');		# reconfigure system databases

	if (&T38lib::Common::stopServiceWithDepend($gConfigValues{SQLServiceName}) != 1) { 
		&T38lib::Common::notifyMe("[main] ** ERROR ** Cannot stop $gConfigValues{SQLServiceName} service."); 
		&T38lib::Common::errorTrap();
	}

	if ( &T38lib::Common::startService($gConfigValues{SQLServiceName}) != 1 ) {
		&T38lib::Common::notifyMe("[main] ** ERROR ** Cannot start $gConfigValues{SQLServiceName} service."); 
		&T38lib::Common::errorTrap();
	}

	if (&T38lib::Common::startService($gConfigValues{SQLAgentName}) != 1) { 
		&T38lib::Common::notifyMe("[main] ** ERROR ** Cannot start $gConfigValues{SQLAgentName} service."); 
		&T38lib::Common::errorTrap();
	}

	&runScriptsDir('\\INSTALLWRK\\dbcrszbase.sql');		# create user database scripts

# Run any customize scripts for database that have created.
# 
	foreach $gkey (keys %UserDb) { 
		if ( -d "USERDB\\$gkey") {
			&runScriptsDir("USERDB\\$gkey"); 	
		}
		else {
			&T38lib::Common::notifyMe("[main] ** WARN ** Can not find directory USERDB\\$gkey");
		}

	}

# Find any directory call INSTALL01 through INSTALL99 
# and run all the scripts in these directories.
#
	if (opendir(CURDIR, $gscriptPath)) {
		@alldir = readdir (CURDIR);
		closedir(CURDIR);

		foreach $dir (@alldir) {
      		if (-d $dir) {
				$lcdir = lc($dir);
         		if ( ($lcdir =~ /^install\d\d$/) and ($lcdir ne "install00") ) {
					&runScriptsDir("$dir"); 			
         		}
      		}
		}
	}
	else {
		&T38lib::Common::notifyMe("[main] ** WARN ** Can not open directory: $gscriptPath");
	}

#--- for MLG Stores---------------

	system('install\\SetRightBT38.cmd');

	if ( system('install\\T38mslogin.pl') != 0 ) {	
		&T38lib::Common::notifyMe("[main] ** WARN ** Fail to run install\\T38mslogin.pl");
	}


	if ( system('install\\T38admsec.pl ' . join(' ', @gArg) ) != 0 ) {	
		&T38lib::Common::notifyMe("[main] ** WARN ** Fail to run install\\T38admsec.pl");
	}

#	&changeSAPassword();

	if (&T38lib::Common::stopServiceWithDepend($gConfigValues{SQLServiceName}) != 1) { 
		&T38lib::Common::notifyMe("[main] ** ERROR ** Cannot stop $gConfigValues{SQLServiceName} service."); 
		&T38lib::Common::errorTrap();
	}

	if ( &T38lib::Common::startService($gConfigValues{SQLServiceName}) != 1 ) {
		&T38lib::Common::notifyMe("[main] ** ERROR ** Cannot start $gConfigValues{SQLServiceName} service."); 
		&T38lib::Common::errorTrap();
	}

	if (&T38lib::Common::startService($gConfigValues{SQLAgentName}) != 1) { 
		&T38lib::Common::notifyMe("[main] ** ERROR ** Cannot start $gConfigValues{SQLAgentName} service."); 
		&T38lib::Common::errorTrap();
	}
}

if ($gsqlInstallStatus == -1) {
	&T38lib::Common::notifyMe("[main] Older Version of Microsoft SQL Server installed on $gServerName ");
	&T38lib::Common::errorTrap();
}

&disconnectNetworkDrive($gmapDrive);

# Build all the share points
#
&buildSharePoints();

# Run script from install directory T38runAgentJobs.sql
#
&runScriptsDir('install\\T38runAgentJobs.sql');		


# If reboot flag is set to Y then reboot the box
# cfg file has the reboot flag default value is N, means do NOT reboot
#
if ( $gConfigValues{RebootFlag} =~ /y/i ) { 	
	&T38lib::Common::notifyMe("[main] DONE of main program: $0");
	&T38lib::Common::notifyMe("[main] Rebooting the Box");
	&T38lib::Common::rebootLocalMachine();
}

&T38lib::Common::notifyMe("[main] DONE of main program: $0");

#################################################################################################
#                       																								#
#                                        END of Main Program												# 
#																																#
#################################################################################################

#------------------------------------------------------------------------------
#	Purpose: Run all the script in the given directory.
#	
#	Input Argumrnt: Directory name or a file name
#	Output:         None
#------------------------------------------------------------------------------
sub runScriptsDir($;$) {
	my ($dfName, $noErrorChk ) = @_; 
	

	my (@scripts) = ();
	my ($progName, $cmdLine, $result, $path, $name, $ext, $outFileName);

	&T38lib::Common::notifyMe("[runScriptsDir] START - Run Pre Build scripts");

	$dfName = "$gscriptPath\\" . $dfName;			# Combine the current directory with the post build script directory

	&T38lib::Common::notifyMe("[runScriptsDir] Running scripts from $dfName");

	if ( -d "$dfName") {
		unless (opendir(GIVENDIR, $dfName)) {
			&T38lib::Common::notifyMe("[runScriptsDir] ** Warn ** Can not open directory: $dfName");
			return;
		}

		foreach (readdir (GIVENDIR)) {
			unless (-d "$dfName\\$_") {				# File is not a directory
				push (@scripts, "$dfName\\$_");		# Push only the file name not the path
			}
		}
		closedir(GIVENDIR);
	}
	elsif ( -s "$dfName") {
		push (@scripts, $dfName);			
	}
	else {
		&T38lib::Common::notifyMe("[runScriptsDir] Invalid program to run: $dfName");
		return;
	}

	@scripts = sort(@scripts);

	if ( defined (@scripts) ) {
		foreach $progName (@scripts) {

			($name,$path,$ext) = fileparse("$progName","");
			$name =~ /\.([^\.]+)$/;
			$ext = lc($1);
	    	$ext =~ s/^\s*//g;							# Remove all leading white spaces
	    	$ext =~ s/\s*$//g;							# Remove all trailing white spaces

			if ( ($ext eq "bat") or ( $ext eq "cmd") or ($ext eq "exe") ) {
				$cmdLine = "$progName";
				$result = system("cmd /C start /wait $cmdLine");

				if ( $result == 0 ) {
					&T38lib::Common::notifyMe("[runScriptsDir] Command = $cmdLine");
					&T38lib::Common::notifyMe("[runScriptsDir] result code from system command = $result");
					&T38lib::Common::notifyMe("[runScriptsDir] script ran successfully");
				}
				else {
					&T38lib::Common::notifyMe("[runScriptsDir] Command = $cmdLine");
					&T38lib::Common::notifyMe("[runScriptsDir] result code from system command = $result");
					&T38lib::Common::notifyMe("[runScriptsDir] ** ERROR ** script failed");
					&T38lib::Common::errorTrap();
				}
			}
			elsif ( $ext eq "pl" ) {
				$cmdLine = "perl $progName";
				$result = system("cmd /C start /wait $cmdLine");

				if ( $result == 0 ) {
					&T38lib::Common::notifyMe("[runScriptsDir] Command = $cmdLine");
					&T38lib::Common::notifyMe("[runScriptsDir] result code from system command = $result");
					&T38lib::Common::notifyMe("[runScriptsDir] script ran successfully");
				}
				else {
					&T38lib::Common::notifyMe("[runScriptsDir] Command = $cmdLine");
					&T38lib::Common::notifyMe("[runScriptsDir] result code from system command = $result");
					&T38lib::Common::notifyMe("[runScriptsDir]  ** ERROR ** script failed");
					&T38lib::Common::errorTrap();
				}
			}
			elsif ( $ext eq "sql" ) {
				($name,$path,$ext) = fileparse("$progName","\.sql");
				$outFileName = $path . $name . "\.out";
				$cmdLine = "osql -E -S$gConfigValues{gSQLConnectName} -i$progName -o$outFileName -w 2048";
				$result = system("cmd /C start /wait $cmdLine");

				if ( $result == 0 ) {
					&T38lib::Common::notifyMe("[runScriptsDir] Command = $cmdLine");
					&T38lib::Common::notifyMe("[runScriptsDir] result code from system command = $result");
					&T38lib::Common::notifyMe("[runScriptsDir] script ran successfully");
				}
				else {
					&T38lib::Common::notifyMe("[runScriptsDir] Command = $cmdLine");
					&T38lib::Common::notifyMe("[runScriptsDir] result code from system command = $result");
					&T38lib::Common::notifyMe("[runScriptsDir] ** ERROR ** script failed");
					&T38lib::Common::errorTrap();
				}

				if ($noErrorChk) {
					next;
				}

				unless (open(OUTFILE, "<$outFileName")) { 
					&T38lib::Common::notifyMe("[runScriptsDir] ** ERROR ** Cannot open file $outFileName for reading. $!"); 
					&T38lib::Common::errorTrap();
				}

				&T38lib::Common::notifyMe("[runScriptsDir] Checking $outFileName for errors.");

				while (<OUTFILE>) {
					if ( (/Msg\s+\d+/i) || (/Error:\s+\d+/i) || (/SQL Server does not exist/i) || (/access denied\./i) ) {
						&T38lib::Common::notifyMe("[runScriptsDir] ** ERROR ** found at $. running $progName, script terminated");
						&T38lib::Common::notifyMe("[runScript] View $outFileName for information");
						&T38lib::Common::errorTrap();
					}	
				}	
				&T38lib::Common::notifyMe("[runScriptsDir] No error found in $outFileName");

			}
			else {
				&T38lib::Common::notifyMe("[runScriptsDir] Invalid program ext to run: $progName");
				&T38lib::Common::notifyMe("[runScriptsDir] extension is $ext");
			}
		}
	}

	&T38lib::Common::notifyMe("[runScriptsDir] DONE - Run Pre Build scripts");

}	# End of runScriptsDir

#------------------------------------------------------------------------------
#	Purpose: Build the setup.iss file and replace variables with values
#			 from cfg files
#
#	Input:	None
#	Output:	None
#------------------------------------------------------------------------------
sub installSQL() {

 	my ($result, $cmd, $ini_section_name, $key, $cnt, $log_filename, $serviceName);
	my $rtn = 0;
 	my (@ServicestoStop);

	&T38lib::Common::notifyMe("[installSQL] START - Install SQL Server.");

	my $setupDirName = 
				($gConfigValues{SQLSrvrEdition} =~ /workstation/) ? "SQL2000_per" :
				($gConfigValues{SQLSrvrEdition} =~ /server/) ? "SQL2000_std" :
				($gConfigValues{SQLSrvrEdition} =~ /enterprise/) ? "SQL2000_ent" : 
				"SQL2000";
				
	@ServicestoStop = split('\,', $gConfigValues{ServicesDown});

	foreach $serviceName (@ServicestoStop) {
		&T38lib::Common::stopServiceWithDepend($serviceName);
	}

  	&T38lib::Common::notifyMe ("[installSQL] preparing to install SQL Server.");
	$log_filename=$ENV{SystemRoot} . "\\" . "setup.log";    	   

	if (-s "$gConfigValues{SQLInstallPath}\\$setupDirName\\x86\\setup\\setupsql.exe") {
		$cmd = "$gConfigValues{SQLInstallPath}\\$setupDirName\\x86\\setup\\setupsql.exe k=SMS -s -m -SMS -f1 $gscriptPath\\INSTALLWRK\\setup.iss";
	} elsif (-s "$gConfigValues{SQLInstallPath}\\x86\\setup\\setupsql.exe") {
		$cmd = "$gConfigValues{SQLInstallPath}\\x86\\setup\\setupsql.exe k=SMS -s -m -SMS -f1 $gscriptPath\\INSTALLWRK\\setup.iss";
	} else {
		&T38lib::Common::notifyMe ("[installSQL] Mapping a net work drive to $gConfigValues{SQLSourceBox} share $gConfigValues{SQLShare}");
		$gmapDrive = &mapNetworkDrive("$gConfigValues{SQLSourceBox}","$gConfigValues{SQLShare}");

		if (-s "$gmapDrive\\sql2000\\$setupDirName\\x86\\setup\\setupsql.exe") {
			$cmd = "$gmapDrive\\sql2000\\$setupDirName\\x86\\setup\\setupsql.exe k=SMS -s -m -SMS -f1 $gscriptPath\\INSTALLWRK\\setup.iss";
		}
		else {
			&T38lib::Common::notifyMe ("[installSQL] ** ERROR ** Can not find file $gmapDrive\\sql2000\\$setupDirName\\x86\\setup\\setupsql.exe");
			&T38lib::Common::errorTrap();
		}					
	}					

	&T38lib::Common::notifyMe("[installSQL] - Installation of SQL Server started.");

	$result = system("cmd /C start /wait $cmd");

	&T38lib::Common::notifyMe("[installSQL] - Installation of SQL Server finished.");

	&T38lib::Common::notifyMe("[installSQL] $cmd");
	&T38lib::Common::notifyMe("[installSQL] return code of the command = $result");

	if ( $result == 0 ) {
		$cnt=0;
		$ini_section_name="Status";
		$key="Completed";

		SUB:
		{
			while ( $cnt < 	$SETUP_TIMEOUT ) {
				&T38lib::Common::notifyMe("[installSQL] Waiting for setupsql.exe to finished Sleep 60 sec ...");
				if ( -s $log_filename ) {
					sleep 10;
					$rtn=&T38lib::Common::readINI($log_filename, $ini_section_name, $key);
					last SUB; 
				}
				else {
					sleep 60;
					$cnt++;
				}
			}
 		}

		if ( $rtn == 1 ) {
			&T38lib::Common::notifyMe ("[installSQL] Installation of SQL Server successful.");

			$gfullPath = &T38lib::Common::getEnvPathVar();
			if ( ($gfullPath != -1) or ($gfullPath ne $T38ERROR) ) {
				$ENV{"PATH"} = $gfullPath;
			}
			else {
				&T38lib::Common::notifyMe("[installSQL] Error getting the Full Path. fullPath = $gfullPath"); 
				&T38lib::Common::errorTrap();
			}
		}
		else {
			&T38lib::Common::notifyMe ("[installSQL] ** ERROR ** Installation of SQL Server failed. Check $ENV{SystemRoot}\\setup.log.");
			&T38lib::Common::notifyMe ("[installSQL] ** ERROR **Installation of SQL Server failed. Check $ENV{SystemRoot}\\sqlstp.log.");
			&T38lib::Common::errorTrap();
		}					
    }
    else {
        &T38lib::Common::notifyMe ("[installSQL]  Could not start $cmd");
		&T38lib::Common::errorTrap();
    }

	&T38lib::Common::notifyMe("[installSQL] DONE  - Install SQL Server.");

}   # end sub installSQL

#------------------------------------------------------------------------------
#	Purpose: Build the setup.iss file and replace variables with values
#			 from cfg files
#
#	Input Argument : template file name
#				  		: output   file name
#	
#	Return:			 None
#------------------------------------------------------------------------------
sub buildSetup($$) {
	my ($setupTpl, $setupIss) = @_;
	
	my ($tmpStatus, $var);
	$setupTpl = "$gscriptPath\\install\\" . $setupTpl;
	$setupIss = "$gscriptPath\\INSTALLWRK\\" . $setupIss;

	&T38lib::Common::notifyMe("[buildSetup] START - Build iss file.");

	$gConfigValues{gIssCollationName} = 
	$charSO{$gConfigValues{SortOrder}}{$gConfigValues{CharSet}}{$gConfigValues{CaseSensitive}};

	# if we have an instance name
	#
	if ( $gConfigValues{SQLInstanceName}) {
		$gConfigValues{gIssInstanceName} = $gConfigValues{SQLInstanceName};
		$gConfigValues{gIssTCPPort}	= 0;
		$gConfigValues{gIssPipeName} = "pipe\\MSSQL\$$gConfigValues{SQLInstanceName}";
	}
	else { 
		$gConfigValues{gIssInstanceName} = "MSSQLSERVER";
		$gConfigValues{gIssTCPPort}	     = 1433;
		$gConfigValues{gIssPipeName}	 = "pipe";
	}

	&T38lib::Common::notifyMe ("[buildSetup] preparing to build the setup.iss file at $gscriptPath\\install directory");

	unless (open(SETUP,">$setupIss")) {
		&T38lib::Common::notifyMe("[buildSetup] ** ERROR ** Cannot open file $setupIss for writing. $!."); 
		&T38lib::Common::errorTrap(); 
	}
	unless (open(SETUPTPL,"<$setupTpl")) { 
		&T38lib::Common::notifyMe("[buildSetup] ** ERROR ** Cannot open file $setupTpl for reading. $!."); 
		&T38lib::Common::errorTrap(); 
	}

	while (<SETUPTPL>) {
		foreach $var (/\$\{([^\s\}]+)\}/g) {
			if (defined($gConfigValues{$var})) { 
				s/\$\{$var\}/$gConfigValues{$var}/; 
			}
			else {
				s/\$\{(\S+)\}/#UNDEFINED#/; 
				&T38lib::Common::notifyMe("[buildSetup] ** Warning ** Variable gConfigValues{$var} is undefined in cfg file for $setupTpl.");
			}
		}
		print SETUP;
	}

	close (SETUP);
	close (SETUPTPL);

	&T38lib::Common::notifyMe ("[buildSetup] new setup.iss file is created at $gscriptPath\\INSTALLWRK directory");

	&T38lib::Common::notifyMe("[buildSetup] DONE  - Build iss file.");

} # end sub buildSetup

#------------------------------------------------------------------------------
#	Purpose: Check the box to see if SQL Server has been installed or it is
#            running before trying to install SQL software again. 
#
#	Input Argument :	None
#	Return:	$sqlInstallStatus
#			0 => No SQL Server is installed on the box
#			1 => SQL Server is installed, run the later half
#		   -1 => Older version of SQL is Installed.
#------------------------------------------------------------------------------
sub checkSystem() {

	my ($sqlInstallStatus, $SQLVersion);	 			
	my ($sqlMajorVer, $sqlMinorVer, $sqlSPVer, $SQLVersion);


	&T38lib::Common::notifyMe("[checkSystem] START - Check if SQL Installed.");

	# check the SQL Server version	
	$SQLVersion = &T38lib::Common::getSqlCurVer($gConfigValues{SQLInstanceName});
	($sqlMajorVer, $sqlMinorVer, $sqlSPVer) = split('\.', $SQLVersion);

 	# if $sqlMajorVer is zero then no SQL server is installed
 	if ($sqlMajorVer == 0 ) {
		&T38lib::Common::notifyMe ("[checkSystem] Microsoft SQL Server version $gConfigValues{SQLServiceVersion} is NOT installed on $gServerName");
		&T38lib::Common::notifyMe ("[checkSystem] Install Microsoft SQL Server version $gConfigValues{SQLServiceVersion}");
		$sqlInstallStatus = 0;
	}
	# SQL server is installed Run the later half
	elsif ( $sqlMajorVer == $gConfigValues{SQLServiceVersion} ) {
		&T38lib::Common::notifyMe ("[checkSystem] Microsoft SQL Server version $SQLVersion is installed on $gServerName");
		$sqlInstallStatus = 1;
	}
	# Older Version of SQL Server is installed.
	else {
		&T38lib::Common::notifyMe ("[checkSystem] Microsoft SQL Server version $SQLVersion is installed on $gServerName");
		&T38lib::Common::notifyMe ("[checkSystem] Older version of Microsoft SQL Server installed");
		$sqlInstallStatus = -1;
	}

	&T38lib::Common::notifyMe("[checkSystem] DONE - Check if SQL Installed.");
	
	return $sqlInstallStatus;

} # end sub checkSystem 

#------------------------------------------------------------------------------
#	Purpose: Build directories 
#
#------------------------------------------------------------------------------
sub buildSQLDirs() {

	my ($crtDir)="";

	&T38lib::Common::notifyMe("[buildSQLDirs] START - Building Directories.");

# Database T-Log and Backup
	$crtDir = "$gConfigValues{DumpDevicesDrive}:$gConfigValues{DumpDevicesPath}";
	&mkdir($crtDir) unless ( -d $crtDir);

# System and user data
	$crtDir = "$gConfigValues{MdfDrive}:$gConfigValues{MdfPath}";					
	&mkdir($crtDir) unless ( -d $crtDir);

# Optional user data contained in databases
	$crtDir = "$gConfigValues{NdfDrive}:$gConfigValues{NdfPath}";					
	&mkdir($crtDir) unless ( -d $crtDir);

# Database Transection log
	$crtDir = "$gConfigValues{LdfDrive}:$gConfigValues{LdfPath}";	
	&mkdir($crtDir) unless ( -d $crtDir);

# SQL Trace file
	$crtDir = "$gConfigValues{TrcDrive}:$gConfigValues{TrcPath}";
	&mkdir($crtDir) unless ( -d $crtDir);

# Temporary Work File
	$crtDir = "$gConfigValues{TmpDrive}:$gConfigValues{TmpPath}";
	&mkdir($crtDir) unless ( -d $crtDir);

# Master and Other System Databases Live
	$crtDir = "$gConfigValues{SQLDataRootDrive}:$gConfigValues{SQLDataRootPath}";
	&mkdir($crtDir) unless ( -d $crtDir);

# DBA Maintenance Scripts
	$crtDir = "$gConfigValues{DBAUtilsDrive}:$gConfigValues{DBAUtilsPath}";
	&mkdir($crtDir) unless ( -d $crtDir);

# SQL Server Binaries
	$crtDir = "$gConfigValues{SQLAppDrive}:$gConfigValues{SQLAppPath}";
	&mkdir($crtDir) unless ( -d $crtDir);

	&T38lib::Common::notifyMe("[buildSQLDirs] DONE  - Building Directories.");

} # end sub buildSQLDirs

#------------------------------------------------------------------------------
#	Purpose: Test all the configuration parameters to make sure they are there
#            Future processing relies on these parameters.
#------------------------------------------------------------------------------
sub testConfigParm() {

	my $AnyError = 0; 				# initialize $AnyError to no errors found
	&T38lib::Common::notifyMe("[testConfigParm] START - Validating configuration parameter.");
   
# NBA cfg file check
#
    if ( ($gConfigValues{EnvironmentType} eq "") || ($gConfigValues{EnvironmentType} !~ /[a-z]/i) )  { 	
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable EnvironmentType is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{SQLSourceBox} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLSourceBox is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{SQLShare} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLShare is undefined in cfg file.");
		$AnyError = 1;
	}
	
    if ( ($gConfigValues{DumpDevicesDrive} eq "") || ($gConfigValues{DumpDevicesDrive} !~ /[a-z]/i) ) {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable DumpDevicesDrive is undefined in cfg file.");
		$AnyError = 1;
	}

   if ( ($gConfigValues{MdfDrive} eq "") || ($gConfigValues{MdfDrive} !~ /[a-z]/i) ) { 	
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable MdfDrive is undefined in cfg file.");
		$AnyError = 1;
	}

    if ( ($gConfigValues{NdfDrive} eq "") || ($gConfigValues{NdfDrive} !~ /[a-z]/i) ) { 	
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable NdfDrive is undefined in cfg file.");
		$AnyError = 1;
	}

    if ( ($gConfigValues{LdfDrive} eq "") || ($gConfigValues{LdfDrive} !~ /[a-z]/i) ) { 	
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable LdfDrive is undefined in cfg file.");
		$AnyError = 1;
	}

    if ( ($gConfigValues{TrcDrive} eq "") || ($gConfigValues{TrcDrive} !~ /[a-z]/i) ) { 	
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable TrcDrive is undefined in cfg file.");
		$AnyError = 1;
	}

    if ( ($gConfigValues{TmpDrive} eq "") || ($gConfigValues{TmpDrive} !~ /[a-z]/i) ) { 	
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable TmpDrive is undefined in cfg file.");
		$AnyError = 1;
	}

    if ( ($gConfigValues{SQLDataRootDrive} eq "") || ($gConfigValues{SQLDataRootDrive} !~ /[a-z]/i) ) { 	
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLDataRootDrive is undefined in cfg file.");
		$AnyError = 1;
	}

    if ( ($gConfigValues{DBAUtilsDrive} eq "") || ($gConfigValues{DBAUtilsDrive} !~ /[a-z]/i) ) { 	
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLDataRootDrive is undefined in cfg file.");
		$AnyError = 1;
	}

    if ( ($gConfigValues{SQLAppDrive} eq "") || ($gConfigValues{SQLAppDrive} !~ /[a-z]/i) ) { 	
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLAppDrive is undefined in cfg file.");
		$AnyError = 1;
	}

	if ( ($gConfigValues{SQLInstanceName}) and ($gConfigValues{SQLInstanceName} =~ /\s/) ) {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLInstanceName is not valid.");
		$AnyError = 1;
	}

	# T38dba cfg file check
	#
	if ($gConfigValues{SQLSrvrEdition} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLSrvrEdition is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{SortOrder} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SortOrder is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{CharSet} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable CharSet is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{CaseSensitive} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable CaseSensitive is undefined in cfg file.");
		$AnyError = 1;
	}

	if ( ! (defined ($charSO{$gConfigValues{SortOrder}}{$gConfigValues{CharSet}}{$gConfigValues{CaseSensitive}})) ) {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Invalid collation (SortOrder=$gConfigValues{SortOrder}, CharSet=$gConfigValues{CharSet}, CaseSensitive=$gConfigValues{CaseSensitive}) ");
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** combination is defined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{SQLMemory} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLMemory is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{RebootFlag} eq "") {
		$gConfigValues{RebootFlag} = "N";
	}

	if ($gConfigValues{DumpDevicesPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable DumpDevicesPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{MdfPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable MdfPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{NdfPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable NdfPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{LdfPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable LdfPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{TrcPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable TrcPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{TmpPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable TmpPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{SQLDataRootPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLDataRootPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{DBAUtilsPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable DBAUtilsPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{SQLAppPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLAppPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{SQLInstallPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLInstallPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{__SharePointDumpDevicesPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable __SharePointDumpDevicesPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{__SharePointMdfPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable __SharePointMdfPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{__SharePointNdfPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable __SharePointNdfPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{__SharePointLdfPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable __SharePointLdfPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{__SharePointTrcPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable __SharePointTrcPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{__SharePointTmpPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable __SharePointTmpPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{__SharePointSQLDataRootPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable __SharePointSQLDataRootPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{__SharePointDBAUtilsPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable __SharePointDBAUtilsPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{__SharePointSQLAppPath} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable __SharePointSQLAppPath is undefined in cfg file.");
		$AnyError = 1;
	}

	if ($gConfigValues{SQLServiceName} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLServiceName is undefined in cfg file.");
		$AnyError = 1;
	}
	if ($gConfigValues{SQLServiceVersion} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLServiceVersion is undefined in cfg file.");
		$AnyError = 1;
	}
	if ($gConfigValues{SQLAgentName} eq "") {
		&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** Configuration variable SQLAgentName is undefined in cfg file.");
		$AnyError = 1;
	}
	
# Service pack related config parameters
#
	if ($gConfigValues{SPVersion} ne "") {
		if ( ($gConfigValues{SPDirectory} eq "") )  {
			&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** SPDirectory is undefined in cfg file");
			$AnyError = 1;
		}
	}
	if ($gConfigValues{SPVersion} eq "") {
		if ( ($gConfigValues{SPDirectory} ne "") )  {
			&T38lib::Common::notifyMe ("[testConfigParm] ** ERROR ** SPVersion is undefined in cfg file.");
			$AnyError = 1;
		}
	}

	if ($AnyError == 1) {
		&T38lib::Common::notifyMe("[testConfigParm] ** ERROR ** Missing/Invalid configuration parameters.");
		&T38lib::Common::notifyMe("[testConfigParm] ** ERROR ** CHECK CFG FILES");
		&T38lib::Common::errorTrap();
	}

	&T38lib::Common::notifyMe("[testConfigParm] DONE - Validating configuration parameter.");

} # end sub testConfigParm

#------------------------------------------------------------------------------
#	Purpose: Read the configuration file(s) T38dba.cfg, NBA.cfg, userdb.cfg
#            Set up global variables with the values read from CFG file(s).
#------------------------------------------------------------------------------
sub readConfigFile() {

	my $status;							# test condition variable for creating dbms\db_apps\install directory
	my ($SysDatabases, $UserDatabases );
	my ($Name, $DataName, $DataSize, $LogName, $LogSize, $DataBackup, $LogBackup, 
	    $TruncLog, $SelectInto, $ExpandData);

	&T38lib::Common::notifyMe("[readConfigFile] START - Reading cfg files.");

	while  (<>) {						# read the input file line by line
		chomp();							# Get rid of new line character
		if ( /^\#/ or /^$/ ) {		# Skip comment and blank lines
			next;
		}

		$_ =~ s/\#.*$//g;				# Remove comments
	    $_ =~ s/^\s*//g;				# Remove all leading white spaces
	    $_ =~ s/\s*$//g;				# Remove all trailing white spaces

		# cfg variable has a value defined and it is assigned to global hash
		#
		if (/^(\S+)\s*=\s*(\S+.*)$/) {
			$gConfigValues{$1}=$2;
		}
		# cfg variable has NO values defined so global hash is initilized
		#
		elsif (/^(\S+)\s*=$/){
			$gConfigValues{$1}="";
		}

		# determine if we have read the <system database> header	
		#
		if (/<system databases>/) { 
			$SysDatabases = 1; 
			next;
		}
     	$SysDatabases = 0 if (/<end system databases>/i);
     	if (($SysDatabases) && 
     		!(/Name\s*DataName\s*DataSize\s*LogName\s*LogSize\s*DataBackup\s*LogBackup\s*TruncLog\s*SelectInto\s*ExpandData/i) &&
			!(/^\s*$/) ) {
			chop;
			s/^[\s]+//g;
			($Name, $DataName, $DataSize, $LogName, $LogSize, $DataBackup, $LogBackup, $TruncLog, $SelectInto, $ExpandData) = 
			split("[\t ]+");
		      
			# create a hash of hashes for system database options
	
			$SystemDb{$Name}{'DataName'}		= $DataName;		# logical name of the database data device
			$SystemDb{$Name}{'DataSize'}		= $DataSize;		# size of the the logical data device
			$SystemDb{$Name}{'LogName'}	   = $LogName;			# logical name of the database log device
			$SystemDb{$Name}{'LogSize'}	   = $LogSize;			# size of the logical log device
			$SystemDb{$Name}{'DataBackup'}	= $DataBackup;		# logical name of the database backup device
			$SystemDb{$Name}{'LogBackup'}		= $LogBackup;		# logical name of the database log backup device
			$SystemDb{$Name}{'TruncLog'}		= $TruncLog;		# "truncate log" option set on / off for this database
			$SystemDb{$Name}{'SelectInto'}	= $SelectInto;		# "select into" option set on / off for this database
			$SystemDb{$Name}{'ExpandData'} 	= $ExpandData;		# Should Data device be automatically expandable 

	    } # end of the if for building hash for system databases 
	
		# determine if we have read the <user database> header
		if (/<user databases>/) { 
			$UserDatabases = 1; 
			next;
		}
     	$UserDatabases = 0 if (/<end user databases>/i);
     	
     	if ( ($UserDatabases) && 
     		!(/Name\s*DataName\s*DataSize\s*LogName\s*LogSize\s*DataBackup\s*LogBackup\s*TruncLog\s*SelectInto\s*ExpandData/i) &&
			!(/^\s*$/)) {
			chop;
			s/^[\s]+//g;
			($Name, $DataName, $DataSize, $LogName, $LogSize, $DataBackup, $LogBackup, $TruncLog, $SelectInto, $ExpandData)
			 = split("[\t ]+");

			# create a hash of hashes for user database options	
			$UserDb{$Name}{"DataName"}		= $DataName;		# logical name of the database data device
			$UserDb{$Name}{"DataSize"}		= $DataSize;		# size of the the logical data device
			$UserDb{$Name}{"LogName"}		= $LogName;			# logical name of the database log device
			$UserDb{$Name}{"LogSize"}		= $LogSize;			# size of the logical log device
			$UserDb{$Name}{"DataBackup"}	= $DataBackup;		# logical name of the database backup device
			$UserDb{$Name}{"LogBackup"}	= $LogBackup;		# logical name of the database log backup device
			$UserDb{$Name}{"TruncLog"}		= $TruncLog;		# "truncate log" option set on / off for this database
			$UserDb{$Name}{"SelectInto"}	= $SelectInto;		# "select into" option set on / off for this database
			$UserDb{$Name}{"ExpandData"} 	= $ExpandData;		# Should Data device be automatically expandable

		
		} # end of the if for building hash for user databases 
	}	  
	# Set dba installation path.
	
	&T38lib::Common::notifyMe("[readConfigFile] DONE - Reading cfg files.");
	
	} # end sub readconfigfile

#------------------------------------------------------------------------------
# Purpose: usage of the program
#------------------------------------------------------------------------------
sub usage() {
	print "\nusage: $0  -h | {CFG file names...} | *.cfg\n\n";
	print "\tName(s) of cfg files {T38DBA.CFG} {NBC.CFG} [USERDB.CFG]\n";
	print "\t-h Display help\n";

} # end sub usage

#------------------------------------------------------------------------------
# Purpose: Install Service Pack
#------------------------------------------------------------------------------
sub installServicePack() {

	my ($serviceName, $rtn, $cmd );
	my ($nosp) = 0;
	my (%result) = ();
	my (@depServices, @sp_version, @cur_version); 

	&T38lib::Common::notifyMe("[installServicePack] START - Check and install Service pack");

	# Check the Server version (include current version or CSD version) with the SP Version
	#
	$result{'CurrentVersion'} = &T38lib::Common::getSqlCurVer("$gConfigValues{SQLInstanceName}");
	$result{'CSDversion'}     = &T38lib::Common::getSqlCSDVer("$gConfigValues{SQLInstanceName}");

	@sp_version = split( /\./, $gConfigValues{SPVersion} );

	if ( defined ($result{"CSDVersion"})  ) {
		@cur_version = split( /\./, $result{"CSDVersion"} );

      if ( $sp_version[0] == $cur_version[0]  &&
          $sp_version[1]  == $cur_version[1]  &&
          $sp_version[2]  == $cur_version[2] ) {
			&T38lib::Common::notifyMe("[installServicePack]: CSDVersion from Registry 	= $result{'CSDVersion'}");
			&T38lib::Common::notifyMe("[installServicePack]: Version from cfg file		= $gConfigValues{SPVersion}");
			&T38lib::Common::notifyMe("** WARN **  [installServicePack]: Service pack is already applied.");
			$nosp = 1;
			#return;
		}
		else {

      	if ( $sp_version[0]  == $cur_version[0]  &&
          	  $sp_version[1]  == $cur_version[1]  &&
          	  $sp_version[2]   > $cur_version[2] ) {
				&T38lib::Common::notifyMe("[installServicePack]: CSDVersion from Registry	= $result{'CSDVersion'}");
				&T38lib::Common::notifyMe("[installServicePack]: Version from cfg file		= $gConfigValues{SPVersion}");
				&T38lib::Common::notifyMe("[installServicePack]: Install Service pack");
			}
			else {
				&T38lib::Common::notifyMe("[installServicePack]: CSDVersion from Registry	= $result{'CSDVersion'}");
				&T38lib::Common::notifyMe("[installServicePack]: Version from cfg file		= $gConfigValues{SPVersion}");
				&T38lib::Common::notifyMe("[installServicePack]: ** WARN ** Service pack is already applied or wrong version.");
				$nosp = 1;
			#	return;
			}
		}
	}
	else {
		@cur_version = split( /\./, $result{"CurrentVersion"} );

      if ( $sp_version[0] == $cur_version[0]  &&
           $sp_version[1] == $cur_version[1]  &&
           $sp_version[2] == $cur_version[2] ) {
			&T38lib::Common::notifyMe("[installServicePack]: CurrentVersion from Registry 	= $result{'CurrentVersion'}");
			&T38lib::Common::notifyMe("[installServicePack]: Version from cfg file  		= $gConfigValues{SPVersion}");
			&T38lib::Common::notifyMe("[installServicePack]: ** WARN ** Servic pack is already applied.");
			$nosp = 1;
			#return;
		}
		else {
      	if ( $sp_version[0] == $cur_version[0]  &&
          	  $sp_version[1] == $cur_version[1]  &&
           	  $sp_version[2]  >  $cur_version[2] ) {
				&T38lib::Common::notifyMe("[installServicePack]: CurrentVersion from Registry 	= $result{'CurrentVersion'}");
				&T38lib::Common::notifyMe("[installServicePack]: Version from cfg file  		= $gConfigValues{SPVersion}");
				&T38lib::Common::notifyMe("[installServicePack]: Install Service pack");
			}
			else {
				&T38lib::Common::notifyMe("[installServicePack]: CurrentVersion from Registry 	= $result{'CurrentVersion'}");
				&T38lib::Common::notifyMe("[installServicePack]: Version from cfg file  		= $gConfigValues{SPVersion}");
				&T38lib::Common::notifyMe("** WARN **  [installServicePack]: Service pack is already applied or wrong version.");
				$nosp = 1;
			#	return;
			}
		}
	}

	# Find all the dependent services
	#
	@depServices = &T38lib::Common::findDependentService($gConfigValues{SQLServiceName});

# If we are not installing the service pack then start the SQL Server and dependent services 
# and return to calling sub.
#
	if ( $nosp == 1 ) {
		if ( &T38lib::Common::startService($gConfigValues{SQLServiceName}) ) {
			&T38lib::Common::notifyMe("[installServicePack]: $gConfigValues{SQLServiceName} STARTED");
		}
		else {
			&T38lib::Common::notifyMe("[installServicePack]: $gConfigValues{SQLServiceName} NOT STARTED");
			&T38lib::Common::errorTrap();
		}

		foreach $serviceName (@depServices) {
			if ( &T38lib::Common::startService($serviceName) ) {
				&T38lib::Common::notifyMe("[installServicePack]: $serviceName STARTED");
			}
			else {
				&T38lib::Common::notifyMe("[installServicePack]: $serviceName NOT STARTED");
			}
		}
		return;
	}

# Stop services and Install the service pack
#
	if ( $depServices[0] eq "$T38ERROR" ) {
		&T38lib::Common::notifyMe("[installServicePack]: call to &T38lib::Common::findDependentService($gConfigValues{SQLServiceName}) failed.");
		&T38lib::Common::notifyMe("[installServicePack]: return value = $depServices[0]");
		&T38lib::Common::notifyMe("[installServicePack] ** ERROR **");
		&T38lib::Common::errorTrap();
	}
	elsif ( $depServices[0] eq "zero" ) {
		&T38lib::Common::notifyMe("[installServicePack]: No dependent services found for $gConfigValues{SQLServiceName}");
	}
	else {
		foreach $serviceName (@depServices) {
			if ( &T38lib::Common::stopService($serviceName) ) {
				&T38lib::Common::notifyMe("[installServicePack]: $serviceName STOPPED");
			}
			else {
				&T38lib::Common::notifyMe("[installServicePack]: $serviceName NOT STOPPED");
			}
		}
	}
	
	# Stop the SQL Server

	if ( &T38lib::Common::stopService($gConfigValues{SQLServiceName}) ) {
		&T38lib::Common::notifyMe("[installServicePack]: $gConfigValues{SQLServiceName} STOPPED");
	}
	else {
		&T38lib::Common::notifyMe("[installServicePack]: $gConfigValues{SQLServiceName} NOT STOPPED");
		&T38lib::Common::errorTrap();
	}

	# Insatall the Service Pack

	$cmd = "$gConfigValues{SPDirectory}\\x86\\setup\\setupsql.exe";

	unless (-s $cmd)  {
		&T38lib::Common::notifyMe ("[installSservicePack] Mapping a net work drive to $gConfigValues{SQLSourceBox} share $gConfigValues{SQLShare}");
		$gmapDrive = &mapNetworkDrive("$gConfigValues{SQLSourceBox}","$gConfigValues{SQLShare}") unless ( defined($gmapDrive));
	 	$gConfigValues{SPDirectory} =~ s/^([a-zA-Z]:)/$gmapDrive/;
		$cmd = "$gConfigValues{SPDirectory}\\x86\\setup\\setupsql.exe";
	}

	unless (-s $cmd)  {
		&T38lib::Common::notifyMe ("[installSservicePack] ** ERROR ** Can not find file $cmd");
		&T38lib::Common::errorTrap();
	}					

	unless (-s "$gscriptPath\\INSTALLWRK\\setupsp.iss")  {
		&T38lib::Common::notifyMe ("[installSservicePack] ** ERROR ** Can not find file $gscriptPath\\INSTALLWRK\\setupsp.iss");
		&T38lib::Common::errorTrap();
	}					

	$cmd = $cmd . " -s -m -SMS -f1 $gscriptPath\\INSTALLWRK\\setupsp.iss";

	&T38lib::Common::notifyMe("[installServicePack] installation of Service pack started");
	$rtn = system("cmd /C start /wait $cmd");
	&T38lib::Common::notifyMe("[installServicePack] installation of Service pack finished");

	&T38lib::Common::notifyMe("[installServicePack] $cmd");
	&T38lib::Common::notifyMe("[installSservicePack] return code of the command = $rtn");

	if ( $rtn == 0 ) {
		&T38lib::Common::notifyMe("[installServicePack]: Service pack install is successful");

		if ( &T38lib::Common::startService($gConfigValues{SQLServiceName}) ) {
			&T38lib::Common::notifyMe("[installServicePack]: $gConfigValues{SQLServiceName} STARTED");
		}
		else {
			&T38lib::Common::notifyMe("[installServicePack]: $gConfigValues{SQLServiceName} NOT STARTED");
			&T38lib::Common::errorTrap();
		}

		if ( $depServices[0] = "zero" ) {
			&T38lib::Common::notifyMe("[installServicePack]: No dependent services found for $gConfigValues{SQLServiceName}");
		}
		else {
			foreach $serviceName (@depServices) {
				if ( &T38lib::Common::startService($serviceName) ) {
					&T38lib::Common::notifyMe("[installServicePack]: $serviceName STARTED");
				}
				else {
					&T38lib::Common::notifyMe("[installServicePack]: $serviceName NOT STARTED");
				}
			}
		}
	}
	else {
		&T38lib::Common::notifyMe("[installServicePack]: Service pack install FAILED");
		&T38lib::Common::errorTrap();
	}

	&T38lib::Common::notifyMe("[installServicePack] DONE - Check and install Service pack");

} # end sub installServicePack

#------------------------------------------------------------------------------
# Purpose: Build share points
#------------------------------------------------------------------------------
sub buildSharePoints() {

	use Win32::NetResource;

	my ($shareInfo, $tmp, $parm, $result, $key, $value);

	&T38lib::Common::notifyMe("[buildSharePoint] START - Build Share points");

	# Delete share points, Just to make sure that these share point are not there.
	# if they are there, delete them
	while (($key,$value) = each(%gConfigValues))
	{
		if ( $key =~ /__SharePoint/ ) {
			Win32::NetResource::NetShareDel($value);
		}
	}

##
	$tmp = "$gConfigValues{DumpDevicesDrive}";
	$tmp = $tmp . ":";
	$tmp = $tmp . "$gConfigValues{shareDumpDevicesPath}";

	$shareInfo = {
		'path' => "$tmp",
		'netname' => "$gConfigValues{__SharePointDumpDevicesPath}",
		'remark' => "Shared by $gscriptName",
	};

	if ( Win32::NetResource::NetShareAdd($shareInfo, $parm) ) {
		&T38lib::Common::notifyMe("[buildSharePoint] Successfully created shared $gConfigValues{__SharePointDumpDevicesPath}");
	} 
	else {
		&T38lib::Common::notifyMe("[buildSharePoint] ** ERROR ** shared $gConfigValues{__SharePointDumpDevicesPath}");
	}
##

	$tmp = "$gConfigValues{MdfDrive}";
	$tmp = $tmp . ":";
	$tmp = $tmp . "$gConfigValues{shareMdfPath}";

	$shareInfo = {
		'path' => "$tmp",
		'netname' => "$gConfigValues{__SharePointMdfPath}",
		'remark' => "Shared by $gscriptName",
	};

	if ( Win32::NetResource::NetShareAdd($shareInfo, $parm) ) {
		&T38lib::Common::notifyMe("[buildSharePoint] Successfully created shared $gConfigValues{__SharePointMdfPath} ");
	} 
	else {
		&T38lib::Common::notifyMe("[buildSharePoint] ** ERROR ** shared $gConfigValues{__SharePointMdfPath}");
	}
##

	$tmp = "$gConfigValues{NdfDrive}";
	$tmp = $tmp . ":";
	$tmp = $tmp . "$gConfigValues{shareNdfPath}";

	$shareInfo = {
		'path' => "$tmp",
		'netname' => "$gConfigValues{__SharePointNdfPath}",
		'remark' => "Shared by $gscriptName",
	};

	if ( Win32::NetResource::NetShareAdd($shareInfo, $parm) ) {
		&T38lib::Common::notifyMe("[buildSharePoint] Successfully created shared $gConfigValues{__SharePointNdfPath}");
	} 
	else {
		&T38lib::Common::notifyMe("[buildSharePoint] ** ERROR ** shared $gConfigValues{__SharePointNdfPath}");
	}
##

	$tmp = "$gConfigValues{LdfDrive}";
	$tmp = $tmp . ":";
	$tmp = $tmp . "$gConfigValues{shareLdfPath}";

	$shareInfo = {
		'path' => "$tmp",
		'netname' => "$gConfigValues{__SharePointLdfPath}",
		'remark' => "Shared by $gscriptName",
	};

	if ( Win32::NetResource::NetShareAdd($shareInfo, $parm) ) {
		&T38lib::Common::notifyMe("[buildSharePoint] Successfully created shared $gConfigValues{__SharePointLdfPath}");
	} 
	else {
		&T38lib::Common::notifyMe("[buildSharePoint] ** ERROR ** shared $gConfigValues{__SharePointLdfPath}");
	}
##

	$tmp = "$gConfigValues{TrcDrive}";
	$tmp = $tmp . ":";
	$tmp = $tmp . "$gConfigValues{shareTrcPath}";

	$shareInfo = {
		'path' => "$tmp",
		'netname' => "$gConfigValues{__SharePointTrcPath}",
		'remark' => "Shared by $gscriptName",
	};

	if ( Win32::NetResource::NetShareAdd($shareInfo, $parm) ) {
		&T38lib::Common::notifyMe("[buildSharePoint] Successfully created shared $gConfigValues{__SharePointTrcPath}");
	} 
	else {
		&T38lib::Common::notifyMe("[buildSharePoint] ** ERROR ** shared $gConfigValues{__SharePointTrcPath}");
	}
##

	$tmp = "$gConfigValues{TmpDrive}";
	$tmp = $tmp . ":";
	$tmp = $tmp . "$gConfigValues{shareTmpPath}";

	$shareInfo = {
		'path' => "$tmp",
		'netname' => "$gConfigValues{__SharePointTmpPath}",
		'remark' => "Shared by $gscriptName",
	};

	if ( Win32::NetResource::NetShareAdd($shareInfo, $parm) ) {
		&T38lib::Common::notifyMe("[buildSharePoint] Successfully created shared $gConfigValues{__SharePointTmpPath}");
	} 
	else {
		&T38lib::Common::notifyMe("[buildSharePoint] ** ERROR ** shared $gConfigValues{__SharePointTmpPath}");
	}
##

	$tmp = "$gConfigValues{SQLDataRootDrive}";
	$tmp = $tmp . ":";
	$tmp = $tmp . "$gConfigValues{shareSQLDataRootPath}";

	$shareInfo = {
		'path' => "$tmp",
		'netname' => "$gConfigValues{__SharePointSQLDataRootPath}",
		'remark' => "Shared by $gscriptName",
	};

	if ( Win32::NetResource::NetShareAdd($shareInfo, $parm) ) {
		&T38lib::Common::notifyMe("[buildSharePoint] Successfully created shared $gConfigValues{__SharePointSQLDataRootPath}");
	} 
	else {
		&T38lib::Common::notifyMe("[buildSharePoint] ** ERROR ** shared $gConfigValues{__SharePointSQLDataRootPath}");
	}
##

	$tmp = "$gConfigValues{DBAUtilsDrive}";
	$tmp = $tmp . ":";
	$tmp = $tmp . "$gConfigValues{shareDBAUtilsPath}";

	$shareInfo = {
		'path' => "$tmp",
		'netname' => "$gConfigValues{__SharePointDBAUtilsPath}",
		'remark' => "Shared by $gscriptName",
	};

	if ( Win32::NetResource::NetShareAdd($shareInfo, $parm) ) {
		&T38lib::Common::notifyMe("[buildSharePoint] Successfully created shared $gConfigValues{__SharePointDBAUtilsPath}");
	} 
	else {
		&T38lib::Common::notifyMe("[buildSharePoint] ** ERROR ** shared $gConfigValues{__SharePointDBAUtilsPath}");
	}
##

	$tmp = "$gConfigValues{SQLAppDrive}";
	$tmp = $tmp . ":";
	$tmp = $tmp . "$gConfigValues{shareSQLAppPath}";

	$shareInfo = {
		'path' => "$tmp",
		'netname' => "$gConfigValues{__SharePointSQLAppPath}",
		'remark' => "Shared by $gscriptName",
	};

	if ( Win32::NetResource::NetShareAdd($shareInfo, $parm) ) {
		&T38lib::Common::notifyMe("[buildSharePoint] Successfully created shared $gConfigValues{__SharePointSQLAppPath}");
	} 
	else {
		&T38lib::Common::notifyMe("[buildSharePoint] ** ERROR ** shared $gConfigValues{__SharePointSQLAppPath}");
	}
##

## Grant Permission to all the share points
#
	while (($key,$value) = each(%gConfigValues))
	{
		if ( $key =~ /__SharePoint/ ) {
			$tmp = "rmtshare ";
			$tmp = $tmp . "\\\\";
			$tmp = $tmp . "$gServerName";
			$tmp = $tmp . "\\";
			$tmp = $tmp . "$value";
			$tmp = $tmp . " /UNLIMITED";
			$tmp = $tmp . " /GRANT";
			$tmp = $tmp . " Administrators:f";
		
			&T38lib::Common::notifyMe("[buildSharePoint] Grant permission to share point $value");
			$result = system("cmd /C $tmp");
			if ( $result != 0 ) {
				&T38lib::Common::notifyMe("[buildSharePoint] ** ERROR ** Can not grant permission to $value");
			}
		}
	}
	&T38lib::Common::notifyMe("[buildSharePoint] DONE - Build Share points");

} # end sub buildSharePoint

#------------------------------------------------------------------------------
# Purpose: Change sa password after the install of SQL Server
#------------------------------------------------------------------------------
sub changeSAPassword() {

	my ($tmp, $result);
	my ($passwordFileName, $serverFileName, $progFileName) = ("install\\password.txt", "installwrk\\server.txt", "install\\t38pwchgv8.exe");

	&T38lib::Common::notifyMe("[changeSAPassword] START - Change sa Password");

	unless (-s $progFileName) {
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** Cannot find file $progFileName"); 
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** SA Password is not changed."); 
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** Change SA password manually"); 
		return;
	}

	unless (-s $passwordFileName) {
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** Cannot find file $passwordFileName"); 
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** SA Password is not changed."); 
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** Change SA password manually"); 
		return;
	}

	unless (open(SERVER,"> $serverFileName")) {
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** Cannot open file $serverFileName for writing."); 
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** SA Password is not changed."); 
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** Change SA password manually"); 
		return;
	}

	$tmp = $gServerName;

	if ( $gConfigValues{SQLInstanceName}) {
		$tmp = $tmp . "\\";
		$tmp = $tmp . $gConfigValues{SQLInstanceName};
	}

	$tmp = $tmp . " $gConfigValues{EnvironmentType} $gConfigValues{EnvironmentType}  ** Changed using $gscriptName";
	print SERVER "$tmp\n";

	close(SERVER);

	unless (-e $serverFileName) {
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** Cannot find file $serverFileName"); 
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** SA Password is not changed."); 
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** Change SA password manually"); 
		return;
	}

	$tmp = $progFileName;
	$tmp = $tmp . " -f ";
	$tmp = $tmp . "$passwordFileName";
	$tmp = $tmp . " -s ";
	$tmp = $tmp . "$serverFileName";

	&T38lib::Common::notifyMe("[changeSAPassword] $tmp"); 

	$result = system("cmd /C $tmp");
	if ( $result != 0 ) {
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** $tmp failed"); 
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** SA Password is not changed."); 
		&T38lib::Common::notifyMe("[changeSAPassword] ** ERROR ** Change SA password manually"); 
	}

	&T38lib::Common::notifyMe("[changeSAPassword] DONE - Change sa Password");

} # end sub chageSAPassword

#------------------------------------------------------------------------------
# Purpose: Build Master
#------------------------------------------------------------------------------
sub buildMaster() {

	&T38lib::Common::notifyMe("[buildMaster] START - Build Master Database");

	my $master	= "$gscriptPath\\INSTALLWRK\\master";

	system("del $master.old") if (-s "$master.old");
	system("rename $master.sql master.old") if (-s "$master.sql");

	unless (open(MASTER, ">$master.sql")) { 
		&T38lib::Common::notifyMe("[buildMaster]  ** ERROR ** Cannot open file $master.sql for writing. $!"); 
		&T38lib::Common::errorTrap();
	}

print MASTER <<"EOT";

/*********************************************************************************/
/* MASTER DATABASE CREATE SCRIPT:                                                */
/* SQL Server "master" DATABASE                                                  */
/* BEST BUY CO, INC.                                                             */
/*-------------------------------------------------------------------------------*/
/* This file is created by $0, $gPgmRevision */

/*********************************************************************************/

set QUOTED_IDENTIFIER off
go

/* Check for correct version of the SQL Server */
if (select \@\@version) not like '%Microsoft SQL Server  2000%'
begin
	RAISERROR("This script is for Microsoft SQL Server  2000", 10, 127) with log
end
GO

PRINT ''
PRINT ''
PRINT '<<<< master >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
PRINT ''

USE master
GO

if (not exists (select 1 from sysdevices where name = 'master_db_bkp'))
	EXEC sp_addumpdevice 'disk', 'master_db_bkp', '$gConfigValues{DumpDevicesDrive}:$gConfigValues{DumpDevicesPath}\\master_db.bkp', 2
GO

if (not exists (select 1 from sysdevices where name = 'master_log_bkp'))
EXEC sp_T38CRBKP \@dbname = 'master', \@bkptype = 'log'
GO

EOT

	if (defined($SystemDb{'master'})) {
		my $dbName		= 'master';
		my $dataName	= 'master';
		my $logName		= 'mastlog';
		my $dataSize	= $SystemDb{$dbName}{'DataSize'};
		my $logSize		= $SystemDb{$dbName}{'LogSize'};
		my $dataBackup	= $SystemDb{$dbName}{'dataBackup'};
		my $logBackup	= $SystemDb{$dbName}{'LogBackup'};
		my $truncLog	= $SystemDb{$dbName}{'TruncLog'};
		my $selectInto	= $SystemDb{$dbName}{'SelectInto'};
		my $backupPath	= ($gConfigValues{DumpDevicesDrive}) ?
					"$gConfigValues{DumpDevicesDrive}:$gConfigValues{DumpDevicesPath}\\$dataBackup.bkp" :
					"\\\\$gConfigValues{DumpDevicesSrvr}$gConfigValues{DumpDevicesPath}\\$dataBackup";

print MASTER <<"EOT";

exec ("use $dbName exec sp_T38ALTERDB \@filename = $dataName, \@filesize = $dataSize, \@filetype = 'D'")
exec ("use $dbName exec sp_T38ALTERDB \@filename = $logName, \@filesize = $logSize, \@filetype = 'L'")


ALTER DATABASE $dbName
MODIFY FILE
	(NAME = $dataName,
	FILEGROWTH = 10MB)
GO

ALTER DATABASE $dbName
MODIFY FILE
	(NAME = $logName,
	FILEGROWTH = 10MB)
GO

EOT
	} ####################### if (defined($SystemDb{'master'}) #######################


	if (defined($SystemDb{'msdb'})) {
		my $dbName		= 'msdb';
		my $dataName	= 'MSDBData';
		my $logName		= 'MSDBLog';
		my $dataSize	= $SystemDb{$dbName}{'DataSize'};
		my $logSize		= $SystemDb{$dbName}{'LogSize'};
		my $dataBackup	= $SystemDb{$dbName}{'DataBackup'};
		my $logBackup	= $SystemDb{$dbName}{'LogBackup'};
		my $truncLog	= $SystemDb{$dbName}{'TruncLog'};
		my $selectInto	= $SystemDb{$dbName}{'SelectInto'};
		my $backupPath	= ($gConfigValues{DumpDevicesDrive})?
					"$gConfigValues{DumpDevicesDrive}:$gConfigValues{DumpDevicesPath}\\$dataBackup.bkp" :
					"\\\\$gConfigValues{DumpDevicesSrvr}$gConfigValues{DumpDevicesPath}\\$dataBackup.$gServerName.bkp";

		print MASTER <<"EOT";

exec ("use $dbName exec sp_T38ALTERDB \@filename = $dataName, \@filesize = $dataSize, \@filetype = 'D'")
exec ("use $dbName exec sp_T38ALTERDB \@filename = $logName, \@filesize = $logSize, \@filetype = 'L'")

if (not exists (select 1 from sysdevices where name = 'msdb_db_bkp'))
EXEC sp_T38CRBKP \@dbname = 'msdb', \@bkptype = 'db'
GO

if (not exists (select 1 from sysdevices where name = 'msdb_log_bkp'))
EXEC sp_T38CRBKP \@dbname = 'msdb', \@bkptype = 'log'
GO

ALTER DATABASE $dbName
MODIFY FILE
	(NAME = $dataName,
	FILEGROWTH = 10MB)
GO

ALTER DATABASE $dbName
MODIFY FILE
	(NAME = $logName,
	FILEGROWTH = 10MB)
GO



EOT
	} ####################### if (defined($SystemDb{'msdb'}) #######################

	if (defined($SystemDb{'tempdb'})) {
		my $dbName		= 'tempdb';
		my $dataName	= 'tempdev';
		my $logName		= 'templog';
		my $dataSize	= $SystemDb{$dbName}{'DataSize'};
		my $logSize		= $SystemDb{$dbName}{'LogSize'};
		my $truncLog	= $SystemDb{$dbName}{'TruncLog'};
		my $selectInto	= $SystemDb{$dbName}{'SelectInto'};

		print MASTER <<"EOT";

use $dbName
GO

exec ("use $dbName exec sp_T38ALTERDB \@filename = $dataName, \@filesize = $dataSize, \@filetype = 'D'")
exec ("use $dbName exec sp_T38ALTERDB \@filename = $logName, \@filesize = $logSize, \@filetype = 'L'")

CHECKPOINT
GO

ALTER DATABASE $dbName
MODIFY FILE
	(NAME = $dataName,
	FILEGROWTH = 32MB)
GO

ALTER DATABASE $dbName
MODIFY FILE
	(NAME = $logName,
	FILEGROWTH = 32MB)
GO


EOT
	} ####################### if (defined($SystemDb{'tempdb'}) #######################

	print MASTER <<"EOT";

use master
GO

/* Set all of the system parameters (Optimize the database) */
PRINT ''
PRINT 'Turn Advanced Server Options On'
go
EXEC sp_configure 'show advanced options', 1
go
reconfigure
go

PRINT ''
PRINT 'Configuring $gConfigValues{SQLMemory} megabytes of minimum server memory'
go
EXEC sp_configure 'min server memory', $gConfigValues{SQLMemory}
go
PRINT ''
PRINT 'Optimizing the database ...'
PRINT ''
EXEC sp_configure 'remote access', 1
go
reconfigure
go


PRINT ''
PRINT 'Dumping database master to master_db_bkp'
BACKUP DATABASE master TO master_db_bkp with init
GO

PRINT ''
PRINT 'MASTER DATABASE SCRIPT COMPLETE'
PRINT ''
GO
EOT
	close (MASTER);

	&T38lib::Common::notifyMe("[buildMaster] DONE - Build Master Database");

} # end sub buildMaster

#------------------------------------------------------------------------------
# Purpose: Build UserDB
#------------------------------------------------------------------------------
sub buildUserDb() {

	my $dbcrsz	= "$gscriptPath\\INSTALLWRK\\dbcrszbase";
	my $dbcrszbase	= "dbcrsz";
	my ($dbcid,$dbid,$mdfpath,$ndfpath,$ldfpath);
	my ($szdb,$szlog,$phydmp,$Name,$truncLog,$selectInto);


	&T38lib::Common::notifyMe("[buildUserDb] START - Build user Database");
	
	system("del $dbcrsz.old") if (-s "$dbcrsz.old");
	system("rename $dbcrsz.sql $dbcrszbase.old") if (-s "$dbcrsz.sql");

	unless (open(DBCRSZ,">$dbcrsz.sql")) { 
		&T38lib::Common::notifyMe("[buildUserDb] ** ERROR ** Cannot open file $dbcrsz.sql for writing. $!"); 
		&T38lib::Common::errorTrap();
	}

print DBCRSZ <<"EOT";
/*********************************************************************************/
/* CREATE USER DATABASES SCRIPT:  $dbcrsz.sql                                     */
/* BEST BUY CO, INC.                                                             */
/*-------------------------------------------------------------------------------*/
/* This file is created by $0, $gPgmRevision */
EOT

	foreach $Name (sort keys %UserDb ) 
	{
		$dbcid=substr($Name,0,3);
		$dbcid =~ tr/A-Z/a-z/;		# make the dbcid string all lower case
		$dbid=substr($Name,-1,1);
		$mdfpath="$gConfigValues{MdfDrive}:$gConfigValues{MdfPath}\\";
		$ndfpath="$gConfigValues{NdfDrive}:$gConfigValues{NdfPath}\\";
		$ldfpath="$gConfigValues{LdfDrive}:$gConfigValues{LdfPath}\\";
		$szdb=$UserDb{$Name}{'DataSize'};
		$szlog=$UserDb{$Name}{'LogSize'};
		$phydmp="$gConfigValues{DumpDevicesDrive}:$gConfigValues{DumpDevicesPath}\\";
		$truncLog=$UserDb{$Name}{'TruncLog'};
		$selectInto=$UserDb{$Name}{'SelectInto'};


		$truncLog	= 
			($truncLog eq "\$none") ?
				$truncLog:
			($truncLog == 1) ?
				"true" :
				"false";
		$selectInto	= 
			($selectInto eq "\$none") ?
				$selectInto:
			($selectInto == 1) ?
				"true" :
				"false";


print DBCRSZ "use master\n";
print DBCRSZ "GO\n";

print DBCRSZ "print ''\n";
print DBCRSZ "print 'SA is creating database for $Name.  This will take awhile...'\n";
print DBCRSZ "GO\n";

print DBCRSZ "EXEC sp_T38CRDB\n";
print DBCRSZ "	\@dbcid='$dbcid',\n";
print DBCRSZ "	\@dbid=$dbid,\n";
print DBCRSZ "	\@mdfpath='$mdfpath',\n"; 
print DBCRSZ "	\@ndfpath='$ndfpath',\n"; 
print DBCRSZ "	\@ldfpath='$ldfpath',\n"; 
print DBCRSZ "	\@szdb=$szdb,\n"; 
print DBCRSZ "	\@szlog=$szlog,\n"; 
print DBCRSZ "	\@phydmp='$phydmp',\n";
print DBCRSZ "  \@backupsets = 1\n";
print DBCRSZ "GO\n";

print DBCRSZ "print ''\n";
if ($truncLog ne "\$none") {
	print DBCRSZ "print 'Changing the logger options for $Name databases.'\n";
	print DBCRSZ "GO\n";

	print DBCRSZ "EXEC sp_dboption $Name, 'trunc. log on chkpt.', $truncLog\n";
	print DBCRSZ "GO\n";
}

if ($selectInto ne "\$none") {
	print DBCRSZ "print 'Changing the bulkcopy options for $Name databases.'\n";
	print DBCRSZ "GO\n";
	print DBCRSZ "EXEC sp_dboption $Name, 'select into/bulkcopy', $selectInto\n";
	print DBCRSZ "GO\n";
}

print DBCRSZ "USE $Name\n";
print DBCRSZ "GO\n";

print DBCRSZ "CHECKPOINT\n";
print DBCRSZ "GO\n";

	} # end of foreach loop

close (DBCRSZ);

	&T38lib::Common::notifyMe("[buildUserDb] DONE - Build user Database");

} # end sub buildUserDb

#------------------------------------------------------------------------------
# Purpose: Copy Maintenance scripts to destination directory.
#------------------------------------------------------------------------------
sub moveSQLScripts() {

	my $cmd;

	&T38lib::Common::notifyMe("[moveSQLScripts] START - copy scripts");

	$cmd = "cmd /C xcopy /Y ";
	$cmd = $cmd . "$gscriptPath\\T38APP80\\*.* ";
	$cmd = $cmd . "$gConfigValues{DBAUtilsDrive}:";
	$cmd = $cmd . "$gConfigValues{DBAUtilsPath}\\";

	&T38lib::Common::notifyMe("[moveSQLScripts] $cmd");

	# Copy files to install directory

	if (system($cmd) != 0) { 
		&T38lib::Common::notifyMe("[moveSQLScripts] copy maintenance scripts.");
	}

	&T38lib::Common::notifyMe("[moveSQLScripts] DONE - copy scripts");

} # end sub move SQLScripts

#------------------------------------------------------------------------------
# Purpose: Map a network drive using the net use command.
# 
#	Input Arguments:	$server, $share
#	Return:				mapped network drive letter
#------------------------------------------------------------------------------
sub mapNetworkDrive($$) {
	my($server, $share) = @_;

	my ($mapDrive, $netUse); 

	$netUse = `net use \* \\\\${server}\\${share} /PERSISTENT:NO`;
	if ($netUse =~ /:/) {
		$mapDrive = substr($netUse, index($netUse, ":")-1, 2);
	}
	else {
		&T38lib::Common::notifyMe("[mapNetworkDrive] ** ERROR ** Unable to map a network drive for server $server, share $share"); 
		&T38lib::Common::errorTrap();
	}

	return $mapDrive;

} # end sub mapNetworkDrive

#------------------------------------------------------------------------------
# Purpose: Disconnect a network drive
#
#	Input Arguments:	$drive
#	Return:				1 succseeded, 0 fail
#------------------------------------------------------------------------------
sub disconnectNetworkDrive($) {
	my($driveLetter) = shift;

	use Win32API::File qw( :ALL);

		if ( GetDriveType($driveLetter) == 4 ) {
			`net use $driveLetter /delete`;
			return 1;
		}
	return 0;

} # end sub disconnectNetworkDrive

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
	&T38lib::Common::notifyMe("[mkdir] ** ERROR ** try to create $string directory failed.") unless ( -d $string);

} # end sub mkdir

__END__

=pod

=head1 NAME

T38instl80.pl - Install Microsoft SQL 2000 and setup the SQL Server

=head1 SYNOPSIS

perl T38instl80.pl {T38dba.cfg}

=head2 OPTIONS

I<T38instl80.pl> accepts the following options:

=over 4

=item [OPTION]

DESCRIPTION OF THE OPTION

=item -h 		(Optional)

Print out a short help message, then exit.

=item *.cfg 	(Required)

Configuration file where the program read it initial parameters


=back

=head1 DESCRIPTION


=head1 EXAMPLE

perl T38instl80.pl T38dba.cfg

Run the install program using T38dba.cfg file for input parameters.

=head1 COMPILE OPTION

=over 4

=item perl -S PerlApp.pl -f -s T38instl80.pl -e T38instl80.exe -c -v

=item using perl 5.005_03, ActivePerl Build 522

=back

=head1 BUGS

I<T38instl80.pl> has no known bugs.

=head1 REVISION HISTORY

$Revision: 1.1 $

=head1 AUTHOR

Asif Kaleem, asif.kaleem@bestbuy.com

=head1 SEE ALSO

Common.pm
Getopt::Std
File::Basename
Cwd
File::Path

=head1 COPYRIGHT and LICENSE

This program is copyright by BestBuy Inc.

=cut
