#!perl 
#*  t38cpdbdisk - Copy SQL Server database using disk copy..
#*
#*    $Author: A645276 $
#*    $Date: 2011/02/08 17:12:22 $
#*    $Revision: 1.1 $
#*    $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/t38cpdbdisk/Scripts/t38cpdbdisk.pv_  $
#*
#* SYNOPSIS
#*    t38cpdbdisk -h -a 10 -l logfileDirSuffix -S server -x execOpt cfgFile1 cfgFile2 ...
#*    
#*    Where:
#*    
#*    -h          Writes help screen on standard output, then exits.
#*    -l logsuffx Optional Log File Directory suffix. This is used to
#*                ensure multiple copies of the program can run at the 
#*                same time without overwriting the log file.
#*    -S server   Name of the SQL Server with destination copy. 
#*                Default is local server on default instance.
#*    -x execOpt  Execution option:
#*                    m = Mark source database with current timestamp using
#*                        T38LIST:DISKMIRRORIncludeDB parameters as input.
#*                    d = DetachDB - detaches databases, listed by 
#*                        T38LIST:DISKMIRRORIncludeDB parameters.
#*                    t = PrepareAttachDBScript - prepares attach db scripts
#*                        for databases, listed by T38LIST:DISKMIRRORIncludeDB
#*                        parameters.
#*                    a = AttachDB - runs attach db scripts for databases, 
#*                        listed by T38LIST:DISKMIRRORIncludeDB parameters.
#*                    o = PrepareCopyDB - prepares CopyDBFilesScript for source
#*                        to destination database.
#*                    c = Copy database using file copy for destination database, 
#*                        runs DetachDB for destination databases, listed with
#*                        T38LIST:DISKCOPYDB parameters. Runs CopyDBFilesScript
#*                        and AttachDB for destination databases, listed
#*                        with T38LIST:DISKCOPYDB parameters.
#*                    v = Verify mark for databases in 
#*                        T38LIST:DISKMIRRORIncludeDB on source and
#*                        destination servers.
#*                    y = Verify mark for source and destination databases in
#*                        T38LIST:DISKCOPYDB list.
#*    cfgFile     Configuration file with configuration parameters. 
#*                Following parameters are accepted to copy database via disk
#*                mirror from one server to another:
#*                    T38LIST:DISKMIRRORIncludeDB    = DBName
#*
#*                Following parameters are accepted to copy database via file
#*                copy on a same server:
#*                   T38LIST:DISKCOPYDB = Source DB Name => Destination DB Name
#*                All copied databases will use following parameters for
#*                destination file names (they normally are provided in
#*                t38dba.cfg).
#*                    MdfDrive = MDF Drive letter for destination database
#*                    NdfDrive = NDF Drive letter for destination database
#*                    LdfDrive = LDF Drive letter for destination database
#*                    MdfPath  = MDF Path for destination database
#*                    NdfPath  = NDF Path for destination database
#*                    LdfPath  = LDF Path for destination database
#*
#*                In order to verify database is copied correctly it is
#*                marked with extended property on source server. For
#*                this process to work the following parameters are used.
#*
#*                Provide source SQL server name for disk mirror.
#*                To provide server name and port number, have to force
#*                TCP Protocol for connection string.
#*
#*                DISKMIRRORSourceSrvr = RVQ02DB02,63519;Network Library=dbmssocn
#*
#*                Disk mirror source database marker record.
#*
#*                DISKMIRRORSourceDBExtPropName = T38DISKMIRRORMARKER
#*
#*    The t38cpdbdisk.pl program copies databases use disk technologies. It 
#*    works with two methods to copy databases.
#*        1) File copy - With this method database files are copied
#*            on a same server from source database to destination. The
#*            t38cpdbdisk.pl has to be called twice for this methods:
#*                a) Use -x o option to prepare all scripts to copy files.
#*                   With this option Source database has to be online. Script
#*                   is prepared to copy files based on source database file
#*                   properties. The files for destination database are 
#*                   based on configuration parameters t38mdf, t38ndf, t38ldf
#*                   and destination database name.
#*                   The second script is created to attach destination file.
#*                b) Use -x c option to detach destination database, copy files
#*                   and attach destination database. It is assumed that source
#*                   database is already detached by different process. Also
#*                   it will not attach the source database. It has to be done
#*                   with another process using the -a option.
#*        2) Disk Mirror - With this method database is copied from one 
#*           server to another with disk mirror technology. This program
#*           performs database related tasks to attach the copied files.
#*           Program assumes that exact disk mirror is created from source
#*           to destination server. It performs two steps: Prepare and
#*           Execute.
#*                a) Use -x mdt options to prepare attach script and to 
#*                   detach the database on destination server. In order
#*                   to create the attach script, database has to be online.
#*                   After attach script is created, database is detached to
#*                   allow disk mirror process to remove mirrored disk,
#*                   synchronize mirror, split the mirror and present it
#*                   to the system.
#*                b) Use -x a option to attach mirrored databases on 
#*                   destination server. This is dependent on success of
#*                   the sync/split process.
#*
#*    Example:
#*        Once a day the SRCDB001, SVCDB001 and SVCDB002 databases are 
#*        copied from source server to target reporting server using EMC
#*        TimeFinder sync/split process. Once a month another copy of 
#*        SVCDB001 database has to be created for month-end reporting.
#*        This copy will be created using file copy process locally on
#*        Reporting server.
#*        Two configuration file will be used for daily and monthly 
#*        process.
#*
#*        T38daily.cfg file records
#*        ==========================
#*
#*        T38LIST:DISKMIRRORIncludeDB    = SRCDB001
#*        T38LIST:DISKMIRRORIncludeDB    = SVCDB001
#*        T38LIST:DISKMIRRORIncludeDB    = SVCDB002
#*
#*        DISKMIRRORSourceSrvr = RVQ02DB02,63519;Network Library=dbmssocn
#*        DISKMIRRORSourceDBExtPropName = T38DISKMIRRORMARKER
#*
#*        T38monthly.cfg file records:
#*        =============================
#*
#*        T38LIST:DISKCOPYDB = SVCDB001=>SUADB001
#*
#*        And standard t38dba.cfg file is used with the following records:
#*        =============================
#*
#*        MdfDrive = F
#*        NdfDrive = F
#*        LdfDrive = L
#*
#*        Once a day, before TimeFinder sync/split process stars, the following
#*        command is scheduled.
#*
#*        1) t38cpdbdisk -x mtd t38daily.cfg
#*        This will create attach scripts for each database and detach them
#*        and mark corresponding database on source server with time stamp.
#*
#*        2) The sync/split process runs, which will copy data and log disk
#*        images from source server to target.
#*
#*        Once sync/split process is done, the following is executed:
#*        3) t38cpdbdisk -x av t38daily.cfg
#*        This will attach databases, using prepared attach scripts and
#*        validate attached database has same mark time stamp as source.
#*
#*        Once a month the following process will be used.
#*
#*        t38cpdbdisk -x o t38monthly.cfg t38dba.cfg
#*        This will create the copy files and attach db scripts for
#*        SUADB001 database.
#*
#*        t38cpdbdisk -x mtd t38daily.cfg
#*        This will create attach scripts for SVCDB001, SVCDB002 and SRCDB001
#*        databases and detach them.
#*
#*        The sync/split process runs, which will copy data and log disk
#*        images from source server to target.
#*
#*        Once sync/split process is done, the following is executed:
#*        t38cpdbdisk -x c t38monthly.cfg
#*        This will copy the SVCDB001 database files (just copied with 
#*        EMC TimeFinder) to files for SUADB001 database, using copy
#*        command. Once SUADB001 files are copied, SUADB001 database is
#*        attached with prepared script.
#*
#*        After SUADB001 database is created, the SVCDB001, SVCDB002 and
#*        SUADB001 databases can be attached.
#*        t38cpdbdisk -x avy t38daily.cfg t38monthly.cfg
#*
#*        This will complete the monthly process to copy SVCDB001 database
#*        from source server to target and then to create another copy of
#*        that database for month-end reporting.
#*
#*
#***

use strict;

use File::Basename;
use T38lib::Common qw(notifyMe notifyWSub logme warnme errme runOSCmd);
use T38lib::bbyado qw(:BBYADO_SUBS :BBYADO_VARS);
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use Getopt::Std;

# Global Variables
my ( $gCurrentDir, $gScriptName, $gScriptPath, $gHostName, $gNWarnings) = "";
my $gWrkDir	= 't38cpdbdiskWRK';
my @gArgs = ();

use vars qw(
		$gRunOpt
		$gSrvrName $gNetName $gInstName
		);

use constant SQLAGENTJOB_TIMEOUT	=> 240;			# Time out value in minutes for sql agent job to finish (4 hours)

# Main
&main();


############################  BBY Subroutines  ####################################

sub main {
	my $mainStatus	= 0;
	my $dbname		= '';
	my $dbpair		= '';
	SUB:
	{
		unless (&housekeeping())	{ $mainStatus = 1; last SUB; }
		unless (&mkwrkdir())		{ $mainStatus = 1; last SUB; }

		if ($gRunOpt =~ /[m]/) {	# Mark databases on source server
			unless (
				(defined ($gConfigValues{'T38LIST:DISKMIRRORIncludeDB'})) &&
				(scalar @{$gConfigValues{'T38LIST:DISKMIRRORIncludeDB'}} > 0)
			) { 
				&errme ("Configuration file is missing T38LIST:DISKMIRRORIncludeDB parameters");
				$mainStatus = 1; last SUB;
			}

			foreach $dbname (@{$gConfigValues{'T38LIST:DISKMIRRORIncludeDB'}}) {
				unless (&markSourceDB($dbname))	{ $mainStatus = 1; }
			}
		}	# if ($gRunOpt =~ /[m]/)

		if ($gRunOpt =~ /[t]/) {	# PrepareAttachDBScript
			unless (
				(defined ($gConfigValues{'T38LIST:DISKMIRRORIncludeDB'})) &&
				(scalar @{$gConfigValues{'T38LIST:DISKMIRRORIncludeDB'}} > 0)
			) { 
				&errme ("Configuration file is missing T38LIST:DISKMIRRORIncludeDB parameters");
				$mainStatus = 1; last SUB;
			}

			foreach $dbname (@{$gConfigValues{'T38LIST:DISKMIRRORIncludeDB'}}) {
				unless (&prepareAttachDBScript($dbname))	{ $mainStatus = 1; }
			}
		}	# if ($gRunOpt =~ /[t]/)

		if ($gRunOpt =~ /[o]/) {	# PrepareCopyDB
			unless (
				(defined ($gConfigValues{'T38LIST:DISKCOPYDB'})) &&
				(scalar @{$gConfigValues{'T38LIST:DISKCOPYDB'}} > 0)
			) { 
				&errme ("Configuration file is missing T38LIST:DISKCOPYDB parameters");
				$mainStatus = 1; last SUB;
			}

			unless(&chkT38DirParms())  { $mainStatus = 1; last SUB; }

			foreach $dbpair (@{$gConfigValues{'T38LIST:DISKCOPYDB'}}) {
				unless (&prepareCopyDB($dbpair))	{ $mainStatus = 1; }
			}
		}	# if ($gRunOpt =~ /[o]/)

		if ($gRunOpt =~ /[d]/) {	# DetachDB
			unless (
				(defined ($gConfigValues{'T38LIST:DISKMIRRORIncludeDB'})) &&
				(scalar @{$gConfigValues{'T38LIST:DISKMIRRORIncludeDB'}} > 0)
			) { 
				&errme ("Configuration file is missing T38LIST:DISKMIRRORIncludeDB parameters");
				$mainStatus = 1; last SUB;
			}

			foreach $dbname (@{$gConfigValues{'T38LIST:DISKMIRRORIncludeDB'}}) {
				unless (&detachDB($dbname))	{ $mainStatus = 1; }
			}
		}	# if ($gRunOpt =~ /[d]/)

		if ($gRunOpt =~ /[c]/) {	# Copy database with file copy
			unless (
				(defined ($gConfigValues{'T38LIST:DISKCOPYDB'})) &&
				(scalar @{$gConfigValues{'T38LIST:DISKCOPYDB'}} > 0)
			) { 
				&errme ("Configuration file is missing T38LIST:DISKCOPYDB parameters");
				$mainStatus = 1; last SUB;
			}

			foreach $dbpair (@{$gConfigValues{'T38LIST:DISKCOPYDB'}}) {
				unless (&runCopyDB($dbpair))	{ $mainStatus = 1; }
			}
		}	# if ($gRunOpt =~ /[c]/)

		if ($gRunOpt =~ /[a]/) {	# AttachDB
			unless (
				(defined ($gConfigValues{'T38LIST:DISKMIRRORIncludeDB'})) &&
				(scalar @{$gConfigValues{'T38LIST:DISKMIRRORIncludeDB'}} > 0)
			) { 
				&errme ("Configuration file is missing T38LIST:DISKMIRRORIncludeDB parameters");
				$mainStatus = 1; last SUB;
			}

			foreach $dbname (@{$gConfigValues{'T38LIST:DISKMIRRORIncludeDB'}}) {
				unless (&attachDB($dbname))	{ $mainStatus = 1; }
			}
		}	# if ($gRunOpt =~ /[a]/)

		if ($gRunOpt =~ /[v]/) {	# validate mark on source and destination servers.
			unless (
				(defined ($gConfigValues{'T38LIST:DISKMIRRORIncludeDB'})) &&
				(scalar @{$gConfigValues{'T38LIST:DISKMIRRORIncludeDB'}} > 0)
			) { 
				&errme ("Configuration file is missing T38LIST:DISKMIRRORIncludeDB parameters");
				$mainStatus = 1; last SUB;
			}

			foreach $dbname (@{$gConfigValues{'T38LIST:DISKMIRRORIncludeDB'}}) {
				unless (&validateMarkedDB($dbname, 1))	{ $mainStatus = 1; }
			}
		}	# if ($gRunOpt =~ /[v]/)

		if ($gRunOpt =~ /[y]/) {	# Validate source and destination databases from file copy
			unless (
				(defined ($gConfigValues{'T38LIST:DISKCOPYDB'})) &&
				(scalar @{$gConfigValues{'T38LIST:DISKCOPYDB'}} > 0)
			) { 
				&errme ("Configuration file is missing T38LIST:DISKCOPYDB parameters");
				$mainStatus = 1; last SUB;
			}

			foreach $dbpair (@{$gConfigValues{'T38LIST:DISKCOPYDB'}}) {
				unless (&validateMarkedDBPair($dbpair))	{ $mainStatus = 1; }
			}
		}	# if ($gRunOpt =~ /[y]/)

		last SUB;
	
	}	# SUB
	# ExitPoint:


	$mainStatus = 1	if ($gNWarnings > 0);

	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;

	exit($mainStatus);

}	# main


#######################  $Workfile:   t38cpdbdisk.pl  $ Subroutines  #################################

# ----------------------------------------------------------------------# ----------------------------------------------------------------------
#	chkT38DirParms		check config file parameters for t38 directories.
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	check config file parameters for t38 directories.
# ----------------------------------------------------------------------

sub chkT38DirParms () {
	my $key		= '';
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");
	foreach $key ((
		'MdfPath',
		'NdfPath',
		'LdfPath',
		'MdfDrive',
		'NdfDrive',
		'LdfDrive'
		)) {
		unless (defined($gConfigValues{$key}) && $gConfigValues{$key}) {
			&errme("Missing parameter $key in configuration file(s) " . join(' ', @gArgs));
			$status = 0;
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# chkT38DirParms


# ----------------------------------------------------------------------
#	getDBAttachScriptName		get database attach script name
# ----------------------------------------------------------------------
#	arguments:
#		$dbname	database name
#	return:
#		file name for attach database script
#	get database attach script name
# ----------------------------------------------------------------------

sub getDBAttachScriptName ($) {
	my $dbname	= shift;

	return ("$gWrkDir\\${dbname}_attachdb.sql");
}	# getDBAttachScriptName


# ----------------------------------------------------------------------
#	getDBCopyFilesScriptName		get database copy files script name
# ----------------------------------------------------------------------
#	arguments:
#		$dbsrc	source database name
#		$dbdest	destination database name
#	return:
#		file name for script to copy database files
# ----------------------------------------------------------------------
#	get database copy files script name
# ----------------------------------------------------------------------

sub getDBCopyFilesScriptName ($$) {
	my $dbsrc	= shift;
	my $dbdest	= shift;

	return ("$gWrkDir\\${dbsrc}-${dbdest}_copyfile.cmd");
}	# getDBCopyFilesScriptName


# ----------------------------------------------------------------------
#	getDBCopyFilesAgentJobName	get name of SQL Agent job for database copy
# ----------------------------------------------------------------------
#	arguments:
#		$dbsrc	source database name
#		$dbdest	destination database name
#	return:
#		SQL Server agent job name
# ----------------------------------------------------------------------
#	get name of SQL Agent job for database copy
# ----------------------------------------------------------------------

sub getDBCopyFilesAgentJobName ($$) {
	my $dbsrc	= shift;
	my $dbdest	= shift;

	return ("t38cpdbfiles${dbsrc}-${dbdest}");
}	# getDBCopyFilesAgentJobName

# ----------------------------------------------------------------------
#	markSourceDB		mark disk mirror source database
# ----------------------------------------------------------------------
#	arguments:
#		$dbname	database name to mark on source server
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	This subroutine marks disk mirror source database with timestamp
#	to validate with copied database.
# ----------------------------------------------------------------------

sub markSourceDB ($) {
	my $dbname		= shift;
	my $key			= '';
	my $adocmd		= 0;		# ADO Command object handle
	my $sql			= '';		# sql command buffer
	my $propname	= '';	# SQL Server database extended property name
	my $status		= 1;
SUB:
{
	&notifyWSub("Started. Database name is $dbname");

	foreach $key ((
		'DISKMIRRORSourceDBExtPropName',
		'DISKMIRRORSourceSrvr'
		)) {
		if (defined($gConfigValues{$key}) && $gConfigValues{$key}) {
			$gConfigValues{$key} = &T38lib::Common::stripWhitespace($gConfigValues{$key});
		} else {
			&errme("Missing parameter $key in configuration file(s) " . join(' ', @gArgs));
			$status = 0;
		}
	}

	unless ($adocmd = adoConnect($gConfigValues{DISKMIRRORSourceSrvr}, 'master')) { 
		&errme("adoConnect($gConfigValues{DISKMIRRORSourceSrvr}) Failed");
		$status = 0; last SUB;
	}

	&notifyWSub("Marking database $dbname on ($gConfigValues{DISKMIRRORSourceSrvr}) server");

	$propname = "N'$gConfigValues{DISKMIRRORSourceDBExtPropName}'";
	$sql	= << "	EOT";
		
		declare \@notes nvarchar(1024)
		set \@notes = N'Disk Mirror Starting for database $dbname at ' + convert(varchar(27), getdate(), 20)
		if exists (
			SELECT * FROM [$dbname].sys.fn_listextendedproperty
				(
				$propname, default, default, default, default, default, default
				)
		)
			EXEC [$dbname].sys.sp_updateextendedproperty \@name=$propname, \@value=\@notes
		else
			EXEC [$dbname].sys.sp_addextendedproperty \@name=$propname, \@value=\@notes
	EOT

	# Debug code: &notifyMe("execSQLCmd(\$adocmd, $sql))");
	unless(&execSQLCmd($adocmd, $sql)) { $status = 0; last SUB; }

	last SUB;
}	# SUB
# ExitPoint:
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# markSourceDB



# ----------------------------------------------------------------------
#	mkwrkdir		make work directory for t38cpdbdisk
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	make work directory for t38cpdbdisk
# ----------------------------------------------------------------------

sub mkwrkdir () {
	my $cmd			= '';
	my $osout		= "${gScriptPath}$gScriptName.mkdir.out";
	my ($logFileName, $lfbase, $logFilePath, $lftype);
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");

	unless ($gWrkDir) {
		&errme ("Empty directory name is not allowed.");
		$status	= 0; last SUB;
	}

	unless (-d $gWrkDir) {
		$logFileName = &T38lib::Common::getLogFileName($0);
		fileparse_set_fstype("MSWin32");
		($lfbase, $logFilePath, $lftype) = fileparse($logFileName, '\.[^\.]*');
		$osout	= $logFilePath . "$lfbase\.mkdir.out";

		$cmd = "mkdir \"$gWrkDir\"";
		unless (&runOSCmd($cmd, \$osout) ) {
			&errme("Cannot create directory $gWrkDir. Problem with $cmd");
			$status	= 0; last SUB;
		}
	}
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# mkwrkdir

# ----------------------------------------------------------------------
#	attachDB		run attach database scripts
# ----------------------------------------------------------------------
#	arguments:
#		$dbname	database name to attach
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	run attach database scripts
# ----------------------------------------------------------------------

sub attachDB ($dbname) {
	my $dbname	= shift;
	my $attachScriptName	= '';
	my $status	= 1;
SUB:
{
	&notifyWSub("Started. Database name $dbname");
	$attachScriptName = &getDBAttachScriptName($dbname);
	# unless ( &T38lib::Common::runSQLChk4Err($attachScriptName, $gSrvrName, "", "", "", "", "", "") == 0) {
	unless ( system("perl ${gScriptPath}t38xsql.pl -i $attachScriptName -S $gSrvrName") == 0) {
		&errme("Problem with running attach database script $attachScriptName.");
		$status = 0; last SUB;
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# attachDB



# ----------------------------------------------------------------------
#	detachDB		detach database
# ----------------------------------------------------------------------
#	arguments:
#		$dbname	database name
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	detach database
# ----------------------------------------------------------------------

sub detachDB ($) {
	my $dbname	= shift;
	my $adocmd	= 0;		# ADO Command object handle
	my @rs		= ();		# array with result set
	my $nrs		= 0;
	my $sql		= '';		# sql command buffer
	my $phyname	= '';
	my $i		= 0;
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");
	unless ($adocmd = adoConnect($gSrvrName, 'master')) { 
		&errme("adoConnect($gSrvrName) Failed");
		$status = 0; last SUB;
	}

	$sql	= << "	EOT";
		select physical_name from [$dbname].sys.database_files 
		order by file_id
	EOT
	unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
	unless (scalar @rs > 0) {
		&errme("No primary files defined for database $dbname");
		$status = 0; last SUB;
	}

	$sql = "ALTER DATABASE [$dbname] SET SINGLE_USER WITH ROLLBACK IMMEDIATE";
	&notifyMe("execSQLCmd(\$adocmd, $sql))");
	unless(&execSQLCmd($adocmd, $sql)) { $status = 0; last SUB; }

	$sql = "sp_detach_db '$dbname'";
	&notifyMe("execSQLCmd(\$adocmd, $sql))");
	unless(&execSQLCmd($adocmd, $sql)) { $status = 0; last SUB; }

	$nrs = scalar @rs;
	foreach $i (0..($nrs - 1)) {
		$phyname = &T38lib::Common::stripWhitespace($rs[$i]{physical_name});
		$phyname =~ s/^([a-z]):/\\\\$gNetName\\$1\$/i;
		unless (&runOSCmd("cacls $phyname /e /g BUILTIN\\Administrators:F") ) {
			&errme("Cannot grant full control rights to BUILTIN Administrators to $phyname file.");
			$status	= 0; last SUB;
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# detachDB


# ----------------------------------------------------------------------
#	parseDBPair		parse db pair
# ----------------------------------------------------------------------
#	arguments:
#		$dbpair
#	return:
#		(db1, db2)	Success
#		0			Failure
# ----------------------------------------------------------------------
#	This subroutine parses string in a form db1 => db2 and 
#	returns list (db1, db2)
# ----------------------------------------------------------------------

sub parseDBPair ($) {
	my $dbpair	= shift;
	my @dbarr	= ();

	@dbarr = split ('=>', $dbpair);
	return (0, 0)	if (scalar (@dbarr) != 2);
	$dbarr[0] = &T38lib::Common::stripWhitespace($dbarr[0]);
	$dbarr[1] = &T38lib::Common::stripWhitespace($dbarr[1]);
	return(@dbarr);
}	# parseDBPair


# ----------------------------------------------------------------------
#	prepareAttachDBScript		Prepare the Attach Database Script
# ----------------------------------------------------------------------
#	arguments:
#		$dbname	database name
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Prepare the Attach Database Script
# ----------------------------------------------------------------------

sub prepareAttachDBScript ($) {
	my $dbname	= shift;
	my $adocmd	= 0;		# ADO Command object handle
	my @rs		= ();		# array with result set
	my $nrs		= 0;
	my $sql		= '';		# sql command buffer
	my $phyname	= '';
	my $attachScriptName	= '';
	my $i		= 0;
	my $status	= 1;
SUB:
{
	&notifyWSub("Started. Database name $dbname");
	unless ($adocmd = adoConnect($gSrvrName, 'master')) { 
		&errme("adoConnect($gSrvrName) Failed");
		$status = 0; last SUB;
	}

	$attachScriptName = &getDBAttachScriptName($dbname);
	&T38lib::Common::archiveFile($attachScriptName, 7);
	unless (open ATTACHDBSCRIPT, ">$attachScriptName") {
		&errme("Cannot open file $attachScriptName for writing. $!"); 
		$status = 1;
	}

	$sql	= << "	EOT";
		select physical_name from [$dbname].sys.database_files 
		order by file_id
	EOT
	unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
	unless (scalar @rs > 0) {
		&errme("Check SQL Server for database $dbname. No files can be found for this database");
		$status = 0; last SUB;
	}

	print ATTACHDBSCRIPT "CREATE DATABASE [$dbname] ON\n";
	$nrs = scalar @rs;
	foreach $i (0..($nrs - 2)) {
		$phyname = &T38lib::Common::stripWhitespace($rs[$i]{physical_name});
		print ATTACHDBSCRIPT "   ( FILENAME = N'$phyname' ),\n";
	}
	$phyname = &T38lib::Common::stripWhitespace($rs[$nrs - 1]{physical_name});
	print ATTACHDBSCRIPT "   ( FILENAME = N'$phyname' )\n";
	print ATTACHDBSCRIPT "FOR ATTACH\nGO\n";
	
	last SUB;
}	# SUB
# ExitPoint:
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	close(ATTACHDBSCRIPT);
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# prepareAttachDBScript

# ----------------------------------------------------------------------
#	prepareCopyDB		prepare database file copy 
# ----------------------------------------------------------------------
#	arguments:
#		$dbpair	source => destination database pair
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	prepare database file copy 
# ----------------------------------------------------------------------

sub prepareCopyDB () {
	my $dbpair		= shift;
	my $dbsrc		= '';
	my $dbdest		= '';
	my $scriptname	= '';
	my $adocmd		= 0;		# ADO Command object handle
	my @rs			= ();		# array with result set
	my $nrs			= 0;
	my $sql			= '';		# sql command buffer
	my $phyname		= '';		# file name for SQL Server source database
	my $destname	= '';		# file name for SQL Server destination database
	my $i			= 0;
	my $status		= 1;
SUB:
{
	&notifyWSub("Started. Copy database $dbpair");
	($dbsrc, $dbdest) = &parseDBPair($dbpair);
	unless ($dbsrc && $dbdest) {
		&errme("Cannot get source and destination database names from the pair $dbpair.");
		$status = 0; last SUB;
	}

	unless ($adocmd = adoConnect($gSrvrName, 'master')) { 
		&errme("adoConnect($gSrvrName) Failed");
		$status = 0; last SUB;
	}

	$sql	= << "	EOT";
		select physical_name from [$dbsrc].sys.database_files 
		order by file_id
	EOT
	unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }

	$nrs = scalar @rs;
	unless ($nrs > 0) {
		&errme("Check SQL Server for database $dbsrc. No files can be found for this database");
		$status = 0; last SUB;
	}


	$scriptname = &getDBCopyFilesScriptName($dbsrc, $dbdest);
	&T38lib::Common::archiveFile($scriptname, 7);
	unless (open SCRIPTFILE, ">$scriptname") {
		&errme("Cannot open file $scriptname for writing. $!"); 
		$status = 1;
	}

	foreach $i (0..($nrs - 1)) {
		$phyname = &T38lib::Common::stripWhitespace($rs[$i]{physical_name});
		($destname = $phyname) =~ s/^.*\\//g;
		$destname  =~ s/$dbsrc/$dbdest/gi;
		# copy "S:\DBMS\t38mdf\QST2\SVCDB001.mdf" "F:\DBMS\T38MDF\QST3\SUADB001.mdf" /Y 

		if ($destname =~ /\.mdf/i) {
			print SCRIPTFILE "copy \"$phyname\" \"$gConfigValues{MdfDrive}:$gConfigValues{MdfPath}\\$gInstName\\$destname\" /Y\n";
		} elsif ($destname =~ /\.ndf/i) {
			print SCRIPTFILE "copy \"$phyname\" \"$gConfigValues{NdfDrive}:$gConfigValues{NdfPath}\\$gInstName\\$destname\" /Y\n";
		} elsif ($destname =~ /\.ldf/i) {
			print SCRIPTFILE "copy \"$phyname\" \"$gConfigValues{LdfDrive}:$gConfigValues{LdfPath}\\$gInstName\\$destname\" /Y\n";
		} else {
			&errme("This program cannot use extention for $destname file. It has to be .mdf, .ndf or .ldf");
			$status = 0;
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	close(SCRIPTFILE);
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# prepareCopyDB


# ----------------------------------------------------------------------
#	runCopyDB		run copy database with file copy 
# ----------------------------------------------------------------------
#	arguments:
#		$dbpair	source => destination database pair
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Run copy database with file copy.
#		1) Detach destination database
#		2) Run scripts created by prepareCopyDB sub via SQL Agent Job.
#		3) Attach destination database.
# ----------------------------------------------------------------------

sub runCopyDB () {
	my $dbpair		= shift;
	my $dbsrc		= '';
	my $dbdest		= '';
	my $agtjobname	= '';
	my $status		= 1;
SUB:
{
	&notifyWSub("Started. Copy database $dbpair");
	($dbsrc, $dbdest) = &parseDBPair($dbpair);
	unless ($dbsrc && $dbdest) {
		&errme("Cannot get source and destination database names from the pair $dbpair.");
		$status = 0; last SUB;
	}

	unless (&prepareAttachDBScript($dbdest))	{ $status = 0; last SUB; }
	unless (&detachDB($dbdest))	{ $status = 0; last SUB; }

	$agtjobname = &getDBCopyFilesAgentJobName($dbsrc, $dbdest);
	unless (&runSQLAgentJob($gSrvrName, $agtjobname))	{ $status = 0; last SUB; }
	unless (&attachDB($dbdest))	{ $status = 0; last SUB; }

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# runCopyDB

# ----------------------------------------------------------------------
#	runSQLAgentJob		run SQL Server Agent job and wait until it is comleted
# ----------------------------------------------------------------------
#	arguments:
#		$agtjobname	SQL Server agent job name.
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	run SQL Server Agent job and wait until it is comleted
# ----------------------------------------------------------------------

sub runSQLAgentJob ($$) {
	my $sqlserver	= shift;
	my $agtjobname	= shift;
	my $adocmd		= 0;		# ADO Command object handle
	my @rs			= ();		# array with result set
	my $sql			= '';		# sql command buffer
	my $i			= 0;
	my $sqlcurtime	= '';
	my $sqlrescode	= -1;
	my $run_requested_date	= '';
	my $stop_execution_date	= '';
	my $run_status	= -1;
	my $session_id	= -1;
	my $job_name	= '';
	my $startedtime	= 0;
	my $status		= 1;
SUB:
{
	&notifyWSub("Started. Job name is $agtjobname. SQL Server name is $sqlserver.");
	unless ($adocmd = adoConnect($sqlserver, 'msdb')) { 
		&errme("adoConnect($sqlserver) Failed");
		$status = 0; last SUB;
	}

	# Start SQL Agent job.
	$sql	= << "	EOT";
		select getdate() as 'currenttime'
		declare \@retcode int
		exec \@retcode = sp_start_job \@job_name = '$agtjobname'
		select \@retcode as 'returncode'
	EOT
	unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }

	foreach $i (0..( (scalar @rs) - 1)) {
		$sqlcurtime = $rs[$i]{currenttime}	if ( defined ($rs[$i]{currenttime}) );
		$sqlrescode = $rs[$i]{returncode}	if ( defined ($rs[$i]{returncode}) );
	}

	unless ($sqlcurtime) {
		&errme("There was problem with execution of the sql batch. Cannot get current date/time from SQL Server $sqlserver.");
		&notifyMe("SQL Batch:");
		&notifyMe($sql);
		$status = 0; last SUB;
	}

	unless ($sqlrescode != -1) {
		&errme("There was problem with execution of the sql batch. Cannot get result code from sp_start_job on $sqlserver.");
		&notifyMe("SQL Batch:");
		&notifyMe($sql);
		$status = 0; last SUB;
	}

	unless ($sqlrescode == 0) {
		&errme("Cannot run sp_start_job on $sqlserver. Result code is $sqlrescode.");
		$status = 0; last SUB;
	}

	# Monitor SQL Agent job.

	@rs = ();
	$sql = "exec sp_help_jobactivity \@job_name = '$agtjobname'";
	unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
	unless ((scalar @rs) == 1) {
		&errme("Multiple result rows for  run sp_help_jobactivity $agtjobname on $sqlserver.");
		$status = 0; last SUB;
	}

	unless (defined ($rs[0]{run_requested_date}) && $rs[0]{run_requested_date}) {
		&errme("The run_requested_date column is not available from sp_help_jobactivity $agtjobname on $sqlserver.");
		$status = 0; last SUB;
	}

	$job_name = &T38lib::Common::stripWhitespace($rs[0]{job_name});
	unless (uc($job_name) eq uc($agtjobname)) {
		&errme("The job name $job_name from sp_help_jobactivity on $sqlserver does not match requested $agtjobname job.");
		$status = 0; last SUB;
	}

	$run_requested_date 	= $rs[0]{run_requested_date};
	$stop_execution_date	= $rs[0]{stop_execution_date};
	$run_status				= $rs[0]{run_status};
	$session_id				= $rs[0]{session_id};


	# Check if $run_requested_date is within reasonable range from the time
	# we requested the job.

	@rs = ();
	$sql = "select datediff(mi, '$sqlcurtime', '$run_requested_date' ) as 'diffinmin'";
	unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
	unless (0 <= $rs[0]{diffinmin} && $rs[0]{diffinmin} < 10) {
		&errme("Internal error. Time difference between actual job requested time ($sqlcurtime) and reported request time ($run_requested_date) is outside of the range 0..10 minutes.");
		$status = 0; last SUB;
	}

	# Requested job started. Now we have to monitor when it is done.

	$startedtime = time();
	while (1)  {
		# If job stop_execution_date is null (it's value is '') or job status is 4, 
		# job is in progress.
		# Note SQL Server also returns null for job_status if it is in progress.
		# Perl will interpret Null result and 0 as same value. For this reason
		# we have to check stop_execution_date and run_status.

		if ($stop_execution_date && $run_status != 4) {
			# We are done, exit the loop.
			last;
		}

		sleep 30;
		if ( (time() - $startedtime)/60 > SQLAGENTJOB_TIMEOUT) {
			&errme("Timeout expired for job $agtjobname. Was waiting for " . (time() - $startedtime)/60 . " minutes for job to complete.");
			$status = 0; last SUB;
		}

		# Get job status.

		@rs = ();
		$sql = "exec sp_help_jobactivity \@job_name = '$agtjobname'";
		unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
		unless ((scalar @rs) == 1) {
			&errme("Multiple result rows for  run sp_help_jobactivity $agtjobname on $sqlserver.");
			$status = 0; last SUB;
		}

		$job_name = &T38lib::Common::stripWhitespace($rs[0]{job_name});
		unless (uc($job_name) eq uc($agtjobname)) {
			&errme("The job name $job_name from sp_help_jobactivity on $sqlserver does not match requested $agtjobname job.");
			$status = 0; last SUB;
		}

		unless ($session_id == $rs[0]{session_id}) {
			&errme("The session id for job name $job_name changed from $session_id to $rs[0]{session_id}.");
			&notifyMe("This must be different job, that we originally requested.");
			$status = 0; last SUB;
		}

		# We are still running same job. Get job run status and check it at the top of the loop.
		$run_status				= $rs[0]{run_status};
		$stop_execution_date	= $rs[0]{stop_execution_date};
	}

	# We are done with the job. Check for good result code.
	# Run Status of the job execution from sysjobhistory
	#
	#	0 = Failed
	#	1 = Succeeded
	#	2 = Retry
	#	3 = Canceled
	#	4 = In progress

	unless ($run_status == 1) {
		&errme ("Job $agtjobname on $sqlserver did not succeed.");
		&notifyMe ("Review job history, fix the problem and re-run $gScriptName");
		$status = 0; last SUB;
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# runSQLAgentJob


# ----------------------------------------------------------------------
#	validateMarkedDB		validate marked database
# ----------------------------------------------------------------------
#	arguments:
#		$dbname		database name to mark on source server
#		$srcSrvrFlg	1 = Check mark between current server and source server
#		$dbdest		(optional) destination database name. If not provided
#					use $dbname for destination database name.
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	This subroutine checks the mark on source and target database. If 
#	$srcSrvrFlg is set, get source server name from DISKMIRRORSourceDBExtPropName
#	configuration file parameter. If $srvSrvrFlg is 0, caller should 
#	provide $dbdest name, which is different from $dbname, since test
#	will be performed on a current server.
# ----------------------------------------------------------------------

sub validateMarkedDB ($) {
	my $dbname		= shift;
	my $srcSrvrFlg	= shift;
	my $dbdest		= shift;
	my $key			= '';
	my $sqlSrvr		= '';
	my $adocmd		= 0;		# ADO Command object handle
	my $sql			= '';		# sql command buffer
	my @rs			= ();		# array with result set
	my $propname	= '';		# SQL Server database extended property name
	my $srcmark		= '';		# Values for the marker on a source database
	my $destmark	= '';		# Values for the marker on a destination database
	my $status		= 1;
SUB:
{
	&notifyWSub("Started. Source Database:$dbname, Source Server Flag: '$srcSrvrFlg', Destination Database: '$dbdest'.");

	$key = 'DISKMIRRORSourceDBExtPropName';
	if (defined($gConfigValues{$key}) && $gConfigValues{$key}) {
		$gConfigValues{$key} = &T38lib::Common::stripWhitespace($gConfigValues{$key});
	} else {
		&errme("Missing parameter $key in configuration file(s) " . join(' ', @gArgs));
		$status = 0;
	}
	$propname = "N'$gConfigValues{$key}'";

	if ($srcSrvrFlg) {
		$key = 'DISKMIRRORSourceSrvr';
		if (defined($gConfigValues{$key}) && $gConfigValues{$key}) {
			$gConfigValues{$key} = &T38lib::Common::stripWhitespace($gConfigValues{$key});
		} else {
			&errme("Missing parameter $key in configuration file(s) " . join(' ', @gArgs));
			$status = 0;
		}
		$sqlSrvr = $gConfigValues{$key};
	} else {
		$sqlSrvr = $gSrvrName;
	}

	# Get marker for source database.

	unless ($adocmd = adoConnect($sqlSrvr, 'master')) { 
		&errme("adoConnect($sqlSrvr) Failed");
		$status = 0; last SUB;
	}

	&notifyWSub("Get database marker $propname for database $dbname from $sqlSrvr");

	$sql	= << "	EOT";
		select value from [$dbname].sys.extended_properties
		where class_desc = 'DATABASE' and name = $propname
	EOT

	# Debug code: &notifyMe("execSQLCmd(\$adocmd, $sql))");
	unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
	unless (scalar @rs == 1) {
		&errme("Cannot get marker value. Problem with SQL statement:");
		&notifyMe("\t $sql");
		$status = 0; last SUB;
	}

	$srcmark = &T38lib::Common::stripWhitespace($rs[0]{value});

	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	@rs = ();

	# Get marker for destination database.

	unless ($dbdest) { $dbdest = $dbname; }

	$sqlSrvr = $gSrvrName;

	unless ($adocmd = adoConnect($sqlSrvr, 'master')) { 
		&errme("adoConnect($sqlSrvr) Failed");
		$status = 0; last SUB;
	}

	&notifyWSub("Get database marker $propname for database $dbdest from $sqlSrvr");

	$sql	= << "	EOT";
		select value from [$dbdest].sys.extended_properties
		where class_desc = 'DATABASE' and name = $propname
	EOT

	# Debug code: &notifyMe("execSQLCmd(\$adocmd, $sql))");
	unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
	unless (scalar @rs == 1) {
		&errme("Cannot get marker value. Problem with SQL statement:");
		&notifyMe("\t $sql");
		$status = 0; last SUB;
	}

	$destmark = &T38lib::Common::stripWhitespace($rs[0]{value});

	# Compare marks.

	unless ($srcmark eq $destmark) {
		&errme("Mark $propname for source database $dbname does not match mark for destination database $dbdest.");
		&notifyMe("Source Mark : $srcmark.");
		&notifyMe("Dest. Mark  : $destmark.");
		$status = 0; last SUB;
	}

	last SUB;
}	# SUB
# ExitPoint:
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# validateMarkedDB


# ----------------------------------------------------------------------
#	validateMarkedDBPair		validate databases from file copy 
# ----------------------------------------------------------------------
#	arguments:
#		$dbpair	source => destination database pair
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Validate markder for source and destination databases created by
#	file copy.
# ----------------------------------------------------------------------

sub validateMarkedDBPair () {
	my $dbpair		= shift;
	my $dbsrc		= '';
	my $dbdest		= '';
	my $status		= 1;
SUB:
{
	&notifyWSub("Started. Validate database $dbpair");
	($dbsrc, $dbdest) = &parseDBPair($dbpair);
	unless ($dbsrc && $dbdest) {
		&errme("Cannot get source and destination database names from the pair $dbpair.");
		$status = 0; last SUB;
	}

	unless (&validateMarkedDB($dbsrc, 0, $dbdest))	{ $status = 0; last SUB; }

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# validateMarkedDBPair


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
	my $logFileName		= '';
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
	$gNetName	= $gHostName;	# SQL Server machine name
	$gInstName	= '';			# SQL Server instance name
	$gRunOpt	= '';			# Execution options 
	$gWrkDir	= "${gScriptPath}${gScriptName}WRK";

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

		&notifyWSub("Domain Name: " . &Win32::DomainName() . " User Name: " . &Win32::LoginName());
		&notifyWSub("Current directory: " .  &Win32::GetCwd());

		if($Getopt::Std::opt_x) {
			$logStr .= " -x $Getopt::Std::opt_x";
			if ($Getopt::Std::opt_x =~ /^[dtaocmvy]+$/) {
				$gRunOpt = $Getopt::Std::opt_x;
			} else {
				&errme("Invalid -x options. Allowed values are dtaocmvy.");
				$status = 0;
				last SUB;
			}
		}

		if ($Getopt::Std::opt_S) {
			$logStr .= " -S $Getopt::Std::opt_S";
			$gSrvrName	= uc($Getopt::Std::opt_S);
			$gSrvrName	=~ s/^\./$gHostName/;
			($gNetName, $gInstName)	=	split("\\\\", $gSrvrName);
			$gInstName =~ s/^\s+//g; $gInstName =~ s/\s+$//g;
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

		# Check Perl version.

		unless ( &T38lib::Common::chkPerlVer() ) {
			&notifyWSub("Wrong version of Perl!");
			&notifyWSub("This program run on Perl version 5.005 and higher.");
			&notifyWSub("Check the Perl version by running perl -v on command line.");
			$status = 0;
			last SUB;
		}

		&notifyWSub("$gHostName: Running dbcopy with the following arguments: $logStr.");
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
#*  t38cpdbdisk - Copy SQL Server database using disk copy..
#*
#*    $Author: A645276 $
#*    $Date: 2011/02/08 17:12:22 $
#*    $Revision: 1.1 $
#*    $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/t38cpdbdisk/Scripts/t38cpdbdisk.pv_  $
#*
#* SYNOPSIS
#*    t38cpdbdisk -h -a 10 -l logfileDirSuffix -S server -x execOpt cfgFile1 cfgFile2 ...
#*    
#*    Where:
#*    
#*    -h          Writes help screen on standard output, then exits.
#*    -l logsuffx Optional Log File Directory suffix. This is used to
#*                ensure multiple copies of the program can run at the 
#*                same time without overwriting the log file.
#*    -S server   Name of the SQL Server with destination copy. 
#*                Default is local server on default instance.
#*    -x execOpt  Execution option:
#*                    m = Mark source database with current timestamp using
#*                        T38LIST:DISKMIRRORIncludeDB parameters as input.
#*                    d = DetachDB - detaches databases, listed by 
#*                        T38LIST:DISKMIRRORIncludeDB parameters.
#*                    t = PrepareAttachDBScript - prepares attach db scripts
#*                        for databases, listed by T38LIST:DISKMIRRORIncludeDB
#*                        parameters.
#*                    a = AttachDB - runs attach db scripts for databases, 
#*                        listed by T38LIST:DISKMIRRORIncludeDB parameters.
#*                    o = PrepareCopyDB - prepares CopyDBFilesScript for source
#*                        to destination database.
#*                    c = Copy database using file copy for destination database, 
#*                        runs DetachDB for destination databases, listed with
#*                        T38LIST:DISKCOPYDB parameters. Runs CopyDBFilesScript
#*                        and AttachDB for destination databases, listed
#*                        with T38LIST:DISKCOPYDB parameters.
#*                    v = Verify mark for databases in 
#*                        T38LIST:DISKMIRRORIncludeDB on source and
#*                        destination servers.
#*                    y = Verify mark for source and destination databases in
#*                        T38LIST:DISKCOPYDB list.
#*    cfgFile     Configuration file with configuration parameters. 
#*                Following parameters are accepted to copy database via disk
#*                mirror from one server to another:
#*                    T38LIST:DISKMIRRORIncludeDB    = DBName
#*
#*                Following parameters are accepted to copy database via file
#*                copy on a same server:
#*                   T38LIST:DISKCOPYDB = Source DB Name => Destination DB Name
#*                All copied databases will use following parameters for
#*                destination file names (they normally are provided in
#*                t38dba.cfg).
#*                    MdfDrive = MDF Drive letter for destination database
#*                    NdfDrive = NDF Drive letter for destination database
#*                    LdfDrive = LDF Drive letter for destination database
#*                    MdfPath  = MDF Path for destination database
#*                    NdfPath  = NDF Path for destination database
#*                    LdfPath  = LDF Path for destination database
#*
#*                In order to verify database is copied correctly it is
#*                marked with extended property on source server. For
#*                this process to work the following parameters are used.
#*
#*                Provide source SQL server name for disk mirror.
#*                To provide server name and port number, have to force
#*                TCP Protocol for connection string.
#*
#*                DISKMIRRORSourceSrvr = RVQ02DB02,63519;Network Library=dbmssocn
#*
#*                Disk mirror source database marker record.
#*
#*                DISKMIRRORSourceDBExtPropName = T38DISKMIRRORMARKER
#*
#*    The t38cpdbdisk.pl program copies databases use disk technologies. It 
#*    works with two methods to copy databases.
#*        1) File copy - With this method database files are copied
#*            on a same server from source database to destination. The
#*            t38cpdbdisk.pl has to be called twice for this methods:
#*                a) Use -x o option to prepare all scripts to copy files.
#*                   With this option Source database has to be online. Script
#*                   is prepared to copy files based on source database file
#*                   properties. The files for destination database are 
#*                   based on configuration parameters t38mdf, t38ndf, t38ldf
#*                   and destination database name.
#*                   The second script is created to attach destination file.
#*                b) Use -x c option to detach destination database, copy files
#*                   and attach destination database. It is assumed that source
#*                   database is already detached by different process. Also
#*                   it will not attach the source database. It has to be done
#*                   with another process using the -a option.
#*        2) Disk Mirror - With this method database is copied from one 
#*           server to another with disk mirror technology. This program
#*           performs database related tasks to attach the copied files.
#*           Program assumes that exact disk mirror is created from source
#*           to destination server. It performs two steps: Prepare and
#*           Execute.
#*                a) Use -x mdt options to prepare attach script and to 
#*                   detach the database on destination server. In order
#*                   to create the attach script, database has to be online.
#*                   After attach script is created, database is detached to
#*                   allow disk mirror process to remove mirrored disk,
#*                   synchronize mirror, split the mirror and present it
#*                   to the system.
#*                b) Use -x a option to attach mirrored databases on 
#*                   destination server. This is dependent on success of
#*                   the sync/split process.
#*
#*    Example:
#*        Once a day the SRCDB001, SVCDB001 and SVCDB002 databases are 
#*        copied from source server to target reporting server using EMC
#*        TimeFinder sync/split process. Once a month another copy of 
#*        SVCDB001 database has to be created for month-end reporting.
#*        This copy will be created using file copy process locally on
#*        Reporting server.
#*        Two configuration file will be used for daily and monthly 
#*        process.
#*
#*        T38daily.cfg file records
#*        ==========================
#*
#*        T38LIST:DISKMIRRORIncludeDB    = SRCDB001
#*        T38LIST:DISKMIRRORIncludeDB    = SVCDB001
#*        T38LIST:DISKMIRRORIncludeDB    = SVCDB002
#*
#*        DISKMIRRORSourceSrvr = RVQ02DB02,63519;Network Library=dbmssocn
#*        DISKMIRRORSourceDBExtPropName = T38DISKMIRRORMARKER
#*
#*        T38monthly.cfg file records:
#*        =============================
#*
#*        T38LIST:DISKCOPYDB = SVCDB001=>SUADB001
#*
#*        And standard t38dba.cfg file is used with the following records:
#*        =============================
#*
#*        MdfDrive = F
#*        NdfDrive = F
#*        LdfDrive = L
#*
#*        Once a day, before TimeFinder sync/split process stars, the following
#*        command is scheduled.
#*
#*        1) t38cpdbdisk -x mtd t38daily.cfg
#*        This will create attach scripts for each database and detach them
#*        and mark corresponding database on source server with time stamp.
#*
#*        2) The sync/split process runs, which will copy data and log disk
#*        images from source server to target.
#*
#*        Once sync/split process is done, the following is executed:
#*        3) t38cpdbdisk -x a t38daily.cfg
#*        This will attach databases, using prepared attach scripts.
#*
#*        Once a month the following process will be used.
#*
#*        t38cpdbdisk -x o t38monthly.cfg t38dba.cfg
#*        This will create the copy files and attach db scripts for
#*        SUADB001 database.
#*
#*        t38cpdbdisk -x mtd t38daily.cfg
#*        This will create attach scripts for SVCDB001, SVCDB002 and SRCDB001
#*        databases and detach them.
#*
#*        The sync/split process runs, which will copy data and log disk
#*        images from source server to target.
#*
#*        Once sync/split process is done, the following is executed:
#*        t38cpdbdisk -x c t38monthly.cfg
#*        This will copy the SVCDB001 database files (just copied with 
#*        EMC TimeFinder) to files for SUADB001 database, using copy
#*        command. Once SUADB001 files are copied, SUADB001 database is
#*        attached with prepared script.
#*
#*        After SUADB001 database is created, the SVCDB001, SVCDB002 and
#*        SUADB001 databases can be attached.
#*        t38cpdbdisk -x a t38daily.cfg
#*
#*        This will complete the monthly process to copy SVCDB001 database
#*        from source server to target and then to create another copy of
#*        that database for month-end reporting.
#*
EOT
} #    showHelp
