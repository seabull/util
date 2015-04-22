#!perl

#------------------------------------------------------------------------------
# PVCS info
#
# $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/T38lib/bbyado.pv_  $
# $Author: A645276 $
# $Date: 2011/02/08 17:25:26 $ 
# $Revision: 1.1 $
#------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# $Workfile:   bbyado.pm  $
#
# History:
#
# $Log: bbyado.pm,v $
# Revision 1.1  2011/02/08 17:25:26  A645276
# init check in
#
# 
#    Rev 1.8   Apr 09 2007 09:26:24   tsmask
# added code so repository server name with instances work properly.
# 
#    Rev 1.7   Aug 30 2004 08:56:50   tsmask
# Added function to connect to Active Directory
# 
#    Rev 1.6   Sep 05 2003 17:27:54   TSMMXR
# Because connection pooling is on, ADO submits all commands twice. First time with FMTONLY option to get result set metadata and second time to execute statements (SET FMTONLY ON exec ... SET FMTONLY OFF exec ...). With extended stored procedures, this produces side effects. Use OLE DB Services=-4; This will disable connection pooling as well as automatic transaction enlistment (used by DTC).
# 
#    Rev 1.4   29 Aug 2002 16:56:36   TSMMXR
# Added function to kill users and restrict access to database.
# 
#    Rev 1.3   19 Aug 2002 13:22:24   TSMMXR
# Added execSQL2Arr subroutine.
# 
#    Rev 1.2   01 Aug 2002 10:31:10   TSMMXR
# Added new function: execSQL2File.
# 
#    Rev 1.1   19 Apr 2002 19:51:04   tsmmxr
# Changed adoConnect subroutine not to use dot for local hostname. Added optional parameter to request dot.
# This change was done to fix bug in older MDAC version, where connection cannot be created to local host, using '.' for server name.
# 
#    Rev 1.0   Nov 21 2001 18:56:52   TSMMXR
# Initial revision.
# 
#
#-------------------------------------------------------------------------------

# Setting the default package to 
package T38lib::bbyado;

use Sys::Hostname;
use T38lib::Common qw(notifyMe notifyWSub  errme);
use OLE;
use Carp qw(croak carp);

# Use the Perl library's Exporter module.
require Exporter;

# Turn on strict
use strict;

# Declaration of package variables.
use vars qw($VERSION $gAdoFlgs @ISA @EXPORT @EXPORT_OK $T38ERROR %EXPORT_TAGS);

# Subclass Exporter and AutoLoader
@ISA = qw(Exporter AutoLoader);

# Add the names of functions and other package variables that we want to
# export by default.
# Item to export into caller namespace by default.
#@EXPORT = qw(adoConnect);

# Add the names of functions and other package variables that we want to 
# exported on request.
@EXPORT_OK = qw(adConnect adoConnect execSQL execSQL2File execSQL2Arr 
				execSQLBat execSQLCmd
				adoProperties adoProperties4Conn adoProperties4Rs
				isADOok killDBAccess showADOErrors setADOShowAllErrors
				);

# All names of EXPORT and EXPORT_OK in EXPORT_TAGS{tag} anonymous list
# Define names for sets of symbols
%EXPORT_TAGS = (
				BBYADO_SUBS => [qw( adConnect adoConnect execSQL execSQL2File execSQL2Arr 
					execSQLBat execSQLCmd
					adoProperties adoProperties4Conn adoProperties4Rs
					isADOok killDBAccess showADOErrors setADOShowAllErrors)],
			    BBYADO_VARS => [qw()]);
			    
# A version number that you should increment every time you generate a new
# release of the module.
$VERSION	= do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf '%d'.'.%02d'x$#r,@r};
$T38ERROR=$T38lib::Common::T38ERROR;
$gAdoFlgs=0;	# Ado flags:
				# 0x0001	Show Ado warnings (SQLState = 01000)

# Function declaration in alphabetical order in bbyado.pm

sub adConnect ();
sub adoConnect ($$;$);
sub adoProperties (\%);
sub adoProperties4Conn (\%);
sub adoProperties4Rs (\%);
sub execSQL ($$$);
sub execSQL2File ($$$$;$$$);
sub execSQL2Arr ($$$);
sub execSQLBat ($$);
sub execSQLCmd ($$);
sub isADOok (\%);
sub killDBAccess ($$);
sub showADOErrors (\%);
sub setADOShowAllErrors ($);



# ----------------------------------------------------------------------
#	ADconnect	ADO connection to Active Directory
# ----------------------------------------------------------------------
#	arguments: None
#
#	return:
#		command object for ADO connection. Command name is "cmd1"
#		0	Failure
# ----------------------------------------------------------------------

sub adConnect () {

	my ($appPath, $appName, $appSuffix);

	my $conn			= 0;		# ADO connection object handle
	my $cmd			= 0;		# ADO Command object handle
	my $sqlerr		= 0;

	my $debug = 0;		# No debug
	# $debug |= 0x01;	# print Connection properties
	# $debug |= 0x02;	# print all SQL Errors (include messages).
SUB:
{
	# Initialize application name.
	my ($appPath, $appName, $appSuffix)	
					= &T38lib::Common::parseProgramName();
	$appName = $0	unless ($appName);

	# Create Connection OLE Object and initialize variables for connection.
	unless ($conn = CreateObject OLE "ADODB.Connection") {
		&errme("Create connection object failed: $!");
		last SUB;
	}

	$sqlerr = $conn->Errors;
	$sqlerr->Clear();

	# Create Command object.

	unless ($cmd = CreateObject OLE "ADODB.Command") {
		&errme("Create command object failed: $!");
		last SUB;
	}

	$conn->{Provider} = "ADsDSOObject";

	# Print connection properties.
	if ($debug & 0x01) { adoProperties4Conn(%{$conn->Properties}); }

	$conn->Open("Active Directory Provider");	# connect to data source

	unless ( &isADOok($sqlerr)) { 
		&errme("Cannot open connection to Active Directory"); 
		showADOErrors(%{$sqlerr});
		$cmd->Close(); $cmd = 0;
		last SUB; 
	}

	if ($debug & 0x01) { adoProperties4Conn(%{$conn->Properties}); }

	$sqlerr->Clear();

	# Setup command for connection, so we can execute batches.

	$cmd->{Name} = "cmd1";
	$cmd->{ActiveConnection} = $conn;

	last SUB;
}
#ExitSub
	# close the data source if we have problem with command object.
	if (!$cmd && $conn)	{ $conn->Close(); $conn = 0; }

	# Return command object.
	return($cmd);
} # adConnect

# ----------------------------------------------------------------------
#	adoConnect	creates connection to database server
# ----------------------------------------------------------------------
#	arguments:
#		dbSrvr		name of the database server: srvrName[\instName]
#		dbName		database name
#		useDotHost	optional flag, forcing to use . for server name if
#					connectiong to local host. 
#	return:
#		command object for ADO connection. Command name is "cmd1"
#		0	Failure
# ----------------------------------------------------------------------

sub adoConnect ($$;$) {
	my $dbSrvr		= shift;
	my $dbName		= shift;
	my $useDotHost	= shift;
	my ($netSrvr, $instName)
					= split("\\\\", $dbSrvr);
    my $lHostName	= hostname;
	my ($appPath, $appName, $appSuffix);
	my $sqlFullName	= '';		# SQL Server full name for connection: (\\server\instance).
	my $conn		= 0;		# ADO connection object handle
	my $cmd			= 0;		# ADO Command object handle
	my $sqlerr		= 0;

	my $debug = 0;		# No debug
	# $debug |= 0x01;	# print Connection properties
	# $debug |= 0x02;	# print all SQL Errors (include messages).
SUB:
{
	# Initialize application name.
	my ($appPath, $appName, $appSuffix)	
					= &T38lib::Common::parseProgramName();
	$appName = $0	unless ($appName);

	if ($useDotHost) {
		# If applicable, add instance name to SQL Server name.
		$netSrvr = uc($netSrvr);
		$netSrvr =  '.'	if ($lHostName eq $netSrvr);

		$sqlFullName = ($instName) ? "$netSrvr\\$instName" : $netSrvr;
	} else {
		$sqlFullName = $dbSrvr;
	}

	# This change is done when the old repository server ds02dba
	# has been decommissioned and we have a new repository server
	# on cluster servers
	#
	# Match $dbSrvr with string "TCP:ServerName,PortNumber"
	# If this is the case then set the SQLFullName variable as
	# Server_name,PortNumber;Network Library=dbmssocn
	#

	$dbSrvr =~ s/^\s+//;		# Remove leading white spaces
	$dbSrvr =~ s/\s+$//;		# Remove trailing white spaces
	if ($dbSrvr =~ /^TCP\s*:\s*(\S+)\s*\,\s*(\d+)$/i) {
		$sqlFullName = "$1,$2;Network Library=dbmssocn";
	}

	# Create Connection OLE Object and initialize variables for connection.
	unless ($conn = CreateObject OLE "ADODB.Connection") {
		&errme("Create connection object failed: $!");
		last SUB;
	}

	$sqlerr = $conn->Errors;
	$sqlerr->Clear();

	# Create Command object.

	unless ($cmd = CreateObject OLE "ADODB.Command") {
		&errme("Create command object failed: $!");
		last SUB;
	}

	# Connect to Database Server with created object.

	# Note. Use OLE DB Services=-4; This will disable connection pooling as well
	# as automatic transaction enlistment (used by DTC). 
	# Disable connection pooling in order to remove set FMTONLY on with ADO.
	# If pooling is enabled, the stored procedures will be executed twice, with
	# SET FMTONLY ON ... SET FMTONLY OFF and without. 
	#
	# Setting OLE DB Services by Using ADO Connection String Attributes
	# Services enabled 				Value in connection string
	# ----------------------------	--------------------------------
	# All services (the default)	"OLE DB Services = -1;" 
	# All services except pooling 	"OLE DB Services = -2;" 
	# All services except pooling 
	#	and auto-enlistment 		"OLE DB Services = -4;" 
	# All services except client 
	#	cursor 						"OLE DB Services = -5;" 
	# All services except client 
	#	cursor and pooling 			"OLE DB Services = -6;" 
	# No services 					"OLE DB Services = 0;" 


	$conn->{ConnectionString} = "Provider=SQLOLEDB;Server=$sqlFullName;Initial Catalog=$dbName;Trusted_Connection=Yes;Application Name=$appName;Connect Timeout=30;OLE DB Services=-4;";

	# Print connection properties.
	if ($debug & 0x01) { adoProperties4Conn(%{$conn->Properties}); }

	$conn->Open();	# connect to data source
	unless ( &isADOok($sqlerr)) { 
		&errme("Cannot open connection to $sqlFullName..$dbName."); 
		showADOErrors(%{$sqlerr});
		$cmd->Close(); $cmd = 0;
		last SUB; 
	}

	if ($debug & 0x01) { adoProperties4Conn(%{$conn->Properties}); }

	$sqlerr->Clear();

	# Setup command for connection, so we can execute batches.

	$cmd->{Name} = "cmd1";
	$cmd->{ActiveConnection} = $conn;

	last SUB;
}
#ExitSub
	# close the data source if we have problem with command object.
	if (!$cmd && $conn)	{ $conn->Close(); $conn = 0; }

	# Return command object.
	return($cmd);
}	# adoConnect


# ----------------------------------------------------------------------
#	adoProperties -- dump ADO properties
# ----------------------------------------------------------------------
#	arguments:
#		properties	ado object properties
# ----------------------------------------------------------------------
#	Ado properties are printed to log file
# ----------------------------------------------------------------------

sub adoProperties (\%) {
	my $properties = shift;
	my $hKey;

	foreach $hKey (keys %{$properties}) {
		&notifyMe("\t${%{$hKey}}{name}\t= ${%{$hKey}}{Value}");
	}
}	# adoProperties

# ----------------------------------------------------------------------
#	adoProperties4Conn -- dump ADO conneciton properties
# ----------------------------------------------------------------------
#	arguments:
#		properties	ado connection object properties
# ----------------------------------------------------------------------
#	Connection object properties are printed to log file
# ----------------------------------------------------------------------

sub adoProperties4Conn (\%) {
	my $properties = shift;

	&notifyWSub("ADO Connection Properties:");
	&adoProperties($properties);
	&notifyMe("=======================================================================");
}	# adoProperties4Conn


# ----------------------------------------------------------------------
#	adoProperties4Rs -- dump ADO record set properties
# ----------------------------------------------------------------------
#	arguments:
#		properties	record set object properties
# ----------------------------------------------------------------------
#	Record set properties are printed to log file
# ----------------------------------------------------------------------

sub adoProperties4Rs (\%) {
	my $properties = shift;

	&notifyWSub("ADO Record Set Properties:");
	&adoProperties($properties);
	&notifyMe("=======================================================================");
}	# adoProperties4Rs

# ----------------------------------------------------------------------
#	execSQL	execute SQL statement and display results via notifyMe
# ----------------------------------------------------------------------
#	arguments:
#		server	server name
#		dbName	database name
#		sql		SQL Command buffer
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Results are printed to log file
# ----------------------------------------------------------------------

sub execSQL ($$$) {
	my $server	= shift;
	my $dbName	= shift;
	my $sql		= shift;	# SQL statements
	my $cmd		= 0;		# ADO Command object handle
	my $status	= 1;
SUB:
{
	# Connect to SQL Server.
	unless ($cmd = adoConnect($server, $dbName)) {
		$status = 0;
		last SUB;
	}

	$status = execSQLBat($cmd, $sql);
	last SUB;
}
#ExitSub
	if ($cmd)	{ 
		my $conn = $cmd->{ActiveConnection};
		if ($conn)	{ $conn->Close(); $conn = 0; }		# close the data source
		$cmd->Close(); $cmd = 0; 
	}
	return($status);
}	# execSQL


# ----------------------------------------------------------------------
#	execSQL2Arr	execute SQL batch with result sets stored in an array
# ----------------------------------------------------------------------
#	arguments:
#		command object
#		sql		SQL Command buffer
#		rsref	reference to array with result set
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	This subroutine executes SQL Statement, and stores result set
#	in an array. It works best with single result set. Multiple result
#	set will be processed but structure of each row will not be uniform.
#	Each array element in the result is a hash with hash keys matching 
#	the result set column names.
#
#	Warning: column names in result set has to be unique. Otherwise
#	they will be overwritten.
#
#	Example 1:
#		execSQL2Arr($cmd, 'select \@\@version as SQLVersion', \@myrs);
#		$sqlversion = $myrs[0]{SQLVersion};
#
#	Example 2:
#		execSQL2Arr($cmd, 'select @@version, @@servername', \@myrs);
#	Will produce unpredictable result, column name is undefined.
#
#	Example 3:
#		execSQL2Arr($cmd, 'select @@servername as Name, SUSER_SNAME() as Name', \@myrs);
#		$servername = $myrs[0]{Name};
#	Will not produce desired result. The $servername will contain SUSER_SNAME.
#
# ----------------------------------------------------------------------

sub execSQL2Arr ($$$) {
	my $cmd		= shift;	# ADO Command object handle
	my $sql		= shift;	# SQL statements
	my $rsref	= shift;	# reference to result set array.
	my $conn	= 0;		# ADO connection object handle
	my $rs		= 0;		# record set handle
	my $sqlerr	= 0;
	my ($colId, $rowId);
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
		&notifyMe("SQL batch:\n$sql");
		&showADOErrors($sqlerr); 
		$status = 0; 
		last SUB;
	}

	$rowId	= 0;
	while($rs && !$rs->EOF) {
		while($rs->Fields->count && ! $rs->EOF) {
			for ( $colId = 0; $colId < $rs->Fields->count; $colId++ ) {
				$$rsref[$rowId]{$rs->Fields($colId)->name} = $rs->Fields($colId)->Value;
			}
			$rs->MoveNext; $rowId++;
		}
		$rs = $rs->NextRecordset;
	}
	last SUB;
}
#ExitSub
	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset
	return($status);
}	# execSQL2Arr


# ----------------------------------------------------------------------
#	execSQL2File	execute SQL batch with result sets
# ----------------------------------------------------------------------
#	arguments:
#		server	server name
#		dbName	database name
#		sql		SQL Command buffer
#		fname	output file name
#		outopt	output options: 
#				h = output with headers
#				a = append to existing output file.
#		rematch	match pattern to be used in substitute expression
#		rerepl	replacement for the substitute expression
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub execSQL2File ($$$$;$$$) {
	my $server	= shift;
	my $dbName	= shift;
	my $sql		= shift;	# SQL statements
	my $fname	= shift;
	my $outopt	= shift;
	my $rematch	= shift;
	my $rerepl	= shift;
	my $cmd		= 0;		# ADO Command object handle
	my $conn	= 0;		# ADO connection object handle
	my $rs		= 0;		# record set handle
	my $sqlerr	= 0;
	my $fldCount;
	my ($fields, $fldSize, @fldSizes);
	my $fldValue;
	my $printstr= "";
	my $i;
	my $status	= 1;

	my $debug = 0;		# No debug
	# $debug |= 0x01;	# print Connection properties
	# $debug |= 0x02;	# print all SQL Errors (include messages).
SUB:
{
	$outopt		= '' unless ($outopt);
	$rematch	= '' unless ($rematch);
	$rerepl		= '' unless ($rerepl);
	$rematch	=~ s/\\/\\\\/g;
	$rerepl		=~ s/\\/\\\\/g;

	# Open output file.

	if ($outopt =~ /a/) {
		$status = open(SQLOUT, ">>$fname");
	} else {
		$status = open(SQLOUT, ">$fname");
	}

	unless ($status) {
		&errme("Cannot open file <$fname> for writing.");
		$status = 0; last SUB;
	}

	# Connect to SQL Server.
	unless ($cmd = adoConnect($server, $dbName)) {
		$status = 0;
		last SUB;
	}

	$conn = $cmd->{ActiveConnection};
	$sqlerr = $conn->Errors;
	$cmd->{CommandText} = $sql;

	# Create record set object.

	unless ($rs = $cmd->Execute()) { 
		&errme("Error in SQL");
		&notifyWSub(" <- Problem caller.", 2);
		&notifyMe("SQL batch:\n$sql");
		&showADOErrors($sqlerr); 
		$status = 0; 
		last SUB;
	}

	while($rs && !$rs->EOF) {
		$printstr = "";
		$fields = $rs->Fields;
		$fldCount = $rs->Fields->count;

		if ($fldCount) {
			for($i = 0; $i < $fldCount; ++$i) {
				# Estimate field size best you can. The DefinedSize is 
				# datalength, not a print size. It should be accurate for
				# character data. It is always small for numeric data.

				$fldSize = (length($rs->Fields($i)->name) > $rs->Fields($i)->DefinedSize)?
					length($rs->Fields($i)->name):
					$rs->Fields($i)->DefinedSize;
				$printstr .= sprintf "%-${fldSize}s ",$rs->Fields($i)->name;
				push(@fldSizes, $fldSize);
			}
			$printstr =~ s/\s+$//g;
			if ($outopt =~ /h/) {
				print SQLOUT $printstr . "\n";
				for($i = 0; $i < $fldCount; ++$i) {
					$fldSize = $fldSizes[$i];
					print SQLOUT '='x$fldSizes[$i] . ' ';
				}
				print SQLOUT "\n";
			}

			while($rs->Fields->count && ! $rs->EOF) {
				$printstr = "";
				for ( $i = 0; $i < $fldCount; $i++ ) {
					$fldSize = $fldSizes[$i];
					$fldValue = $rs->Fields($i)->Value;
					$fldValue =~ s/$rematch/$rerepl/g	if ($rematch);
					$printstr .= sprintf "%-${fldSize}s ",$fldValue;
				}
				$printstr =~ s/\s+$//g;
				print SQLOUT $printstr . "\n";
				$rs->MoveNext;
			}
		}
		$rs = $rs->NextRecordset;
	}
	last SUB;
}
#ExitSub
	close(SQLOUT);
	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset
	if ($cmd)	{ 
		$conn = $cmd->{ActiveConnection};
		if ($conn)	{ $conn->Close(); $conn = 0; }		# close the data source
		$cmd->Close(); $cmd = 0; 
	}
	return($status);
}	# execSQL2File


# ----------------------------------------------------------------------
#	execSQLBat	execute SQL batch with result sets
# ----------------------------------------------------------------------
#	arguments:
#		command object
#		sql		SQL Command buffer
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub execSQLBat ($$) {
	my $cmd		= shift;		# ADO Command object handle
	my $sql		= shift;	# SQL statements
	my $conn	= 0;		# ADO connection object handle
	my $rs		= 0;		# record set handle
	my $sqlerr	= 0;
	my $fldCount;
	my $i;
	my ($fields, $fldSize, @fldSizes);
	my $printstr= "";
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
		&notifyMe("SQL batch:\n$sql");
		&showADOErrors($sqlerr); 
		$status = 0; 
		last SUB;
	}

	while($rs && !$rs->EOF) {
		$printstr = "";
		$fields = $rs->Fields;
		$fldCount = $rs->Fields->count;

		if ($fldCount) {
			for($i = 0; $i < $fldCount; ++$i) {
				# Estimate field size best you can. The DefinedSize is 
				# datalength, not a print size. It should be accurate for
				# character data. It is always small for numeric data.

				$fldSize = (length($rs->Fields($i)->name) > $rs->Fields($i)->DefinedSize)?
					length($rs->Fields($i)->name):
					$rs->Fields($i)->DefinedSize;
				$printstr .= sprintf "%-${fldSize}s ",$rs->Fields($i)->name;
				push(@fldSizes, $fldSize);
			}
			&notifyMe($printstr);

			while($rs->Fields->count && ! $rs->EOF) {
				$printstr = "";
				for ( $i = 0; $i < $fldCount; $i++ ) {
					$fldSize = $fldSizes[$i];
					$printstr .= sprintf "%-${fldSize}s ",$rs->Fields($i)->Value;
				}
				&notifyMe($printstr);
				$rs->MoveNext;
			}
		}
		$rs = $rs->NextRecordset;
	}
	last SUB;
}
#ExitSub
	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset
	return($status);
}	# execSQLBat


# ----------------------------------------------------------------------
#	execSQLCmd	execute SQL command batch with no result set
# ----------------------------------------------------------------------
#	arguments:
#		command object
#		sql		SQL Command buffer
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub execSQLCmd ($$) {
	my $cmd		= shift;		# ADO Command object handle
	my $sql		= shift;	# SQL statements
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
		&notifyMe("SQL batch:\n$sql");
		&showADOErrors($sqlerr); 
		$status = 0; 
		last SUB;
	}

	while($rs && !$rs->EOF) {
		# $rs->MoveNext;
		$rs = $rs->NextRecordset;
	}
	last SUB;
}
#ExitSub
	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset
	return($status);
}	# execSQLCmd


# ----------------------------------------------------------------------
#	killDBAccess	kill users and restrict access to database
# ----------------------------------------------------------------------
#	arguments:
#		cmd		connection command object for database server
#		dbname	name of the database to restrict access
#	return:
#		none
# ----------------------------------------------------------------------

sub killDBAccess ($$) {
	my $cmd			= shift;		# ADO Command object handle
	my $dbname		= shift;
	my $conn		= 0;		# ADO connection object handle
	my $rs			= 0;		# record set handle
	my $sqlerr		= 0;
	my $sql			= '';		# sql command buffer
	my @spids		= ();		# list of system user ids in current database
	my $status		= 0;
SUB:
{
	&notifyWSub("Kill users and restirct $dbname database access.");

	# Put database into restricted usage mode.

	$sql = "alter database $dbname set RESTRICTED_USER with ROLLBACK IMMEDIATE ";
	&notifyMe("execSQLCmd(\$cmd, $sql))");
	unless(&execSQLCmd($cmd, $sql)) { $status = 0; last SUB; }

	# Get remaining list of users to terminate.
	$conn = $cmd->{ActiveConnection};
	$sqlerr = $conn->Errors;
	$sql = "select spid from master..sysprocesses where db_name(dbid) = \'$dbname\'";
	$cmd->{CommandText} = $sql;

	# Create record set object.

	unless ($rs = $cmd->Execute()) { 
		&errme("Error in SQL");
		&notifyWSub("SQL batch:\n$sql");
		&showADOErrors($sqlerr); 
		$status = 0; 
		last SUB;
	}

	while(!$rs->EOF) {
		push(@spids, $rs->Fields('spid')->Value);
		$rs->MoveNext;
	}

	# Kill users.

	foreach (@spids) {
		$sql = "kill $_";
		&notifyMe("execSQLCmd(\$cmd, $sql))");
		unless(&execSQLCmd($cmd, $sql)) { $status = 0; last SUB; }
	}

	$status	= 1;
	last SUB;
}	# SUB
# ExitPoint:
	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset
	return($status);
}	# killDBAccess


# ----------------------------------------------------------------------
#	isADOok -- check if any critical errors are on ADO Comunication.
# ----------------------------------------------------------------------
#	arguments:
#		ADO error object
#	return:
#		1	No errors
#		0	Error found
# ----------------------------------------------------------------------

sub isADOok (\%) {
	my $sqlerr	= shift;
	my $err;
	my $status	= 1;

	if ($sqlerr->{Count} == 0) {return ($status); }

	foreach $err (keys %$sqlerr) {
		$status = 0 if ($err->{SQLState} ne "01000");
		last;
	}
	
	return($status);
}	# isADOok

# ----------------------------------------------------------------------
#	showADOErrors -- dump ADO error structure
# ----------------------------------------------------------------------
#	arguments:
#		ADO error object
#	return:
#		1	No errors
#		0	Error found
# ----------------------------------------------------------------------

sub showADOErrors (\%) {
	my $sqlerr	= shift;
	my $err;
	my $status	= 0;
	my $debug	= 0;
SUB:
{
	if ($sqlerr->{Count} == 0) {$status = 1; last SUB; }

	&notifyWSub("Number of errors in conn object is $sqlerr->{Count}");
	foreach $err (keys %$sqlerr) {
		if (($err->{SQLState} ne "01000") || ($gAdoFlgs & 0x1) || ($debug)) {
			&notifyMe("SQL Error: $err->{Description}");
			&notifyMe("SQL State: $err->{SQLState}");
			&notifyMe("NativeError: $err->{NativeError}");
			&notifyMe("Source: $err->{Source}");
			&notifyMe("Error Number: $err->{Number}");
			if ($err->{HelpFile}) {
				&notifyMe("HelpFile: $err->{HelpFile}");
				&notifyMe("HelpContext: $err->{HelpContext}");
			}
		}
		$status = 0 if ($err->{SQLState} ne "01000");
	}
	
	last SUB;
}
#ExitSub
	$status;
}	# showADOErrors


# ----------------------------------------------------------------------
#	setADOShowAllErrors -- set flag to show all ADO error messages
# ----------------------------------------------------------------------
#	arguments:
#		flag	0 = show only ADO errors.
#				1 = show warnings with SQLState = 01000
#	return:
#		old flag setting
# ----------------------------------------------------------------------

sub setADOShowAllErrors ($) {
	my $newflag	= shift;
	my $oldflag	= $gAdoFlgs & 0x1;

	$gAdoFlgs = ($newflag) ? $gAdoFlgs | 0x0001 : $gAdoFlgs & 0xFFFE;
	$oldflag;
}	# setADOShowAllErrors

1;

__END__

=pod

=head1 NAME

T38lib::bbyado - Perl extension Best Buy commonly used functions for ADO connections.

=head1 SYNOPSIS

=over

=item *

use T38lib::bbyado;

=back

=head1 FUNCTION LISTING

 sub adoConnect ($$;$);
 sub adoProperties (\%);
 sub adoProperties4Conn (\%);
 sub adoProperties4Rs (\%);
 sub execSQL ($$$);
 sub execSQL2File ($$$$;$$$);
 sub execSQL2Arr ($$$);
 sub execSQLBat ($$);
 sub execSQLCmd ($$);
 sub isADOok (\%);
 sub killDBAccess ($$);
 sub showADOErrors (\%);
 sub setADOShowAllErrors ($);

=head2 DESCRIPTION

 adoConnect -- creates connection to database server
 Sub Call &T38lib::bbyado::adoConnect
 arguments:
		dbSrvr	name of the database server: srvrName[\instName]
		dbName	database name
		useDotHost	optional flag, forcing to use . for server name if
					connecting to local host
	return:
		command object for ADO connection. Command name is "cmd1"
		0	Failure

 execSQL -- executes SQL statement on a given server. Results are printed
 to program's log file, using T38lib::Common::notifyMe.
 Sub Call &T38lib::bbyado::execSQL($serverName, $dbName, $sqlCmd)
 arguments:
		server	SQL server name
		dbName	database name
		sql		SQL Command buffer
 return:
		1	Success
		0	Failure

 execSQL2Arr	execute SQL batch with result sets stored in an array
	This subroutine executes SQL Statement, and stores result set
	in an array. It works best with single result set. Multiple result
	set will be processed but structure of each row will not be uniform.
	Each array element in the result is a hash with hash keys matching 
	the result set column names.

	Warning: column names in result set has to be unique. Otherwise
	they will be overwritten.

	Example 1:
		execSQL2Arr($cmd, 'select \@\@version as SQLVersion', \@myrs);
		$sqlversion = $myrs[0]{SQLVersion};

	Example 2:
		execSQL2Arr($cmd, 'select \@\@version, \@\@servername', \@myrs);
	Will produce unpredictable result, column name is undefined.

	Example 3:
		execSQL2Arr($cmd, 'select @@servername as Name, SUSER_SNAME() as Name', \@myrs);
		$servername = $myrs[0]{Name};
	Will not produce desired result. The $servername will contain SUSER_SNAME.
 Sub Call &T38lib::bbyado::execSQL2Arr($cmd, $sql, \$rsref)
 arguments:
		command object
		sql		SQL Command buffer
		rsref	reference to array with result set
 return:
		1	Success
		0	Failure

 execSQL2File	execute SQL batch with result sets stored in output file.
 The Output option allows caller to print column headers and append result
 sets instead of overwriting the file. Each option is represented by one
 character. One or all options can be specified in the outopt string.
 The rematch and replstr optional parameters can be used to modify result
 set. If rematch string is provided, it will be used as a match pattern on
 each column in the result set and replaced by replstr. If rematch is
 specified, the '' replstr will be used as default.
 Sub Call &T38lib::bbyado::execSQL2File($serverName, $dbName, $sqlCmd, $fileName, $outopt, $rematch, $replstr)
 arguments:
	server	server name
	dbName	database name
	sql		SQL Command buffer
	fname	output file name
	outopt	output options: 
			h = print column headers to output file (default, no headers).
			a = append results to existing output file.
	rematch	match pattern to be used in substitute expression
	replstr	replacement string for the substitute expression
 return:
		1	Success
		0	Failure

 execSQLBat	-- executes SQL batch, which produces result set.  SQL batch
 is executed via given connection command object. Result set is printed
 to program's log file, using using T38lib::Common::notifyMe.
 Sub Call &T38lib::bbyado::execSQLBat($cmdHdl, $sqlCmdBuffer)
 arguments:
		command object
		sql		SQL Command buffer
 return:
		1	Success
		0	Failure

 execSQLCmd	-- execute SQL command batch with no result set. SQL command
 buffer is executed via given connection command object. This function
 assumes there are no results. It skips all record sets, produced by
 SQL commands.
 Sub Call &T38lib::bbyado::execSQLCmd($cmdHdl, $sqlCmdBuffer)
 arguments:
		command object
		sql		SQL Command buffer
 return:
		1	Success
		0	Failure

 isADOok -- check if any ADO critical errors are present.
 Sub Call &T38lib::bbyado::isADOok($sqlerr)
 arguments:
		ADO error object
 return:
		1	No errors
		0	Error found

 killDBAccess	kill users and restrict access to database
 Sub Call &T38lib::bbyado::killDBAccess($cmd, $dbname)
	arguments:
		cmd		connection command object for database server
		dbname	name of the database to restrict access
	return:
		none

 showADOErrors -- dump ADO error structure to program's
 log file, using T38lib::Common::notifyMe.
 Sub Call &T38lib::bbyado::showADOErrors($sqlerr)
 arguments:
		ADO error object
 return:
		1	No errors
		0	Error found

 setADOShowAllErrors -- set flag to show all ADO error messages
 Sub Call &T38lib::bbyado::setADOShowAllErrors($newflag)
 arguments:
		flag	0 = show only ADO errors.
				1 = show warnings with SQLState = 01000
 return:
		old flag setting

=head1 BUGS

I<bbyado.pm> has no known bugs.

=head1 REVISION

$Revision: 1.1 $

=head1 AUTHOR

$Author: A645276 $

=head1 SEE ALSO

Sys::Hostname T38lib::Common OLE and Carp

=head1 COPYRIGHT and LICENSE

This program is copyright by BestBuy Inc.

=cut
