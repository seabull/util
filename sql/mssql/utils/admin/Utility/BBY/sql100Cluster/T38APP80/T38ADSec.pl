#!perl

# PVCS header information
# $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38ADSec.pv_  $
# $Author: A645276 $
# $Date: 2011/02/08 17:12:19 $
# $Revision: 1.1 $
#
#* Purpose: NA Security
#*
#* Summary:
#*   1. Get SQL resource names from Active directory and assign map it to SQL group
#*
#* Program must be executed from within the directory it is located.
#*
#* SYNOPSIS
#* T38ADSec.pl -c cfgfile and -S server name or -h
#*
#* Command line:
#*
#* -c configration file name (required)
#* -S	server, optional server name (optional)
#* -p Process request for admin accounts (SA or DC) (optional)
#* -h  Writes help screen on standard output, then exits (optional)
#*
#* Example: 
#*   1. Run T38ADSec.pl using T38ADSec.cfg as a configuration file on local server.
#*      perl T38ADSec.pl -c T38ADSec.cfg
#*		
#*   2. Show the help screen and quit.
#*      perl T38ADSec.pl -h
#*	
#*   3. Run T38ADSec.pl using T38ADSec.cfg as a configuration file on given server name. 
#*      perl T38ADSec.pl -c T38ADSec.cfg -S ServerName 
#*	
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
use T38lib::t38cfgfile;
use T38lib::bbyado qw(:BBYADO_SUBS :BBYADO_VARS);

#------------------------------------------------------------------------------------------
# Function declaration in alphabetical order
#------------------------------------------------------------------------------------------
sub mainControl();
sub processRes($$$$$$$$);
sub chkNaResFields($$$$$$$);
sub showHelp();
sub AddAcct2Role($$$$);
sub processDO($$$$$$$$);
sub processDL($$$$$$$$);
sub processDW($$$$$$$$);
sub processDR($$$$$$$$);
sub processSU($$$$$$$$);
sub processFixedSrvRole($$$$$$$$);
sub initFromCFGFile();
sub processIns($$);

#------------------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------------------
my ($gprocessSA) = 0;					# 0 mean DO NOT process SA accounts
my ($gserverName,$gscript, $gdomainName, $gconfigFile, $exitStatus);
my ($glogFileName, $gnetSrvr, $gInstName) = ("","","");

my ($gscriptSuffix,$gscriptName) = ("","");	# Base name of the current script.
my ($gscriptPath) = ".\\";		        			# Directory path to current script.

# SA => Admin  (Sa rights)
# DC => Database Creator
#
# DO => DBO
# DW => Data Writer (RW)
# DR => Data Reader (RO)
# DL => Run all DDL (DL) DDL Admin

# Set from cfg file
my ($gadPath, $gsqlType, $gfilterDB);
my (%gvalidAccessType,%gsqlRole, %gCFGResourceName);
my ($gcompandsrvrName, $gcompanyName, $gsecurityGrpLoc );
my $genvironmentType	= '';

my ($gT38ERROR) = $T38lib::Common::T38ERROR;			
my ($gisql) = "osql -E -h-1 -n -w2048"; 

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
# 												***  SUBROUTINES ***
#------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------
#	Purpose:  Main driver of the program
#
#	Input Argument:  None
#	Output:  0 OK, 1 Failed
#------------------------------------------------------------------------------------------
sub mainControl() {

	my ($mainStatus,$ADResFound) = (0,0);
	my ($numArchive) = 3;
	my ($logStr) = $0;
	my ($cmdSrvrName) = ("");
	my ($sql) = ("");
	my ($comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted);
	my ($j,$adCfgPath, $conStr);
	my (@ADResources, @allDC, @DCName);
	my ($preWin2000); 
	my ($ADHandle, $i);
	my ($aref, $nvals, $tmp, $dbRole, $loginName);

	#------------------------------------------------------------------------------------------
	# Get the script path, name and suffix
	#------------------------------------------------------------------------------------------
	($gscriptPath, $gscriptName, $gscriptSuffix) = &T38lib::Common::parseProgramName();

	
	#------------------------------------------------------------------------------------------
	# check the command line arguments
	#------------------------------------------------------------------------------------------
	getopts('hpS:c:');

	#------------------------------------------------------------------------------------------
	# If -h command line option is given show help message
	#------------------------------------------------------------------------------------------
	if ($Getopt::Std::opt_h) {
		&showHelp();
		exit($mainStatus);	
	}

	BLOCK: {	# START OF BLOCK 

		unless (&T38lib::Common::setLogFileDir("${gscriptPath}\\T38LOG")) {
			&T38lib::Common::errme("Can not set up the log file directory.");
			$mainStatus = 1;
			last BLOCK;
		}

		#------------------------------------------------------------------------------------------
		# Archive the log file.  Keep last three run archive.
		#------------------------------------------------------------------------------------------
		&T38lib::Common::archiveLogFile($numArchive);

		&T38lib::Common::notifyWSub("SUB STARTED");

		if ($Getopt::Std::opt_c) {
			$gconfigFile = $Getopt::Std::opt_c;
			$logStr = $logStr . " -c $gconfigFile";
			if ( (&T38lib::t38cfgfile::readConfigFile($gconfigFile)) == 0 ) {
				&T38lib::Common::errme("Can not read cfg file: $gconfigFile");
				$mainStatus = 1;
				last BLOCK;
			}

			unless (&initFromCFGFile()) {
				&T38lib::Common::errme("Can not validate parameter in cfg file: $gconfigFile");
				$mainStatus = 1;
				last BLOCK;
			}
		}
		else {
			&T38lib::Common::errme("Command line argument -c CFGFILENAME missing");
			$mainStatus = 1;
			last BLOCK;
		}
		
		# Uncomment the for testing.
		#my ($key, $value);
		#while (($key,$value) = each(%gvalidAccessType)) {
		#	print "key = $key  value = $value\n";
		#}

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

			$logStr = $logStr . " -S $gserverName";
			$gisql = $gisql . " -S $gserverName";
		}
		else {
			$gnetSrvr = $gserverName;
			$gisql = $gisql . " -S $gserverName";
		}

		if ($Getopt::Std::opt_p) {
			$gprocessSA = 1;
			$logStr = $logStr . " -p";
		}
		
		&T38lib::Common::notifyWSub("Command line: $logStr");
		#------------------------------------------------------------------------------------------
		# Get a connection handle to active directory.
		#------------------------------------------------------------------------------------------
		if ( ($ADHandle = &adConnect()) == 0 ) {
			&T38lib::Common::errme("Can not get a connection to Active Directory");
			$mainStatus = 1;
			last BLOCK;
		}
		
		#------------------------------------------------------------------------------------------
		# Get the domain name 
		#------------------------------------------------------------------------------------------
		@allDC = split("DC\=", $gadPath) ;

		# Build the Path so we can get domain name using select statement
		($adCfgPath = $gadPath) =~ s|[^/]+$||;
		$adCfgPath = $adCfgPath . "CN=$allDC[1]CN=Partitions,CN=Configuration,";
		$j = $#allDC - 1;
		while ($j <= $#allDC) {
			$adCfgPath = $adCfgPath . "DC=" . $allDC[$j];
			$j++;
		}
		($conStr = $allDC[1]) =~ s/,//g;
	
		# Build the select statement and execute to get the domain name
		$sql = "select nETBIOSName from " . "'" . $adCfgPath . "' Where nETBIOSName = '$conStr'" ;
		&T38lib::Common::notifyWSub("** Select statement to get the domain name **");
		&T38lib::Common::notifyWSub("$sql");
		execSQL2Arr($ADHandle, $sql, \@DCName);

		# Assign the domain name to the global variable
		$gdomainName = $DCName[0]{nETBIOSName};

		# Make sure that we have a domain name
		if (! defined($gdomainName) ) {
			&T38lib::Common::errme("Can not get Domain Name from LDAP path");
			&T38lib::Common::errme("LDAP path = $adCfgPath");
			$mainStatus = 1;
			last BLOCK;
		}
		
		#------------------------------------------------------------------------------------------
		# Run your SQL statements to select proper resouces from Active
		# Directory database.  Active directory path is read from CFG file
		# and used in this select statement.  Also handle to the Active 
		# directory is used to execute the SQL and store the results into 
		# an array.
		#
		# This select statement is selecting 2 colums Resource Name and
		# Resource short Name.
		#------------------------------------------------------------------------------------------
		if ( $gcompanyName =~ /\$\$servername/i ) {
			($gcompandsrvrName = $gcompanyName) =~ s/\$\$servername/-$gnetSrvr/;
			$gcompanyName =~ s/\$\$servername//;
		}

		$sql = "select name, sAMAccountName from '" . $gadPath;
		$sql = $sql . "' where name = '" . $gcompandsrvrName . "*'";
		$sql = $sql . " or name = '" . $gcompanyName . "-" . $gsecurityGrpLoc . "*'";
		if ($gsecurityGrpLoc ne $genvironmentType) {
			$sql = $sql . " or name = '" . $gcompanyName . "-" . $genvironmentType . "*'";
		}

		&T38lib::Common::notifyWSub("** Select statement to get Resources from Active Directory **");
		&T38lib::Common::notifyWSub("$sql");

		#------------------------------------------------------------------------------------------
		# Call the BBYADO library sub to execute the SQL and store the results
		# in an array
		#------------------------------------------------------------------------------------------
		execSQL2Arr($ADHandle, $sql, \@ADResources);

		$i=0;
		%gCFGResourceName = ();
		while ($i <= $#ADResources) {
			if ( $ADResources[$i]{name} =~ /^($gcompanyName)-($gnetSrvr|$gsecurityGrpLoc|$genvironmentType)-(\w+)-(.+)-($gsqlType)-(\w{2})$/ ) {
				($comCode, $grpType) = split (/\-/, $1);
				($srvName, $insName, $resName, $resType, $accGranted) = ($2, $3, $4, $5, $6);
				$preWin2000 = $ADResources[$i]{sAMAccountName};

				if ( $preWin2000 eq "") {
					&T38lib::Common::errme("Resource short is is not define for Resource: $ADResources[$i]{name}");
					&T38lib::Common::errme("Can NOT process the AD Resource");
					$i++;
					next;
				}

				# Grant System Role SA or DC  used by tripwire
				#
				# Check to see if the Active directory resource is also in CFG file with T38LIST
				# If there is one from cfg file then process it 
				# 
				# T38LIST:T38adsec_grant_sysrole:BBY-R-SQLCORP-A-Tripwire-SQL-SU=SA
				#
				$tmp = "T38LIST:T38adsec_grant_sysrole:" . $ADResources[$i]{name};
				if (defined($T38lib::t38cfgfile::gConfigValues{$tmp})) {
					%gCFGResourceName = ();
					$aref = $T38lib::t38cfgfile::gConfigValues{$tmp};
					$nvals = scalar @{$aref};
					for $j (0..$nvals-1) {
						$gCFGResourceName{$$aref[$j]} = $ADResources[$i]{name};
					}
					while (($dbRole,$loginName) = each(%gCFGResourceName)) {
						($comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) = split (/\-/, $loginName);
						$loginName   = $gdomainName . "\\" . $loginName; 

						if ( ($dbRole eq $gsqlRole{SA}) or ($dbRole eq $gsqlRole{DC}) ) {
							unless (&processFixedSrvRole($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $dbRole) ) {
								&T38lib::Common::notifyWSub("sub call to processFixedSrvRole failed");
								$mainStatus = 1;
								last BLOCK;
							}
						}
						else {
							&T38lib::Common::notifyWSub("Skipping resource for SA or DC from CFG file:$comCode-$grpType-$srvName-$insName-$resName-$resType-$accGranted");
						}
					}
				}
				
				# Grant Permission for TripWire
				# These lines for SQL 2005
				#
				# T38LIST:T38adsec_grant_perm:BBY-R-SQLCORP-A-Tripwire-SQL-SU=View Any Definition
				# T38LIST:T38adsec_grant_perm:BBY-R-SQLCORP-A-Tripwire-SQL-SU=Alter Trace
				#
				$tmp = "T38LIST:T38adsec_grant_perm:" . $ADResources[$i]{name};
				if (defined($T38lib::t38cfgfile::gConfigValues{$tmp})) {
					%gCFGResourceName = ();
					$aref = $T38lib::t38cfgfile::gConfigValues{$tmp};
					$nvals = scalar @{$aref};
					for $j (0..$nvals-1) {
						$gCFGResourceName{$$aref[$j]} = $ADResources[$i]{name};
					}
					unless (&processGrantPerm() ) {
						&T38lib::Common::notifyWSub("sub call to processGrantPerm failed");
						$mainStatus = 1;
						last BLOCK;
					}
				}

				# Grant db role to the provided database
				#
				# T38LIST:T38adsec_grant_dbrole:BBY-R-SQLCORP-A-Tripwire-SQL-SU=DR:MSDB
				#
				$tmp = "T38LIST:T38adsec_grant_dbrole:" . $ADResources[$i]{name};
				if (defined($T38lib::t38cfgfile::gConfigValues{$tmp})) {
					%gCFGResourceName = ();
					$aref = $T38lib::t38cfgfile::gConfigValues{$tmp};
					$nvals = scalar @{$aref};
					for $j (0..$nvals-1) {
						$gCFGResourceName{$$aref[$j]} = $ADResources[$i]{name};
					}
					unless (&processGrantDBRole() ) {
						&T38lib::Common::notifyWSub("sub call to processGrantDBRole failed");
						$mainStatus = 1;
						last BLOCK;
					}
				}

				if ( $ADResources[$i]{name} =~ /BBY-R-SQLCORP-A-Tripwire-SQL-SU/i ) {
					$i++;
					next;
				}

				
				&T38lib::Common::notifyWSub("Processing $comCode-$grpType-$srvName-$insName-$resName-$resType-$accGranted");
				$ADResFound = 1;

				unless (&processIns($cmdSrvrName, $insName) ) {
					&T38lib::Common::warnme("Skiping Resource Name: $comCode-$grpType-$srvName-$insName-$resName-$resType-$accGranted");
					$i++;
					next;
				}

				unless (&processRes($preWin2000, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted)) {
					&T38lib::Common::errme("Can not Process resources: $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted");
					$mainStatus = 1;
				}
			}
			$i++;
		}

		# No resources to process from Active Directory for the given server
		#
		if ( $ADResFound == 0 ) {
			&T38lib::Common::warnme("No Resource form Active Directory to process for server $gserverName");
		}

	} # END OF BLOCK 


	($mainStatus == 0 ) ? 
		&T38lib::Common::notifyWSub("Sub Status $mainStatus, OK"):
		&T38lib::Common::notifyWSub("Sub Status $mainStatus, FAILED");

	return ($mainStatus);

} # End of mainControl

#------------------------------------------------------------------------------------------
#	Purpose:  Process Instances properly
#
#	Input Argument: Command line server name and Intance name from AD resource
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub processIns($$) {
	my ($cmdSrvrName, $ADinsName) = @_;

	my ($subStatus) = 1;		# 1 = True, Every thing is OK, 0 means failed
	my ($netSrvr, $InstName);

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {

		# if no server name is given in the command line
		# Process A (All) and D (Default) 
		if ( $cmdSrvrName eq "")  {
			if ( ($ADinsName eq "A") or ($ADinsName eq "D") ) {
				last BLOCK;
			}
			else {
				$subStatus = 0;
				last BLOCK;
			}
		}

		# Command line has a server name
		# Check to see if we have an instance with the server name
		($netSrvr, $InstName)	=	split("\\\\", $gserverName); 
		$InstName =  &T38lib::Common::stripWhitespace($InstName);

		# If we have a server name in the command line,  but no instance name
		# Then process A (All) and D (default) 
		if ($InstName eq "") {
			if ( ($ADinsName eq "A") or ($ADinsName eq "D") ) {
				last BLOCK;
			}
			else {
				$subStatus = 0;
				last BLOCK;
			}
		}
	
		# We have an instance name given in the command line
		# Process the given instance Name and A (All)
		if ( ($InstName eq $ADinsName) or ($ADinsName eq "A") ) {
			last BLOCK;
		}
		else {
			$subStatus = 0;
			last BLOCK;
		}
		
	} # End of BLOCK

	($subStatus == 1 ) ? 
		&T38lib::Common::notifyWSub("Sub Status $subStatus, OK"):
		&T38lib::Common::notifyWSub("Sub Status $subStatus, FAILED");

	return ($subStatus);
}

#------------------------------------------------------------------------------------------
#	Purpose:  Process the NA resource name and call other function get the 
#				 permission granted at SQL leverl
#
#	Input Argument: Company Code, Group Type, Server Name, Instance Name
#	                Resource Name, Resource Type, Access Type
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub processRes($$$$$$$$) {
	my ($preWin2000, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) = @_;

	my ($subStatus) = 1;		# 1 = True, Every thing is OK, 0 means failed
	my ($loginName) = ("");

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {
	
		unless ( &chkNaResFields($comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) ) {
			&T38lib::Common::notifyWSub("Failed to validate all the fields in NA Resource");
			&T38lib::Common::notifyWSub("Correct format is AAA-A-AAAAAAAA-AAAA-AAAAA-AAA-A");
			&T38lib::Common::notifyWSub("Where AAA      => Company code");
			&T38lib::Common::notifyWSub("      A        => Group Type");
			&T38lib::Common::notifyWSub("      AAAAAAAA => Server Name");
			&T38lib::Common::notifyWSub("      AAAA     => Instance Name");
			&T38lib::Common::notifyWSub("      AAAAA    => Resource Name");
			&T38lib::Common::notifyWSub("      AAA      => Resource Type (SQL)");
			&T38lib::Common::notifyWSub("      AA       => Access Granted");
	
			$subStatus = 0;
			last BLOCK;
		}


		$loginName   = $gdomainName . "\\" . $preWin2000; 
		&T38lib::Common::notifyWSub("Processing => $loginName");

		# If access granted is not a valid access type like SA, DC, DO, DW, DR
		# then skip this resource.
		if (!($gvalidAccessType{$accGranted})) {
			&T38lib::Common::notifyWSub ("Skip, Not a Valid Access type $accGranted");
			last BLOCK;
		}

		#------------------------------------------------------------------------------------------
		# Process NA resources SU Only (Special User Group in System Database)
		#------------------------------------------------------------------------------------------
		if ( ($accGranted eq $gvalidAccessType{SU}) and ($resType eq $gsqlType) ) {
			unless (&processSU($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) ) {
				&T38lib::Common::notifyWSub("sub call to processSU failed");
				$subStatus = 0;
				last BLOCK;
			}
		}
		
		#------------------------------------------------------------------------------------------
		# Process NA resources DC Only (Data Creator)
		#------------------------------------------------------------------------------------------
		if ( ($accGranted eq $gvalidAccessType{DC}) and ($resType eq $gsqlType) ) {
			unless (&processFixedSrvRole($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) ) {
				&T38lib::Common::notifyWSub("sub call to processFixedSrvRole failed");
				$subStatus = 0;
				last BLOCK;
			}
		}
		
		#------------------------------------------------------------------------------------------
		# Process NA resources SA Only (System Admin)
		#------------------------------------------------------------------------------------------
		if ( ($accGranted eq $gvalidAccessType{SA}) and ($resType eq $gsqlType) ) {
			unless (&processFixedSrvRole($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) ) {
				&T38lib::Common::notifyWSub("sub call to processFixedSrvRole failed");
				$subStatus = 0;
				last BLOCK;
			}
		}
		
		#------------------------------------------------------------------------------------------
		# Process NA resources DO Only (Database owner)
		#------------------------------------------------------------------------------------------
		if ( ($accGranted eq $gvalidAccessType{DO}) and ($resType eq $gsqlType) ) {
			unless (&processDO($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) ) {
				&T38lib::Common::notifyWSub("sub call to processDO failed");
				$subStatus = 0;
				last BLOCK;
			}
		}

		#------------------------------------------------------------------------------------------
		# Process NA resources DL Only (DDL Admin)
		#------------------------------------------------------------------------------------------
		if ( ($accGranted eq $gvalidAccessType{DL}) and ($resType eq $gsqlType) ) {
			unless (&processDL($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) ) {
				&T38lib::Common::notifyWSub("sub call to processDL failed");
				$subStatus = 0;
				last BLOCK;
			}
		}
		
		#------------------------------------------------------------------------------------------
		# Process NA resources DW Only (Data Writer)
		#------------------------------------------------------------------------------------------
		if ( ($accGranted eq $gvalidAccessType{DW}) and ($resType eq $gsqlType) ) {
			unless (&processDW($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) ) {
				&T38lib::Common::notifyWSub("sub call to processDW failed");
				$subStatus = 0;
				last BLOCK;
			}
		}
		
		#------------------------------------------------------------------------------------------
		# Process NA resources DR Only (Data Reader)
		#------------------------------------------------------------------------------------------
		if ( ($accGranted eq $gvalidAccessType{DR}) and ($resType eq $gsqlType) ) {
			unless (&processDR($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) ) {
				&T38lib::Common::notifyWSub("sub call to processDR failed");
				$subStatus = 0;
				last BLOCK;
			}
		}

	} # End of BLOCK

	($subStatus == 1 ) ? 
		&T38lib::Common::notifyWSub("Sub Status $subStatus, OK"):
		&T38lib::Common::notifyWSub("Sub Status $subStatus, FAILED");

	return ($subStatus);
}

#------------------------------------------------------------------------------------------
#	Purpose:  Process the NA resources for SA or DC
#
#	Input Argument: Login Name, Company Code, Group Type, Server Name, Instance Name
#	                Resource Name, Resource Type, Access Type
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub processFixedSrvRole($$$$$$$$) {
	my ($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) = @_;

	my ($subStatus) = 1;									# 1 = True, Every thing is OK, 0 means failed
	my ($sqlCmd, $sqlOut) = ("", "");
	my ($rtnCode);
	my ($sqlCmdFile) = ("sqlcmd.sql");
	my ($dbRole) = $gsqlRole{$accGranted};

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {
		if ( ($dbRole eq $gsqlRole{SA}) or ($dbRole eq $gsqlRole{DC}) ) {
			if ($gprocessSA != 1) {
				&T38lib::Common::notifyWSub("Skipping resource for SA or DC: $comCode-$grpType-$srvName-$insName-$resName-$resType-$accGranted");
				&T38lib::Common::notifyWSub("Command line option -p is not given to process SA or DC account");
				last BLOCK;
			}
		}

		#----------------------------------------------------------------
		# Open a temp file 
		#----------------------------------------------------------------
		unless (open(SQLCMD,"> $sqlCmdFile")) {
			&T38lib::Common::errme("Cannot open file $sqlCmdFile");
			$subStatus = 0 ;
			last BLOCK;
		}

		#------------------------------------------------------------------------------------------
		# Add this account the the syslogins by calling xp_grantlogin
		#------------------------------------------------------------------------------------------
		print SQLCMD "if not exists (select 1 from syslogins where name = '$loginName')\n";
		print SQLCMD "begin\n";
		print SQLCMD "exec master..xp_grantlogin '$loginName'\n";
		print SQLCMD "end\n";

		close(SQLCMD);
		
		$sqlCmd = "$gisql -i \"$sqlCmdFile\"";
		$sqlOut = `$sqlCmd`;
		if ( ($sqlOut =~ /Msg/i) or ($sqlOut =~ /ConnectionOpen/i) ) {
			&T38lib::Common::errme("SQL command Failed");
			&T38lib::Common::errme("$sqlCmd");
			&T38lib::Common::errme("$sqlOut");
			$subStatus = 0;
			last BLOCK;
		}

		$sqlCmd = "$gisql -Q \"exec master..sp_addsrvrolemember '$loginName', '$dbRole'\"";
		$sqlOut = `$sqlCmd`;
		if ( ($sqlOut =~ /Msg/i) or ($sqlOut =~ /ConnectionOpen/i) ) {
			&T38lib::Common::errme("SQL command Failed");
			&T38lib::Common::errme("$sqlCmd");
			&T38lib::Common::errme("$sqlOut");
			$subStatus = 0;
			last BLOCK;
		}
		else {
			&T38lib::Common::notifyWSub("Resource $loginName added as role $dbRole");
			last BLOCK;
		}

	} # End of Block

	&T38lib::Common::notifyWSub("SUB DONE");
	return ($subStatus);
}

#------------------------------------------------------------------------------------------
#	Purpose:  Process the NA resource for Data Reader (DR)
#
#	Input Argument: Login Name, Company Code, Group Type, Server Name, Instance Name
#	                Resource Name, Resource Type, Access Type
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub processDR($$$$$$$$) {
	my ($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) = @_;

	my ($subStatus) = 1;									# 1 = True, Every thing is OK, 0 means failed
	my (@dbNames, @temp) = ("", "");
	my ($db, $sqlCmd, $sqlOut);
	my ($dbRole) = $gsqlRole{$accGranted};
	my ($dbFound) = 0;
	my $readonly;

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {
		#------------------------------------------------------------------------------------------
		# get all the databases name from the server system tables.
		#------------------------------------------------------------------------------------------
		@dbNames=&T38lib::Common::getDBNames($gserverName);
		if ( $dbNames[0] eq "$gT38ERROR" ) {
			&T38lib::Common::errme("Call to &T38lib::Common::getDBNames($gserverName) failed.");
			$subStatus = 0;
			last BLOCK;
		}

		#----------------------------------------------------------------
		# Don't process database IF database is in readonly mode
		#----------------------------------------------------------------
		foreach $db (@dbNames) {	
			$readonly =`$gisql -Q "select 1 from master..sysdatabases where name = \'$db\' AND status & 1024 > 0"`;
			if ($readonly =~ 1){
				&T38lib::Common::warnme ("$db is in readonly mode, skipping the database");
				if ( $gfilterDB !~ /${db}/i ) {
					$gfilterDB = $gfilterDB . "|$db";
				}	
			}
		}

		&T38lib::Common::notifyWSub ("$gfilterDB");

		#------------------------------------------------------------------------------------------
		# Filter database that we don't want to do dump
		# example tempdb, model ....
		#------------------------------------------------------------------------------------------
		foreach $db (@dbNames) {	
			unless ($db =~ /^($gfilterDB)$/i ) {
				push (@temp, $db);
			}
		}

		#------------------------------------------------------------------------------------------
		# Do it for all databases if resName is "T38DBALL"
		# else do it for the given database, 
		# resName will have the database name
		# else resName is a role name created by the DBA
		#------------------------------------------------------------------------------------------
		if ( $resName eq "T38DBALL" ) {
			@dbNames = @temp;
		}
		else {
			foreach $db (@temp) {	
				if ( $db eq $resName ) {
					@dbNames = "";
					$dbNames[0] = $resName;
					$dbFound = 1;
					last;
				}
			}
			if ( $dbFound == 0 ) {
				@dbNames = "";
				$dbRole = $resName;
				@dbNames = @temp;
			}
		}
		
		foreach $db (@dbNames) {
			#------------------------------------------------------------------------------------------
			#  Make sure we have the given database at SQL server
			#------------------------------------------------------------------------------------------
			$sqlCmd ="$gisql -Q \"select 1 from master..sysdatabases where name = '$db'\"";
			$sqlOut = `$sqlCmd`;
			if ( ($sqlOut =~ /Msg/i) or ($sqlOut =~ /ConnectionOpen/i) ) {
				&T38lib::Common::errme("SQL command Failed");
				&T38lib::Common::errme("$sqlCmd");
				&T38lib::Common::errme("$sqlOut");
				$subStatus = 0;
				last BLOCK;
			}
			if ( !($sqlOut =~ /1/)  ) {
				&T38lib::Common::warnme("$db not found");
				#$subStatus = 0;
				last BLOCK;
			}
			
			#------------------------------------------------------------------------------------------
			#  Make sure that the given database is writeable
			#------------------------------------------------------------------------------------------

			if (&chkDbWriteable($db) == 0) {
				&T38lib::Common::warnme("Database $db not Writable");
				last BLOCK;
			}

			&T38lib::Common::notifyWSub("Processing for Database $db");

			unless ( &AddAcct2Role($srvName, $db, $loginName ,$dbRole) ) {
				&T38lib::Common::errme("Sub AddAcct2Role failed");
				$subStatus = 0;
				last BLOCK;
			}
		}

	} # End of Block

	($subStatus == 1 ) ? 
		&T38lib::Common::notifyWSub("Sub Status $subStatus, OK"):
		&T38lib::Common::notifyWSub("Sub Status $subStatus, FAILED");
	
	return ($subStatus);
}

#------------------------------------------------------------------------------------------
#	Purpose:  Process the NA resource for Data Writer (DW)
#
#	Input Argument: Login Name, Company Code, Group Type, Server Name, Instance Name
#	                Resource Name, Resource Type, Access Type
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub processDW($$$$$$$$) {
	my ($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) = @_;

	my ($subStatus) = 1;									# 1 = True, Every thing is OK, 0 means failed
	my (@dbNames, @temp) = ("", "");
	my ($db, $sqlCmd, $sqlOut);
	my ($dbRole) = $gsqlRole{$accGranted};
	my ($dbFound) = 0;
	my ($sqlCmd, $rtnCode);
	my ($dbRoleFromAD ) = "";
	my $readonly;

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {
		#------------------------------------------------------------------------------------------
		# get all the databases name from the server system tables.
		#------------------------------------------------------------------------------------------
		@dbNames=&T38lib::Common::getDBNames($gserverName);
		if ( $dbNames[0] eq "$gT38ERROR" ) {
			&T38lib::Common::errme("Call to &T38lib::Common::getDBNames($gserverName) failed.");
			$subStatus = 0;
			last BLOCK;
		}

		#----------------------------------------------------------------
		# Don't process database IF database is in readonly mode
		#----------------------------------------------------------------
		foreach $db (@dbNames) {	
			$readonly =`$gisql -Q "select 1 from master..sysdatabases where name = \'$db\' AND status & 1024 > 0"`;
			if ($readonly =~ 1){
				&T38lib::Common::warnme ("$db is in readonly mode, skipping the database");
				if ( $gfilterDB !~ /${db}/i ) {
					$gfilterDB = $gfilterDB . "|$db";
				}	
			}
		}

		&T38lib::Common::notifyWSub ("$gfilterDB");
		#------------------------------------------------------------------------------------------
		# Filter database that we don't want to do dump
		# example tempdb, model ....
		#------------------------------------------------------------------------------------------
		foreach $db (@dbNames) {	
			unless ($db =~ /^($gfilterDB)$/i ) {
				push (@temp, $db);
			}
		}
		
		#------------------------------------------------------------------------------------------
		# Do it for all databases if resName is "T38DBALL"
		# else do it for the given database, 
		# resName will have the database name
		# else resName is a role name created by the DBA
		#------------------------------------------------------------------------------------------
		if ( $resName eq "T38DBALL" ) {
			# Do it for all the databases
			@dbNames = @temp;
		}
		else {
			# Is resource name is a database name 
			foreach $db (@temp) {	
				if ( $db eq $resName ) {
					@dbNames = "";
					$dbNames[0] = $resName;
					$dbFound = 1;
					last;
				}
			}
			# if resource name is not a database name then
			# resource name is a role name
			# set dbRole to resource name
			if ( $dbFound == 0 ) {
				@dbNames = "";
				$dbRole = $resName;
				$dbRoleFromAD = $resName;
				@dbNames = @temp;
			}
		}
		
		foreach $db (@dbNames) {
			#------------------------------------------------------------------------------------------
			#  Make sure we have the given database at SQL server
			#------------------------------------------------------------------------------------------
			$sqlCmd ="$gisql -Q \"select 1 from master..sysdatabases where name = '$db'\"";
			$sqlOut = `$sqlCmd`;
			if ( ($sqlOut =~ /Msg/i) or ($sqlOut =~ /ConnectionOpen/i) ) {
				&T38lib::Common::errme("SQL command Failed");
				&T38lib::Common::errme("$sqlCmd");
				&T38lib::Common::errme("$sqlOut");
				$subStatus = 0;
				last BLOCK;
			}
			if ( !($sqlOut =~ /1/)  ) {
				&T38lib::Common::warnme("Database $db not found");
				#$subStatus = 0;
				last BLOCK;
			}
			
			#------------------------------------------------------------------------------------------
			#  Make sure that the given database is writeable
			#------------------------------------------------------------------------------------------
			if (&chkDbWriteable($db) == 0) {
				&T38lib::Common::warnme("Database $db not Writable");
				last BLOCK;
			}

			&T38lib::Common::notifyWSub("Processing for Database $db");

			unless ( &AddAcct2Role($srvName, $db, $loginName ,$dbRole) ) {
				&T38lib::Common::errme("Sub AddAcct2Role failed");
				$subStatus = 0;
				last BLOCK;
			}
	
			# Data writer should also be added as Data reader 
			# If the resource name form Active directory is 
			# a role name then use this role name else
			# simple send Role DR

			if ( $dbRoleFromAD eq "") {
				unless ( &AddAcct2Role($srvName, $db, $loginName , $gsqlRole{DR}) ) {
					&T38lib::Common::errme("Sub AddAcct2Role failed");
					$subStatus = 0;
					last BLOCK;
				}
			}
			else {
				unless ( &AddAcct2Role($srvName, $db, $loginName , $dbRoleFromAD) ) {
					&T38lib::Common::errme("Sub AddAcct2Role failed");
					$subStatus = 0;
					last BLOCK;
				}
			}
		}
	} # End of Block

	($subStatus == 1 ) ? 
		&T38lib::Common::notifyWSub("Sub Status $subStatus, OK"):
		&T38lib::Common::notifyWSub("Sub Status $subStatus, FAILED");
	
	return ($subStatus);
}

#------------------------------------------------------------------------------------------
#	Purpose:  Process the NA resource for Database Owner (DBO)
#
#	Input Argument: Login Name, Company Code, Group Type, Server Name, Instance Name
#	                Resource Name, Resource Type, Access Type
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub processDO($$$$$$$$) {
	my ($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) = @_;

	my ($subStatus) = 1;									# 1 = True, Every thing is OK, 0 means failed
	my ($dbFound) = 0;
	my (@dbNames, @temp) = ("", "");
	my ($db, $chkDBSql);
	my ($dbRole) = $gsqlRole{$accGranted};
	my ($sqlCmd, $rtnCode);
	my $readonly;

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {
		#------------------------------------------------------------------------------------------
		# get all the databases name from the server system tables.
		#------------------------------------------------------------------------------------------
		@dbNames=&T38lib::Common::getDBNames($gserverName);
		if ( $dbNames[0] eq "$gT38ERROR" ) {
			&T38lib::Common::errme("Call to &T38lib::Common::getDBNames($gserverName) failed.");
			$subStatus = 0;
			last BLOCK;
		}

		#----------------------------------------------------------------
		# Don't process database IF database is in readonly mode
		#----------------------------------------------------------------
		foreach $db (@dbNames) {	
			$readonly =`$gisql -Q "select 1 from master..sysdatabases where name = \'$db\' AND status & 1024 > 0"`;
			if ($readonly =~ 1){
				&T38lib::Common::warnme ("$db is in readonly mode, skipping the database");
				if ( $gfilterDB !~ /${db}/i ) {
					$gfilterDB = $gfilterDB . "|$db";
				}	
			}
		}
		&T38lib::Common::notifyWSub ("$gfilterDB");

		#------------------------------------------------------------------------------------------
		# Filter database that we don't want to do dump
		# example tempdb, model ....
		#------------------------------------------------------------------------------------------
		foreach $db (@dbNames) {	
			unless ($db =~ /^($gfilterDB)$/i ) {
				push (@temp, $db);
			}
		}
		
		#------------------------------------------------------------------------------------------
		# Do it for all databases if resName is "T38DBALL"
		# else do it for the given database, 
		# resName will have the database name
		# else resName is a role name created by the DBA
		#------------------------------------------------------------------------------------------
		if ( $resName eq "T38DBALL" ) {
			# Do it for all the databases
			@dbNames = @temp;
		}
		else {
			# Is resource name is a database name 
			foreach $db (@temp) {	
				if ( $db eq $resName ) {
					@dbNames = "";
					$dbNames[0] = $resName;
					$dbFound = 1;
					last;
				}
			}

			# if resource name is not a database name then
			# resource name is a role name
			# set dbRole to resource name
			if ( $dbFound == 0 ) {
			 	@dbNames = "";
				$dbRole = $resName;
				@dbNames = @temp;
			}
		}
		
		foreach $db (@dbNames) {
			#------------------------------------------------------------------------------------------
			#  Make sure we have the given database at SQL server
			#------------------------------------------------------------------------------------------
			$chkDBSql =`$gisql -Q "select 1 from master..sysdatabases where name = '$db'"`;
			if ( ($chkDBSql =~ /Msg/i) or ($chkDBSql =~ /ConnectionOpen/i) ) {
				&T38lib::Common::errme("SQL command Failed");
				&T38lib::Common::errme("$chkDBSql");
				$subStatus = 0;
				last BLOCK;
			}
			if ( !($chkDBSql =~ 1)  ) {
				&T38lib::Common::warnme("Database $db not found");
				#$subStatus = 0;
				last BLOCK;
			}
			
			#------------------------------------------------------------------------------------------
			#  Make sure that the given database is writeable
			#------------------------------------------------------------------------------------------
			if (&chkDbWriteable($db) == 0) {
				&T38lib::Common::warnme("Database $db not Writable");
				last BLOCK;
			}

			&T38lib::Common::notifyWSub("Processing for Database $db");

			unless ( &AddAcct2Role($srvName, $db, $loginName ,$dbRole) ) {
				&T38lib::Common::errme("Sub AddAcct2Role failed");
				$subStatus = 0;
				last BLOCK;
			}
		}

	} # End of Block

	($subStatus == 1 ) ? 
		&T38lib::Common::notifyWSub("Sub Status $subStatus, OK"):
		&T38lib::Common::notifyWSub("Sub Status $subStatus, FAILED");
	
	return ($subStatus);
}

#------------------------------------------------------------------------------------------
#	Purpose:  Process the NA resource for DDL Admin
#
#	Input Argument: Login Name, Company Code, Group Type, Server Name, Instance Name
#	                Resource Name, Resource Type, Access Type
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub processDL($$$$$$$$) {
	my ($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) = @_;

	my ($subStatus) = 1;									# 1 = True, Every thing is OK, 0 means failed
	my ($dbFound) = 0;
	my (@dbNames, @temp) = ("", "");
	my ($db, $chkDBSql);
	my ($dbRole) = $gsqlRole{$accGranted};
	my ($sqlCmd, $rtnCode);
	my $readonly;

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {
		#------------------------------------------------------------------------------------------
		# get all the databases name from the server system tables.
		#------------------------------------------------------------------------------------------
		@dbNames=&T38lib::Common::getDBNames($gserverName);
		if ( $dbNames[0] eq "$gT38ERROR" ) {
			&T38lib::Common::errme("Call to &T38lib::Common::getDBNames($gserverName) failed.");
			$subStatus = 0;
			last BLOCK;
		}

		#----------------------------------------------------------------
		# Don't process database IF database is in readonly mode
		#----------------------------------------------------------------
		foreach $db (@dbNames) {	
			$readonly =`$gisql -Q "select 1 from master..sysdatabases where name = \'$db\' AND status & 1024 > 0"`;
			if ($readonly =~ 1){
				&T38lib::Common::warnme ("$db is in readonly mode, skipping the database");
				if ( $gfilterDB !~ /${db}/i ) {
					$gfilterDB = $gfilterDB . "|$db";
				}	
			}
		}
		&T38lib::Common::notifyWSub ("$gfilterDB");

		#------------------------------------------------------------------------------------------
		# Filter database that we don't want to do dump
		# example tempdb, model ....
		#------------------------------------------------------------------------------------------
		foreach $db (@dbNames) {	
			unless ($db =~ /^($gfilterDB)$/i ) {
				push (@temp, $db);
			}
		}
		
		#------------------------------------------------------------------------------------------
		# Do it for all databases if resName is "T38DBALL"
		# else do it for the given database, 
		# resName will have the database name
		# else resName is a role name created by the DBA
		#------------------------------------------------------------------------------------------
		if ( $resName eq "T38DBALL" ) {
			# Do it for all the databases
			@dbNames = @temp;
		}
		else {
			# Is resource name is a database name 
			foreach $db (@temp) {	
				if ( $db eq $resName ) {
					@dbNames = "";
					$dbNames[0] = $resName;
					$dbFound = 1;
					last;
				}
			}

			# if resource name is not a database name then
			# resource name is a role name
			# set dbRole to resource name
			if ( $dbFound == 0 ) {
			 	@dbNames = "";
				$dbRole = $resName;
				@dbNames = @temp;
			}
		}
		
		foreach $db (@dbNames) {
			#------------------------------------------------------------------------------------------
			#  Make sure we have the given database at SQL server
			#------------------------------------------------------------------------------------------
			$chkDBSql =`$gisql -Q "select 1 from master..sysdatabases where name = '$db'"`;
			if ( ($chkDBSql =~ /Msg/i) or ($chkDBSql =~ /ConnectionOpen/i) ) {
				&T38lib::Common::errme("SQL command Failed");
				&T38lib::Common::errme("$chkDBSql");
				$subStatus = 0;
				last BLOCK;
			}
			if ( !($chkDBSql =~ 1)  ) {
				&T38lib::Common::warnme("Database $db not found");
				#$subStatus = 0;
				last BLOCK;
			}
			
			#------------------------------------------------------------------------------------------
			#  Make sure that the given database is writeable
			#------------------------------------------------------------------------------------------
			if (&chkDbWriteable($db) == 0) {
				&T38lib::Common::warnme("Database $db not Writable");
				last BLOCK;
			}

			&T38lib::Common::notifyWSub("Processing for Database $db");

			unless ( &AddAcct2Role($srvName, $db, $loginName ,$dbRole) ) {
				&T38lib::Common::errme("Sub AddAcct2Role failed");
				$subStatus = 0;
				last BLOCK;
			}
		}

	} # End of Block

	($subStatus == 1 ) ? 
		&T38lib::Common::notifyWSub("Sub Status $subStatus, OK"):
		&T38lib::Common::notifyWSub("Sub Status $subStatus, FAILED");
	
	return ($subStatus);
}

#------------------------------------------------------------------------------------------
#	Purpose:  Process the NA resource for Special User Group in System Database (SU)
#
#	Input Argument: Login Name, Company Code, Group Type, Server Name, Instance Name
#	                Resource Name, Resource Type, Access Type
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub processSU($$$$$$$$) {
	my ($loginName, $comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) = @_;

	my ($subStatus) = 1;									# 1 = True, Every thing is OK, 0 means failed
	my (@dbNames, @temp) = ("", "");
	my ($db, $sqlCmd, $sqlOut);
	my ($dbFound) = 0;
	my $readonly;

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {
		if ($gprocessSA != 1) {
			&T38lib::Common::notifyWSub("Skipping resource for SU: $comCode-$grpType-$srvName-$insName-$resName-$resType-$accGranted");
			&T38lib::Common::notifyWSub("Command line option -p is not given to process SU account");
			last BLOCK;
		}
		#------------------------------------------------------------------------------------------
		# get all the databases name from the server system tables.
		#------------------------------------------------------------------------------------------
		@dbNames=&T38lib::Common::getDBNames($gserverName);
		if ( $dbNames[0] eq "$gT38ERROR" ) {
			&T38lib::Common::errme("Call to &T38lib::Common::getDBNames($gserverName) failed.");
			$subStatus = 0;
			last BLOCK;
		}

		#----------------------------------------------------------------
		# Don't process database IF database is in readonly mode
		#----------------------------------------------------------------
		foreach $db (@dbNames) {	
			$readonly =`$gisql -Q "select 1 from master..sysdatabases where name = \'$db\' AND status & 1024 > 0"`;
			if ($readonly =~ 1){
				&T38lib::Common::warnme ("$db is in readonly mode, skipping the database");
				if ( $gfilterDB !~ /${db}/i ) {
					$gfilterDB = $gfilterDB . "|$db";
				}	
			}
		}

		&T38lib::Common::notifyWSub ("$gfilterDB");
		#------------------------------------------------------------------------------------------
		# Filter out user database that we don't want to do
		# and include only database, that would normally be filtered out, example master, msdb ....
		#------------------------------------------------------------------------------------------
		foreach $db (@dbNames) {	
			if ($db =~ /^($gfilterDB)$/i ) {
				push (@temp, $db);
			}
		}

		@dbNames = @temp;

		foreach $db (@dbNames) {
			#------------------------------------------------------------------------------------------
			#  Make sure we have the given database at SQL server
			#------------------------------------------------------------------------------------------
			$sqlCmd ="$gisql -Q \"select 1 from master..sysdatabases where name = '$db'\"";
			$sqlOut = `$sqlCmd`;
			if ( ($sqlOut =~ /Msg/i) or ($sqlOut =~ /ConnectionOpen/i) ) {
				&T38lib::Common::errme("SQL command Failed");
				&T38lib::Common::errme("$sqlCmd");
				&T38lib::Common::errme("$sqlOut");
				$subStatus = 0;
				last BLOCK;
			}
			if ( !($sqlOut =~ /1/)  ) {
				&T38lib::Common::warnme("$db not found");
				#$subStatus = 0;
				last BLOCK;
			}
			
			#------------------------------------------------------------------------------------------
			#  Make sure that the given database is writeable
			#------------------------------------------------------------------------------------------
			if (&chkDbWriteable($db) == 0) {
				&T38lib::Common::warnme("Database $db not Writable");
				last BLOCK;
			}

			&T38lib::Common::notifyWSub("Processing for Database $db");

			unless ( &AddAcct2Role($srvName, $db, $loginName ,$resName) ) {
				&T38lib::Common::errme("Sub AddAcct2Role failed");
				$subStatus = 0;
				last BLOCK;
			}
		}

	} # End of Block

	($subStatus == 1 ) ? 
		&T38lib::Common::notifyWSub("Sub Status $subStatus, OK"):
		&T38lib::Common::notifyWSub("Sub Status $subStatus, FAILED");
	
	return ($subStatus);
}

#------------------------------------------------------------------------------------------
#	Purpose:  Use the given database and add the account to the give role
#
#	Input Argument: Database name, Account Name, DB role
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub AddAcct2Role($$$$) {
	my ($srvName, $dataBaseName, $loginName, $dbRole) = @_;

	my ($subStatus) = 1;		# 1 = True, Every thing is OK, 0 means failed
	my ($sqlCmdFile) = ("sqlcmd.sql");
	my ($tmp2OUTFile) = "{$dbRole}$$.out";
	my ($logFileName);
	my ($base, $logFilePath, $type) = ("", "", "");
	my ($runSQLStatus) = 1;
	my ($sqlCmd, $sqlOut) = ("", "");

	&T38lib::Common::notifyWSub("SUB STARTED");

	$logFileName = &T38lib::Common::getLogFileName($0);
	fileparse_set_fstype("MSWin32");
	($base, $logFilePath, $type) = fileparse($logFileName, '\.[^\.]*');
			
	# Set the output file name using -o option
	#
	$sqlCmdFile = $logFilePath . "$sqlCmdFile";

	BLOCK: {
		
		#----------------------------------------------------------------
		# Open a temp file 
		#----------------------------------------------------------------
		unless (open(SQLCMD,"> $sqlCmdFile")) {
			&T38lib::Common::errme("Cannot open file $sqlCmdFile");
			$subStatus = 0 ;
			last BLOCK;
		}

		#------------------------------------------------------------------------------------------
		# Add this account the the syslogins by calling xp_grantlogin
		#------------------------------------------------------------------------------------------
		print SQLCMD "if not exists (select 1 from syslogins where name = '$loginName')\n";
		print SQLCMD "begin\n";
		print SQLCMD "exec master..xp_grantlogin '$loginName'\n";
		print SQLCMD "end\n";

		close(SQLCMD);
		
		$sqlCmd = "$gisql -i \"$sqlCmdFile\"";
		$sqlOut = `$sqlCmd`;
		if ( ($sqlOut =~ /Msg/i) or ($sqlOut =~ /ConnectionOpen/i) ) {
			&T38lib::Common::errme("SQL command Failed");
			&T38lib::Common::errme("$sqlCmd");
			&T38lib::Common::errme("$sqlOut");
			$subStatus = 0;
			last BLOCK;
		}
		
		#----------------------------------------------------------------
		# Open a temp file 
		#----------------------------------------------------------------
		unless (open(SQLCMD,"> $sqlCmdFile")) {
			&T38lib::Common::errme("Cannot open file $sqlCmdFile");
			$subStatus = 0 ;
			last BLOCK;
		}

		#----------------------------------------------------------------
		# Write the SQL to get the dbnames
		#----------------------------------------------------------------
		# For Data writer add this role as a data reader.
		# Skip checking the login in this case since it is 
		# already created when we give permission for data writer
		
		print SQLCMD "use $dataBaseName\n";
		print SQLCMD "go\n";
		print SQLCMD "if exists (select name from sysusers where issqlrole = 1 and name = '$dbRole')\n";
		print SQLCMD "begin\n";
		print SQLCMD "if not exists (select * from sysusers where name = '$loginName')\n";
		print SQLCMD "begin\n";
		print SQLCMD "exec sp_grantdbaccess '$loginName'\n";
		print SQLCMD "select 'Grant DB Access'\n";
		print SQLCMD "end\n";
		print SQLCMD "exec sp_addrolemember '$dbRole', '$loginName'\n";
		print SQLCMD "select 'Add Role Member'\n";
		print SQLCMD "end\n";
		print SQLCMD "go\n";

		close(SQLCMD);

		$sqlCmd = "$gisql -i \"$sqlCmdFile\"";
		$sqlOut = `$sqlCmd`;
		if ( ($sqlOut =~ /Msg/i) or ($sqlOut =~ /ConnectionOpen/i) ) {
			&T38lib::Common::errme("SQL command Failed");
			&T38lib::Common::errme("$sqlCmd");
			&T38lib::Common::errme("$sqlOut");
			$subStatus = 0;
			last BLOCK;
		}

		if ( ($sqlOut =~ /Grant DB Access/) ) {
			&T38lib::Common::notifyWSub("Resource $loginName added in database $dataBaseName successfully");
		}
		elsif ( ($sqlOut =~ /Add Role Member/) ) {
			&T38lib::Common::notifyWSub("Resource $loginName added in database $dataBaseName successfully");
		}

		# If we have a error do NOT delete the sqlCmdFile
		if ( $subStatus == 0) {
			last BLOCK;
		}

		# Delete temp files when done, leave them if there are errors
		unlink ($sqlCmdFile);

	} # End of BLOCK

	($subStatus == 1 ) ? 
		&T38lib::Common::notifyWSub("Sub Status $subStatus, OK"):
		&T38lib::Common::notifyWSub("Sub Status $subStatus, FAILED");
	
	return ($subStatus);
}

#------------------------------------------------------------------------------------------
#	Purpose:  Check all the fields are there in the NA Resource Name
#
#	Input Argument: NA Resouce Name
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub chkNaResFields($$$$$$$) {
	my ($comCode, $grpType, $srvName, $insName, $resName, $resType, $accGranted) = @_;

	my ($subStatus) = 1;		# 1 = True, Every thing is OK, 0 means failed

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {

		if (! (defined($comCode)) ) {
			&T38lib::Common::notifyWSub("Company Code is NOT defined");
			$subStatus = 0;
		}	
		if (! (defined($grpType)) ) {
			&T38lib::Common::notifyWSub("Group type is NOT defined");
			$subStatus = 0;
		}	
		if (! (defined($srvName)) ) {
			&T38lib::Common::notifyWSub("Server Name is NOT defined");
			$subStatus = 0;
		}	
		if (! (defined($insName)) ) {
			&T38lib::Common::notifyWSub("Instance Name is NOT defined");
			$subStatus = 0;
		}	
		if (! (defined($resName)) ) {
			&T38lib::Common::notifyWSub("Resource Name is NOT defined");
			$subStatus = 0;
		}	
		if ( (!(defined($resType))) or ( (uc($resType)) ne $gsqlType) ) {
			&T38lib::Common::notifyWSub("Resource Type is NOT defined or ");
			&T38lib::Common::notifyWSub("Resource Type is NOT $gsqlType");
			$subStatus = 0;
		}	
		if (! (defined($accGranted)) ) {
			&T38lib::Common::notifyWSub("Account Type is NOT defined");
			$subStatus = 0;
		}
	
		if ( $subStatus == 0 ) {
			last BLOCK;
		}

	} # End of BLOCK

	($subStatus == 1 ) ? 
		&T38lib::Common::notifyWSub("Sub Status $subStatus, OK"):
		&T38lib::Common::notifyWSub("Sub Status $subStatus, FAILED");
	
	return ($subStatus);
}

#------------------------------------------------------------------------------------------
#	Purpose:  Check if database is writable
#
#	Input Argument: database name
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub chkDbWriteable($) {
	my $dbname	= shift;
	my $sqlCmd	= '';
	my $sqlOut	= '';
	my $sqlVersion	= '';
	my $subStatus	= 0;

	BLOCK: {
		# First get SQL Server version.

		$sqlVersion = &T38lib::Common::getSqlVerReg($gnetSrvr, $gInstName);
		if ($sqlVersion != 0 ) {
			$sqlVersion =~ s/\.\d+$//;
		}
		else {
			&T38lib::Common::errme("Call to &T38lib::Common::getSqlVerReg($gnetSrvr, $gInstName) failed");
			&T38lib::Common::notifyWSub("Call to &T38lib::Common::getSqlVerReg($gnetSrvr, $gInstName) failed");
			&T38lib::Common::notifyWSub("Can not get sql version using default $sqlVersion");
			$subStatus = 0;
			last BLOCK;
		}

		if ($sqlVersion !~ /^(7\.00|8\.00|9\.00|10\.)/) {
			&T38lib::Common::errme("The SQL Server version $sqlVersion cannot be handled by this program.");
			$subStatus = 0;
			last BLOCK;
		}

		#------------------------------------------------------------------------------------------
		#  Make sure that the given database is writeable
		#------------------------------------------------------------------------------------------

		if ($sqlVersion eq '7.00') {
			$sqlCmd = "$gisql -Q \"" .
				"if (select ".
				" DATABASEPROPERTY(name, N'IsDetached') + " .
				" DATABASEPROPERTY(name, N'IsShutdown') + " .
				" DATABASEPROPERTY(name, N'IsSuspect') +" .
				" DATABASEPROPERTY(name, N'IsOffline') +" .
				" DATABASEPROPERTY(name, N'IsInLoad') +" .
				" DATABASEPROPERTY(name, N'IsInRecovery') +" .
				" DATABASEPROPERTY(name, N'IsNotRecovered') +" .
				" DATABASEPROPERTY(name, N'IsEmergencyMode') +" .
				" DATABASEPROPERTY(name, N'IsInStandBy') +" .
				" DATABASEPROPERTY(name, N'IsReadOnly')" .
				" from master.dbo.sysdatabases where name = '$dbname') = 0 " .
				"   select 'T38Writable' " .
				" else " .
				"   select 'T38DontKnow' " . '"';
		} else {
			$sqlCmd ="$gisql -Q \"select master.dbo.fn_T38CHKDBWRITABLE('$dbname')\"";
		}
		
		$sqlOut = `$sqlCmd`;
		if ( ($sqlOut =~ /Msg/i) or ($sqlOut =~ /ConnectionOpen/i) ) {
			&T38lib::Common::errme("SQL command Failed");
			&T38lib::Common::errme("$sqlCmd");
			&T38lib::Common::errme("$sqlOut");
			$subStatus = 0;
			last BLOCK;
		}
	
		$sqlOut =  &T38lib::Common::stripWhitespace($sqlOut);
		$subStatus =  ($sqlOut =~ /T38Writable/i) ? 1:0;
	} # End of Block

	($subStatus == 1 ) ? 
		&T38lib::Common::notifyWSub("Sub Status $subStatus, OK"):
		&T38lib::Common::notifyWSub("Sub Status $subStatus, FAILED");
	
	return ($subStatus);
}

#------------------------------------------------------------------------------------------
#	Purpose:  Check the parameter from cfg file and initilize the program variables
#			    with the values from cfg file
#
#	Input Argument: None
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub initFromCFGFile() {

	my ($subStatus) = 1;		# 1 = True, Every thing is OK, 0 means failed
	my ($at, $sq, $sqRole, $sqDesc);
	my (@sqlRole);

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {
		# Check for ADPath
		if ($T38lib::t38cfgfile::gConfigValues{ADPath} eq "") {
			&T38lib::Common::notifyWSub("ADPath is NOT set properly in the cfg file.");
			$subStatus = 0;
			last BLOCK;
		}
 		$gadPath = &T38lib::Common::stripWhitespace($T38lib::t38cfgfile::gConfigValues{ADPath});

		# Check for SQLRole
		if ($T38lib::t38cfgfile::gConfigValues{SQLRole} eq "") {
			&T38lib::Common::notifyWSub("SQLRole is NOT set properly in the cfg file.");
			$subStatus = 0;
			last BLOCK;
		}
		else {
			@sqlRole =  split(",", $T38lib::t38cfgfile::gConfigValues{SQLRole});
			foreach $sq (@sqlRole) {
				$sq = &T38lib::Common::stripWhitespace($sq);
				($sqRole, $sqDesc) = split (/\|/, $sq);
				$sqRole = uc($sqRole);
				if ( ($sqRole eq "") or ($sqDesc eq "") ) {
					&T38lib::Common::notifyWSub("SQLRole is NOT paired properly.");
					&T38lib::Common::notifyWSub("$sqRole, $sqDesc");
					$subStatus = 0;
					last BLOCK;
				}
				else {
					$sqRole = &T38lib::Common::stripWhitespace($sqRole);
					$sqDesc = &T38lib::Common::stripWhitespace($sqDesc);
					$gsqlRole{$sqRole} = $sqDesc;
					$gvalidAccessType{$sqRole} = $sqRole; 
				}
			}
		}
		
		# Check for SQLType
		if ($T38lib::t38cfgfile::gConfigValues{SQLType} eq "") {
			&T38lib::Common::notifyWSub("SQLType is NOT set properly in the cfg file.");
			$subStatus = 0;
			last BLOCK;
		}
		$gsqlType = &T38lib::Common::stripWhitespace($T38lib::t38cfgfile::gConfigValues{SQLType});
		
		# Check for CompanyName
		if ($T38lib::t38cfgfile::gConfigValues{CompanyName} eq "") {
			&T38lib::Common::notifyWSub("CompanyName is NOT set properly in the cfg file.");
			$subStatus = 0;
			last BLOCK;
		}
		$gcompanyName = &T38lib::Common::stripWhitespace($T38lib::t38cfgfile::gConfigValues{CompanyName});
		
		# Check for FilterDBNames
		if ($T38lib::t38cfgfile::gConfigValues{FilterDBNames} eq "") {
			&T38lib::Common::notifyWSub("FilterDBNames is NOT set properly in the cfg file.");
			$subStatus = 0;
			last BLOCK;
		}
		$gfilterDB = &T38lib::Common::stripWhitespace($T38lib::t38cfgfile::gConfigValues{FilterDBNames});
		
		if ( $gfilterDB !~ /master/i ) {
			$gfilterDB = $gfilterDB . "|master";
		}

		if ( $gfilterDB !~ /model/i ) {
			$gfilterDB = $gfilterDB . "|model";
		}

		if ($T38lib::t38cfgfile::gConfigValues{SecurityGroupLocation} eq "") {
			&T38lib::Common::notifyWSub("SecurityGroupLocation is NOT set properly in the cfg file.");
			$subStatus = 0;
			last BLOCK;
		}

		# Drive group Name from security group location cfg file
		#
		if ($T38lib::t38cfgfile::gConfigValues{SecurityGroupLocation} =~ /S/i ) {
			$gsecurityGrpLoc = "SQLSTORE";
		}
		elsif ($T38lib::t38cfgfile::gConfigValues{SecurityGroupLocation} =~ /C/i ) {
			$gsecurityGrpLoc = "SQLCORP";
		}
		elsif ($T38lib::t38cfgfile::gConfigValues{SecurityGroupLocation} =~ /I/i ) {
			$gsecurityGrpLoc = "SQLINET";
		}
		else {
			&T38lib::Common::notifyWSub("$T38lib::t38cfgfile::gConfigValues{SecurityGroupLocation} is not a valid code" );
			&T38lib::Common::notifyWSub("Valid security group locations are S => SQLSTORW, C => SQLCORP, I => SQLINET");
			$subStatus = 0;
			last BLOCK;
		}

		# If environment type is defined, add it to filter criteria for AD resource groups.

		if (uc($T38lib::t38cfgfile::gConfigValues{EnvironmentType}) eq 'D') {
			$genvironmentType = $gsecurityGrpLoc . 'Dev';
		} elsif (uc($T38lib::t38cfgfile::gConfigValues{EnvironmentType}) eq 'T') {
			$genvironmentType = $gsecurityGrpLoc . 'Dev';
		} elsif (uc($T38lib::t38cfgfile::gConfigValues{EnvironmentType}) eq 'Q') {
			$genvironmentType = $gsecurityGrpLoc . 'QA';
		} elsif (uc($T38lib::t38cfgfile::gConfigValues{EnvironmentType}) eq 'P') {
			$genvironmentType = $gsecurityGrpLoc . 'Prod';
		} else {
			$genvironmentType = $gsecurityGrpLoc;
		};

	} # End of BLOCK

	($subStatus == 1 ) ? 
		&T38lib::Common::notifyWSub("Sub Status $subStatus, OK"):
		&T38lib::Common::notifyWSub("Sub Status $subStatus, FAILED");
	
	return ($subStatus);
}

#------------------------------------------------------------------------------------------
#	Purpose:  Process T38LIST:T38adsec_grant_perm
#
#	Input Argument: None
#
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub processGrantPerm() {

	my ($subStatus) = 1;						# 1 = True, Every thing is OK, 0 means failed
	my ($sqlCmd, $sqlOut) = ("", "");
	my ($rtnCode);
	my ($sqlCmdFile) = ("sqlcmd.sql");
	my ($perm,$loginName) = ("","");
	my ($first) = 1;

	&T38lib::Common::notifyWSub("SUB STARTED");

	#----------------------------------------------------------------
	# Open a temp file 
	#----------------------------------------------------------------
	unless (open(SQLCMD,"> $sqlCmdFile")) {
		&T38lib::Common::errme("Cannot open file $sqlCmdFile");
		$subStatus = 0 ;
		last BLOCK;
	}

	BLOCK: {
		while (($perm,$loginName) = each(%gCFGResourceName)) {
			$loginName   = $gdomainName . "\\" . $loginName; 

			if ($first) {
				print SQLCMD "if not exists (select 1 from syslogins where name = '$loginName')\n";
				print SQLCMD "begin\n";
				print SQLCMD "exec master..xp_grantlogin '$loginName'\n";
				print SQLCMD "end\n";
				$first = 0;
			}

			print SQLCMD "use master\n";
			print SQLCMD "go\n";
			print SQLCMD "Grant $perm to [$loginName]\n";
			print SQLCMD "go\n";

		}
	
		close(SQLCMD);
		
		$sqlCmd = "$gisql -i \"$sqlCmdFile\"";
		$sqlOut = `$sqlCmd`;
		if ( ($sqlOut =~ /Msg/i) or ($sqlOut =~ /ConnectionOpen/i) ) {
			&T38lib::Common::errme("SQL command Failed");
			&T38lib::Common::errme("$sqlCmd");
			&T38lib::Common::errme("$sqlOut");
			$subStatus = 0;
			last BLOCK;
		}

	} # End of Block

	&T38lib::Common::notifyWSub("SUB DONE");
	return ($subStatus);
}


#------------------------------------------------------------------------------------------
#	Purpose:  Process T38LIST:T38adsec_grant_perm
#
#	Input Argument: None
#
#	Output:  1 OK, 0 Failed
#------------------------------------------------------------------------------------------
sub processGrantDBRole() {

	my ($subStatus) = 1;						# 1 = True, Every thing is OK, 0 means failed
	my ($sqlCmd, $sqlOut) = ("", "");
	my ($rtnCode);
	my ($sqlCmdFile) = ("sqlcmd.sql");
	my ($perm,$loginName) = ("","");
	my ($first) = 1;
	my ($roleCode, $DBName, $dbRole);

	&T38lib::Common::notifyWSub("SUB STARTED");

	#----------------------------------------------------------------
	# Open a temp file 
	#----------------------------------------------------------------
	unless (open(SQLCMD,"> $sqlCmdFile")) {
		&T38lib::Common::errme("Cannot open file $sqlCmdFile");
		$subStatus = 0 ;
		last BLOCK;
	}

	BLOCK: {
		while (($perm,$loginName) = each(%gCFGResourceName)) {
			$loginName   = $gdomainName . "\\" . $loginName; 

			if ($first) {
				print SQLCMD "if not exists (select 1 from syslogins where name = '$loginName')\n";
				print SQLCMD "begin\n";
				print SQLCMD "exec master..xp_grantlogin '$loginName'\n";
				print SQLCMD "end\n";
				$first = 0;
			}

			($roleCode, $DBName) = split (/:/, $perm);
			($dbRole) = $gsqlRole{$roleCode};

			print SQLCMD "use $DBName\n";
			print SQLCMD "go\n";
			print SQLCMD "exec sp_addrolemember [$dbRole], [$loginName]\n";
			print SQLCMD "go\n";

		}
	
		close(SQLCMD);
		
		$sqlCmd = "$gisql -i \"$sqlCmdFile\"";
		$sqlOut = `$sqlCmd`;
		if ( ($sqlOut =~ /Msg/i) or ($sqlOut =~ /ConnectionOpen/i) ) {
			&T38lib::Common::errme("SQL command Failed");
			&T38lib::Common::errme("$sqlCmd");
			&T38lib::Common::errme("$sqlOut");
			$subStatus = 0;
			last BLOCK;
		}

	} # End of Block

	&T38lib::Common::notifyWSub("SUB DONE");
	return ($subStatus);
}

#------------------------------------------------------------------------------------------
#	Purpose:  Print a help screen on std out.
#
#	Input Argument: None
#	Output:         None
#------------------------------------------------------------------------------------------
sub showHelp() {

print << 'EOT';
#* PVCS header information
#* $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38ADSec.pv_  $
#* $Author: A645276 $
#* $Date: 2011/02/08 17:12:19 $
#* $Revision: 1.1 $
#*
#* Purpose: NA Security
#*
#* Summary:
#*   1. Get SQL resource names from Active directory and assign map it to SQL group
#*
#* Program must be executed from within the directory it is located.
#*
#* SYNOPSIS
#* T38ADSec.pl -c cfgfile and/or and -S server name or -h
#*
#* Command line:
#*
#* -c configration file name (required)
#* -S	server, optional server name (optional)
#* -p Process request for admin accounts (SA or DC) (optional)
#* -h  Writes help screen on standard output, then exits (optional)
#*
#* Example: 
#*   1. Run T38ADSec.pl using T38ADSec.cfg as a configuration file on local server.
#*      perl T38ADSec.pl -c T38ADSec.cfg
#*		
#*   2. Show the help screen and quit.
#*      perl T38ADSec.pl -h
#*	
#*   3. Run T38ADSec.pl using T38ADSec.cfg as a configuration file on given server name.   
#*      perl T38ADSec.pl -c T38ADSec.cfg -S ServerName 
#*	
#*	
#***
EOT

} # End of showHelp

__END__

=pod

=head1 T38ADSec.pl

T38ADSec.pl - NA security

=head1 SYNOPSIS

perl T38ADSec.pl -c Cfg FileName and -S ServerName or -h

=head2 OPTIONS

I<T38ADSec.pl> accepts the following options:

=over 4

=item -h 		(Optional)

Print out a short help message, then exit.

=item -c Cfg File Name (Required)

-c cfg file name 

=item -S Server Name (Optional)

-S option to provide Server Name

=item -p  (Optional)

-p Process request for admin accounts (SA or DC) (optional)

=back

=head1 DESCRIPTION

=head1 EXAMPLE

	perl T38ADSec.pl -c T38ADSec.cfg
	Run T38ADSec.pl using T38ADSec.cfg as a configuration file on local server

	perl T38ADSec.pl -c T38ADSec.cfg -S ServerName 
	Run T38ADSec.pl using T38ADSec.cfg as a configuration file on given server name.


	perl T38ADSec.pl -h
	Run T38ADSec.pl and show help screen and quit.  No processing is done.

=head2 Notes

 Uses sp_T38ADSec store proc

=head1 BUGS

I<T38ADSec.pl> has no known bugs.

=head1 REVISION HISTORY

$Revision: 1.1 $

=head1 AUTHOR

Asif Kaleem, Asif.Kaleem@bestbuy.com

=head1 SEE ALSO

Common.pm
t38cfgfile.pm
bbyado.pm

=head1 COPYRIGHT and LICENSE

This program is copyright by Best Buy Inc.

=cut
