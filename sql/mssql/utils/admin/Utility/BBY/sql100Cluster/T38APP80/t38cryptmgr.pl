#!perl 
#*  t38cryptmgr - encryption maintenance manager.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:22 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/DataEncryption/Scripts/t38cryptmgr.pv_  $
#*
#* SYNOPSIS
#*  t38cryptmgr -h -a 10 -l logfileDirSuffix -x brc -S server cfgFile
#*	
#*  Where:
#*
#*  -h          Writes help screen on standard output, then exits.
#*  -a 10       Number of log file archived, default is 7
#*  -l logsuffx Optional Log File Directory suffix. This is used to
#*              ensure multiple copies of the program can run at the 
#*              same time without overwriting the log file.
#*  -S server   Name of the SQL Server with encrypted data. 
#*              Default is local server on default instance.
#*  -x execOpt  Execution option:
#*                  b = Backup Database master keys and store backup
#*					    password in T38DB002.
#*                  r = Regenerate Database master keys and store passwords
#*                      in T38DB002.
#*                  c = Checks symmetric/asymmetric keys in user databases.
#*					d = Check database master key on target server.
#*  cfgFile     Configuration file with configuration parameters. 
#*              Following parameters are accepted by t38cryptmgr.pl:
#*                  T38LIST:DMKBackupIncludeDB    = DBName
#*                  T38LIST:DMKBackupExcludeDB    = DBName
#*                  T38LIST:DMKRegenIncludeDB     = DBName
#*                  T38LIST:DMKRegenExcludeDB     = DBName
#*                  T38LIST:CRYPKEYCheckIncludeDB = DBName
#*                  T38LIST:CRYPKEYCheckExcludeDB = DBName
#*                  T38LIST:DMKCheckIncludeDB     = SrvrName\InstName.DBName
#*                  T38LIST:DMKCheckExcludeDB     = SrvrName\InstName.DBName
#*					  or
#*                  T38LIST:DMKCheckIncludeDB     = SrvrName.DBName
#*                  T38LIST:DMKCheckExcludeDB     = SrvrName.DBName
#*
#*
#*              In addition program is using the following parameters
#*              to connect to password database:
#*                  SQLInstallPwdSrvr = tcp:DVP02DB03,63520
#*                  SQLInstallPwdDB   = T38DB002
#*					SQLPwdDBPassPhrase
#*
#*
#*  The t38cryptmgr.pl program performs key management on requested
#*  databases in a given instance of SQL 2005 Server. For each
#*  requested database program can perform the following actions: 
#*
#*  - If backup of the master key is requested, program backs up dmk
#*  and saves the backup password in password management table in
#*  T38DB002 database.
#*
#*  - If regen of the master key is requested, program regenerates
#*  the dmk and saves the dmk password in password management table in
#*  T38DB002 database.
#*
#*  - If check user keys is requested, program calls the sp_T38CHKUSERKEYS
#*  procedure to use asymmetric/symmetric keys to encrypt/decrypt test
#*  string and issue an error for the first key that didn't work.
#*
#*  - If check database master key is requested, program reads list
#*  of all available databases from T38DB002 database. Filters out
#*  databases based on T38LIST:DMKCheckIncludeDB and T38LIST:DMKCheckExcludeDB
#*  lists to create list of databases to process. If -S option is used
#*  it will process databases only for that server. In order to check
#*  database master key, program reads dmk password from T38DB002
#*  database, connects to target database and attempts to open
#*  database master key.
#*
#*  Example:
#*      t38crypmgr.pl -S tcp:DVD10DB01,63518 -x bc t38dba.cfg
#*      Check user keys in databases, provided in t38dba.cfg file and
#*      backup database master keys on DVD10DB01\DF01 instance.
#*
#*      t38crypmgr.pl -x d t38dba.cfg t38cryptmgr.cfg
#*      Check database master keys. Get password management database (T38DB002)
#*      connection information from t38dba.cfg. Get list of databases to 
#*      filter out from t38cryptmgr.cfg file.
#*
#***

use strict;

use File::Basename;
use T38lib::Common qw(runSQLChk4Err notifyMe notifyWSub logme warnme errme);
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use T38lib::bbyado qw(:BBYADO_SUBS :BBYADO_VARS);
use Getopt::Std;

# Global Variables
my ( $gCurrentDir, $gScriptName, $gScriptPath, $gHostName, $gNWarnings) = "";
my @gArgs = ();
use vars qw(
		$gRunOpt
		$gSrvrName
		);

my $gDMKCheckSrvr = '';
my @gAllDBNames = ();
my @gExcludeDbNames = ('master', 'model', 'tempdb', 'msdb');	# These databases are always excluded from any operations.
my $gNumArchive = 0;
my $gLogFileBase = '';


# Main
&main();


############################  BBY Subroutines  ####################################

sub main {
	my $mainStatus	= 0;
	SUB:
	{
		unless (&housekeeping())	{ $mainStatus = 1; last SUB; }

		&setADOShowAllErrors(1);		# Ensure we will see all errors and warnings for specific SQL Statement.
		if ($gRunOpt =~ /[c]/) {	# Check if asymmetric/symmetric keys are OK.
				unless (&chkUserKeys())	{ $mainStatus = 1; }
		}	# if ($gRunOpt =~ /[c]/)
		if ($gRunOpt =~ /[b]/) {	# Backup database master key.
				unless (&bkpdmk())	{ $mainStatus = 1; }
		}	# if ($gRunOpt =~ /[b]/)
		if ($gRunOpt =~ /[r]/) {	# Regenerate database master key.
				unless (&regendmk())	{ $mainStatus = 1; }
		}	# if ($gRunOpt =~ /[r]/)
		if ($gRunOpt =~ /[d]/) {	# Check database master key.
				unless (&chkdmk())	{ $mainStatus = 1; }
		}	# if ($gRunOpt =~ /[d]/)

		last SUB;
	
	}	# SUB
	# ExitPoint:


	$mainStatus = 1	if ($gNWarnings > 0);

	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;

	exit($mainStatus);

}	# main


#######################  $Workfile:   t38cryptmgr.pl  $ Subroutines  #################################

# ----------------------------------------------------------------------
#	bkpdmk		backup database master key
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub bkpdmk () {
	my @processDbNames = ();
	my $dbname	= '';
	my $sql		= '';
	my $prtsql	= '';		# safe for printing sql text.
	my $adocmd	= 0;		# ADO Command object handle for server with sensitive data.
	my $adocmdr	= 0;		# ADO Command object handle for repository server.
	my @rs		= ();		# array with result set
	my $netName	= '';		# SQL Server network name.
	my $srvrName	= '';
	my $bkppath	= '';
	my $bkpfile	= '';
	my $bkppwd	= '';
	my $pwdenc	= '';		# Encrypted password
	my $status	= 1;
	SUB:
	{
		&notifyWSub("Started.");

		# Get list of database to process.

		unless (&getFilteredDBs('DMKBackupIncludeDB', 'DMKBackupExcludeDB', \@processDbNames)) {
			&errme("Cannot get list of databases to process on $gSrvrName. Check include and exclude parameters in cfg files.");
			$status = 0; last SUB;
		}

		&notifyWSub("Process Databases on $gSrvrName: @processDbNames");

		# Create ADO Connections. Do not force '.' for local host 
		# but request encrypted connection.

		unless ($adocmd = adoConnect($gSrvrName, 'master', 0, 1)) { 
			&errme("adoConnect($gSrvrName) Failed");
			$status = 0; last SUB;
		}

		foreach $dbname (sort (@processDbNames)) {
			&notifyWSub("Processing database $dbname.");

			# Check if database has master key.

			$sql = "select name from $dbname.sys.symmetric_keys where name = '\#\#MS_DatabaseMasterKey\#\#'";
			unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
			unless(defined($rs[0])) {
				&notifyWSub("Database $dbname has no master key. Continue with next database.");
				next;
			}

			@rs = ();

			# Get machine name of sql server
			
			unless ($netName && $srvrName) {
				$sql = "SELECT SERVERPROPERTY('MachineName') as MachineName, SERVERPROPERTY('ServerName') as ServerName";
				unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
				unless(defined($rs[0])) {
					&errme("Cannot get machine name for $gSrvrName.");
					$status = 0; last SUB;
				}
				$netName = &T38lib::Common::stripWhitespace($rs[0]{MachineName});
				$srvrName = &T38lib::Common::stripWhitespace($rs[0]{ServerName});
				@rs = ();
			}

			# Get backup path.
			unless ($bkppath) {
				$sql = "select physical_name from sys.backup_devices where name = 'master_db_bkp' and type = 2";
				unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
				unless($rs[0]{physical_name}) {
					&errme("Cannot get backup device name for master database.");
					$status = 0; last SUB;
				}
				$bkppath = &T38lib::Common::stripWhitespace($rs[0]{physical_name});
				$bkppath =~ s/[\\\/][^\\\/]+$//;	# Strip base file name.
				$bkppath =~ s/^([a-z]):/\\\\$netName\\$1\$/i;	# Convert physical path to UNC.
				@rs = ();
			}
			$bkpfile = "$bkppath\\${dbname}_dmk.bkp";

			# Generate password for backup.
			# Also get encrypted password so it will not show up in SQL Trace file.


			$sql = << "			EOSQLT";
			declare \@pwd		varchar(42)
			declare \@pwdenc varbinary(143)
			declare \@pwdstr	varchar(143)
			

			set \@pwd = cast (newid() as varchar(42))
			set \@pwdenc = EncryptByPassPhrase('$gConfigValues{SQLPwdDBPassPhrase}', \@pwd)
			exec sp_T38hexadecimal \@pwdenc, \@pwdstr output
			select bkppwd = \@pwd, pwdenc = \@pwdstr
			EOSQLT

			unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
			unless(defined($rs[0])) {
				&errme("Cannot generate password.");
				$status = 0; last SUB;
			}
			$bkppwd = &T38lib::Common::stripWhitespace($rs[0]{bkppwd});
			$pwdenc = &T38lib::Common::stripWhitespace($rs[0]{pwdenc});
			@rs = ();

			# We have to delete old backup file before we can create new one.

			unlink($bkpfile);
			
			# Backup database master key. Since we are passing password, 
			# do not use common library. It could print SQL statements to log
			# file and we should not print passwords.

			$sql = "USE $dbname; BACKUP MASTER KEY TO FILE = '$bkpfile' ENCRYPTION BY PASSWORD = '$bkppwd'";
			$prtsql = "USE $dbname; BACKUP MASTER KEY TO FILE = '$bkpfile' ENCRYPTION BY PASSWORD = 'XXXXXX'";
			unless (&execSQLCmdSafe($adocmd, $sql, $prtsql)) {
				&errme("Cannot backup master key to file $bkpfile.");
				$status = 0; next;
			}

			# Save password to repository.

			# First need connection to repository.
			unless ($adocmdr) {
				unless ($adocmdr = adoConnect($gConfigValues{SQLInstallPwdSrvr}, $gConfigValues{SQLInstallPwdDB}, 0, 1)) { 
					&errme("adoConnect($gConfigValues{SQLInstallPwdSrvr}) Failed");
					$status = 0; last SUB;
				}
			}

			# Save dmk backup password. Have to use encrypted password here.

			$sql = "T38UPDINSACCOUNT \@serviceName = 'dmkbkp:$srvrName.$dbname', \@accntName = 'dmkbkp', \@password = $pwdenc";
			$prtsql = "T38UPDINSACCOUNT \@serviceName = 'dmkbkp:$srvrName.$dbname', \@accntName = 'dmkbkp', \@password = XXXXXX";
			unless (&execSQLCmdSafe($adocmdr, $sql, $prtsql)) {
				&errme("Cannot store password for master key backup to $gConfigValues{SQLInstallPwdSrvr}.$gConfigValues{SQLInstallPwdDB}");
				$status = 0; next;
			}

		}

		last SUB;
	}	# SUB
	# ExitPoint:

	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	if ($adocmdr) { $adocmdr->Close(); $adocmdr = 0; }
	&notifyWSub("bkpdmk finised with $status status.");

	return($status);

}	# bkpdmk

# ----------------------------------------------------------------------
#	regendmk		regenerate database master key
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub regendmk () {
	my @processDbNames = ();
	my $dbname	= '';
	my $sql		= '';
	my $prtsql	= '';		# safe for printing sql text.
	my $adocmd	= 0;		# ADO Command object handle for server with sensitive data.
	my $adocmdr	= 0;		# ADO Command object handle for repository server.
	my @rs		= ();		# array with result set
	my $srvrName	= '';
	my $dmkpwd	= '';
	my $pwdenc	= '';		# Encrypted password
	my $status	= 1;
	SUB:
	{
		&notifyWSub("Started.");

		# Get list of database to process.

		unless (&getFilteredDBs('DMKRegenIncludeDB', 'DMKRegenExcludeDB', \@processDbNames)) {
			&errme("Cannot get list of databases to process on $gSrvrName. Check include and exclude parameters in cfg files.");
			$status = 0; last SUB;
		}

		# Create ADO Connections. Do not force '.' for local host 
		# but request encrypted connection.

		unless ($adocmd = adoConnect($gSrvrName, 'master', 0, 1)) { 
			&errme("adoConnect($gSrvrName) Failed");
			$status = 0; last SUB;
		}

		foreach $dbname (sort (@processDbNames)) {
			&notifyWSub("Processing database $dbname.");

			# Check if database has master key.

			$sql = "select name from $dbname.sys.symmetric_keys where name = '\#\#MS_DatabaseMasterKey\#\#'";
			unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
			unless(defined($rs[0])) {
				&notifyWSub("Database $dbname has no master key. Continue with next database.");
				next;
			}

			@rs = ();

			# Get sql server name
			
			unless ($srvrName) {
				$sql = "SELECT SERVERPROPERTY('ServerName') as ServerName";
				unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
				unless(defined($rs[0])) {
					&errme("Cannot get sql name for $gSrvrName.");
					$status = 0; last SUB;
				}
				$srvrName = &T38lib::Common::stripWhitespace($rs[0]{ServerName});
				@rs = ();
			}

			# Generate password for dmk.

			# $sql = "select dmkpwd = cast (newid() as varchar(256))";
			$sql = << "			EOSQLT";
			declare \@pwd		varchar(42)
			declare \@pwdenc varbinary(143)
			declare \@pwdstr	varchar(143)
			

			set \@pwd = cast (newid() as varchar(42))
			set \@pwdenc = EncryptByPassPhrase('$gConfigValues{SQLPwdDBPassPhrase}', \@pwd)
			exec sp_T38hexadecimal \@pwdenc, \@pwdstr output
			select dmkpwd = \@pwd, pwdenc = \@pwdstr
			EOSQLT

			unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
			unless(defined($rs[0])) {
				&errme("Cannot generate password.");
				$status = 0; last SUB;
			}
			$dmkpwd = &T38lib::Common::stripWhitespace($rs[0]{dmkpwd});
			$pwdenc = &T38lib::Common::stripWhitespace($rs[0]{pwdenc});
			@rs = ();

			# Regenerate database master key. Since we are passing password, 
			# do not use common library. It could print SQL statements to log
			# file and we should not print passwords.

			$sql = "USE $dbname; ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = '$dmkpwd'";
			$prtsql = "USE $dbname; ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = 'XXXXXX'";
			unless (&execSQLCmdSafe($adocmd, $sql, $prtsql)) {
				&errme("Cannot regenerate master key.");
				$status = 0; next;
			}

			# Save password to repository.

			# First need connection to repository.
			unless ($adocmdr) {
				unless ($adocmdr = adoConnect($gConfigValues{SQLInstallPwdSrvr}, $gConfigValues{SQLInstallPwdDB}, 0, 1)) { 
					&errme("adoConnect($gConfigValues{SQLInstallPwdSrvr}) Failed");
					$status = 0; last SUB;
				}
			}

			# Save dmk password.

			$sql = "T38UPDINSACCOUNT \@serviceName = 'dmk:$srvrName.$dbname', \@accntName = 'dmk', \@password = $pwdenc";
			$prtsql = "T38UPDINSACCOUNT \@serviceName = 'dmk:$srvrName.$dbname', \@accntName = 'dmk', \@password = XXXXXX";
			unless (&execSQLCmdSafe($adocmdr, $sql, $prtsql)) {
				&errme("Cannot store password for database master key to $gConfigValues{SQLInstallPwdSrvr}.$gConfigValues{SQLInstallPwdDB}");
				$status = 0; next;
			}

		}

		last SUB;
	}	# SUB
	# ExitPoint:
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	if ($adocmdr) { $adocmdr->Close(); $adocmdr = 0; }

	&notifyWSub("regendmk finised with $status status.");
	return($status);

}	# regendmk

# ----------------------------------------------------------------------
#	chkUserKeys		check asymmetric/symmetric keys
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub chkUserKeys () {
	my @processDbNames = ();
	my $dbname	= '';
	my $sql		= '';
	my $outfile	= "$gLogFileBase.chkuserkeys.out";
	my $outtmp	= "$gLogFileBase.chkuserkeys.tmp";
	my $subresult	= 0;
	my $status	= 1;
	SUB:
	{
		&notifyWSub("Started.");

		# Get list of database to process.

		unless (&getFilteredDBs('CRYPKEYCheckIncludeDB', 'CRYPKEYCheckExcludeDB', \@processDbNames)) {
			&errme("Cannot get list of databases to process on $gSrvrName. Check include and exclude parameters in cfg files.");
			$status = 0; last SUB;
		}

		&notifyWSub("Process Databases on $gSrvrName: @processDbNames");

		&T38lib::Common::archiveFile($outfile, $gNumArchive);
		foreach $dbname (sort (@processDbNames)) {
			&notifyWSub("Processing database $dbname.");
			$sql = "exec sp_T38CHKUSERKEYS";
			$subresult = &runSQLChk4Err($sql, $gSrvrName, $dbname, $outtmp, "", "", "", "", [], [], 1);

			&appendFile($outtmp, $outfile);
			if ($subresult == 1) {
				&errme("Problem with keys in $dbname database. Review $outfile for errors.");
				$status = 0;
			}
		}

		last SUB;
	}	# SUB
	# ExitPoint:

	&notifyWSub("chkUserKeys finised with $status status.");

	return($status);

}	# chkUserKeys

# ----------------------------------------------------------------------
#	chkdmk		check database master key
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub chkdmk () {
	my @processDbNames = ();
	my $dbname	= '';
	my $svcname	= '';		# Service name to process in the form ServerName_InstanceName.DatabaseName 
	my $sqlSrvrName	= '';	# Standard SQL Server name (ServerName\InstanceName).
	my $sql		= '';
	my $prtsql	= '';		# safe for printing sql text.
	my $adocmd	= 0;		# ADO Command object handle for server with sensitive data.
	my $adocmdr	= 0;		# ADO Command object handle for repository server.
	my @rs		= ();		# array with result set
	my $dmkpwd	= '';
	my $srvrName	= '';	# Server name to filter on in the form ServerName_InstanceName (if defined).
	my $status	= 1;
	SUB:
	{
		&notifyWSub("Started.");

		# Get list of database to process.

		unless (&getFilteredSrvrsWDBs('DMKCheckIncludeDB', 'DMKCheckExcludeDB', \@processDbNames)) {
			&errme("Cannot get list of databases to process. Check include and exclude parameters in cfg files.");
			$status = 0; last SUB;
		}

		# Get normalized server name if requested.

		if ($gDMKCheckSrvr) {
			unless ($adocmd = adoConnect($gDMKCheckSrvr, 'master')) { 
				&errme("adoConnect($gSrvrName) Failed");
				$status = 0; last SUB;
			}
			$sql = "SELECT SERVERPROPERTY('ServerName') as ServerName";
			unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
			unless(defined($rs[0])) {
				&errme("Cannot get sql name for $gDMKCheckSrvr.");
				$status = 0; last SUB;
			}
			$srvrName = &T38lib::Common::stripWhitespace($rs[0]{ServerName});
			@rs = ();
			$adocmd->Close(); $adocmd = 0;
		}

		# Establish secured connection to password database.

		unless ($adocmdr) {
			unless ($adocmdr = adoConnect($gConfigValues{SQLInstallPwdSrvr}, $gConfigValues{SQLInstallPwdDB}, 0, 1)) { 
				&errme("adoConnect($gConfigValues{SQLInstallPwdSrvr}, $gConfigValues{SQLInstallPwdDB}) Failed");
				$status = 0; last SUB;
			}
		}

		foreach $svcname (@processDbNames) {
			&notifyWSub("Processing $svcname.");

			# Check if service should be processed for requested server.

			my $qSrvrName = quotemeta $srvrName;
			if ($srvrName && ($svcname !~/^$qSrvrName\./i) ) {
				# It is requested to process only for specific server,
				# but current service is not for that server, go to next on.
				&notifyWSub("Requested to skip $svcname because it is not on $srvrName. Continue with next server/database.");
				next;
			}

			# Get password for the service.

			$sql = "T38GETACCOUNT \@serviceName = 'dmk:$svcname', \@accntName = 'dmk'";
			unless (&execSQL2Arr($adocmdr, $sql, \@rs))  { $status = 0; last SUB; }
			unless(defined($rs[0])) {
				&errme("Cannot get password for dmk:$svcname from $gConfigValues{SQLInstallPwdSrvr}.$gConfigValues{SQLInstallPwdDB}");
				$status = 0; next;
			}

			$dmkpwd = &T38lib::Common::stripWhitespace($rs[0]{''});
			@rs = ();

			($sqlSrvrName, $dbname) = ($svcname =~ /(^.+)\.(.+)/);
			
			unless ($adocmd = adoConnectTcpEncrypt($sqlSrvrName, $dbname)) { 
				&errme("adoConnect($sqlSrvrName) Failed");
				$status = 0; last SUB;
			}

			# Check master key. Since we are passing password, 
			# do not use common library. It could print SQL statements to log
			# file and we should not print passwords.

			$sql = "USE $dbname; OPEN MASTER KEY DECRYPTION BY PASSWORD = '$dmkpwd'";
			$prtsql = "USE $dbname; OPEN MASTER KEY DECRYPTION BY PASSWORD = 'XXXXXX'";
			unless (&execSQLCmdSafe($adocmd, $sql, $prtsql)) {
				&errme("Cannot open master key for $svcname. verify password on $gConfigValues{SQLInstallPwdSrvr}.$gConfigValues{SQLInstallPwdDB} is valid.");
				if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
				$status = 0; next;
			}
			if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
		}

		last SUB;
	}	# SUB
	# ExitPoint:
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	if ($adocmdr) { $adocmdr->Close(); $adocmdr = 0; }

	&notifyWSub("chkdmk finised with $status status.");
	return($status);

}	# chkdmk

# ----------------------------------------------------------------------
#	adoConnectTcpEncrypt		create encrypted ado connection using tcp port 
# ----------------------------------------------------------------------
#	arguments:
#		dbSrvr		name of the database server: srvrName[\instName]
#		dbName		database name
#	return:
#		command object for ADO connection. Command name is "cmd1"
#		0	Failure
# ----------------------------------------------------------------------
#	create encrypted ado connection using tcp port 
# ----------------------------------------------------------------------

sub adoConnectTcpEncrypt () {
	my $dbSrvr	= shift;
	my $dbName	= shift;
	my $sqlConn	= $dbSrvr;
	my $netName	= '';
	my $instName	= '';
	my $portNo	= 0;
	my $adocmd	= 0;
SUB:
{
	if ($dbSrvr =~ /^TCP\s*:/i || $dbSrvr !~ /^(.+)\\(.+)$/) {
		$sqlConn = $dbSrvr;
	} else {
		# Assume Server name is srvrname\instancename. Convert it to
		# tcp:Srvrname,portNo

		$netName	= $1;
		$instName	= $2;
		unless($portNo = &T38lib::Common::getSqlPort($netName, $instName) ) {
			&errme("Cannot get port number for SQL Server instance $dbSrvr.");
			$adocmd = 0; last SUB;
		}
		$sqlConn = "tcp:$netName,$portNo";
	}

	unless ($adocmd = adoConnect($sqlConn, $dbName, 0, 1)) { 
		&errme("adoConnect($sqlConn, $dbName) Failed");
		$adocmd = 0; last SUB;
	}
	last SUB;
}	# SUB
# ExitPoint:
	return($adocmd);
}	# adoConnectTcpEncrypt


# ----------------------------------------------------------------------
#	execSQLCmdSafe	execute SQL command batch with no result set
# ----------------------------------------------------------------------
#	arguments:
#		command object
#		sql		SQL Command buffer
#		prtsql	SQL Statement safe to print.
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub execSQLCmdSafe ($$$) {
	my $cmd		= shift;		# ADO Command object handle
	my $sql		= shift;	# SQL statements
	my $prtsql	= shift;	# SQL statements, safe to print
	my $conn	= 0;		# ADO connection object handle
	my $rs		= 0;		# record set handle
	my $sqlerr	= 0;
	my $status	= 1;

	my $debug = 0;		# No debug
	# $debug |= 0x01;	# print Connection properties
	# $debug |= 0x02;	# print all SQL Errors (include messages).
SUB:
{
	# Connect to SQL Server.

	$conn = $cmd->{ActiveConnection};
	$sqlerr = $conn->Errors;
	$cmd->{CommandText} = $sql;

	# Create record set object.

	unless ($rs = $cmd->Execute()) { 
		&errme("Error in SQL");
		&notifyWSub(" <- Problem caller.", 2);
		&notifyMe("SQL batch:\n$prtsql");
		&showADOErrors($sqlerr); 
		$status = 0; 
		last SUB;
	}

	while($rs && !$rs->EOF) {
		# $rs->MoveNext;
		$rs = $rs->NextRecordset;
		if ( !&isADOok($sqlerr)) { 
			&errme("Error in SQL");
			&notifyWSub(" <- Problem caller.", 2);
			&notifyMe("SQL batch:\n$prtsql");
			&showADOErrors($sqlerr); 
			$status = 0; 
		}
	}
	last SUB;
}
#ExitSub
	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset
	return($status);
}	# execSQLCmdSafe


# ----------------------------------------------------------------------
#	getFilteredDBs		get list of filtered databases
# ----------------------------------------------------------------------
#	arguments:
#		$includeCfgParm	name of the configuration file param for included DBs
#		$excludeCfgParm	name of the configuration file param for included DBs
#		$arefresult		array reference for the filtered result.
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub getFilteredDBs ($$$) {
	my $includeCfgParm	= shift;
	my $excludeCfgParm	= shift;
	my $arefresult		= shift;
	my @includeDbNames = ();
	my @excludeDbNames = ();
	my $status	= 1;
	SUB:
	{
		&notifyWSub("getFilteredDBs started");

		#----------------------------------------------------------------
		# get all database names from the server system table
		#----------------------------------------------------------------
		if ((scalar @gAllDBNames) == 0) {
			@gAllDBNames=&T38lib::Common::getDBNames($gSrvrName);
			if ( $gAllDBNames[0] eq $T38lib::Common::T38ERROR ) {
				&errme("Call to &T38lib::Common::getDBNames($gSrvrName) failed.");
				$status = 0;
				last SUB;
			}
			&notifyWSub("Databases on $gSrvrName: @gAllDBNames");
		}

		if (defined ($gConfigValues{"T38LIST:$includeCfgParm"}) ) {
			push (@includeDbNames, @{$gConfigValues{"T38LIST:$includeCfgParm"}});
		}
		&notifyWSub("Include Databases on $gSrvrName: @includeDbNames");

		push (@excludeDbNames, @gExcludeDbNames);
		if (defined ($gConfigValues{"T38LIST:$excludeCfgParm"}) ) {
			push (@excludeDbNames, @{$gConfigValues{"T38LIST:$excludeCfgParm"}});
		}
		&notifyWSub("Exclude Databases on $gSrvrName: @excludeDbNames");

		# Now get list of requested databases.

		@{$arefresult} = &T38lib::Common::filterDB(\@gAllDBNames,\@includeDbNames, \@excludeDbNames);
		
		last SUB;
	}	# SUB
	# ExitPoint:

	&notifyWSub("getFilteredDBs finised with $status status.");

	return($status);

}	# getFilteredDBs


# ----------------------------------------------------------------------
#	getFilteredSrvrsWDBs		get list of filtered servers with databases
# ----------------------------------------------------------------------
#	arguments:
#		$includeCfgParm	name of the configuration file param for included DBs
#		$excludeCfgParm	name of the configuration file param for included DBs
#		$arefresult		array reference for the filtered result.
#	return:
#		1	Success
#		0	Failure
#	This subroutine reads list of server, database names from password
#   management database and filters out names provided in configuration file.
# ----------------------------------------------------------------------

sub getFilteredSrvrsWDBs ($$$) {
	my $includeCfgParm	= shift;
	my $excludeCfgParm	= shift;
	my $arefresult		= shift;
	my $sql		= '';
	my $adocmd	= 0;		# ADO Command object handle for server with sensitive data.
	my @rs		= ();		# array with result set
	my $i		= 0;
	my @allDbNames		= ();
	my @includeDbNames	= ();
	my @excludeDbNames	= ();
	my $status	= 1;
	SUB:
	{
		&notifyWSub("getFilteredSrvrsWDBs started");

		#----------------------------------------------------------------
		# get all database names from the server system table
		#----------------------------------------------------------------
		unless ($adocmd = adoConnect($gConfigValues{SQLInstallPwdSrvr}, $gConfigValues{SQLInstallPwdDB}, 0, 1)) { 
			&errme("adoConnect($gConfigValues{SQLInstallPwdSrvr}, $gConfigValues{SQLInstallPwdDB}) Failed");
			$status = 0; last SUB;
		}

		$sql = "select SERVICE from dbo.BBTG_SECPWMAN_PASSWD where ACCOUNT = 'dmk' order by SERVICE";
		unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }

		foreach $i  (0..$#rs ) { 
			$allDbNames[$i] = &T38lib::Common::stripWhitespace($rs[$i]{SERVICE});
			$allDbNames[$i] =~ s/^dmk://;
		}
		@rs = ();

		if (defined ($gConfigValues{"T38LIST:$includeCfgParm"}) ) {
			push (@includeDbNames, @{$gConfigValues{"T38LIST:$includeCfgParm"}});
		}
		&notifyWSub("Include Databases: @includeDbNames");

		if (defined ($gConfigValues{"T38LIST:$excludeCfgParm"}) ) {
			push (@excludeDbNames, @{$gConfigValues{"T38LIST:$excludeCfgParm"}});
		}
		&notifyWSub("Exclude Databases: @excludeDbNames");

		# Now get list of requested databases.

		@{$arefresult} = &T38lib::Common::filterList(\@allDbNames,\@includeDbNames, \@excludeDbNames);
		
		last SUB;
	}	# SUB
	# ExitPoint:
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }

	&notifyWSub("getFilteredSrvrsWDBs finised with $status status.");

	return($status);

}	# getFilteredSrvrsWDBs


# ----------------------------------------------------------------------
#	printSQLOut		print outout of SQL commands to log file.
# ----------------------------------------------------------------------
#	arguments:
#		$fname	file to print.
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	print outout of SQL commands to log file.
# ----------------------------------------------------------------------

sub printSQLOut ($) {
	my $fname	= shift;
	my $status	= 1;
SUB:
{
	unless (open(TMP,"< $fname"))  {
		&errme("Cannot open file $fname.");
		$status = 1; last SUB;
	}

	while (<TMP>) { &notifyMe($_); }
	close(TMP);

	last SUB;
}	# SUB
# ExitPoint:
	$gNWarnings++ if ($status == 0);
	return($status);
}	# printSQLOut



# ----------------------------------------------------------------------
#	appendFile		append first file at the end of second one.
# ----------------------------------------------------------------------
#	arguments:
#		$fname1	first file.
#		$fname2	second file.
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	append first file at the end of second one.
# ----------------------------------------------------------------------

sub appendFile ($$) {
	my $fname1	= shift;
	my $fname2	= shift;
	my $status	= 1;
SUB:
{
	unless (open(TMP1,"< $fname1"))  {
		&errme("Cannot open file $fname1.");
		$status = 0; last SUB;
	}
	unless (open(TMP2,">> $fname2"))  {
		&errme("Cannot open file $fname2 for writing.");
		$status = 0; last SUB;
	}

	while (<TMP1>) { 
		print TMP2 "$_";
	}
	close(TMP2);
	close(TMP1);

	last SUB;
}	# SUB
# ExitPoint:
	$gNWarnings++ if ($status == 0);
	return($status);
}	# appendFile



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

sub housekeeping() { 

	my $scriptSuffix;
	my $numArchive = 7;
	my $status = 1;
	my ($lfbase, $logFilePath, $lftype);
	my $logFileName 	= '';
	my $logDirSuffix	= '';
	my $logStr			= '';

	$gScriptName	= "";			# Base name of the current script.
	$gScriptPath	= ".\\";		# Directory path to current script.


	($gScriptPath, $gScriptName, $scriptSuffix) = &T38lib::Common::parseProgramName();

	#-- initialize standard options

	getopts('ha:l:S:x:');

	$gHostName	= uc(Win32::NodeName());
	$gNWarnings	= 0;

	#-- program specific initialization


	$gSrvrName	= $gHostName;	# SQL Server name
	$gRunOpt	= '';			# Execution options 

	#-- show help

	if ($Getopt::Std::opt_h) { &showHelp(); exit; }

	# Open log and error files, if needed.

	SUB: {
		$logFileName = $gScriptName;

		#----------------------------------------------------------------
		# Append the log file directory suffix if it was supplied 
		#----------------------------------------------------------------

		if($Getopt::Std::opt_l) {
			$logStr .= " -l $Getopt::Std::opt_l";
			$logDirSuffix = $Getopt::Std::opt_l;
			$logFileName = $logFileName . $logDirSuffix;
		}

		unless (&T38lib::Common::setLogFileDir("${gScriptPath}T38LOG\\$logFileName")) {
			&errme("Cannot set program log directory.");
			$status = 0;
			last SUB;
		}

		#<# Change number archived logs #>#
		if($Getopt::Std::opt_a) {
			$logStr .= " -a $Getopt::Std::opt_a";
				if ( $Getopt::Std::opt_a =~ /\d/) {
					if ( ($Getopt::Std::opt_a < 101) and ($Getopt::Std::opt_a > 0) ) {
						$numArchive = $Getopt::Std::opt_a;
					}
				}
			}

		&T38lib::Common::archiveLogFile($numArchive);
		&logme("Starting $gScriptName from $gScriptPath", "started");

		$gNumArchive 	= $numArchive;
		$logFileName = &T38lib::Common::getLogFileName($0);
		fileparse_set_fstype("MSWin32");
		($lfbase, $logFilePath, $lftype) = fileparse($logFileName, '\.[^\.]*');
		$gLogFileBase	= $logFilePath . $lfbase;


		&notifyWSub("Domain Name: " . &Win32::DomainName() . " User Name: " . &Win32::LoginName());
		&notifyWSub("Current directory: " .  &Win32::GetCwd());

		if($Getopt::Std::opt_x) {
			$logStr .= " -x $Getopt::Std::opt_x";
			if ($Getopt::Std::opt_x =~ /^[dbcr]+$/) {
				$gRunOpt = $Getopt::Std::opt_x;
			} else {
				&errme("Invalid -x options. Allowed values are dbcr.");
				$status = 0;
				last SUB;
			}
		}

		if ($Getopt::Std::opt_S) {
			$logStr .= " -S $Getopt::Std::opt_S";
			$gSrvrName	= uc($Getopt::Std::opt_S);
			$gSrvrName	=~ s/^\./$gHostName/;
			$gSrvrName	=~ s/^TCP:/tcp:/i;
			$gDMKCheckSrvr = $gSrvrName;
		}

		my $cfgFile	= '';
		if ($#ARGV < 0 ) {
			&showHelp();
			&errme("Missing configuration file.");
			$status = 0;
			last SUB;
		} else {
			# Expand command line arguments, perform globbing.
			# If command line contain any wild characters then expand 
			#
			@gArgs = &T38lib::Common::globbing(@ARGV);
			if ( $gArgs[0] ne $T38lib::Common::T38ERROR ) {
				@ARGV = @gArgs;
			} else {
				&warnme("Globbing of Command line argument failed");
				$status = 0; last SUB;
			}
		}	# endif $#ARGV != 0

		foreach $cfgFile (@gArgs)	{
			$logStr .= " $cfgFile";
			unless(&readConfigFile($cfgFile)) { $status = 0; last SUB; }
		}

		# Check key configuration file parameters.
		my $errflg = 0;
		foreach my $key ((
				'SQLInstallPwdSrvr',
				'SQLInstallPwdDB',
				'SQLPwdDBPassPhrase'
			)) {
			if ( !($gConfigValues{$key}) ) {
				&errme("Configuration variable $key is not valid.");
				$errflg = 1;
			}
		}

		if ($errflg) {
			$status = 0; last SUB;
		}

		# Check Perl version.

		unless ( &T38lib::Common::chkPerlVer() ) {
			&notifyWSub("Wrong version of Perl!");
			&notifyWSub("This program run on Perl version 5.005 and higher.");
			&notifyWSub("Check the Perl version by running perl -v on command line.");
			$status = 0;
			last SUB;
		}

		&notifyWSub("$gHostName: Running crypto manager with the following arguments: $logStr.");
	}	# SUB
	# ExitPoint:

	return($status);

}	# housekeeping

# ----------------------------------------------------------------------
# showHelp
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
sub showHelp() {
	print <<'EOT'
#*  t38cryptmgr - encryption maintenance manager.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:22 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/DataEncryption/Scripts/t38cryptmgr.pv_  $
#*
#* SYNOPSIS
#*  t38cryptmgr -h -a 10 -l logfileDirSuffix -x brc -S server cfgFile
#*	
#*  Where:
#*
#*  -h          Writes help screen on standard output, then exits.
#*  -a 10       Number of log file archived, default is 7
#*  -l logsuffx Optional Log File Directory suffix. This is used to
#*              ensure multiple copies of the program can run at the 
#*              same time without overwriting the log file.
#*  -S server   Name of the SQL Server with encrypted data. 
#*              Default is local server on default instance.
#*  -x execOpt  Execution option:
#*                  b = Backup Database master keys and store backup
#*					    password in T38DB002.
#*                  r = Regenerate Database master keys and store passwords
#*                      in T38DB002.
#*                  c = Checks symmetric/asymmetric keys in user databases.
#*					d = Check database master key on target server.
#*  cfgFile     Configuration file with configuration parameters. 
#*              Following parameters are accepted by t38cryptmgr.pl:
#*                  T38LIST:DMKBackupIncludeDB    = DBName
#*                  T38LIST:DMKBackupExcludeDB    = DBName
#*                  T38LIST:DMKRegenIncludeDB     = DBName
#*                  T38LIST:DMKRegenExcludeDB     = DBName
#*                  T38LIST:CRYPKEYCheckIncludeDB = DBName
#*                  T38LIST:CRYPKEYCheckExcludeDB = DBName
#*                  T38LIST:DMKCheckIncludeDB     = SrvrName\InstName.DBName
#*                  T38LIST:DMKCheckExcludeDB     = SrvrName\InstName.DBName
#*					  or
#*                  T38LIST:DMKCheckIncludeDB     = SrvrName.DBName
#*                  T38LIST:DMKCheckExcludeDB     = SrvrName.DBName
#*
#*
#*              In addition program is using the following parameters
#*              to connect to password database:
#*                  SQLInstallPwdSrvr = tcp:DVP02DB03,63520
#*                  SQLInstallPwdDB   = T38DB002
#*
#*
#*  The t38cryptmgr.pl program performs key management on requested
#*  databases in a given instance of SQL 2005 Server. For each
#*  requested database program can perform the following actions: 
#*
#*  - If backup of the master key is requested, program backs up dmk
#*  and saves the backup password in password management table in
#*  T38DB002 database.
#*
#*  - If regen of the master key is requested, program regenerates
#*  the dmk and saves the dmk password in password management table in
#*  T38DB002 database.
#*
#*  - If check user keys is requested, program calls the sp_T38CHKUSERKEYS
#*  procedure to use asymmetric/symmetric keys to encrypt/decrypt test
#*  string and issue an error for the first key that didn't work.
#*
#*  - If check database master key is requested, program reads list
#*  of all available databases from T38DB002 database. Filters out
#*  databases based on T38LIST:DMKCheckIncludeDB and T38LIST:DMKCheckExcludeDB
#*  lists to create list of databases to process. If -S option is used
#*  it will process databases only for that server. In order to check
#*  database master key, program reads dmk password from T38DB002
#*  database, connects to target database and attempts to open
#*  database master key.
#*
#*  Example:
#*      t38crypmgr.pl -S tcp:DVD10DB01,63518 -x bc t38dba.cfg
#*      Check user keys in databases, provided in t38dba.cfg file and
#*      backup database master keys on DVD10DB01\DF01 instance.
#*
#*      t38crypmgr.pl -x d t38dba.cfg t38cryptmgr.cfg
#*      Check database master keys. Get password management database (T38DB002)
#*      connection information from t38dba.cfg. Get list of databases to 
#*      filter out from t38cryptmgr.cfg file.
#***
EOT
} #	showHelp
