#!perl 
#* t38srvstats - Collect server statistics and store it in master repository.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:23 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/t38srvstats/t38srvstats.pv_  $
#*
#* SYNOPSIS
#*	t38srvstats -h -S server -r rServer -d rDatabase -x{s|d} -e{D|M|P|Q|T} 
#*					-l{C|I|S} -c cfgFile
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-S server	Name of the server to add to central repository. Default is
#*				local server.
#*	-r rServer	Name of the database server with repository database.
#*				Default is local server.
#*	-d rDBase	Name of the centrol repository database with Servers
#*				information. Default is ADMDB004.
#*	-x execOpt	Execution option: 
#*					s -- collect OS level information
#*					d -- collect database level information
#*				default is collect OS and database information.
#*	-e EnvrTyp	SQL Server Environment type:
#*					D -- DEV, 	Development (Default)
#*					M -- MDWE,	Middleware
#*					P -- PROD,	Production
#*					Q -- QUAL,	Quality Assurnc
#*					T -- TEST,	Test Env
#*	-l secLog	Security Group Location:
#*					C -- Corporate Location (Default)
#*					I -- Internet Location
#*					S -- Store Location
#*	-c cfgFile	Configuration file with optional parameters. They
#*				provide defaults for common options.
#*				Following parameters are excepted:
#*				RepositoryServerName 	-- can be overwritten by -r option
#*				RepositoryDBName		-- can be overwritten by -d option
#*				EnvironmentType			-- can be overwritten by -e option
#*				SecurityGroupLocation	-- can be overwritten by -l option
#*	
#*	This server collects vital statistics on SQL Server machine and stores it
#*	in repostiroy database.
#*
#*	REQUIRED FILES:
#*
#*	t38mdac.ver.cfg
#*
#*	REQUIRED OS Utilities:
#*
#*	NT 4.0: winmsd, filever.
#*	Win2K:	msinfo32, filever.
#*
#***

use strict;

#-- constants

use constant DEFAULT_INST_NM => 'MSSQLServer';

use Win32;
use Win32::OLE qw(in with);
use Win32::Registry;
use Math::BigInt;
use Win32::Process;
use T38lib::Common qw(getWinClusterName getSQLInst4VirtualSrvr notifyMe notifyWSub logme warnme errme logEvent whence isX64Process);
use T38lib::bbyado qw(adoConnect adoProperties4Conn adoProperties4Rs execSQLBat execSQLCmd execSQL2Arr showADOErrors);
use File::Path;
use File::Basename;
use Win32::TieRegistry ( Delimiter=>"/", ArrayValues=>0);

use vars qw(
		$gScriptName $gScriptPath
		$opt_h $opt_c $opt_d $opt_e $opt_l $opt_r $opt_S $opt_x
		$gHostName $gSrvr $gRepoSrvr $gRepoDB $gEnvrTyp $gSecGrpLoc
		%gSysInfo
		$gNWarnings
		$T38ERROR
		%gLOC_SRVR %gLOC_SRVR_DRV %gListLOC_SRVR_DRV %gOS_VER %gDBMS_VER
		);
		# todo %gLOC_SRVR_DRV_SHARE
		# todo %gLOC_SRVR_DFLT_SHARE

$main::gDebug	= 0;	# Turn printing of debug information for whole program on/off.
my ($gisql) = "osql -E -h-1 -n -w2048"; 
my $gx64flg = 0;

# Main

&main();

sub main {
	my $mainStatus	= 0;
SUB:
{
	unless (&housekeeping())	{ $mainStatus = 1; last SUB; }
	$gx64flg = &T38lib::Common::chkx64($gSrvr);

	if (!$opt_x || $opt_x =~ /s/i) {
		unless (&getSysInfoReg())	{ $mainStatus = 1; last SUB; }
		unless (&getSysInfoFile())	{ $mainStatus = 1; last SUB; }

		unless (&loadSrvStats())	{ $mainStatus = 1; last SUB; }
		unless (&updateLocSrvr())	{ $mainStatus = 1; last SUB; }

		unless (&updateSrvrDrv())	{ $mainStatus = 1; last SUB; }
	}

	if (!$opt_x || $opt_x =~ /d/i) {
		unless (&updateSQLInst())	{ $mainStatus = 1; last SUB; }
	}
	
	my $debug = 0;
	if ($debug || $main::gDebug) {
		&notifyWSub("gLOC_SRVR:");
		&debugPrintHash(\%gLOC_SRVR);
	}
	$debug = 0;
	if ($debug || $main::gDebug) {
		&notifyWSub("gLOC_SRVR_DRV:");
		my $id;
		my $hKey;
		foreach $id (sort keys %gListLOC_SRVR_DRV) {
			my $msg = "\t$id: " . join(", ", (sort keys (%{$gListLOC_SRVR_DRV{$id}})));
			&notifyMe($msg);
			foreach $hKey (sort keys (%{$gListLOC_SRVR_DRV{$id}})) {
				&notifyMe("\tLOC_SRVR_DRV[$id].$hKey = $gListLOC_SRVR_DRV{$id}{$hKey}");
			}
		}
	}

	last SUB;
	
}	# SUB
# ExitPoint:
	$mainStatus = 1	if ($gNWarnings > 0);
	# Force the Status to Zero, since we don't want 
	# to get a INET ticket for this job.
	$mainStatus = 0;
	( $mainStatus == 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;
	exit($mainStatus);
}	# main

#######################  $Workfile:   t38srvstats.pl  $ Subroutines  #################################


# ----------------------------------------------------------------------
#	chkDrvInfo	check physical drive information
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub chkDrvInfo {
	my	$status	= 1;
	my	$drvNm	= '';
SUB:
{
	&notifyWSub("Started.");
	unless (keys %gListLOC_SRVR_DRV) {
		&errme("Did not find any local drives on $gSrvr.");
		$status = 0;
		last SUB;
	}

	foreach $drvNm (sort keys %gListLOC_SRVR_DRV) {
		if ($gListLOC_SRVR_DRV{$drvNm}{DRV_TOT_SPACE_QTY} eq $T38ERROR) {
			$gListLOC_SRVR_DRV{$drvNm}{DRV_TOT_SPACE_QTY} = 0;
			&warnme("Cannot calculate total space for disk drive $drvNm on $gSrvr. Will store 0 value.");
			$gNWarnings++;
		}
		if ($gListLOC_SRVR_DRV{$drvNm}{DRV_AVAIL_SPACE_QTY} eq $T38ERROR) {
			$gListLOC_SRVR_DRV{$drvNm}{DRV_AVAIL_SPACE_QTY} = 0;
			&warnme("Cannot calculate available space for disk drive $drvNm on $gSrvr. Will store 0 value.");
			$gNWarnings++;
		}
	}

	last SUB;
}
	&notifyWSub("Done");
	return ($status);
}	# chkDrvInfo


# ----------------------------------------------------------------------
#	getDbmsVerId	Get DBMS_VER_ID for all MSSQL Server versions
# ----------------------------------------------------------------------
#	arguments:
#		command object
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate %gDBMS_VER.
# ----------------------------------------------------------------------

sub getDbmsVerId (\%) {
	my $cmd		= shift;
	my $conn	= 0;		# ADO connection object handle
	my $rs		= 0;		# record set handle
	my $sql		= "";		# SQL statements
	my $sqlerr	= 0;
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");
	$conn = $cmd->{ActiveConnection};
	$sqlerr = $conn->Errors;

	$sql = 
			"select DBMS_VER_ID, DBMS_VER_PATCH_ID\n" . 
			"from DBMS_VER\n" . 
			"where DBMS_TYP = 'MSSQL'"
			;

	$cmd->{CommandText} = $sql;

	unless ($rs = $cmd->Execute()) { &errme("Error in SQL"); &notifyMe("\n$sql"); &showADOErrors($sqlerr); $status = 0; last SUB; }

	while(! $rs->EOF) {
		$gDBMS_VER{$rs->Fields('DBMS_VER_PATCH_ID')->Value} = $rs->Fields('DBMS_VER_ID')->Value;
		$rs->MoveNext;
	}

	last SUB;
}
	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset

	&notifyWSub("Done");

	return ($status);
}	# getDbmsVerId


# ----------------------------------------------------------------------
#	getDbOsVerNm	Get OS_VER_NM from database
# ----------------------------------------------------------------------
#	arguments:
#		command object
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate global %gLOC_SRVR{OS_VER_NM}.
# ----------------------------------------------------------------------

sub getDbOsVerNm (\%) {
	my $cmd		= shift;
	my $conn	= 0;		# ADO connection object handle
	my $rs		= 0;		# record set handle
	my $sql		= "";		# SQL statements
	my $sqlerr	= 0;
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");
	$conn = $cmd->{ActiveConnection};
	$sqlerr = $conn->Errors;

	$sql = 
			"select OS_VER_NM from OS_TYP t, OS_VER v " . 
			"where lower(t.OS_TYP_DESC) = '" . lc($gOS_VER{OS_TYP_DESC}) . "' ".
			"	and t.OS_TYP = v.OS_TYP " .
			"	and v.OS_VER_PATCH_ID = '" . $gOS_VER{OS_VER_PATCH_ID} . "'" 
			;


	$cmd->{CommandText} = $sql;

	unless ($rs = $cmd->Execute()) { &errme("Error in SQL"); notifyMe($sql); &showADOErrors($sqlerr); $status = 0; last SUB; }

	while(! $rs->EOF) {
		$gLOC_SRVR{OS_VER_NM} = $rs->Fields('OS_VER_NM')->Value;
		$gLOC_SRVR{OS_VER_NM} =~ s/\s+$//g;
		$rs->MoveNext;
	}

	if ($gLOC_SRVR{OS_VER_NM} eq $T38ERROR) {
		&errme("Cannot find OS_VER_NM in $gRepoDB for Patch ID $gOS_VER{OS_VER_PATCH_ID}.");
		&notifyMe("OS Description is: $gOS_VER{OS_TYP_DESC}.");
		$status = 0;
		last SUB;
	}

	last SUB;
}
	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset

	&notifyWSub("Done");

	return ($status);
}	# getDbOsVerNm


# ----------------------------------------------------------------------
#	getDbLocSrvr	Get LOC_SRVR record from database
# ----------------------------------------------------------------------
#	arguments:
#		command object
#		lLOC_SRVR structure
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate %lLOC_SRVR{OS_VER_NM}.
# ----------------------------------------------------------------------

sub getDbLocSrvr (\%$) {
	my $cmd			= shift;
	my $lLOC_SRVR	= shift;
	my $hKey		= 0;
	my $conn		= 0;		# ADO connection object handle
	my $rs			= 0;		# record set handle
	my $sql			= "";		# SQL statements
	my $sqlerr		= 0;
	my $fldCount;
	my $i;
	my ($fields, $fldSize, @fldSizes);
	my $status		= 1;

	my $debug		= 0;
SUB:
{
	&notifyWSub("Started.");
	$conn = $cmd->{ActiveConnection};
	$sqlerr = $conn->Errors;

	# Create SQL command as:
	#	select column_list 
	#	from LOC_SRVR where LOC_SRVR_NM = 'Server_name'
	$sql = "select\n";
	foreach $hKey (keys (%{$lLOC_SRVR})) {
		$sql .= "\t$hKey,\n";
	}
	chomp($sql);
	$sql =~ s/,$/\nfrom LOC_SRVR where LOC_SRVR_NM = \'$gLOC_SRVR{LOC_SRVR_NM}\'/;

	$cmd->{CommandText} = $sql;

	unless ($rs = $cmd->Execute()) { &errme("Error in SQL"); notifyMe($sql); &showADOErrors($sqlerr); $status = 0; last SUB; }

	$fields = $rs->Fields;

	my $fldCount = $rs->Fields->count;
	my ($i, $recCnt) = (0, 0);
	while(! $rs->EOF) {
		$recCnt++;
		for ( $i = 0; $i < $fldCount; $i++ ) {
			if (defined($$lLOC_SRVR{$rs->Fields($i)->Name})) {
				$$lLOC_SRVR{$rs->Fields($i)->Name} = $rs->Fields($i)->Value;
			} else {
				&errme("Internal error. Select statement column $rs->Fields($i)->Name does not match lLOC_SRVR structure.");
				$status = 0;
				last SUB;
			}
		}
		$rs->MoveNext;
	}

	if ($recCnt > 1) {
		&errme("Database is corrupted. Multiple records found for $gLOC_SRVR{LOC_SRVR_NM}.");
		$status = 0;
		last SUB;
	}

	$debug = 0;
	if ($debug || $main::gDebug) {
		&notifyWSub("lLOC_SRVR:");
		&debugPrintHash($lLOC_SRVR);
	}

	last SUB;
}
	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset

	&notifyWSub("Done");

	return ($status);
}	# getDbLocSrvr


# ----------------------------------------------------------------------
#	getDbSize	Get Database sizes for database
# ----------------------------------------------------------------------
#	arguments:
#		command object
#		LOC_SRVR_DBINST record
#		LOC_SRVR_DBINST_DB	record
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate %lLOC_SRVR{OS_VER_NM}.
# ----------------------------------------------------------------------

sub getDbSize (\%\%\%) {
	my $cmd					= shift;
	my $rLOC_SRVR_DBINST	= shift;
	my $dbRec				= shift;
	my ($dbmsVerMajor, $dbmsVerMinor, $dbmsVerPatch)
							= split('\.', $$rLOC_SRVR_DBINST{DBMS_VER_PATCH_ID});
	my $conn		= 0;
	my $dbincon		= '';		# Current database, used by connection.
	my @rsarr		= ();		# record set
	my $sql			= "";		# SQL statements
	my $i;
	my $found		= 0;
	my $status		= 1;
	my $debug		= 0;

SUB:
{
	&notifyWSub("Started.");

	# Set current catalog to database, we need to get size for.
	$conn = $cmd->{ActiveConnection};
	$dbincon = $conn->Properties->{"Current Catalog"}->Value;
	unless ($dbincon) {
		&errme("Unexpected error. Existing connection is not connected to any database.");
		&adoProperties4Conn(%{$conn->Properties});
		$status = 0; last SUB;
	} 
	unless ($$dbRec{dbName}) {
		&errme("Unexpected error. Missing database name in dbRec structure.");
		$status = 0; last SUB;
	}

	# Check to see if we can use the database
	# Code added for Mirror databases, since we can not 
	# get size of mirror databases
	#
	$sql =	"select convert(sysname, databasepropertyex(\'$$dbRec{dbName}\', \'Status\')) Status"; 
	unless (&execSQL2Arr($cmd, $sql, \@rsarr)) { $status = 0; last SUB; }

	&notifyWSub("**** $$dbRec{dbName} Status => $rsarr[0]{Status} ");

	# Database is mirror 
	if ($rsarr[0]{Status} !~ /online/i ) {
		$$dbRec{totalSpc}	= 0;
		$$dbRec{usedSpc}	= 0;
		last SUB;
	}
	@rsarr	= ();

	$conn->Properties->{"Current Catalog"} = $$dbRec{dbName};

	# Get database sizes.
	#
	if ($dbmsVerMajor >= 7) {
		$sql = <<'EOT';
		SELECT 
			db_name() as currentdb,
			FileType,
			round(cast(sum(size) as float)*8/1024, 0) as size, 
			round(cast(sum (Used) as float) *8/1024, 0) as used
		from (
			Select 
				FILEPROPERTY (name, 'islogfile') as FileType, 
				size, 
				FILEPROPERTY (name, 'spaceused') as Used 
				from sysfiles) 
			AS UsedResults
		group by FileType
		having FileType = 0
EOT
;
	} else {
		$sql = <<'EOT';
		select 
			db_name() as 'currentdb', 
			0 as FileType, 
			(select (convert(decimal(15,2), sum(size)*2))/1024 from master..sysusages
				where dbid = db_id() and segmap = 3 or dbid = db_id() and segmap = 7) as 'size',
			(select (convert(decimal(15,2), sum(used)*2))/1024 from sysindexes where id <> object_id('syslogs')) as used
EOT
;
	}

	unless (&execSQL2Arr($cmd, $sql, \@rsarr)) { $status = 0; last SUB; }

	$found = 0;
	foreach $i (0..@rsarr-1) {
		if ($rsarr[$i]{currentdb}) {
			if ($rsarr[$i]{currentdb} eq $$dbRec{dbName}) {
				$$dbRec{totalSpc}	= $rsarr[$i]{size};
				$$dbRec{usedSpc}	= $rsarr[$i]{used};
				$found	= 1;
			} else {
				&warnme("Cannot use $$dbRec{dbName} database. Collected size for db = $rsarr[$i]{currentdb}, size = $rsarr[$i]{size}, used = $rsarr[$i]{used}");
				$gNWarnings++;
				last SUB;
			}
			last;
		}
	}

	if (!$found) {
		&warnme("Cannot get database size for $$dbRec{dbName} on $$rLOC_SRVR_DBINST{LOC_SRVR_NM}\\$$rLOC_SRVR_DBINST{LOC_SRVR_DBINST_NM}.");
		$gNWarnings++;
		last SUB;
	}

	last SUB;
}
	# Reset database, that is current for connection back to wat it was before
	# this subroutine was started.
	if ($dbincon && $conn) { $conn->Properties->{"Current Catalog"} = $dbincon; }

	&notifyWSub("Done");

	return ($status);
}	# getDbSize


# ----------------------------------------------------------------------
#	getIpAddress	Get server ip address id
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate global %gLOC_SRVR{IP_ADDR_ID}.
# ----------------------------------------------------------------------

sub getIpAddress {
	my $pingOut	= "";
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");
	$pingOut = `ping -n 1 -w 1 $gSrvr`;

	if ($pingOut =~ /Pinging $gSrvr.* \[(\d+\.\d+\.\d+\.\d+)\]/i) {
		$gLOC_SRVR{IP_ADDR_ID} = $1;
	} else {
		&errme("Cannot get ip address for $gSrvr.");
		notifyMe("Ping results: $pingOut");
		$status = 0;
		last SUB;
	}
	last SUB;
}

	&notifyWSub("Done");

	return ($status);
}	# getIpAddress


# ----------------------------------------------------------------------
#	getMDACVer	Get MDAC Version
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate global $gLOC_SRVR{MDAC_VER_ID}.
# ----------------------------------------------------------------------

sub getMDACVer {
	my $programFilesDir	= $gSysInfo{ProgramFilesDir};
	my $commonFilesDir	= "$programFilesDir\\Common Files";
	my $systemRoot		= $gSysInfo{SystemRoot};
	my $mdacCfgFile		= "t38mdac.ver.cfg";
	my $result			= "";
	my $fname			= "";							# check file name
	my $fsufx			= "";
	my $fver			= "";							# version number to check for
	my $build			= "";							# MDAC build id
	my $status			= 1;
	my %checkedFiles	= ();							# List of checked files.
	my $verOut			= "";
	my $mdacVer			= "";
SUB:
{
	&notifyWSub("Started.");
	if ($gHostName ne $gSrvr) {
		$programFilesDir	=~ s/^([A-Z]):/\\\\$gSrvr\\\1\$/;
		$commonFilesDir		=~ s/^([A-Z]):/\\\\$gSrvr\\\1\$/;
		$systemRoot			=~ s/^([A-Z]):/\\\\$gSrvr\\\1\$/;
	}

	if (-e "$gScriptPath$mdacCfgFile") { $mdacCfgFile = "$gScriptPath$mdacCfgFile"; }
	elsif ($result = &whence($mdacCfgFile)) { $mdacCfgFile = $result; } 
	else { &errme("Cannot find mdac configuration file $mdacCfgFile."); $status = 0; last SUB; }

	unless (open(MDACCFG, $mdacCfgFile)) { &errme("Cannot read file $mdacCfgFile!"); $status = 0; last SUB; }

	while (<MDACCFG>) {
		if (
			/^\s*[#\;]/ ||
			/^\s*$/ ||
			/^File\s+FileVersion\s+BuildSource\s*/i
			) {
			# Skip headings, blank and comment lines
			next;
		}
		if (/^(.*\.)(dll|exe)\s+([\d\.]+)\s+(\S.*\S)\s*$/i) {
			$fname	= $1;
			$fsufx	= $2;
			$fver	= $3;
			$build	= $4;
			$fname =~ s/\$systemRoot/$systemRoot/g;
			$fname =~ s/\$programFilesDir/$programFilesDir/g;
			$fname =~ s/\$commonFilesDir/$commonFilesDir/g;
			$fname = lc("$fname$fsufx");
			$fsufx = lc($fsufx);

			unless (defined($checkedFiles{$fname})) {
				my $basename = &basename($fname, ($fsufx));
				$verOut = `filever \"$fname\"`;
				if ($verOut =~ /(W32i|Wx64|WAMD64)\s+(APP|DLL)\s+\S+\s+([\d\.]+)\s.*\s$basename/i) {
					$checkedFiles{$fname}{Version} = $3;
				} else {
					&errme("Cannot get version id for $fname.");
					$status = 0;
					last SUB;
				}
			}

			if ($checkedFiles{$fname}{Version} eq $fver) { $mdacVer = $build; }
			next;
		}
	}

	if ($mdacVer) {
		$gLOC_SRVR{MDAC_VER_ID} = $mdacVer;
	} else {
		&warnme("Cannot match mdac version id from $mdacCfgFile.");
		$gNWarnings++;
	}

	last SUB;
}
	close(MDACCFG);

	&notifyWSub("Done");

	return ($status);
}	# getMDACVer


# ----------------------------------------------------------------------
#	getOsVerPatch	Get OS Version patch id
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate global %gOS_VER{OS_VER_PATCH_ID}.
# ----------------------------------------------------------------------

sub getOsVerPatch {
	my $osCmdExe	= "";
	my $verOut		= "";
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");
	if ($gHostName eq $gSrvr) {
		$osCmdExe = "$gSysInfo{SystemRoot}\\system32\\cmd.exe";
	} else {
		($osCmdExe	= "$gSysInfo{SystemRoot}\\system32\\cmd.exe") =~ s/^([A-Z]):/\1\$/;
		$osCmdExe	= "\\\\$gSrvr\\$osCmdExe";
	}

	$verOut = `filever \"$osCmdExe\"`;
	if ($verOut =~ /(W32i|Wx64|WAMD64)\s+APP\s+ENU\s+([\d\.]+)\s.*\scmd.exe/i) {
		$gOS_VER{OS_VER_PATCH_ID} = $2;
	} else {
		&errme("Cannot get version id for $osCmdExe.");
		$status = 0;
		last SUB;
	}
	last SUB;
}

	&notifyWSub("Done");

	return ($status);
}	# getOsVerPatch


# ----------------------------------------------------------------------
#	getPerlVer	Get Perl version
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate global %gLOC_SRVR{PERL_VER_NBR}.
# ----------------------------------------------------------------------

sub getPerlVer {
	my $perlExe	= "";
	my $verOut		= "";
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");
	if ($gHostName eq $gSrvr) {
		$perlExe = &whence("perl.exe");
	} else {
		# Check if file can be found on $PATH of the remote server.
		my $dir;
	
		foreach $dir (split(';', $gSysInfo{EnvPath})) {
			$dir =~ s/[\\\/]\s*$//;					# Remove trailing directory separator.
			$dir =~ s/^([A-Z]):/\\\\$gSrvr\\$1\$/i;	# Replace drive name by administrative share
			if ( -e "$dir/perl.exe" ) { $perlExe = "$dir/perl.exe"; last; }
		}
	}

	if ($perlExe) {
		$verOut = `filever -V \"$perlExe\"`;
		if ($verOut =~ /ProductVersion\s+Build\s+(\d+)/i) {
			$gLOC_SRVR{PERL_VER_NBR} = $1;
		}
	}

	last SUB;
}

	&notifyWSub("Done");

	return ($status);
}	# getPerlVer

# ----------------------------------------------------------------------
#	getSharedDisk4VSQL		get shared disks for Virtual SQL Server
# ----------------------------------------------------------------------
#	arguments:
#		\@vslqDisk			reference to list of disks
#	return:
#		none
# ----------------------------------------------------------------------
#	get shared disks for Virtual SQL Server
# ----------------------------------------------------------------------

sub getSharedDisk4VSQL () {
	my $rVsqlDisk	= shift;	# Reference to @vsqlDisk.
	my $instName	= '';
	my $cmd			= 0;
	my $sql			= '';
	my @rsarr		= ();		# record set
	my $i			= 0;
	my $status		= 1;
	my $portNo 		= 0;

SUB:
{
	&notifyWSub("Started.");
	unless ($instName = getSQLInst4VirtualSrvr($gSrvr)) {
		&errme("Cannot get instance name for Virtual SQL Server $gSrvr.");
		$status = 0; $gNWarnings++;
		last SUB;
	}

	$sql = 'select DriveName from ::fn_servershareddrives()';

	# Cluster servers have always uses instances
	# Get the port number for the instance and pass
	# server name to adoconnect like "tcp:ServerName,PortNumber"
	#
	unless($portNo = &T38lib::Common::getSqlPort($gSrvr, $instName) ) {
		&errme("Cannot get port number for SQL Server instance $gSrvr.");
		$status = 0; 
		last SUB;
	}

	unless ($cmd = adoConnect("tcp:$gSrvr,$portNo", 'master')) {
		$status = 0; 
		last SUB;
	}
	unless (&execSQL2Arr($cmd, $sql, \@rsarr)) { $status = 0; $gNWarnings++; last SUB; }

	foreach $i (0..@rsarr-1) {
		push (@{$rVsqlDisk}, $rsarr[$i]{DriveName}) if ($rsarr[$i]{DriveName});
	}

	last SUB;
}	# SUB
# ExitPoint:
	if ($cmd)	{ 
		my $conn = $cmd->{ActiveConnection};
		if ($conn)	{ $conn->Close(); $conn = 0; }		# close the data source
		$cmd->Close(); $cmd = 0; 
	}

	&notifyWSub("Done");
	#&notifyWSub("Done. Status: $status.");
	
	return($status);
}	# getSharedDisk4VSQL


# ----------------------------------------------------------------------
#	getSQLInstLst	Get list of SQL Server instances on a server
# ----------------------------------------------------------------------
#	arguments:
#		instLst	reference to list of SQL Server instances
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub getSQLInstLst ($) {
	my $rInstLst	= shift;
	my @instLst		= ();
	my $machine		= ($gHostName eq $gSrvr) ? "": "//$gSrvr/";
	my $keyName		= '';
	my $instName	= '';
	my $dbmsVer		= '';
	my $hKey		= 0;
	my $status		= 1;
	my $regValue	= '';
	my %hinstlist = ();

SUB:
{
	&notifyWSub("Started.");

	if (getWinClusterName($gSrvr)) {
			unless ($instName = getSQLInst4VirtualSrvr($gSrvr) ) {
				&errme("Cannot get instance name for Virtual SQL Server $gSrvr.");
				$status = 0;
				last SUB;
			}
			$instLst[0] = $instName;
	} else {
		&T38lib::Common::getSQLInstLst(\%hinstlist, $gSrvr);
		foreach $instName (keys %hinstlist) { 
			push (@instLst, $instName); 
		}
	}

	foreach $instName (@instLst) {
		if ($instName)  {
			$$rInstLst{$instName}{LOC_SRVR_NM} = $gSrvr;
			$$rInstLst{$instName}{LOC_SRVR_DBINST_NM} = $instName;
			$dbmsVer = &getSQLInstVer($instName);
			$$rInstLst{$instName}{DBMS_VER_PATCH_ID} = ($dbmsVer) ? $dbmsVer : $T38ERROR;
		}
	}

	# Set DBMS_VER_ID, based on DBMS_VER_PATCH_ID.
	foreach $hKey (sort keys %{$rInstLst}) {
		$dbmsVer = $$rInstLst{$hKey}{DBMS_VER_PATCH_ID};
		if (defined $gDBMS_VER{$dbmsVer}) {
			$$rInstLst{$hKey}{DBMS_VER_ID} = $gDBMS_VER{$dbmsVer};
		} else {
			&errme("New DBMS Version is found on $gSrvr: $dbmsVer. Update $gScriptName and $gRepoSrvr.$gRepoDB.DBMS_VER.");
			$status = 0;
			last SUB;
		}
	}

	last SUB;
}

	&notifyWSub("Done");

	return ($status);
}	# getSQLInstLst


# ----------------------------------------------------------------------
#	getSQLInstVer	Get SQL Server Version for the instance
# ----------------------------------------------------------------------
#	arguments:
#		instanceName	SQL Server instance name. Default instance name
#						is NULL or MSSQLSERVER.
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub getSQLInstVer ($) {
	my $instanceName = shift;

	my $machine	= ($gHostName eq $gSrvr) ? "": "//$gSrvr/";
	my $sqlVer	= 0;
	my $x64Proc = &T38lib::Common::isX64Process();
	my $keyName	= "";

SUB:
{
	&notifyWSub("Started.");
	$keyName = ($instanceName && uc($instanceName) ne uc(DEFAULT_INST_NM)) ?
		"${machine}LMachine/Software/Microsoft/Microsoft SQL Server/$instanceName/MSSQLServer/CurrentVersion":
		"${machine}LMachine/Software/Microsoft/MSSQLServer/MSSQLServer/CurrentVersion";

	# AK
	if ($gx64flg != 1 || $x64Proc == 1) {
		if (defined($Registry->{$keyName}->{CSDVersion})) {
			$sqlVer = $Registry->{$keyName}->{CSDVersion};
		} elsif (defined($Registry->{$keyName}->{CurrentVersion})) {
			$sqlVer = $Registry->{$keyName}->{CurrentVersion};
		} else {
			&warnme("Cannot determine SQL Server version for $gSrvr\\$instanceName.");
			$gNWarnings++;
			$sqlVer = 0;
			last SUB;
		}
	}
	else {
		$keyName = ($instanceName && uc($instanceName) ne uc(DEFAULT_INST_NM)) ?
		"HKLM\\Software\\Microsoft\\Microsoft SQL Server\\$instanceName\\MSSQLServer\\CurrentVersion":
		"HKLM\\Software\\Microsoft\\MSSQLServer\\MSSQLServer\\CurrentVersion";
		$sqlVer = &T38lib::Common::regReadValExe("$keyName", "CurrentVersion", $gHostName);
	}


	last SUB;
}

	&notifyWSub("Done");

	return ($sqlVer);
}	# getSQLInstVer


# ----------------------------------------------------------------------
#	getSysInfoFile	Get file with system information
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	$servername.txt file is created by msinfo32.
# ----------------------------------------------------------------------
sub getSysInfoFile {
	my $computerArg	= ($gHostName eq $gSrvr) ? "" : "/computer $gSrvr";
	my $report		= "${gScriptPath}$gSrvr.txt";	# Stores output of winmsd command on NT 4.0
	# my $report		= "$gSrvr.txt";
	my $cmdOut		= "";
	my $status		= 1;

	SUB:
	{
		&notifyWSub("Started.");
		# We can use msinfo32 to collect server stats from local or remote computer. However it runs only
		# on Windows 2000 computer. On NT 4.0 we have to run winmsd and this will not collect required
		# information from remote server.
		# Check what we can use with current setup.

		if (($gHostName ne $gSrvr) && ($gSysInfo{OSVerLocal} !~ /^[5-9].\d/)) {
			&errme("Cannot collect remote server stats from NT 4.0 machine.");
			$status = 0;
			last SUB;
		}

		# remove old reports.

		unlink($report);

		if ($gSysInfo{OSVerLocal} =~ /^[5-9].\d/) {
			unless ($status = &getSysInfoWMI() ) {
				errme("Call to sub getSysInfoWMI failed.");
 			}
			last SUB;

		} elsif ($gSysInfo{OSVerLocal} eq "4.0") {
			my $winmsdExe = &whence("winmsd.exe");
			unless ($status = &execOSCmd($winmsdExe, " /f") ) { 
				last SUB;
	 		} 
		} else {
			errme("$gSysInfo{OSVerLocal} is invalid OS Version.");
			$status = 0;
			last SUB;
		}

		unless (&parseSysInfoWinmsd($report)) { 
			$status = 0; 
			last SUB;
 		}

		unless (&chkDrvInfo()) {
			$status = 0;
			last SUB;
 		}

		unlink($report);
		last SUB;
	} # End of SUB

	&notifyWSub("Done");

	return ($status);

}	# getSysInfoFile

# ----------------------------------------------------------------------
#	getSysInfoReg	Get system information from registry.
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate global %gSysInfo structure.
# ----------------------------------------------------------------------

sub getSysInfoReg {
	my $machine	= ($gHostName eq $gSrvr) ? "": "//$gSrvr/";
	my $status	= 1;
	my $keyName	= "";
SUB:
{
	&notifyWSub("Started.");
	# Various NT System information is stored in following registry entries:
	# SysterRoot: HKLM/Software/Microsoft/Windows NT/CurrentVersion/SystemRoot (D:\WinNT)
	# ProgramFilesDir: HKLM/Software/Microsoft/Windows/CurrentVersion/ProgramFilesDir (D:\Program Files)
	# OS Version: HKLM/Software/Microsoft/Windows NT/CurrentVersion/CurrentVersion (5.0, 4.0)
	# Path: HKLM/System/CurrentControlSet/Control/Session Manager/Environment/Path

	$keyName	= "${machine}LMachine/Software/Microsoft/Windows NT/CurrentVersion/SystemRoot";
	if (defined($Registry->{$keyName})) {
		$gSysInfo{SystemRoot} = $Registry->{$keyName};
	} else {
		&errme("Registry value $keyName is unaccessible.");
		$status = 0;
		last SUB;
	}

	$keyName	= "${machine}LMachine/Software/Microsoft/Windows/CurrentVersion/ProgramFilesDir";
	if (defined($Registry->{$keyName})) {
		$gSysInfo{ProgramFilesDir} = $Registry->{$keyName};
	} else {
		&errme("Registry value $keyName is unaccessible.");
		$status = 0;
		last SUB;
	}

	$keyName	= "${machine}LMachine/Software/Microsoft/Windows NT/CurrentVersion/CurrentVersion";
	if (defined($Registry->{$keyName})) {
		$gSysInfo{OSVersion} = $Registry->{$keyName};
	} else {
		&errme("Registry value $keyName is unaccessible.");
		$status = 0;
		last SUB;
	}

	$keyName	= "LMachine/Software/Microsoft/Windows NT/CurrentVersion/CurrentVersion";
	if (defined($Registry->{$keyName})) {
		$gSysInfo{OSVerLocal} = $Registry->{$keyName};
	} else {
		&errme("Registry value $keyName is unaccessible.");
		$status = 0;
		last SUB;
	}

	$gSysInfo{SystemDrive} = substr($gSysInfo{SystemRoot}, 0, 2);

	$keyName	= "${machine}LMachine/System/CurrentControlSet/Control/Session Manager/Environment/Path";
	if (defined($Registry->{$keyName})) {
		$gSysInfo{EnvPath} = $Registry->{$keyName};
	} else {
		&errme("Registry value $keyName is unaccessible.");
		$status = 0;
		last SUB;
	}

	my $envPath		= $gSysInfo{EnvPath};
	my $envVar		= '';
	my $envVarVal	= '';
	while ($gSysInfo{EnvPath} =~ /%([^%]+)%/gc) {
		$envVar		= $1;
		$envVarVal	= '';
		$envVar =~ s/%//g;
		if (uc($envVar) eq "SYSTEMDRIVE") {
			$envVarVal = $gSysInfo{SystemDrive};
		} elsif (uc($envVar) eq "SYSTEMROOT") {
			$envVarVal = $gSysInfo{SystemRoot};
		} else {
			$keyName	= "${machine}LMachine/System/CurrentControlSet/Control/Session Manager/Environment/$envVar";
			$envVarVal = $Registry->{$keyName}	if (defined($Registry->{$keyName}));
		}

		$envPath =~ s/%$envVar%/$envVarVal/g	if ($envVarVal);
	}

	$gSysInfo{EnvPath} = $envPath;

	# Debug code.

	my $debug = 0;
	if ($debug || $main::gDebug) {
		&notifyWSub("gHostname: $gHostName, gSrvr: $gSrvr");
		&notifyWSub("gSysInfo:");
		&debugPrintHash(\%gSysInfo);
	}
	# End Debug code.


	last SUB;
}

	&notifyWSub("Done");

	return ($status);
}	# getSysInfoReg

# ----------------------------------------------------------------------
#	loadSrvStats	Load Server statistics into %gLOC_SRVR
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate global %gLOC_SRVR structure.
# ----------------------------------------------------------------------

sub loadSrvStats {
	my	$status	= 1;
SUB:
{
	&notifyWSub("Started.");
	&notifyWSub("Get Server Information: OS Patch, ip address, MDAC version.");
	unless (&getOsVerPatch())		{ $status = 0; last SUB; }
	unless (&getIpAddress())	{ $status = 0; last SUB; }
	unless (&getMDACVer())		{ $status = 0; last SUB; }
	# unless (&getServicesStat())	{ $status = 0; last SUB; }
	unless (&getPerlVer())		{ $status = 0; last SUB; }
	# unless (&getPerfMonStat())	{ $status = 0; last SUB; }
	last SUB;
}

	&notifyWSub("Done");

	return ($status);
}	# loadSrvStats

# ----------------------------------------------------------------------
#	Get System info using WMI, CPU, DISK...
# ----------------------------------------------------------------------
#	arguments:
#		None
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate global %gLOC_SRVR structure.
# ----------------------------------------------------------------------
sub getSysInfoWMI () {

	my $status			= 1;
	my @vsqlDisk		= ();
	my $isSQLCluster	= getWinClusterName($gSrvr);
	my ($WMI, $Services, $sys_set, $sys, $processor_set, $proc);
	my ($os_set, $os, $ldisk_set, $ldisk, $oneMB);
	my ($driveName, $ldisk_DriveType, $ldisk_Size, $bival, $diskSize);
	my ($ldisk_FreeSpace, $bival, $freeSpace, $mhzFrReg, $key );

	&notifyWSub("Started.");
	&notifyWSub("Getting System Information Using WMI");
	
	# One megabyte, stored as BigInt for calculating disk space.
	$oneMB= Math::BigInt->new(1024*1024);	

	# Default row for LOC_SRVR_DRV table.
	%gLOC_SRVR_DRV	= (LOC_SRVR_NM				=> $gSrvr,
							LOC_SRVR_DRV_NM		=> $T38ERROR,
							SRVR_RAID_TYP			=> $T38ERROR,
							DRV_TOT_SPACE_QTY		=> $T38ERROR,
							DRV_AVAIL_SPACE_QTY	=> $T38ERROR,
							DRV_SPACE_UOM			=> $T38ERROR);
	$gLOC_SRVR{LOC_SRVR_CLUSTER_FLG} = ($isSQLCluster) ? 'Y':'N';

	BLOCK: {

		unless ($WMI = Win32::OLE->new('WbemScripting.SWbemLocator') ) {
			$status = 0;
			last BLOCK;
		}

		unless ($Services = $WMI->ConnectServer($gLOC_SRVR_DRV{LOC_SRVR_NM}) )  {
			$status = 0;
			last BLOCK;
		}

		# Gather Computer System Information
		$sys_set = $Services->InstancesOf("Win32_ComputerSystem");

		foreach $sys (in($sys_set)) {  
			$gLOC_SRVR{LOC_SRVR_CPU_QTY}  = $sys->{'NumberOfProcessors'};
		}

		# Gather Processor Information
		$processor_set = $Services->InstancesOf("Win32_Processor");

		foreach $proc (in($processor_set)) {
#			While doing the test current clock speed has the correct value
#			MaxClockSpeed some time came with a value of zero.
#			$gLOC_SRVR{LOC_SRVR_MAX_CPU_SPD} = $proc->{'MaxClockSpeed'};
			$gLOC_SRVR{LOC_SRVR_CPU_SPD}		= $proc->{'CurrentClockSpeed'};

		}
	
		# Get the CPU speed from registry
		unless ($mhzFrReg = &getCPUSpeedReg) {
			errme("Call to sub getCPUSpeedReg failed.");
			$status = 0;
			last BLOCK;
		}

		# If os report wrong CPU Speed then use the CPU speed from registry
		if ( ($gLOC_SRVR{LOC_SRVR_CPU_SPD} >= 32000) or ($gLOC_SRVR{LOC_SRVR_CPU_SPD} == 0) ) {
			if ( $mhzFrReg > 0 ) {
				$gLOC_SRVR{LOC_SRVR_CPU_SPD}		= $mhzFrReg;
			}
			else {
				errme("Invalid CPU speed...");
				$status = 0;
				last BLOCK;
			}
		}

		# Gather Operating System Information
		$os_set = $Services->InstancesOf("Win32_OperatingSystem");
		foreach $os (in($os_set)) {
			$gOS_VER{OS_TYP_DESC}         = $os->{'Caption'};
			$gLOC_SRVR{LOC_SRVR_MEM_SIZE} = $os->{'TotalVisibleMemorySize'};
			$gLOC_SRVR{MEM_SIZE_UOM} = "KB";
		}

		# Gather Disk Information

		# If it is clustered server, get list of shared disks that Virtual 
		# SQL Server can use.

		&getSharedDisk4VSQL(\@vsqlDisk)	if ( $isSQLCluster );
		
		# Get disk information via WMI.

		$ldisk_set= $Services->InstancesOf("Win32_LogicalDisk");

		foreach $ldisk (in($ldisk_set)) 
		{
			$driveName      		= substr($ldisk->{'DeviceId'}, 0,1);
			$ldisk_DriveType		= $ldisk->{'DriveType'};

			# Disk size is in K bytes change it to MB
			$ldisk_Size				= $ldisk->{'Size'};
			$bival = Math::BigInt->new($ldisk_Size);
			$diskSize = $bival->bdiv($oneMB);
			$diskSize =~ s/^\+|\-//g;
		
			# Free space is in K bytes change it to MB
			$ldisk_FreeSpace		= $ldisk->{'FreeSpace'};
			$bival = Math::BigInt->new($ldisk_FreeSpace);
			$freeSpace = $bival->bdiv($oneMB);
			$freeSpace =~ s/^\+|\-//g;

			# If the disk is a Local Fix disk, store information to the hash
			# Also if collecting datat for a clustered server, check if disk
			# is one of the shared disk for vsql.
			
			if ($ldisk_DriveType == 3 && 
				( (!$isSQLCluster) || ( grep( uc($_) eq uc($driveName), @vsqlDisk) ) )
				) {
				%gLOC_SRVR_DRV	= (
									LOC_SRVR_NM			=> $gSrvr,
									LOC_SRVR_DRV_NM		=> $driveName,
									SRVR_RAID_TYP		=> $T38ERROR,
									DRV_TOT_SPACE_QTY	=> $diskSize,
									DRV_AVAIL_SPACE_QTY	=> $freeSpace,
									DRV_SPACE_UOM		=> "MB");
			
				# Copy the disk drive info to global hash, so it can be written 
				# to the database
				foreach $key (keys(%gLOC_SRVR_DRV)) {
					$gListLOC_SRVR_DRV{$gLOC_SRVR_DRV{LOC_SRVR_DRV_NM}}{$key} = $gLOC_SRVR_DRV{$key};
				}
			}

		}

		last BLOCK;
	} # End of BLOCK

	&notifyWSub("Done");

	return ($status);

} # End of getSysInfoWMI

# ----------------------------------------------------------------------
#	Get CPU speed from registry
# ----------------------------------------------------------------------
#	arguments:
#		None
#	return:
#		CPU Speed 	Success
#		0				Failure
# ----------------------------------------------------------------------
sub getCPUSpeedReg () {

	my $CPUSpeed	= 0;

	my $tmp	= 0;
	my $keyName	= "";

	&notifyWSub("Started.");
	$keyName = "//${gSrvr}/LMachine/HARDWARE/DESCRIPTION/System/CentralProcessor/0";

	if (defined($Registry->{$keyName}->{'~Mhz'})) {
		$tmp = $Registry->{$keyName}->{'~Mhz'};
		$CPUSpeed = hex($tmp);
	}

	&notifyWSub("Done");

	return ($CPUSpeed);

}	# End getCPUSpeedReg 

# ----------------------------------------------------------------------
#	parseSysInfoMsinfo	Parse system info file, created with msinfo32.
# ----------------------------------------------------------------------
#	arguments:
#		System Information file name
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate global %gLOC_SRVR structure.
# ----------------------------------------------------------------------

sub parseSysInfoMsinfo ($) {
	my $sysinfo		= shift;
	my $section		= '';
	my $sysname		= '';
	my $cpuCnt		= 0;
	my $driveName	= "";
	my $locDiskFlg	= 0;
	my $status		= 1;
SUB:
{
	&notifyWSub("Started.");
	&notifyWSub("Parsing $sysinfo");
	%gLOC_SRVR_DRV	= (						# Default row for LOC_SRVR_DRV table.
					LOC_SRVR_NM				=> $gSrvr,
					LOC_SRVR_DRV_NM			=> $T38ERROR,
					SRVR_RAID_TYP			=> $T38ERROR,
					DRV_TOT_SPACE_QTY		=> $T38ERROR,
					DRV_AVAIL_SPACE_QTY		=> $T38ERROR,
					DRV_SPACE_UOM			=> $T38ERROR
					);
	unless (open(SYSINFO, $sysinfo)) { &errme("Cannot read file $sysinfo!"); $status = 0; last SUB; }
	while (<SYSINFO>) {
		if (/^\[(.*)\]$/) { 
			$section = $1;
			$driveName	= "";
			$locDiskFlg	= 0;
			next;
		}
		if (($section eq "System Summary") && /^System Name\s+(\S*)\s*$/i) {
			$sysname = uc($1);
			unless ($sysname eq $gSrvr) {
				&errme("Problem in system information file. System name in the file is $sysname, for server $gSrvr.");
				$status = 0;
				last SUB;
			}
			next;
		}
		if (($section eq "System Summary") && /^OS Name\s+(.+)\s*$/i) {
			$gOS_VER{OS_TYP_DESC} = $1;
			$gOS_VER{OS_TYP_DESC} =~ s/\s+/ /g;

			# Since winmsd reports all server editions the same, we have to do the same in msinfo32.
			$gOS_VER{OS_TYP_DESC} =~ s/Microsoft Windows NT \S* Server/Microsoft Windows NT Server/i;

			next;
		}
		if (($section eq "System Summary") && /^Processor\s+.*[^\d](\d+)\s+(\S+)\s*$/i) {
			$cpuCnt++;
			if ($cpuCnt == 1) {
				if (uc($2) ne 'MHZ') {
					&warnme("Check measurement units for CPU speed in $sysinfo. Update $gScriptName with new unit.");
					$gNWarnings++;
				}
				$gLOC_SRVR{LOC_SRVR_CPU_SPD} = $1;
			}
			next;
		}
		if (($section eq "System Summary") && /^Total Physical Memory\s+([\d,.]+)\s*(\S+)\s*$/i) {
			my	$memSizeUOM	= uc($2);
			if ($memSizeUOM ne 'KB' and $memSizeUOM ne 'MB') {
				warnme("Check measurement units for Physical Memory in $sysinfo. It should be KB. Update $gScriptName with new unit.");
				$gNWarnings++;
			}
			($gLOC_SRVR{LOC_SRVR_MEM_SIZE} = $1) =~ s/,//g;
			$gLOC_SRVR{MEM_SIZE_UOM} = $memSizeUOM;
			next;
		}
		if (($section eq "Drives") && /^Drive\s+([A-Z]):\s*$/i) {
			$driveName = uc($1);
			$locDiskFlg	= 0;

			# We have new drive. If we already processed one drive, add
			# it to the list.

			if ($gLOC_SRVR_DRV{LOC_SRVR_DRV_NM} ne $T38ERROR) {
				# Add this drive to our list.
				my $key;
				foreach $key (keys(%gLOC_SRVR_DRV)) {
					$gListLOC_SRVR_DRV{$gLOC_SRVR_DRV{LOC_SRVR_DRV_NM}}{$key} = $gLOC_SRVR_DRV{$key};
				}
			}
			next;
		}
		if (($section eq "Drives") && $driveName && /^Description\s+Local Fixed Disk\s*$/i) {
			$locDiskFlg = 1;

			# We have new logical drive. Initialize LOC_SRVR_DRV record.

			%gLOC_SRVR_DRV	= (
							LOC_SRVR_NM				=> $gSrvr,
							LOC_SRVR_DRV_NM			=> $driveName,
							SRVR_RAID_TYP			=> $T38ERROR,
							DRV_TOT_SPACE_QTY		=> $T38ERROR,
							DRV_AVAIL_SPACE_QTY		=> $T38ERROR,
							DRV_SPACE_UOM			=> "MB"
							);
			next;
		}
		if (($section eq "Drives") && $driveName && $locDiskFlg && /^Size\s+.*\((\d[\d,]*) byte.*\)\s*$/i) {
			($gLOC_SRVR_DRV{DRV_TOT_SPACE_QTY} = $1) =~ s/,//g;
			$gLOC_SRVR_DRV{DRV_TOT_SPACE_QTY} = int($gLOC_SRVR_DRV{DRV_TOT_SPACE_QTY}/(1024*1024));
			next;
		}
		if (($section eq "Drives") && $driveName && $locDiskFlg && /^Free Space\s+.*\s\(?(\d[\d,]*) byte[s\)\s]*$/i) {
			($gLOC_SRVR_DRV{DRV_AVAIL_SPACE_QTY} = $1) =~ s/,//g;
			$gLOC_SRVR_DRV{DRV_AVAIL_SPACE_QTY} = int($gLOC_SRVR_DRV{DRV_AVAIL_SPACE_QTY}/(1024*1024));
			next;
		}
	}

	unless ($sysname) {
		&errme("Problem in system information file. System name is not in the $sysname.");
		$status = 0;
		last SUB;
	}

	# Update CPU count.
	if ($cpuCnt) { $gLOC_SRVR{LOC_SRVR_CPU_QTY} = $cpuCnt; }

	# Add last drive, if needed.
	if (
		$gLOC_SRVR_DRV{LOC_SRVR_DRV_NM} ne $T38ERROR && 
		!defined($gListLOC_SRVR_DRV{$gLOC_SRVR_DRV{LOC_SRVR_DRV_NM}})) {

		my $key;
		foreach $key (keys(%gLOC_SRVR_DRV)) {
			$gListLOC_SRVR_DRV{$gLOC_SRVR_DRV{LOC_SRVR_DRV_NM}}{$key} = $gLOC_SRVR_DRV{$key};
		}
	}
	last SUB;
}
	close(SYSINFO);

	&notifyWSub("Done");

	return ($status);
}	# parseSysInfoMsinfo


# ----------------------------------------------------------------------
#	parseSysInfoWinmsd	Parse system info file, created with winmsd.
# ----------------------------------------------------------------------
#	arguments:
#		System Information file name
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate global %gLOC_SRVR and @gLOC_SRVR_DRV.
# ----------------------------------------------------------------------

sub parseSysInfoWinmsd ($) {
	my $sysinfo		= shift;
	my $section		= '';
	my $sysname		= '';
	my $cpuCnt		= 0;
	my $driveName	= "";
	my $locDiskFlg	= 0;
	my $status		= 1;
SUB:
{
	&notifyWSub("Started.");
	&notifyWSub("Parsing $sysinfo");
	%gLOC_SRVR_DRV	= (						# Default row for LOC_SRVR_DRV table.
					LOC_SRVR_NM				=> $gSrvr,
					LOC_SRVR_DRV_NM			=> $T38ERROR,
					SRVR_RAID_TYP			=> $T38ERROR,
					DRV_TOT_SPACE_QTY		=> $T38ERROR,
					DRV_AVAIL_SPACE_QTY		=> $T38ERROR,
					DRV_SPACE_UOM			=> $T38ERROR
					);
	unless (open(SYSINFO, $sysinfo)) { &errme("Cannot read file $sysinfo!"); $status = 0; last SUB; }
	while (<SYSINFO>) {
		if (/^Microsoft Diagnostics Report For \\\\(.*)\s*$/i) {
			$sysname = uc($1);
			unless ($sysname eq $gSrvr) {
				&errme("Problem in system information file. System name in the file is $sysname, for server $gSrvr.");
				$status = 0;
				last SUB;
			}
			next;
		}
		if (/OS Version Report/i) {
			# In OS Version report section. OS Descripiton is first line after the header.
			<SYSINFO>; 
			$_ = <SYSINFO>; 
			# Remove (R) and (TM)s. Also remove all extra spaces.
			s/\(R\)|\(TM\)//g;
			s/^\s*//; s/\s*$//;
			s/\s+/ /g;
			$gOS_VER{OS_TYP_DESC} = $_;
			next;
		}
		if (/Report$/i) {
			chomp;
			$section = $_;
			$_ = <SYSINFO>;
			unless (/^\-+$/) {
				&warnme("New formating is found for Section header in $sysinfo. Update $gScriptName before running it again.");
				&notifyMe("Invalid Section header: $section.");
				$gNWarnings++;
				$status = 0;
				last SUB;
			}
			$section = uc($section);
			next;
		}

		if ($section eq "SYSTEM REPORT" && /Processor list:/i) {
			$section = "Processor List";
			next;
		}
		if ($section eq "Processor List" && /^\s*\d+:.*[^\d](\d+)\s(\S+)\s*$/i) {
			$cpuCnt++;
			if ($cpuCnt == 1) {
				if (uc($2) ne 'MHZ') {
					warnme("Check measurement units for CPU speed in $sysinfo. Update $gScriptName with new unit.");
					$gNWarnings++;
				}
				$gLOC_SRVR{LOC_SRVR_CPU_SPD} = $1;
			}
			next;
		}
		if ($section eq "Processor List" && /^\s*\-+\s*$/i) {
			# End of the "Processor List" section.
			$section = "";
			next;
		}
		if ($section eq "MEMORY REPORT" && /^Physical Memory \((.+)\)\s*$/i) {
			if (uc($1) ne 'K') {
				warnme("Check measurement units for Physical Memory in $sysinfo. It should be K. Update $gScriptName with new unit.");
				$gNWarnings++;
			}
			$section = "Physical Memory";
			next;
		}
		if (($section eq "Physical Memory") && /^\s*Total:\s+([\d,]+)\s*$/i) {
			($gLOC_SRVR{LOC_SRVR_MEM_SIZE} = $1) =~ s/,//g;
			$gLOC_SRVR{MEM_SIZE_UOM} = "KB";
			next;
		}
		if ($section eq "DRIVES REPORT" && /^([A-Z]):\\\s+\(Local .*Total:\s+([\d,]+) (.*),\s+Free:\s+([\d,]+) (.*)\s*$/i) {
			if (uc($3) ne 'KB' || uc($5) ne 'KB') {
				warnme("Check measurement units in Drives Report section for $sysinfo. It should be KB. Update $gScriptName with new unit.");
				$gNWarnings++;
			}
			%gLOC_SRVR_DRV	= (
							LOC_SRVR_NM				=> $gSrvr,
							LOC_SRVR_DRV_NM			=> uc($1),
							SRVR_RAID_TYP			=> $T38ERROR,
							DRV_TOT_SPACE_QTY		=> $2,
							DRV_AVAIL_SPACE_QTY		=> $4,
							DRV_SPACE_UOM			=> "KB"
							);
			$gLOC_SRVR_DRV{DRV_TOT_SPACE_QTY} =~ s/,//g;
			$gLOC_SRVR_DRV{DRV_TOT_SPACE_QTY} = int($gLOC_SRVR_DRV{DRV_TOT_SPACE_QTY}/1024);
			$gLOC_SRVR_DRV{DRV_AVAIL_SPACE_QTY} =~ s/,//g;
			$gLOC_SRVR_DRV{DRV_AVAIL_SPACE_QTY} = int($gLOC_SRVR_DRV{DRV_AVAIL_SPACE_QTY}/1024);
			$gLOC_SRVR_DRV{DRV_SPACE_UOM} = "MB";

			my $key;
			foreach $key (keys(%gLOC_SRVR_DRV)) {
				$gListLOC_SRVR_DRV{$gLOC_SRVR_DRV{LOC_SRVR_DRV_NM}}{$key} = $gLOC_SRVR_DRV{$key};
			}
			next;
		}

	} # while (<SYSINFO>)

	if ($cpuCnt) { $gLOC_SRVR{LOC_SRVR_CPU_QTY} = $cpuCnt; }
	unless ($sysname) {
		&errme("Problem in system information file. System name is not in the $sysname.");
		$status = 0;
		last SUB;
	}

	last SUB;
}
	close(SYSINFO);

	&notifyWSub("Done");

	return ($status);
}	# parseSysInfoWinmsd


#------------------------------------------------------------------------------
#	Purpose: Read the configuration file(s) T38dba.cfg, NBA.cfg, userdb.cfg
#            Set up global variables with the values read from CFG file(s).
#------------------------------------------------------------------------------

sub readConfigFile($) {
	my $cfgFile	= shift;
	my %configValues= ();
SUB:
{
	&notifyWSub("Started.");
	&notifyWSub("START - Reading cfg files.");
	unless (open(CFGFILE, $cfgFile)) { &warnme("Cannot read file $cfgFile!"); $gNWarnings++; last SUB; }

	while  (<CFGFILE>) {						# read the input file line by line
		chomp();							# Get rid of new line character
		if ( /^\#/ or /^$/ ) {		# Skip comment and blank lines
			next;
		}

		$_ =~ s/\#.*$//g;				# Remove comments
	    $_ =~ s/^\s*//g;				# Remove all leading white spaces
	    $_ =~ s/\s*$//g;				# Remove all trailing white spaces

		if (/^(\S+)\s*=\s*(\S+.*)$/) {
			# cfg variable has a value defined and it is assigned to global hash
			#
			$configValues{$1}=$2;
		} elsif (/^(\S+)\s*=$/) {
			# cfg variable has NO values defined so global hash is initilized
			#
			$configValues{$1}="";
		}
	}

	$gRepoSrvr 	= uc($configValues{RepositoryServerName})	if (defined($configValues{RepositoryServerName}) && $configValues{RepositoryServerName});
	$gRepoDB 	= $configValues{RepositoryDBName}			if (defined($configValues{RepositoryDBName}) && $configValues{RepositoryDBName});
	$gEnvrTyp 	= uc($configValues{EnvironmentType})		if (defined($configValues{EnvironmentType}) && $configValues{EnvironmentType});
	$gSecGrpLoc	= uc($configValues{SecurityGroupLocation})	if (defined($configValues{SecurityGroupLocation}) && $configValues{SecurityGroupLocation});
	last SUB;
}
	close(CFGFILE);

	&notifyWSub("Done");

	#&notifyWSub("DONE - Reading cfg files.");
	
	return(1);	
} # readConfigFile

# ----------------------------------------------------------------------
#	updateCurrentDB	update LOC_SRVR_DBINST_DB
# ----------------------------------------------------------------------
#	arguments:
#		command object
#		LOC_SRVR_DBINST record
#		LOC_SRVR_DBINST_DB	record
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	LOC_SRVR_DBINST_DB record is updated in database.
# ----------------------------------------------------------------------

sub updateCurrentDB (\%\%\%) {
	my $cmd					= shift;
	my $rLOC_SRVR_DBINST	= shift;
	my $dbRec				= shift;
	my $sql					= "";		# SQL statements
	my $lLOC_SRVR_NM		= $$rLOC_SRVR_DBINST{LOC_SRVR_NM};
	my $lLOC_SRVR_DBINST_NM = $$rLOC_SRVR_DBINST{LOC_SRVR_DBINST_NM};
	my $lDBMS_VER_ID		= $$rLOC_SRVR_DBINST{DBMS_VER_ID};
	my $lLOC_SRVR_DBINST_DB_NM
							= $$dbRec{dbName};
	my $lDB_SORT_ORDER_ID	= $$dbRec{sortId};
	my $lDB_SORT_ORDER_TYP	= $$dbRec{sortTyp};
	my $lDB_TOT_SPACE_QTY	= $$dbRec{totalSpc};
	my $lDB_USE_SPACE_QTY	= $$dbRec{usedSpc};
	my $status			= 1;
	my $debug			= 0;

	#---------------------------------------------------#
	# 	SQL Server 2000 databases status bits:          #
	#                                                   #
	# 	1 = autoclose; set with sp_dboption.            #
	# 	4 = select into/bulkcopy; set with sp_dboption. #
	# 	8 = trunc. log on chkpt; set with sp_dboption.  #
	# 	16 = torn page detection, set with sp_dboption. #
	# 	32 = loading.                                   #
	# 	64 = pre recovery.                              #
	# 	128 = recovering.                               #
	# 	256 = not recovered.                            #
	# 	512 = offline; set with sp_dboption.            #
	# 	1024 = read only; set with sp_dboption.         #
	# 	2048 = dbo use only; set with sp_dboption.      #
	# 	4096 = single user; set with sp_dboption.       #
	# 	32768 = emergency mode.                         #
	# 	4194304 = autoshrink.                           #
	# 	1073741824 = cleanly shutdown.                  #
	#                                                   #
	# 	Multiple bits can be on at the same time.       #
	#---------------------------------------------------#

	my $lDB_BULK_COPY_FLG	= ($$dbRec{dbStatus} & 4) ? 'Y' : 'N';
	my $lDB_TRUNC_CHKPNT_FLG= ($$dbRec{dbStatus} & 8) ? 'Y' : 'N';
SUB:
{
	&notifyWSub("Started.");
	$sql = <<"EOT";
	declare
		\@locSrvrNm		char(18),
		\@dbInstNm		char(15),
		\@actvFlg		char(1),
		\@bulkCopyFlg	char(1),
		\@truncCPFlg	char(1),
		\@usedSpc		decimal(9,2),
		\@totalSpc		decimal(9,2),
		\@sortOrderId	int,
		\@sortOrderTyp	varchar(20)


	select \@locSrvrNm = LOC_SRVR_NM,
		\@actvFlg		= DB_ACTV_FLG,
		\@sortOrderId	= DB_SORT_ORDER_ID,
		\@sortOrderTyp	= DB_SORT_ORDER_TYP,
		\@usedSpc		= DB_USE_SPACE_QTY,
		\@totalSpc		= DB_TOT_SPACE_QTY,
		\@bulkCopyFlg	= DB_BULK_COPY_FLG,
		\@truncCPFlg	= DB_TRUNC_CHKPNT_FLG
	from LOC_SRVR_DBINST_DB
	where LOC_SRVR_NM = '$lLOC_SRVR_NM'
	and LOC_SRVR_DBINST_NM = '$lLOC_SRVR_DBINST_NM'
	and LOC_SRVR_DBINST_DB_NM = '$lLOC_SRVR_DBINST_DB_NM'

	if (\@locSrvrNm is not NULL)
	begin
		if (
			\@actvFlg		!= 'Y' OR
			\@sortOrderId	!= $lDB_SORT_ORDER_ID OR
			\@sortOrderTyp	!= '$lDB_SORT_ORDER_TYP' OR
			\@usedSpc		!= $lDB_USE_SPACE_QTY OR
			\@totalSpc		!= $lDB_TOT_SPACE_QTY OR
			\@bulkCopyFlg	!= '$lDB_BULK_COPY_FLG' OR
			\@truncCPFlg	!= '$lDB_TRUNC_CHKPNT_FLG' OR
			\@usedSpc is NULL or
			\@totalSpc is NULL
		)
		begin
			update LOC_SRVR_DBINST_DB set
			DB_ACTV_FLG			= 'Y',
			DB_SORT_ORDER_ID	= $lDB_SORT_ORDER_ID,
			DB_SORT_ORDER_TYP	= '$lDB_SORT_ORDER_TYP',
			DB_USE_SPACE_QTY	= $lDB_USE_SPACE_QTY,
			DB_TOT_SPACE_QTY	= $lDB_TOT_SPACE_QTY,
			DB_BULK_COPY_FLG	= '$lDB_BULK_COPY_FLG',
			DB_TRUNC_CHKPNT_FLG	= '$lDB_TRUNC_CHKPNT_FLG',
			REC_UPD_TS = getdate(), REC_UPD_USR_ID = system_user, REC_UPD_PGM_ID = app_name()
		where LOC_SRVR_NM = '$lLOC_SRVR_NM'
		and LOC_SRVR_DBINST_NM = '$lLOC_SRVR_DBINST_NM'
		and LOC_SRVR_DBINST_DB_NM = '$lLOC_SRVR_DBINST_DB_NM'
		select 'LOC_SRVR_DBINST_DB is updated for $lLOC_SRVR_NM\\$lLOC_SRVR_DBINST_NM'
		end
	end
	else 
	begin
		insert into LOC_SRVR_DBINST_DB(
			LOC_SRVR_NM, LOC_SRVR_DBINST_NM, LOC_SRVR_DBINST_DB_NM, 
			DB_SORT_ORDER_ID, DB_SORT_ORDER_TYP, 
			DB_TOT_SPACE_QTY, DB_USE_SPACE_QTY,
			DB_BULK_COPY_FLG, DB_TRUNC_CHKPNT_FLG
			)
		values (
			'$lLOC_SRVR_NM', '$lLOC_SRVR_DBINST_NM', '$lLOC_SRVR_DBINST_DB_NM',
			$lDB_SORT_ORDER_ID, '$lDB_SORT_ORDER_TYP',
			$lDB_TOT_SPACE_QTY, $lDB_USE_SPACE_QTY,
			'$lDB_BULK_COPY_FLG', '$lDB_TRUNC_CHKPNT_FLG'
			)
		select 'New LOC_SRVR_DBINST_DB is created for $lLOC_SRVR_NM\\$lLOC_SRVR_DBINST_NM'
	end
EOT
;

	unless (&execSQLBat($cmd, $sql)) { $status = 0; last SUB; }
	last SUB;
}

	&notifyWSub("Done");

	return ($status);
}	# updateCurrentDB


# ----------------------------------------------------------------------
#	updateCurrentInst	update LOC_SRVR_DBINST
# ----------------------------------------------------------------------
#	arguments:
#		command object
#		LOC_SRVR_DBINST	record
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	LOC_SRVR_DBINST records are updated in database.
# ----------------------------------------------------------------------

sub updateCurrentInst (\%\%) {
	my $cmd					= shift;
	my $rLOC_SRVR_DBINST	= shift;

	my $sql					= "";		# SQL statements
	my $lLOC_SRVR_NM		= $$rLOC_SRVR_DBINST{LOC_SRVR_NM};
	my $lLOC_SRVR_DBINST_NM = $$rLOC_SRVR_DBINST{LOC_SRVR_DBINST_NM};
	my $lDBMS_VER_ID		= $$rLOC_SRVR_DBINST{DBMS_VER_ID};
	my $lEnvrTyp			= ($gEnvrTyp eq $T38ERROR) ? "NULL" : "\'$gEnvrTyp\'";
	my $lSecGrpLoc			= ($gSecGrpLoc eq $T38ERROR) ? "NULL" : "\'$gSecGrpLoc\'";
	my $status			= 1;
	my $debug			= 0;
SUB:
{
	&notifyWSub("Started.");
	$sql =
		"declare\n" .
		'	@locSrvrNm		char(18),' . "\n" .
		'	@actvFlg		char(1),' . "\n" .
		'	@dbmsVerId		int' . "\n" .
		"\n" .
		'select @locSrvrNm = LOC_SRVR_NM,' . "\n" .
		'	@actvFlg = DBINST_ACTV_FLG,' . "\n" .
		'	@dbmsVerId = DBMS_VER_ID' . "\n" .
		"from LOC_SRVR_DBINST\n" .
		"where LOC_SRVR_NM = '$lLOC_SRVR_NM'\n" .
		"and LOC_SRVR_DBINST_NM = '$lLOC_SRVR_DBINST_NM'\n" .
		"\n".
		'if (@locSrvrNm is not NULL)' . "\n" .
		"begin\n" .
		"	if (\@dbmsVerId != $lDBMS_VER_ID)\n" .
		"	begin\n" .
		"		update LOC_SRVR_DBINST set\n" .
		"		DBMS_VER_ID = $lDBMS_VER_ID, \n" .
		"		DBINST_ACTV_FLG = 'Y', \n" .
		"		REC_UPD_TS = getdate(), REC_UPD_USR_ID = system_user, REC_UPD_PGM_ID = app_name() \n" .
		"	where LOC_SRVR_NM = '$lLOC_SRVR_NM'\n" .
		"	and LOC_SRVR_DBINST_NM = '$lLOC_SRVR_DBINST_NM'\n" .
		"	select 'LOC_SRVR_DBINST.DBMS_VER_ID is updated for $lLOC_SRVR_NM\\$lLOC_SRVR_DBINST_NM'\n" .
		"	end\n" .
		"	else if (\@actvFlg = 'N')\n" .
		"	begin\n" .
		"		update LOC_SRVR_DBINST set\n" .
		"		DBINST_ACTV_FLG = 'Y', \n" .
		"		REC_UPD_TS = getdate(), REC_UPD_USR_ID = system_user, REC_UPD_PGM_ID = app_name() \n" .
		"	where LOC_SRVR_NM = '$lLOC_SRVR_NM'\n" .
		"	and LOC_SRVR_DBINST_NM = '$lLOC_SRVR_DBINST_NM'\n" .
		"	select 'LOC_SRVR_DBINST.DBMS_VER_ID is updated for $lLOC_SRVR_NM\\$lLOC_SRVR_DBINST_NM'\n" .
		"	end\n" .
		"end\n" .
		"else \n" .
		"begin\n" .
		"	insert into LOC_SRVR_DBINST(LOC_SRVR_NM, LOC_SRVR_DBINST_NM, DBMS_VER_ID, ENVR_TYP, SRVR_SCRTY_GRP_TYP)\n" .
		"	values ('$lLOC_SRVR_NM', '$lLOC_SRVR_DBINST_NM', $lDBMS_VER_ID, $lEnvrTyp, $lSecGrpLoc)\n" .
		"	select 'New LOC_SRVR_DBINST is created for $lLOC_SRVR_NM\\$lLOC_SRVR_DBINST_NM'\n" .
		"end"
		;

	unless (&execSQLBat($cmd, $sql)) { $status = 0; last SUB; }

	unless (&updateDBaseStats($cmd, $rLOC_SRVR_DBINST)) { 
		&warnme("Problems with updating database stats for $lLOC_SRVR_NM\\$lLOC_SRVR_DBINST_NM");
		&notifyMe("Processing will continue with next instance.");
		$gNWarnings++;
		$status = 1; last SUB; 
	}
	
	last SUB;
}

	&notifyWSub("Done");

	return ($status);
}	# updateCurrentInst


# ----------------------------------------------------------------------
#	updateDBaseStats update LOC_SRVR_DBINST_DB records for the instance
# ----------------------------------------------------------------------
#	arguments:
#		repository server command object
#		LOC_SRVR_DBINST	record
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	All LOC_SRVR_DBINST_DB records for the instance are updated.
# ----------------------------------------------------------------------

sub updateDBaseStats () {
	my $rCmd					= shift;
	my $rLOC_SRVR_DBINST	= shift;
	my $sql					= "";		# SQL statements
	my $sqlval				= "";		# list of values part for SQL statements
	my $lLOC_SRVR_NM		= $$rLOC_SRVR_DBINST{LOC_SRVR_NM};
	my $lLOC_SRVR_DBINST_NM = $$rLOC_SRVR_DBINST{LOC_SRVR_DBINST_NM};
	my $lDBMS_VER_PATCH_ID	= $$rLOC_SRVR_DBINST{DBMS_VER_PATCH_ID};
	my $dbSrvrName			= '';
	my ($dbmsVerMajor, $dbmsVerMinor, $dbmsVerPatch)
							= split('\.', $lDBMS_VER_PATCH_ID);
	my $rConn				= 0;		# connection object for repository server
	my $cmd					= 0;		# ADO Command object handle
	my $conn				= 0;		# ADO connection object handle
	my $rs					= 0;		# record set handle
	my @rsarr				= ();		# record set array
	my $sqlerr				= 0;
	my $caseTyp				= '';
	my $sortTyp				= '';
	my $dbName				= '';
	my %dbLst				= ();
	my $maxDbNameSz			= 256;
	my $status				= 1;
	my $debug				= 0;
	my $portNo				= 0;
	my ($srvr, $instName);
SUB:
{
	&notifyWSub("Started.");
	$dbSrvrName	=($gHostName eq $lLOC_SRVR_NM) ?  $lLOC_SRVR_NM : $lLOC_SRVR_NM;
	$dbSrvrName = (uc($lLOC_SRVR_DBINST_NM) eq uc(DEFAULT_INST_NM)) ? $dbSrvrName : "$dbSrvrName\\$lLOC_SRVR_DBINST_NM";

	# Get max size for database name.

	$sql = "select length as colsize from syscolumns where id = object_id('ADMTIDB') and name = 'LOC_SRVR_DBINST_DB_NM'";
	unless (&execSQL2Arr($rCmd, $sql, \@rsarr)) { $status = 0; last SUB; }
	$maxDbNameSz = $rsarr[0]{colsize};

	# Connect to monitored server.

	# if we have a instance name then get the port number
	# and pass server name "TCP:ServerName,PortNumber"
	#
	if ( $dbSrvrName =~ /\\/ ) {
		($srvr, $instName) = split (/\\/, $dbSrvrName);
		unless($portNo = &T38lib::Common::getSqlPort($srvr, $instName) ) {
			&errme("Cannot get port number for SQL Server instance $srvr.");
			$status = 0; 
			last SUB;
		}
		$dbSrvrName = "tcp:$srvr,$portNo";
	}

	unless ($cmd = adoConnect($dbSrvrName, '')) {
		$status = 0;
		last SUB;
	}

	if (uc($lLOC_SRVR_DBINST_NM) eq uc(DEFAULT_INST_NM)) {
		# Set sort order and character of the server, using information from default instance.
		if ($dbmsVerMajor < 8) {
			$sql = 
				'select "SortOrderName" = s.name, s.description' . "\n" .
				'	from master..syscharsets s, ' . "\n" .
				'	master..syscurconfigs' . "\n" .
				'	where s.id = value and config = 1123'
			;
		} else {
			$sql = 
				'select "SortOrderName" = name, description' . "\n" .
				'	from master..syscharsets' . "\n" .
				'	where id = convert(int, serverproperty(\'SQLSortOrder\'))'
			;
		}

		$cmd->{CommandText} = $sql;

		unless ($rs = $cmd->Execute()) { &errme("Error in SQL"); &notifyMe("\n$sql"); &showADOErrors($sqlerr); $status = 0; last SUB; }

		while(! $rs->EOF) {
			$sortTyp = $rs->Fields('SortOrderName')->Value;
			$caseTyp = ($rs->Fields('description')->Value =~ /case.insensitive/i) ? 'Insensitive' : 'Sensitive';
			$rs->MoveNext;
		}
		if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset

		# Update LOC_SRVR.

		$sql =
			"if not exists (\n" .
			"	select 1 from LOC_SRVR where LOC_SRVR_NM = '$lLOC_SRVR_NM'\n" .
			"	and (LOC_SRVR_CASE_TYP = '$caseTyp' AND LOC_SRVR_SORT_TYP = '$sortTyp')\n" .
			")\n" .
			"update LOC_SRVR set\n" .
			"	LOC_SRVR_CASE_TYP = '$caseTyp', LOC_SRVR_SORT_TYP = '$sortTyp',\n" .
			"	REC_UPD_TS = getdate(), REC_UPD_USR_ID = system_user, REC_UPD_PGM_ID = app_name() \n" .
			"where LOC_SRVR_NM = '$lLOC_SRVR_NM'"
			;
		unless (&execSQLCmd($rCmd, $sql)) { $status = 0; last SUB; }
	}

	# Collect statistics for each database.
	if ($dbmsVerMajor < 8) {
		$sql = <<'EOT';
/* SQL 7 and 6.5 */
select
	"dbname" = d.name, 
   "SortOrderName" = isnull(s.name, 'NA'), "SortOrderId" = isnull(s.id, 0),
	"dbstatus" = d.status
	from 
		(
		master..syscharsets s join 
		master..syscurconfigs c 
		on value = s.id and c.config = 1123)
	right outer join master..sysdatabases d 
	on 1 = 1
	where lower(d.name) not in  ('master', 'model', 'msdb', 'tempdb', 'northwind', 'pubs')
EOT
;
	} else {
		$sql = <<'EOT';
/* SQL 2000 */
select
	"dbname" = d.name, 
   "SortOrderName" = isnull(s.name, 'NA'), "SortOrderId" = isnull(s.id, 0),
	"dbstatus" = d.status
	from
		master..syscharsets s right outer join 
		master..sysdatabases d on s.id = convert(int, databasepropertyex(d.name, 'SQLSortOrder'))
	where 
	lower(d.name) not in ('master', 'model', 'msdb', 'tempdb', 'northwind', 'pubs')
EOT
;
	}

	$cmd->{CommandText} = $sql;

	unless ($rs = $cmd->Execute()) { &errme("Error in SQL"); &notifyMe("\n$sql"); &showADOErrors($sqlerr); $status = 0; last SUB; }

	while(! $rs->EOF) {
		$dbName		= $rs->Fields('dbname')->Value;
		$dbName		=~ s/\s*$//g;
		if (length($dbName) > $maxDbNameSz) {
			&warnme("Database $dbName on $$rLOC_SRVR_DBINST{LOC_SRVR_NM}\\$$rLOC_SRVR_DBINST{LOC_SRVR_DBINST_NM} cannot be stored in repository. Database name is longer than $maxDbNameSz characters.");
		} else {
			$dbLst{$dbName}{dbName}		= $dbName;
			$dbLst{$dbName}{sortTyp}	= $rs->Fields('SortOrderName')->Value;
			$dbLst{$dbName}{sortId}	= $rs->Fields('SortOrderId')->Value;
			$dbLst{$dbName}{totalSpc}	= 0;
			$dbLst{$dbName}{usedSpc}	= 0;
			$dbLst{$dbName}{dbStatus}	= $rs->Fields('dbstatus')->Value;
		}

		$rs->MoveNext;
	}
	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset

	# Get Database sizes.

	foreach $dbName (sort keys %dbLst) {
		unless ($status = &getDbSize($cmd, $rLOC_SRVR_DBINST, $dbLst{$dbName})) { last SUB; }
		# Debug code: &notifyMe("$dbName = $dbLst{$dbName}{totalSpc} / $dbLst{$dbName}{usedSpc}");
	}

	# Update LOC_SRVR_DBINST_DB.

	$sqlval = join(", ", map { "\'$_\'" } (keys %dbLst));
	if ($sqlval =~ /^\s*$/) {
		# We didn't find any user databases on a server. Create dummy name for the "in"
		# clause to mark all old databases as inactive.
		$sqlval = "''";
	}
	$sql = 
		"update LOC_SRVR_DBINST_DB set DB_ACTV_FLG = 'N',\n" .
		"		REC_UPD_TS = getdate(), REC_UPD_USR_ID = system_user, REC_UPD_PGM_ID = app_name() \n" .
		"where LOC_SRVR_NM = '$lLOC_SRVR_NM' and LOC_SRVR_DBINST_NM = '$lLOC_SRVR_DBINST_NM'\n" .
		"and LOC_SRVR_DBINST_DB_NM not in ($sqlval)";
	unless (&execSQLCmd($rCmd, $sql)) {	$status = 0; last SUB; }

	$rConn = $rCmd->{ActiveConnection};

	# When large number of Store servers is updating repository, connection is
	#  killed due to deadlock. Try to remove transactions to provide short 
	#  term solution to deadlocking.
	# $rConn->BeginTrans();

	foreach $dbName (sort keys %dbLst) {
		unless ($status = &updateCurrentDB($rCmd, $rLOC_SRVR_DBINST, $dbLst{$dbName})) { last SUB; }
	}
	# $rConn->CommitTrans();
	last SUB;

}
	# $rConn->RollbackTrans()	unless ($status || !$rConn );
	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset
	if ($cmd)	{ 
		my $conn = $cmd->{ActiveConnection};
		if ($conn)	{ $conn->Close(); $conn = 0; }		# close the data source
		$cmd->Close(); $cmd = 0; 
	}

	&notifyWSub("Done");

	return ($status);
}	# updateDBaseStats


# ----------------------------------------------------------------------
#	updateLocSrvr	update LOC_SRVR
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	LOC_SRVR record is updated in database.
# ----------------------------------------------------------------------

sub updateLocSrvr () {
	my $cmd			= 0;		# ADO Command object handle
	my $rs			= 0;		# record set handle
	my $sql			= "";		# SQL statements
	my $sqlins		= "";		# insert part of the SQL insert statements
	my $sqlval		= "";		# values part of the SQL insert statements
	my $intValsPat	= 'LOC_SRVR_MEM_SIZE|LOC_SRVR_CPU_QTY|LOC_SRVR_CPU_SPD|LOC_ID';
	my $status		= 1;
	my $hKey;
	my %lLOC_SRVR	= (
					LOC_SRVR_NM				=> $T38ERROR,
					IP_ADDR_ID				=> $T38ERROR,
					LOC_SRVR_PHYS_NM		=> $T38ERROR,
					LOC_SRVR_MEM_SIZE		=> $T38ERROR,
					MEM_SIZE_UOM			=> $T38ERROR,
					OS_VER_NM				=> $T38ERROR,
					LOC_SRVR_CPU_QTY		=> $T38ERROR,
					LOC_SRVR_CPU_SPD		=> $T38ERROR,
					PERL_VER_NBR			=> $T38ERROR,
					MDAC_VER_ID				=> $T38ERROR,
					LOC_SRVR_CLUSTER_FLG	=> $T38ERROR
					);


	my $debug = 0;		# No debug
	# $debug |= 0x01;	# print Connection properties
	# $debug |= 0x02;	# print all SQL Errors (include messages).
SUB:
{

	&notifyWSub("Started.");
	&notifyWSub("Updating LOC_SRVR table.");

	# Connect to SQL Server.

	unless ($cmd = adoConnect($gRepoSrvr, $gRepoDB)) {
		$status = 0;
		last SUB;
	}

	unless ($status = &getDbOsVerNm($cmd))	{ last SUB; }
	unless ($status = &getDbLocSrvr($cmd, \%lLOC_SRVR))	{ last SUB; }
	$lLOC_SRVR{LOC_SRVR_NM} =~ s/\s+$//g;

	$debug = 0;
	if ($debug || $main::gDebug) {
		&notifyWSub("lLOC_SRVR:");
		&debugPrintHash(\%lLOC_SRVR);
	}

	if ($lLOC_SRVR{LOC_SRVR_NM} eq $gLOC_SRVR{LOC_SRVR_NM}) {
		# Record exists. Update it if needed.
		$sqlval = '';
		foreach $hKey (keys (%lLOC_SRVR)) {
			$lLOC_SRVR{$hKey} =~ s/\s+$//g;
			if (($gLOC_SRVR{$hKey} ne $T38ERROR) && ($lLOC_SRVR{$hKey} ne $gLOC_SRVR{$hKey})) {
				if ($hKey =~ /$intValsPat/) {
					$sqlval .= "$hKey = $gLOC_SRVR{$hKey}, ";
				} else {
					$sqlval .= "$hKey = \'$gLOC_SRVR{$hKey}\', ";
				}
			}
		}

		if ($sqlval) {
			$sql = 
				"update LOC_SRVR SET $sqlval " .
				"REC_UPD_TS = getdate\(\), REC_UPD_USR_ID = system_user, REC_UPD_PGM_ID = app_name\(\) " .
				"where LOC_SRVR_NM = \'$gLOC_SRVR{LOC_SRVR_NM}\'";
			unless (&execSQLCmd($cmd, $sql)) { $status = 0; last SUB; }
			&notifyWSub("LOC_SRVR record is updated.");
		} else {
			&notifyWSub("LOC_SRVR record was not changed.");
		}

	} else {
		# Insert new record.
		
		if (!$gLOC_SRVR{LOC_SRVR_NM} || $gLOC_SRVR{LOC_SRVR_NM} eq $T38ERROR) {
			&errme("Internal error. gLOC_SRVR structure is corruped. Bad LOC_SRVR_NM.");
			$status = 0;
			last SUB;
		}

		$sqlins = '(';
		$sqlval = '(';
		foreach $hKey (keys (%gLOC_SRVR)) {
			if ($gLOC_SRVR{$hKey} ne $T38ERROR) {
				$sqlins .= "$hKey, ";

				if ($hKey =~ /$intValsPat/) {
					$sqlval .= "$gLOC_SRVR{$hKey}, ";
				} else {
					$sqlval .= "\'$gLOC_SRVR{$hKey}\', ";
				}
			}
		}
		$sqlins =~ s/, $/\)/;
		$sqlval =~ s/, $/\)/;

		$sql = "insert into LOC_SRVR${sqlins} values $sqlval";
		unless (&execSQLCmd($cmd, $sql)) { $status = 0; last SUB; }
		&notifyWSub("New LOC_SRVR record created.");
	}

	last SUB;
}
#ExitSub
	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset
	if ($cmd)	{ 
		my $conn = $cmd->{ActiveConnection};
		if ($conn)	{ $conn->Close(); $conn = 0; }		# close the data source
		$cmd->Close(); $cmd = 0; 
	}

	&notifyWSub("Done");

	return($status);
}	# updateLocSrvr


# ----------------------------------------------------------------------
#	updateSQLInst	update SQL Server Instance statistics.
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	LOC_SRVR_DBINST record is updated in database.
# ----------------------------------------------------------------------

sub updateSQLInst () {
	my $status		= 1;
	my $cmd			= 0;		# ADO Command object handle
	my $sql			= "";		# SQL statements
	my $sqlval		= "";		# values part of the SQL insert statements
	my $sqlerr		= 0;
	my $hKey		= 0;
	my %instLst		= ();		# List of SQL Server instances.

	my $debug = 0;		# No debug
SUB:
{
	&notifyWSub("Started.");
	&notifyWSub("Updating LOC_SRVR_DBINST table.");

	# Connect to Repository Server.

	unless ($cmd = adoConnect($gRepoSrvr, $gRepoDB)) {
		$status = 0;
		last SUB;
	}

	unless ($status = &getDbmsVerId($cmd))	{ 
		last SUB; 
	}

	unless ($status = &getSQLInstLst(\%instLst)) {
		last SUB;
	}

	unless (keys %instLst) {
		# We cannot find any SQL Server instances.
		last SUB;
	}

	# First mark all deleted instances.

	$sqlval = join(", ", map { "\'$_\'" } (keys %instLst));
	unless ($sqlval =~ /^\s*$/) {
		$sql = 
			"begin tran\n" .
			"update LOC_SRVR_DBINST set DBINST_ACTV_FLG = 'N',\n" .
			"		REC_UPD_TS = getdate(), REC_UPD_USR_ID = system_user, REC_UPD_PGM_ID = app_name() \n" .
			"where LOC_SRVR_NM = '$gSrvr' and LOC_SRVR_DBINST_NM not in ($sqlval)\n" .
			"update LOC_SRVR_DBINST_DB set DB_ACTV_FLG = 'N',\n" .
			"		REC_UPD_TS = getdate(), REC_UPD_USR_ID = system_user, REC_UPD_PGM_ID = app_name() \n" .
			"where LOC_SRVR_NM = '$gSrvr' and LOC_SRVR_DBINST_NM not in ($sqlval)\n" .
			"commit tran"
			;
		unless (&execSQLCmd($cmd, $sql)) {	$status = 0; last SUB; }
	}

	foreach $hKey (sort keys (%instLst)) {
		unless ($status = &updateCurrentInst($cmd, $instLst{$hKey}))	{ last SUB; }
	}

	last SUB;
}
#ExitSub
	if ($cmd)	{ $cmd->Close(); $cmd = 0; }

	&notifyWSub("Done");

	return($status);
}	# updateSQLInst


# ----------------------------------------------------------------------
#	updateSrvrDrv	update LOC_SRVR_DRV
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	LOC_SRVR_DRV records are updated in database.
# ----------------------------------------------------------------------

sub updateSrvrDrv () {
	my $conn		= 0;		# ADO connection object handle
	my $cmd			= 0;		# ADO Command object handle
	my $rs			= 0;		# record set handle
	my $sql			= "";		# SQL statements
	my $sqlins		= "";		# insert part of the SQL insert statements
	my $sqlval		= "";		# values part of the SQL insert statements
	my $sqlerr		= 0;
	my $intValsPat	= 'LOC_SRVR_MEM_SIZE|LOC_SRVR_CPU_QTY|LOC_SRVR_CPU_SPD|LOC_ID';
	my $status		= 1;
	my $hKey;
	my $drvNm		= '';
	my $debug = 0;		# No debug
	# $debug |= 0x01;	# print Connection properties
	# $debug |= 0x02;	# print all SQL Errors (include messages).
SUB:
{

	&notifyWSub("Started.");
	&notifyWSub("Updating LOC_SRVR_DRV table.");

	# Connect to SQL Server.

	unless ($cmd = adoConnect($gRepoSrvr, $gRepoDB)) {
		$status = 0;
		last SUB;
	}

	# First delete unused drives:

	$conn = $cmd->{ActiveConnection};
	$sqlerr = $conn->Errors;

	$sqlval = join(", ", (keys %gListLOC_SRVR_DRV));
	unless ($sqlval =~ /^\s*$/) {
		$sqlval =~ s/([A-Z])/\'$1\'/gi;
		$sql = "delete LOC_SRVR_DRV where LOC_SRVR_NM = \'$gLOC_SRVR{LOC_SRVR_NM}\' and LOC_SRVR_DRV_NM not in ($sqlval)";
		$cmd->{CommandText} = $sql;
		unless ($cmd->Execute()) { &errme("Error in SQL"); &notifyMe($sql); &showADOErrors($sqlerr); $status = 0; last SUB; }
	}

	foreach $drvNm (sort keys %gListLOC_SRVR_DRV) {
		$sql =
			'declare' . "\n" .
			'	@locSrvrNm		char(18),' . "\n" .
			'	@drvTotSpace	decimal(9,2),' . "\n" .
			'	@drvAvailSpace	decimal(9,2),' . "\n" .
			'	@drvUOM			char(4)' . "\n" .
			"\n" .
			'select @locSrvrNm = LOC_SRVR_NM, ' . "\n" .
			'	@drvTotSpace = DRV_TOT_SPACE_QTY, @drvAvailSpace = DRV_AVAIL_SPACE_QTY, @drvUOM = DRV_SPACE_UOM' . "\n" .
			'from LOC_SRVR_DRV' . "\n" .
			'where LOC_SRVR_NM = ' . "\'$gListLOC_SRVR_DRV{$drvNm}{LOC_SRVR_NM}\'\n" .
			'and LOC_SRVR_DRV_NM = ' . "\'$gListLOC_SRVR_DRV{$drvNm}{LOC_SRVR_DRV_NM}\'\n" .
			"\n".
			'if (@locSrvrNm is not NULL)' . "\n" .
			'begin' . "\n" .
			'	if (@drvTotSpace != ' . "$gListLOC_SRVR_DRV{$drvNm}{DRV_TOT_SPACE_QTY} OR\n" .
			'		@drvAvailSpace != ' . "$gListLOC_SRVR_DRV{$drvNm}{DRV_AVAIL_SPACE_QTY} OR\n" .
			'		@drvUOM != ' . "\'$gListLOC_SRVR_DRV{$drvNm}{DRV_SPACE_UOM}\')\n" .
			'	begin' . "\n" .
			'		update LOC_SRVR_DRV set ' . "\n" .
			'		DRV_TOT_SPACE_QTY = ' . "$gListLOC_SRVR_DRV{$drvNm}{DRV_TOT_SPACE_QTY}, \n" .
			'		DRV_AVAIL_SPACE_QTY = ' . "$gListLOC_SRVR_DRV{$drvNm}{DRV_AVAIL_SPACE_QTY}, \n" .
			'		DRV_SPACE_UOM = ' . "\'$gListLOC_SRVR_DRV{$drvNm}{DRV_SPACE_UOM}\',\n" .
			'		REC_UPD_TS = getdate(), REC_UPD_USR_ID = system_user, REC_UPD_PGM_ID = app_name() ' . "\n" .
			'		where LOC_SRVR_NM = ' . "\'$gListLOC_SRVR_DRV{$drvNm}{LOC_SRVR_NM}\'\n" .
			'		and LOC_SRVR_DRV_NM = ' . "\'$gListLOC_SRVR_DRV{$drvNm}{LOC_SRVR_DRV_NM}\'\n" .
			'	end' . "\n" .
			'	select 1 as UPDRESULT' . "\n" .
			'end' . "\n" .
			'else select 0 as UPDRESULT' . "\n"
			;
		$cmd->{CommandText} = $sql;
		unless ($rs = $cmd->Execute()) { &errme("Error in SQL"); notifyMe($sql); &showADOErrors($sqlerr); $status = 0; last SUB; }

		$debug = 0; if ($debug || $main::gDebug) { &notifyMe("\n$sql"); } $debug = 0;
		$debug = 0x00; if ($debug & 0x01) { &adoProperties4Rs($rs->Properties); }	$debug = 0;

		my $updResult = $T38ERROR;
		while($rs && !$rs->EOF) {
			$updResult = $rs->Fields('UPDRESULT')->Value if (defined($rs->Fields('UPDRESULT')));
			$rs->MoveNext;
			$rs = $rs->NextRecordset;
		}

		if ($updResult != 1) {
			# Try to insert new record.
			$sql = 
				"insert into LOC_SRVR_DRV(LOC_SRVR_NM, LOC_SRVR_DRV_NM, DRV_TOT_SPACE_QTY, DRV_AVAIL_SPACE_QTY, DRV_SPACE_UOM\)\n" .
				"values\n".
				"	(\n" .
				"	\'$gListLOC_SRVR_DRV{$drvNm}{LOC_SRVR_NM}\',\n" .
				"	\'$gListLOC_SRVR_DRV{$drvNm}{LOC_SRVR_DRV_NM}\',\n" .
				"	$gListLOC_SRVR_DRV{$drvNm}{DRV_TOT_SPACE_QTY},\n" .
				"	$gListLOC_SRVR_DRV{$drvNm}{DRV_AVAIL_SPACE_QTY},\n" .
				"	\'$gListLOC_SRVR_DRV{$drvNm}{DRV_SPACE_UOM}\'\)\n"
				;
			unless (&execSQLCmd($cmd, $sql)) { $status = 0; last SUB; }
		}
	}
	last SUB;
}
#ExitSub
	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset
	if ($cmd)	{ $cmd->Close(); $cmd = 0; }
	if ($conn)	{ $conn->Close(); $conn = 0; }		# close the data source

	&notifyWSub("Done");

	return($status);
}	# updateSrvrDrv



############################  BBY Subroutines  ####################################


# ----------------------------------------------------------------------
# housekeeping
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Perform the initial housekeeping chores.
# ----------------------------------------------------------------------

sub housekeeping { 
	use Cwd;
	use Getopt::Std;

	my $scriptSuffix	= ".pl";

	$gScriptName	= "";			# Base name of the current script.
	$gScriptPath	= ".\\";		# Directory path to current script.

	($gScriptPath, $gScriptName, $scriptSuffix) = &T38lib::Common::parseProgramName();

	$T38ERROR = $T38lib::Common::T38ERROR;

	#-- initialize standard options

	$opt_h	= 0;	# help option.
	$opt_c	= 0;	# Optional Configuration file name.
	$opt_d	= 0;	# Repository database name.
	$opt_e	= 0;	# Environment type.
	$opt_l	= 0;	# Security Group Location.
	$opt_r	= 0;	# Repository server.
	$opt_S	= 0;	# Server to process.
	$opt_x	= 0;	# Execution option.


	getopts('c:d:e:hl:r:S:x:');

	#-- program specific initialization

	$gHostName	= `hostname`; chomp($gHostName); $gHostName = uc($gHostName);
	$gSrvr		= $gHostName;
	$gRepoSrvr	= $gHostName;
	$gRepoDB	= "ADMDB004";
	$gEnvrTyp	= "D";
	$gSecGrpLoc	= "C";
	$gNWarnings	= 0;

	#-- show help

	if ($opt_h) { &showHelp; exit; }

	# Open log and error files, if needed.

	unless (&T38lib::Common::setLogFileDir("${gScriptPath}T38LOG")) {
		&errme("Cannot set program log directory.");
		return 0;
	}

	&T38lib::Common::archiveLogFile(7);
	&logme("Starting $gScriptName from $gScriptPath", "started");

	# Overwrite parameters from configuration file.

	&readConfigFile($opt_c)	if ($opt_c);

	# And now overwrite them from command line.

	$gSrvr		= uc($opt_S)	if ($opt_S);
	$gRepoSrvr	= uc($opt_r)	if ($opt_r);
	$gRepoDB	= $opt_d		if ($opt_d);
	$gEnvrTyp	= uc($opt_e)	if ($opt_e);
	$gSecGrpLoc	= uc($opt_l)	if ($opt_l);

	if ($gEnvrTyp eq "D")	{$gEnvrTyp = 'DEV';}
	elsif ($gEnvrTyp eq "M")	{$gEnvrTyp = 'MDWE';}
	elsif ($gEnvrTyp eq "P")	{$gEnvrTyp = 'PROD';}
	elsif ($gEnvrTyp eq "Q")	{$gEnvrTyp = 'QUAL';}
	elsif ($gEnvrTyp eq "T")	{$gEnvrTyp = 'TEST';}
	else {
		&warnme("Invalid environment type: $gEnvrTyp. Option ignored.");
		$gEnvrTyp = $T38ERROR;
	}

	if ($gSecGrpLoc !~ /^C|I|S$/) {
		&warnme("Invalid security group location: $gSecGrpLoc. Option ignored.");
		$gSecGrpLoc = $T38ERROR;
	}

	%gLOC_SRVR	= (
					LOC_SRVR_NM				=> $gSrvr,
					IP_ADDR_ID				=> $T38ERROR,
					LOC_SRVR_PHYS_NM		=> $T38ERROR,
					LOC_SRVR_MEM_SIZE		=> $T38ERROR,
					MEM_SIZE_UOM			=> $T38ERROR,
					LOC_SRVR_VER_NBR		=> $T38ERROR,
					LOC_SRVR_REPLIC_FLG		=> $T38ERROR,
					LOC_SRVR_REPL_OMIT_FLG	=> $T38ERROR,
					LOC_SRVR_REPL_OMIT_TS	=> $T38ERROR,
					LOC_SRVR_MQ_REPL_FLG	=> $T38ERROR,
					LOC_SRVR_CASE_TYP		=> $T38ERROR,
					LOC_SRVR_SORT_TYP		=> $T38ERROR,
					LOC_SRVR_SHAREPT		=> $T38ERROR,
					OS_VER_NM				=> $T38ERROR,
					LOC_SRVR_CPU_QTY		=> $T38ERROR,
					LOC_SRVR_CPU_SPD		=> $T38ERROR,
					TELNET_FLG				=> $T38ERROR,
					PERL_VER_NBR			=> $T38ERROR,
					PERF_MON_FLG			=> $T38ERROR,
					SMS_FLG					=> $T38ERROR,
					MDAC_VER_ID				=> $T38ERROR,
					REM_DESKTOP_FLG			=> $T38ERROR,
					LOC_SRVR_CLUSTER_FLG	=> $T38ERROR,
					LOC_ID					=> $T38ERROR
					);

	%gOS_VER		= (
					OS_TYP_DESC				=> $T38ERROR,
					OS_VER_PATCH_ID			=> $T38ERROR
					);

	%gSysInfo		= (
					SystemRoot				=> $T38ERROR,	# D:\Winnt
					ProgramFilesDir			=> $T38ERROR,	# D:\Program Files
					SystemDrive				=> $T38ERROR,	# D:
					EnvPath					=> $T38ERROR,	# Path enviroment variable for the scanned server
					OSVerLocal				=> $T38ERROR,	# 5.0, 4.0
					OSVersion				=> $T38ERROR	# 5.0, 4.0
					);

	%gLOC_SRVR_DRV	= (						# Default row for LOC_SRVR_DRV table.
					LOC_SRVR_NM				=> $gSrvr,
					LOC_SRVR_DRV_NM			=> $T38ERROR,
					SRVR_RAID_TYP			=> $T38ERROR,
					DRV_TOT_SPACE_QTY		=> $T38ERROR,
					DRV_AVAIL_SPACE_QTY		=> $T38ERROR,
					DRV_SPACE_UOM			=> $T38ERROR
					);

	%gListLOC_SRVR_DRV	= ();		# List of LOC_SRVR_DRV, each entry is a structure:
	%gDBMS_VER			= ();		# DBMS_VER_ID for all MSSQL versions.

	# Check Perl version.

	unless ( &T38lib::Common::chkPerlVer() ) {
		&notifyWSub("Wrong version of Perl!");
		&notifyWSub("This program run on Perl version 5.005 and higher.");
		&notifyWSub("Check the Perl version by running perl -v on command line.");
		return 0;
	}

	# Check Version of the filever program.
	# die "check filever on hst1db with long file names";

	my $fileverexe	= &whence("filever.exe");
	if (!$fileverexe) {
		&errme("$gScriptName aborted. Cannot find filever.exe!");
		return 0;
	}
	my $fileverout = `filever /V \"$fileverexe\"`;
	if ($fileverout !~ /FileDescription\s*Microsoft\s*Version\s*Resource\s*Dump\s*Utility/i) {
		&errme("Invalid version of the Microsoft Version Resource Dump Utility found using filever $fileverexe.");
		&notifyWSub("$fileverout.");
		return 0;
	}

	&notifyWSub("$gHostName is collecting server stats for $gSrvr. Storage: $gRepoSrvr..$gRepoDB.");

	return(1);
}	# housekeeping
	

# ----------------------------------------------------------------------
#	debugPrintHash 
# ----------------------------------------------------------------------
#	arguments:
#		Reference to Hash
#	return:
#		none
# ----------------------------------------------------------------------
#	Print all kesy in a hash.
# ----------------------------------------------------------------------

sub debugPrintHash ($) {
	my $hashref	= shift;
	my $hKey;

	foreach $hKey (sort keys (%{$hashref})) {
		&notifyMe("\t$hKey = $$hashref{$hKey}");
	}
}	# debugPrintHash

###


# ----------------------------------------------------------------------
#	execOSCmd -- execute OS Command
# ----------------------------------------------------------------------
#	arguments:
#		executable file
#		command line arguments string
#	return:
#		1	No errors
#		0	Error found
# ----------------------------------------------------------------------

sub execOSCmd ($$) {
	my $exe			= shift;
	my $arg			= shift;
	my $hProcess	= 0;
	my $pid			= 0;
	my $pResult		= 0;
	my $debug		= 1;
	my $status		= 1;

	&notifyWSub("Started.");

	$exe =~ s/\\/\//g;
	&notifyWSub("execOSCmd: $exe $arg", 2);

SUB:
{
	unless (&Win32::Process::Create($hProcess, $exe, $arg, 0, NORMAL_PRIORITY_CLASS, ".") ) {
		&errme( Win32::FormatMessage( Win32::GetLastError() ) );
		$status	= 0;
		last SUB;
	}

	$pid = $hProcess->GetProcessID();
	$pResult = $hProcess->Wait(5*60*1000);

	unless ($pResult) {
		Win32::Process::KillProcess($pid, 1) if ($pid);
		&errme("The $exe command timed out after 5 minutes. $gScriptName is terminating.");
		&notifyWSub("execOSCmd: $exe $arg", 2);
		$status	= 0;
		last SUB;
	}
} # End of SUB

	&notifyWSub("Done");
	return($status);
}



###	showHelp -- show help information.
###

sub showHelp {
	print <<'EOT'
#* t38srvstats - Collect server statistics and store it in master repository.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:23 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/t38srvstats/t38srvstats.pv_  $
#*
#* SYNOPSIS
#*	t38srvstats -h -S server -r rServer -d rDatabase -x{s|d} -e{D|M|P|Q|T} 
#*					-l{C|I|S} -c cfgFile
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-S server	Name of the server to add to central repository. Default is
#*				local server.
#*	-r rServer	Name of the database server with repository database.
#*				Default is local server.
#*	-d rDBase	Name of the centrol repository database with Servers
#*				information. Default is ADMDB004.
#*	-x execOpt	Execution option: 
#*					s -- collect OS level information
#*					d -- collect database level information
#*				default is collect OS and database information.
#*	-e EnvrTyp	SQL Server Environment type:
#*					D -- DEV, 	Development (Default)
#*					M -- MDWE,	Middleware
#*					P -- PROD,	Production
#*					Q -- QUAL,	Quality Assurnc
#*					T -- TEST,	Test Env
#*	-l secLog	Security Group Location:
#*					C -- Corporate Location (Default)
#*					I -- Internet Location
#*					S -- Store Location
#*	-c cfgFile	Configuration file with optional parameters. They
#*				provide defaults for common options.
#*				Following parameters are excepted:
#*				RepositoryServerName 	-- can be overwritten by -r option
#*				RepositoryDBName		-- can be overwritten by -d option
#*				EnvironmentType			-- can be overwritten by -e option
#*				SecurityGroupLocation	-- can be overwritten by -l option
#*	
#*	This server collects vital statistics on SQL Server machine and stores it
#*	in repostiroy database.
#*
#*	REQUIRED FILES:
#*
#*	t38mdac.ver.cfg
#*
#*	REQUIRED OS Utilities:
#*
#*	NT 4.0: winmsd, filever.
#*	Win2K:	msinfo32, filever.
#*
#***
EOT
} #	showHelp
