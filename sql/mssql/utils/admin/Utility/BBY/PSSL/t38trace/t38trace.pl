#!perl 
#*  t38trace - Configures and controls SQL Trace for MSSQL 7.0 and 2000. 
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/09 22:53:27 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/t38trace/t38trace.pv_  $
#*
#* SYNOPSIS
#*	t38trace -h -a 10 -n nTraces -S server -s debugSQLFile -x{s|x} -f filters trcParms
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-a 10		Number of log file archived, default is 7
#*	-n nTraces	Number of trace files, to keep, default is 7.
#*	-S server	Name of the server where to create SQL Trace. Default is
#*				local server.
#*	-s debugSql	debug file name for sql statements.
#*	-x execOpt	Execution option: 
#*					s -- start SQL Trace
#*					x -- stop SQL Trace
#*				default is to start SQL Trace.
#*	-f filters	Optional configuration file with filters to apply. These
#*				filters will overwrite SQL Trace filters, created by default.
#*	trcParms	configuration file with standard sql trace parameters.
#*	
#*	
#*	This program is managing SQL Traces for SQL 7 and SQL 2000 servers. 
#*	The execution option -x is used to start or stop SQL Trace. The trcParms
#*	file provides list of columns, events and filters to use with SQL Trace
#*	stored procedures. The trcParams files are preconfigured and should not be
#*	modified during day to day operations. The option -f parameter
#*	provides mechanism for customizing standard traces with 
#*	additional filters.
#*
#*	Example 1:
#*		Start tracing, using data columns, events and filters, defined in
#*		SQLTraceStandard.cfg file.
#*
#*		t38trace.pl SQLTraceStandard.cfg
#*
#*	Example 2:
#*		Stop SQL Trace, created by SQLTraceStandard.cfg.
#*
#*		t38trace.pl -xx SQLTraceStandard.cfg
#*
#*	Example 3:
#*		Start tracing, using SQLTraceStandard.cfg file and apply 
#*		filters, defined in SQLTraceStdCustom.cfg file.
#*
#*		t38trace.pl -f \\%computername%\t38tmp\SQLTraceStdCustom.cfg SQLTraceStandard.cfg
#*
#*	The t38trace.pl performs following steps:
#*
#*	Get version of SQL Server.
#*	Read SQL Server trace configuration, defined in trcParms.
#*	Read SQL Server trace configuration, defined in custom filters file.
#*	Resolve collisions between filters and trcParms files.
#*	For SQL 7 server, use xp_trace_getqueuedestination to find queue, matching
#*		trcParms file name.
#*	For SQL 2000 server, stop traces, with the trcParms name.
#*	Archive current trace file, using last 10 copies.
#*	If requested to start trace
#*		Use corresponding version of SQL Server	to configure trace parameters.
#*		Start SQL Trace.
#*
#***

use strict;

use T38lib::Common qw(notifyMe notifyWSub logme warnme errme);
use T38lib::bbyado qw(:BBYADO_SUBS :BBYADO_VARS);
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use Getopt::Std;
use File::Basename;
use File::DosGlob qw(glob);

# Constant

use constant SQL8MAXTRCSIZE	=> 5;	# Maximum trace file size before rollover


# Global Variables

my ( $gCurrentDir, $gScriptName, $gScriptPath, $gHostName, $gNWarnings) = "";
my ( $gNTraceFiles, $gSrvrName, $gTrcName, $gTrcFileName, $gTrcBaseName, $gSQLVersion, $gRunOpt);
my ( $gSrvrName, $gNetName, $gInstName);
my ( $gDebugSQL);

my @gSQLTraceErrStat = ();

$gSQLTraceErrStat[1] = "Unknown error.";
$gSQLTraceErrStat[2] = "The trace is currently running. Changing the trace at this time will result in an error.";
$gSQLTraceErrStat[3] = "The specified Event is not valid. The Event may not exist or it is not an appropriate one for the store procedure.";
$gSQLTraceErrStat[4] = "The specified Column is not valid.";
$gSQLTraceErrStat[5] = "The specified Column is not allowed for filtering. This value is returned only from sp_trace_setfilter.";
$gSQLTraceErrStat[6] = "The specified Comparison Operator is not valid.";
$gSQLTraceErrStat[7] = "The specified Logical Operator is not valid.";
$gSQLTraceErrStat[8] = "The specified Status is not valid.";
$gSQLTraceErrStat[9] = "The specified Trace Handle is not valid.";
$gSQLTraceErrStat[10] = "Invalid options. Returned when options specified are incompatible.";
$gSQLTraceErrStat[11] = "The specified Column is used internally and cannot be removed. ";
$gSQLTraceErrStat[12] = "File not created.";
$gSQLTraceErrStat[13] = "Out of memory. Returned when there is not enough memory to perform the specified action.";
$gSQLTraceErrStat[14] = "Invalid stop time. Returned when the stop time specified has already happened.";
$gSQLTraceErrStat[15] = "Invalid parameters. Returned when the user supplied incompatible parameters.";
$gSQLTraceErrStat[16] = "The function is not valid for this trace.";

my @gDoEvents		= ();	# Requested SQL Trace events.
my %gDoFilters		= ();	# Requested SQL Trace filters to be applied.
my @gDoColumns		= ();	# Requested SQL Trace data columns to be used for the trace.

use constant SQL7MAXEVENT	=> 81;	# SQL 7 highest event id
my %gTrcEvents		=		# SQL Trace events definition.
	(
	RPCCompleted				=>	10,
	RPCStarting					=>	11,
	SQLBatchCompleted			=>	12,
	SQLBatchStarting			=>	13,
	Login						=>	14,
	Logout						=>	15,
	Attention					=>	16,
	ExistingConnection			=>	17,
	ServiceControl				=>	18,
	DTCTransaction				=>	19,
	LoginFailed					=>	20,
	EventLog					=>	21,
	ErrorLog					=>	22,
	LockReleased				=>	23,
	LockAcquired				=>	24,
	LockDeadlock				=>	25,
	LockCancel					=>	26,
	LockTimeout					=>	27,
	DOPEvent					=>	28,
	Exception					=>	33,
	SPCacheMiss					=>	34,
	SPCacheInsert				=>	35,
	SPCacheRemove				=>	36,
	SPRecompile					=>	37,
	SPCacheHit					=>	38,
	SPExecContextHit			=>	39,
	SQLStmtStarting				=>	40,
	SQLStmtCompleted			=>	41,
	SPStarting					=>	42,
	SPCompleted					=>	43,
	ObjectCreated				=>	46,
	ObjectDeleted				=>	47,
	SQLTransaction				=>	50,
	ScanStarted					=>	51,
	ScanStopped					=>	52,
	CursorOpen					=>	53,
	TransactionLog				=>	54,
	HashWarning					=>	55,
	AutoUpdateStats				=>	58,
	LockDeadlockChain			=>	59,
	LockEscalation				=>	60,
	OLEDBErrors					=>	61,
	ExecutionWarnings			=>	67,
	ExecutionPlan				=>	68,
	SortWarnings				=>	69,
	CursorPrepare				=>	70,
	PrepareSQL					=>	71,
	ExecPreparedSQL				=>	72,
	UnprepareSQL				=>	73,
	CursorExecute				=>	74,
	CursorRecompile				=>	75,
	CursorImplicitConversion	=>	76,
	CursorUnprepare				=>	77,
	CursorClose					=>	78,
	MissingColumnStatistics		=>	79,
	MissingJoinPredicate		=>	80,
	ServerMemoryChange			=>	81,
	DataFileAutoGrow			=>	92,
	LogFileAutoGrow				=>	93,
	DataFileAutoShrink			=>	94,
	LogFileAutoShrink			=>	95,
	ShowPlanText				=>	96,
	ShowPlanALL					=>	97,
	ShowPlanStatistics			=>	98,
	RPCOutputParameter			=>	100,
	AuditStatementGDR			=>	102,
	AuditObjectGDR				=>	103,
	AuditAddDropLogin			=>	104,
	AuditLoginGDR				=>	105,
	AuditLoginChangeProperty	=>	106,
	AuditLoginChangePassword	=>	107,
	AuditAddLogintoServerRole	=>	108,
	AuditAddDBUser				=>	109,
	AuditAddMembertoDB			=>	110,
	AuditAddDropRole			=>	111,
	AppRolePassChange			=>	112,
	AuditStatementPermission	=>	113,
	AuditObjectPermission		=>	114,
	AuditBackupRestore			=>	115,
	AuditDBCC					=>	116,
	AuditChangeAudit			=>	117,
	AuditObjectDerivedPermission=>	118,
	);

my %gTrcColumns		= 		# SQL Trace data columns to be used for the trace.
	(
	TextData			=> {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => \&fltHdlrSql7str, SQL7spName => 'xp_trace_settextfilter', SQL8ColmId => 1, SQL7ColmId => 1},
	BinaryData			=> {SQL8FltrHdlr => 0, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 2, SQL7ColmId => 2},
	DatabaseID			=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => \&fltHdlrSql7eqn, SQL7spName => 'xp_trace_setdbidfilter', SQL8ColmId => 3, SQL7ColmId => 4},
	TransactionID		=> {SQL8FltrHdlr => 0, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 4, SQL7ColmId => 8},
	ConnectionID		=> {SQL8FltrHdlr => 0, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 0, SQL7ColmId => 16},
	NTUserName			=> {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => \&fltHdlrSql7str, SQL7spName => 'xp_trace_setntnmfilter', SQL8ColmId => 6, SQL7ColmId => 32},
	NTDomainName		=> {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => \&fltHdlrSql7str, SQL7spName => 'xp_trace_setntdmfilter', SQL8ColmId => 7, SQL7ColmId => 64},
	ClientHostName		=> {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => \&fltHdlrSql7str, SQL7spName => 'xp_trace_sethostfilter', SQL8ColmId => 8, SQL7ColmId => 128},
	ClientProcessID		=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => \&fltHdlrSql7eqn, SQL7spName => 'xp_trace_sethpidfilter', SQL8ColmId => 9, SQL7ColmId => 256},
	ApplicationName		=> {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => \&fltHdlrSql7str, SQL7spName => 'xp_trace_setappfilter', SQL8ColmId => 10, SQL7ColmId => 512},
	SQLSecurityLoginName => {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => \&fltHdlrSql7str, SQL7spName => 'xp_trace_setuserfilter', SQL8ColmId => 11, SQL7ColmId => 1024},
	SPID				=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => \&fltHdlrSql7eqn, SQL7spName => 'xp_trace_setspidfilter', SQL8ColmId => 12, SQL7ColmId => 2048},
	Duration			=> {SQL8FltrHdlr => \&fltHdlrSql8numb, SQL7FltrHdlr => \&fltHdlrSql7num, SQL7spName => 'xp_trace_setdurationfilter', SQL8ColmId => 13, SQL7ColmId => 4096},
	StartTime			=> {SQL8FltrHdlr => \&fltHdlrSql8date, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 14, SQL7ColmId => 8192},
	EndTime				=> {SQL8FltrHdlr => \&fltHdlrSql8date, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 15, SQL7ColmId => 16384},
	Reads				=> {SQL8FltrHdlr => \&fltHdlrSql8numb, SQL7FltrHdlr => \&fltHdlrSql7num, SQL7spName => 'xp_trace_setreadfilter', SQL8ColmId => 16, SQL7ColmId => 32768},
	Writes				=> {SQL8FltrHdlr => \&fltHdlrSql8numb, SQL7FltrHdlr => \&fltHdlrSql7num, SQL7spName => 'xp_trace_setwritefilter', SQL8ColmId => 17, SQL7ColmId => 65536},
	CPU					=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => \&fltHdlrSql7num, SQL7spName => 'xp_trace_setcpufilter', SQL8ColmId => 18, SQL7ColmId => 131072},
	Permissions			=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 19, SQL7ColmId => 0},
	Severity			=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => \&fltHdlrSql7num, SQL7spName => 'xp_trace_setseverityfilter', SQL8ColmId => 20, SQL7ColmId => 524288},
	EventSubClass		=> {SQL8FltrHdlr => 0, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 21, SQL7ColmId => 1048576},
	ObjectID			=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => \&fltHdlrSql7eqn, SQL7spName => 'xp_trace_setobjidfilter', SQL8ColmId => 22, SQL7ColmId => 2097152},
	Success				=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 23, SQL7ColmId => 0},
	IndexID				=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => \&fltHdlrSql7eqn, SQL7spName => 'xp_trace_setindidfilter', SQL8ColmId => 24, SQL7ColmId => 8388608},
	IntegerData			=> {SQL8FltrHdlr => 0, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 25, SQL7ColmId => 16777216},
	ServerName			=> {SQL8FltrHdlr => 0, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 26, SQL7ColmId => 33554432},
	EventClass			=> {SQL8FltrHdlr => 0, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 27, SQL7ColmId => 67108864},
	ObjectType			=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 28, SQL7ColmId => 0},
	NestLevel			=> {SQL8FltrHdlr => 0, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 29, SQL7ColmId => 0},
	State				=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 30, SQL7ColmId => 0},
	Error				=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 31, SQL7ColmId => 0},
	Mode				=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 32, SQL7ColmId => 0},
	Handle				=> {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 33, SQL7ColmId => 0},
	ObjectName			=> {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 34, SQL7ColmId => 0},
	DatabaseName		=> {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 35, SQL7ColmId => 0},
	Filename			=> {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 36, SQL7ColmId => 0},
	ObjectOwner			=> {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 37, SQL7ColmId => 0},
	TargetRoleName		=> {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 38, SQL7ColmId => 0},
	TargetUserName		=> {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 39, SQL7ColmId => 0},
	DatabaseUserName	=> {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 40, SQL7ColmId => 0},
	LoginSID			=> {SQL8FltrHdlr => 0, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 41, SQL7ColmId => 0},
	TargetLoginName		=> {SQL8FltrHdlr => \&fltHdlrSql8str, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 42, SQL7ColmId => 0},
	TargetLoginSID	 	=> {SQL8FltrHdlr => 0, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 43, SQL7ColmId => 0},
	ColumnPermissionsSet => {SQL8FltrHdlr => \&fltHdlrSql8num, SQL7FltrHdlr => 0, SQL7spName => 0, SQL8ColmId => 44, SQL7ColmId => 0},
	);


# Main
&main();


############################  BBY Subroutines  ####################################

sub main {
	my $mainStatus	= 0;
	SUB:
	{
		unless (&housekeeping())	{ $mainStatus = 1; last SUB; }
		unless (&stopTrace())		{ $mainStatus = 1; last SUB; }
		if ( $gRunOpt eq 's' )		{ &delTraceFiles(); }
		if ( ($gRunOpt eq 's') && !&startTrace())	{ $mainStatus = 1; last SUB; } 		
		last SUB;
	
	}	# SUB
	# ExitPoint:


	$mainStatus = 1	if ($gNWarnings > 0);

	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;

	exit($mainStatus);

}	# main


#######################  $Workfile:   t38trace.pl  $ Subroutines  #################################

# ----------------------------------------------------------------------
#	startTrace		start SQL Server trace
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		status		0 - failed
#					1 - success
# ----------------------------------------------------------------------

sub startTrace () {
	my $status	= 1;
SUB:
{
	&notifyWSub("startTrace started");

	&notifyMe("Requested filters:")
	&notifyMe("============================================================");
	debugPrintHash(\%gDoFilters);

	&notifyMe("Requested Events:")
	&notifyMe("============================================================");
	&notifyMe("\n\t\t" . join("\n\t\t", @gDoEvents));

	&notifyMe("Requested Columns:")
	&notifyMe("============================================================");
	&notifyMe("\n\t\t" . join("\n\t\t", @gDoColumns));

	if ($gSQLVersion eq '7.00') {
		unless ($status = &startSQL7trace())	{ last SUB; }
	} else {
		unless ($status = &startSQL8trace())	{ last SUB; }
	}
	last SUB;
}	# SUB
	# ExitPoint:

	&notifyWSub("Finised with status $status.");

	return($status);

}	# startTrace

# ----------------------------------------------------------------------
#	startSQL7trace		start SQL 7 trace
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		status		0 - failed
#					1 - success
# ----------------------------------------------------------------------
#	start SQL 7 trace
# ----------------------------------------------------------------------

sub startSQL7trace () {
	my $status			= 1;
	my $qHandle			= 0;
	my $adocmd			= 0;		# ADO Command object handle
	my @rs				= ();		# array with result set
	my $sql				= '';		# sql command buffer
	my $maxitems		= 8000;		# Is an integer representing the maximum number of items buffered
									# or stored in the trace queue. The recommended value is 1000, 
									# the minimum is 1, and the maximum is 20,000. 
	my $timeout			= 5;		# Is an integer representing the time-out value in seconds 
									# for the trace queue. The default value is 5, 
									# the minimum is 1, and the maximum is 10. 
									# At time-out, the trace queue, for a brief period of time, stops accepting new events. 
	my $threadboost		= 95;		# Is an integer representing the percentage of items
									# in the trace queue causing the trace queue consumer 
									# to receive a boost in priority and increases the 
									# priority setting for the specified application thread.
									# The default value is 95%, the minimum is 1%, 
									# and the maximum is 100%. thread_reduce cannot be greater than thread_boost. 
	my $threadreduce	= 90;		# Is an integer representing the percentage of items 
									# in the trace queue causing the trace queue consumer to 
									# receive a reduction in priority and decreases the 
									# priority setting for the specified application thread.
									# The default value is 90%, the minimum is 0%, and 
									# the maximum is 99%. thread_reduce cannot be greater than thread_boost. 
	my $trcColumnMask	= 0;		# SQL Trace column mask.
	my $akey			= '';
	my $oldAdoFlg		= 0;		# old flag to show all ADO errors.

	# SQL 7 trace stored procedures show messages as warnings.
	# Set bbyado.pm to show all messages.
	$oldAdoFlg = &setADOShowAllErrors(1);
SUB:
{
	&notifyWSub("Started.");
	unless ($adocmd = adoConnect($gSrvrName, 'master')) { 
		&errme("adoConnect($gSrvrName) Failed");
		$status = 0; last SUB;
	}
	debugPrintSQL("use master");

	# Build requested data columns mask for SQL Trace.
	foreach (@gDoColumns) {	$trcColumnMask |= $gTrcColumns{$_}{SQL7ColmId};	}

	# Create trace queue.
	$sql	= << "	EOT";
		declare \@rc				int		-- Return Code
		declare \@queue_handle 		int 	-- queue handle new running trace queue
		exec \@rc = xp_trace_addnewqueue $maxitems, $timeout, $threadboost, $threadreduce, $trcColumnMask, \@queue_handle output
		select \@rc as ResultCode, \@queue_handle as QueueHandle
	EOT

	debugPrintSQL($sql);
	unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
	if ($rs[0]{ResultCode} > 0) {
		&errme("Invalid result code ($rs[0]{ResultCode}) from xp_trace_addnewqueue $trcColumnMask.");
		$status = 0;
		last SUB;
	}
	if ($rs[0]{QueueHandle}) {
		$qHandle = $rs[0]{QueueHandle};
	} else {
		&errme("Invalide Queue handle returned from xp_trace_addnewqueue $trcColumnMask.");
		$status = 0;
		last SUB;
	}

	# Setup events.
	foreach $akey (@gDoEvents) {
		$sql = << "		EOT";
			declare \@rc	int		-- Return Code
			exec \@rc = xp_trace_seteventclassrequired $qHandle, $gTrcEvents{$akey}, 1
			select \@rc as ResultCode
		EOT

		debugPrintSQL($sql);
		unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
		if ($rs[0]{ResultCode} > 0) {
			&errme("Invalid result code ($rs[0]{ResultCode}) from xp_trace_seteventclassrequired $qHandle, $gTrcEvents{$akey} ($akey).");
			$status = 0;
			last SUB;
		}
	}

	# Setup filters.

	foreach $akey (keys %gDoFilters) {
		unless ( & { $gTrcColumns{$akey}{SQL7FltrHdlr} } ($gTrcColumns{$akey}{SQL7spName}, $gDoFilters{$akey}, $qHandle, \$sql) ) {
			&errme("Invalid SQL 7 filter request for column $akey ($gDoFilters{$akey}).");
			$status = 0;
			last SUB;
		}
		&notifyWSub("Apply filter: $sql");
		$sql = << "		EOT";
			declare \@rc	int		-- Return Code
			exec \@rc = $sql
			select \@rc as ResultCode
		EOT

		debugPrintSQL($sql);
		unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
		if ($rs[0]{ResultCode} > 0) {
			&errme("Invalid result code ($rs[0]{ResultCode}) for filter $akey.\n\t\tSQL statement:\n$sql.");
			$status = 0;
			last SUB;
		}
	}

	# Start queue

		$sql = << "		EOT";
			declare \@rc	int		-- Return Code
			exec \@rc = xp_trace_setqueuedestination $qHandle, 2, 1, NULL, '$gTrcFileName'
			select \@rc as ResultCode
		EOT

		debugPrintSQL($sql);
		unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
		if ($rs[0]{ResultCode} > 0) {
			&errme("Invalid result code ($rs[0]{ResultCode}) for xp_trace_setqueuedestination $qHandle, $gTrcFileName.");
			$status = 0;
			last SUB;
		}

		$sql = << "		EOT";
			declare \@rc	int		-- Return Code
			exec \@rc = xp_trace_startconsumer $qHandle
			select \@rc as ResultCode
		EOT

		debugPrintSQL($sql);
		unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
		if ($rs[0]{ResultCode} > 0) {
			&errme("Invalid result code ($rs[0]{ResultCode}) for exec xp_trace_startconsumer $qHandle.");
			$status = 0;
			last SUB;
		}

	last SUB;
}	# SUB
# ExitPoint:
	# debug code start
	# $status = 0;	# This is to destroy queue when done. Remove this code, once this sub is coded to assign file to a queue. Then it can be destroyend with -x x option.
	# debug code end
	if (!$status && $adocmd && $qHandle) {
		# Destroy partially created trace.
		debugPrintSQL("exec xp_trace_destroyqueue $qHandle");
		&execSQLBat($adocmd, "exec xp_trace_destroyqueue $qHandle");
	}
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	&setADOShowAllErrors($oldAdoFlg);

	&notifyWSub("Done. Queue handle: $qHandle, Status: $status.");
	return($status);
}	# startSQL7trace


# ----------------------------------------------------------------------
#	startSQL8trace		start SQL 8 trace
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		status		0 - failed
#					1 - success
# ----------------------------------------------------------------------
#	start SQL 8 trace
# ----------------------------------------------------------------------

sub startSQL8trace () {
	my $status	= 1;
	my $qHandle			= 0;
	my $adocmd			= 0;		# ADO Command object handle
	my @rs				= ();		# array with result set
	my $declare			= 0;		# sql statements to declare variable
	my $sql				= '';		# sql command buffer
	my $ckey			= '';		# key for columns list
	my $ekey			= '';		# key for events list
	my $fkey			= '';		# key for filters list
	my $trcFileName		= '';		# Trace file name to use in sp_trace_create
	my $maxfilesize		= SQL8MAXTRCSIZE;	# Maximum trace file size before rollover
SUB:
{
	&notifyWSub("Started.");

	debugPrintSQL("use master");
	unless ($adocmd = adoConnect($gSrvrName, 'master')) { 
		&errme("adoConnect($gSrvrName) Failed");
		$status = 0; last SUB;
	}

	# If rollover maxfilesize is specified SQL server appends .trc extension.
	# Remove .trc from trace file name.

	($trcFileName = $gTrcFileName) =~ s/.trc$//i;

	# Create SQL Trace.

	$sql	= << "	EOT";
		declare \@rc				int		-- Return Code
		declare \@queue_handle 		int 	-- queue handle new running trace queue
		declare \@maxfilesize		bigint
		set \@maxfilesize = $maxfilesize 

		exec \@rc = sp_trace_create 
			\@queue_handle output, 	--	Trace handle - needed for subsequent trace operations
			2, 						--	2 Indicates file rollover
			N'$trcFileName',		--	Full trace file name 
			\@maxfilesize, 			--	Maximum trace file size before rollover
			NULL 			--	Trace stop time
		select \@rc as ResultCode, \@queue_handle as QueueHandle
	EOT

	debugPrintSQL($sql);
	unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
	if ($rs[0]{ResultCode} > 0) {
		&errme("Invalid result code ($rs[0]{ResultCode}) from sp_trace_create $gTrcFileName.");
		(defined($gSQLTraceErrStat[$rs[0]{ResultCode}])) ?
			&notifyWSub($gSQLTraceErrStat[$rs[0]{ResultCode}]):
			&notifyWSub($gSQLTraceErrStat[1]);
		$status = 0;
		last SUB;
	}
	if ($rs[0]{QueueHandle}) {
		$qHandle = $rs[0]{QueueHandle};
	} else {
		&errme("Invalid Queue handle returned from sp_trace_create $gTrcFileName.");
		$status = 0;
		last SUB;
	}

	# Setup events.

	foreach $ekey (@gDoEvents) {
		foreach $ckey (@gDoColumns) {
			$declare	= 'declare @on bit set @on = 1';
			$sql		= "sp_trace_setevent $qHandle, $gTrcEvents{$ekey}, $gTrcColumns{$ckey}{SQL8ColmId}, \@on";
			unless ($status = &execSQL8tracesp($adocmd, $sql, $declare)) { last SUB; }
		}
	}

	# Setup filters.

	foreach $fkey (keys %gDoFilters) {
		unless ( & { $gTrcColumns{$fkey}{SQL8FltrHdlr} } ($fkey, $gDoFilters{$fkey}, $qHandle, $adocmd) ) {
			&errme("Invalid SQL 8 filter request for column $fkey ($gDoFilters{$fkey}).");
			$status = 0;
			last SUB;
		}
	}

	# Start trace
	$sql = "sp_trace_setstatus $qHandle, 1";
	unless ($status = &execSQL8tracesp($adocmd, $sql)) { last SUB; }

	last SUB;
}	# SUB
# ExitPoint:
	if (!$status && $adocmd && $qHandle) {
		# Destroy partially created trace.
		$sql = 
			"exec sp_trace_setstatus $qHandle, 0\n" . 
			"exec sp_trace_setstatus $qHandle, 2\n";

		debugPrintSQL($sql);
		&execSQLBat($adocmd, $sql);
	}
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }

	&notifyWSub("Done. Queue handle: $qHandle, Status: $status.");
	return($status);
}	# startSQL8trace


# ----------------------------------------------------------------------
#	stopTrace		Stop SQL Trace for the $gTrcName
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		status		0 - failed
#					1 - success
# ----------------------------------------------------------------------

sub stopTrace () {
	my $status		= 1;
	my $oldAdoFlg	= 0;		# old flag to show all ADO errors.
	my $adocmd		= 0;		# ADO Command object handle
	my @rs			= ();		# array with result set
	my $rsrow		= 0;		# result set row
	my $sql			= '';		# sql command buffer

	# SQL 7 trace stored procedures show messages as warnings.
	# Set bbyado.pm to show all messages.
	$oldAdoFlg = &setADOShowAllErrors(1);

SUB:
{
	&notifyWSub("stopTrace started");

	debugPrintSQL("use master");
	unless ($adocmd = adoConnect($gSrvrName, 'master')) { 
		&errme("adoConnect($gSrvrName) Failed");
		$status = 0; last SUB;
	}



	if ($gSQLVersion eq '7.00') {
		# SQL 7 trace.
		$sql = <<"		EOT";
			create table #tracehdls (QueueHandle 	int not null)
			create table #tracequeues (
				[QueueHandle] 	int not null,
				[On]			bit null,
				[Object]		sysname	null
			)

			create table #tracedestination (
				[Destination]	int	null,
				[On]			bit	null,
				[Server]		sysname	null,
				[Object]		sysname	null
			)

			insert into #tracehdls (QueueHandle) exec master..xp_trace_enumqueuehandles


			DECLARE trcqueues CURSOR
			FAST_FORWARD
			FOR select QueueHandle from #tracehdls 

			DECLARE \@queuehdl int
			OPEN trcqueues

			FETCH NEXT FROM trcqueues INTO \@queuehdl
			WHILE (\@\@fetch_status <> -1)
			BEGIN
				IF (\@\@fetch_status <> -2)
				BEGIN
					truncate table #tracedestination
					insert into #tracedestination exec master..xp_trace_getqueuedestination \@queuehdl, 2
					insert into #tracequeues select \@queuehdl, [On], Object from #tracedestination
				END
				FETCH NEXT FROM trcqueues INTO \@queuehdl
			END

			CLOSE trcqueues
			DEALLOCATE trcqueues


			select  QueueHandle, [On], Object from #tracequeues where upper(Object) like '$gTrcBaseName%'
			drop table #tracehdls
			drop table #tracedestination
			drop table #tracequeues
		EOT

		debugPrintSQL($sql);
		unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
		foreach $rsrow (@rs) {
			# Destroy queue for select trace.
			&notifyWSub("Destroy queue handle $$rsrow{QueueHandle}, $$rsrow{Object}.");
			$sql = "exec xp_trace_destroyqueue $$rsrow{QueueHandle}";
			debugPrintSQL($sql);
			unless (&execSQLBat($adocmd, $sql)) { $status = 0; last SUB; }
		}
	} else {
		# SQL 8 trace.
		$sql = <<"		EOT";
			select traceid, value
			FROM 	::fn_trace_getinfo(default) 
			WHERE 	property = 2	-- trace file name
			AND	upper(convert(sysname,value))  LIKE '%${gTrcBaseName}\%'
		EOT

		debugPrintSQL($sql);
		unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
		foreach $rsrow (@rs) {
			# Destroy queue for select trace.
			&notifyWSub("Destroy queue handle $$rsrow{traceid}, $$rsrow{value}.");
			$sql = "sp_trace_setstatus $$rsrow{traceid}, 0";
			unless ($status = &execSQL8tracesp($adocmd, $sql)) { last SUB; }

			$sql = "sp_trace_setstatus $$rsrow{traceid}, 2";
			unless ($status = &execSQL8tracesp($adocmd, $sql)) { last SUB; }
		}
	}
	last SUB;
}	# SUB
# ExitPoint:

	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	&setADOShowAllErrors($oldAdoFlg);

	&notifyWSub("stopTrace finised with $status status.");

	return($status);

}	# stopTrace


# ----------------------------------------------------------------------
#	delTraceFiles		delete old trace files
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		status		1 - success
# ----------------------------------------------------------------------
#	delete old trace files
# ----------------------------------------------------------------------

sub delTraceFiles () {
	my $filepat		= "$gTrcBaseName\*.trc";
	my $status		= 1;
	my @filelist	= ();
	my $filename	= '';
	my $i			= 0;
SUB:
{
	&notifyWSub("Started.");

	@filelist = glob($filepat);
	foreach $filename (reverse sort @filelist) {
		$i++;
		if ($i >=  $gNTraceFiles) {
			&notifyMe("Delete trace file $filename.");
			unlink ($filename);
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# delTraceFiles


# ----------------------------------------------------------------------
#	execSQL8tracesp		executue sql 8 trace sp
# ----------------------------------------------------------------------
#	arguments:
#		adocmd			ADO Command object handle
#		$sql			sp_trace stored procedure with all arguments
#		$declareSql		optionally declare variables, used in sql
#	return:
#		status		0 - failed
#					1 - success
# ----------------------------------------------------------------------
#	executue sql 8 trace sp
# ----------------------------------------------------------------------

sub execSQL8tracesp ($$\$) {
	my $adocmd		= shift;
	my $sqlin		= shift;
	my $declareSql	= shift;
	my $sql			= '';		# sql buffer
	my @rs			= ();		# array with result set
	my $status		= 1;
SUB:
{
	debugPrintSQL("use master");

	$sql = "$declareSql\n"	if $declareSql;
	$sql .= 
		"declare \@rc	int \n" .
		"exec \@rc = $sqlin\n" .
		"select \@rc as ResultCode\n";

	debugPrintSQL($sql);
	unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }
	if ($rs[0]{ResultCode} > 0) {
		&errme("Invalid result code ($rs[0]{ResultCode}).\n\t\tSQL statement:\n$sql.");
		(defined($gSQLTraceErrStat[$rs[0]{ResultCode}])) ?
			&notifyWSub($gSQLTraceErrStat[$rs[0]{ResultCode}]):
			&notifyWSub($gSQLTraceErrStat[1]);
		$status = 0;
		last SUB;
	}
	last SUB;
}	# SUB
# ExitPoint:
	return($status);
}	# execSQL8tracesp


# ----------------------------------------------------------------------
#	fltHdlrSql7eqn		filter handler for SQL 7 numeric columns with equal comparison
# ----------------------------------------------------------------------
#	arguments:
#		spName	SQL 7 Filter stored procedure name
#		reqStr	request string
#		qHandle	queue handle
#		refSql	reference to SQL Statement string to generate
#	return:
#		status		0 - failed
#					1 - success
# ----------------------------------------------------------------------
#	Input is a numeric value that specifies the id for which to capture
#	events.
# ----------------------------------------------------------------------

sub fltHdlrSql7eqn () {
	my $status	= 1;
	my $spName	= shift;
	my $reqStr	= shift;
	my $qHandle	= shift;
	my $refSql	= shift;
SUB:
{
	&notifyWSub("Started.");

	# Verfiy input string.

	if ($reqStr !~ /^\s*(\d+)$/) {
		&errme("Invalid input parameter $reqStr for $spName filter.");
		$status = 0;
		last SUB;
	}

	$$refSql	= "$spName $qHandle, $1";

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# fltHdlrSql7eqn


# ----------------------------------------------------------------------
#	fltHdlrSql7num		filter handler for SQL 7 numeric column
# ----------------------------------------------------------------------
#	arguments:
#		spName	SQL 7 Filter stored procedure name
#		reqStr	request string
#		qHandle	queue handle
#		refSql	reference to SQL Statement string to generate
#	return:
#		status		0 - failed
#					1 - success
# ----------------------------------------------------------------------
#	Filter handler for SQL 7 numeric column. The minimum value is a 
#	number, specifying the minimum value for which to trace. There is 
#	no default value. If 0, there are no minimum restrictions.
#	The maximum value is a number, specifying the maximum value for
#	which to trace. There is no default value. If 0, there are no
#	maximum restrictions.
# ----------------------------------------------------------------------

sub fltHdlrSql7num () {
	my $spName	= shift;
	my $reqStr	= shift;
	my $qHandle	= shift;
	my $refSql	= shift;
	my $oper	= '';		# Boolean operator.
	my $val		= 0;
	my $minval	= 0;
	my $maxval	= 0;
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");
	# Verfiy input string.

	if ($reqStr !~ /^([<>])\s*(\d+)$/) {
		&errme("Invalid input parameter $reqStr for $spName filter.");
		$status = 0;
		last SUB;
	}

	$oper	= $1;
	$val	= $2;

	if ($oper eq '<') {
		$minval = 0;
		$maxval	= $val;
	} else {
		$minval	= $val;
		$maxval = 0;
	}

	$$refSql	= "$spName $qHandle, $minval, $maxval";

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# fltHdlrSql7num


# ----------------------------------------------------------------------
#	fltHdlrSql7str		filter handler for SQL 7 string columns
# ----------------------------------------------------------------------
#	arguments:
#		spName	SQL 7 Filter stored procedure name
#		reqStr	request string
#		qHandle	queue handle
#		refSql	reference to SQL Statement string to generate
#	return:
#		status		0 - failed
#					1 - success
# ----------------------------------------------------------------------
#	This handler works with string data columns. The  include
#	filter string indicates the column values, separated by 
#	semicolons (;), that should be considered when capturing data 
#	previously determined by sp_seteventclassrequired. The % wildcard 
#	character can be used in specifying the selected column to include 
#	in the trace. If NULL, there are no restrictions to include for the 
#	specified event classes.
#	Exclude filter string indicates the column values, separated
#	by semicolons (;), that should not be considered when capturing data 
#	previously determined by sp_seteventclassrequired. The % wildcard 
#	character can be used in specifying the selected column to exclude 
#	in the trace. If NULL, there are no excluded values for the specified
#	event classes 
# ----------------------------------------------------------------------

sub fltHdlrSql7str () {
	my $status	= 1;
	my $spName	= shift;
	my $reqStr	= shift;
	my $qHandle	= shift;
	my $refSql	= shift;
	my $oper	= '';		# Boolean operator.
	my $val		= 0;
	my @args	= ();		# arguments, provided in reqStr
	my $arg		= '';		# one of arguments in @args array
	my @incArg	= ();		# list of include arguments
	my @excArg	= ();		# list of exclude arguments
	my $incStr	= '';		# include string
	my $excStr	= '';		# exclude string
SUB:
{
	&notifyWSub("Started.");

	@args = split ';', $reqStr;
	foreach $arg (@args) {
		$arg =~ /^\s*(\!?)\s*N?(.*)\s*$/;
		$oper	= $1;
		$val	= $2;
		$val	=~ s/^\s*['"]//; 
		$val	=~ s/['"]$//;

		if ($val =~ /^\s*$/) {
			&errme("Empty argument for $spName filter");
			$status = 0;
			last SUB;
		}
		($oper eq '!') ? push @excArg, $val:push @incArg, $val;
	}
	$incStr	= join(';', @incArg);
	$excStr	= join(';', @excArg);

	if ($incStr =~ /^\s*$/) {
		$incStr = 'NULL';
	} else {
		$incStr = "N'$incStr'";
	}
	if ($excStr =~ /^\s*$/) {
		$excStr = 'NULL';
	} else {
		$excStr = "N'$excStr'";
	}

	if ($incStr eq 'NULL' && $excStr eq 'NULL') {
		&errme("No arguments provided for $spName filter");
		$status = 0;
		last SUB;
	}


	$$refSql	= "$spName $qHandle, $incStr, $excStr";

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# fltHdlrSql7str


# ----------------------------------------------------------------------
#	fltHdlrSql8date		filter handler for SQL 8 date column
# ----------------------------------------------------------------------
#	arguments:
#		colmname	SQL 8 trace column name
#		reqStr	request string
#		qHandle	queue handle
#		adocmd	ADO Command object handle
#	return:
#		status		0 - failed
#					1 - success
# ----------------------------------------------------------------------
#	Filter handler for SQL 8 date column. 
#	Columns with datetime, can be defined as following:
#	columnName => timestamp
#	columnName =< timestamp
#	Where timestamp can me in one of the following formats:
#	'YYYY-MM-DD' or 'YYYY-MM-DD HH:MM:SS'
#
#	Available comaprison operators are:
#		Value	Comparison operator 		Implemented?
#		0 		= (Equal) 					No
#		1 		<> (Not Equal) 				No
#		2 		> (Greater Than) 			Yes
#		3 		< (Less Than) 				Yes
#		4 		>= (Greater Than Or Equal)	No
#		5 		<= (Less Than Or Equal) 	No
#		6 		LIKE  						No
#		7 		NOT LIKE  					No
# ----------------------------------------------------------------------

sub fltHdlrSql8date () {
	my $colmname	= shift;
	my $reqStr		= shift;
	my $qHandle		= shift;
	my $adocmd		= shift;
	my $colmid		= $gTrcColumns{$colmname}{SQL8ColmId};
	my $declare		= 0;		# sql statements to declare variable
	my $sql			= '';		# sql command buffer
	my $oper		= '';		# Boolean operator.
	my $operid		= 0;		# SQL 8 trace operator id
	my $logicalop	= 0;		# SQL 8 trace logical operator AND (0) or OR (1), 1 is used only with operator 0 and 6 
	my $val			= 0;
	my $year		= 0;
	my $mon			= 0;
	my $day			= 0;
	my $hour		= 0;
	my $min			= 0;
	my $sec			= 0;
	my $status		= 1;
SUB:
{
	&notifyWSub("Started filter for $colmname.");
	# Verfiy input string.

	if ($reqStr !~ /^([<>])\s*['"]?(\d\d\d\d)-(\d\d)-(\d\d) ((\d\d):(\d\d):(\d\d))?['"]?$/) {
		&errme("Invalid input parameter $reqStr for the filter $colmname.");
		$status = 0;
		last SUB;
	}

	$oper	= $1;
	$year	= $2;
	$mon	= $3;
	$day	= $4;

	if ($day > 31 || $mon > 12) {
		&errme("Invalid date ($reqStr) requested for the filter $colmname..");
	}

	if ($5) {
		$val	= $5;
		$hour	= $6;
		$min	= $7;
		$sec	= $8;
		if ($hour >= 24 || $min >= 60 || $sec >= 60) {
			&errme("Invalid time ($reqStr) requested for the filter $colmname.");
		}
	} else {
		$hour	= 0;
		$min	= 0;
		$sec	= 0;
	}

	$val = sprintf("%04d-%02d-%02d %02d:%02d:%02d.000", $year, $mon, $day, $hour, $min, $sec);

	if ($oper eq '<') {
		$operid		= 3;
		$logicalop	= 0;
	} elsif ($oper eq '>') {
		$operid		= 2;
		$logicalop	= 0;
	}

	$declare	= "declare \@val datetime set \@val = '$val'";
	$sql		= "sp_trace_setfilter $qHandle, $colmid, $logicalop, $operid, \@val";

	&notifyWSub("Apply filter: \n$declare\n$sql");
	unless ($status = &execSQL8tracesp($adocmd, $sql, $declare)) { last SUB; }

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# fltHdlrSql8date


# ----------------------------------------------------------------------
#	fltHdlrSql8numb		filter handler for SQL 8 big numeric column
# ----------------------------------------------------------------------
#	arguments:
#		colmname	SQL 8 trace column name
#		reqStr		request string
#		qHandle		queue handle
#		adocmd		ADO Command object handle
#	return:
#		status		0 - failed
#					1 - success
# ----------------------------------------------------------------------
#	Filter handler for SQL 8 numeric column. Available comaprison 
#	operators are:
#		Value	Comparison operator 		Implemented?
#		0 		= (Equal) 					Yes
#		1 		<> (Not Equal) 				Yes
#		2 		> (Greater Than) 			No
#		3 		< (Less Than) 				No
#		4 		>= (Greater Than Or Equal)	Yes
#		5 		<= (Less Than Or Equal) 	Yes
#		6 		LIKE  						No
#		7 		NOT LIKE  					No
# ----------------------------------------------------------------------

sub fltHdlrSql8numb ($$$$) {
	my $colmname	= shift;
	my $reqStr		= shift;
	my $qHandle		= shift;
	my $adocmd		= shift;
	my $status		= 1;
SUB:
{
	&notifyWSub("Started filter for $colmname.");
	$status = &fltHdlrSql8num($colmname, $reqStr, $qHandle, $adocmd, 1);
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# fltHdlrSql8numb


# ----------------------------------------------------------------------
#	fltHdlrSql8num		filter handler for SQL 8 numeric column
# ----------------------------------------------------------------------
#	arguments:
#		colmname	SQL 8 trace column name
#		reqStr		request string
#		qHandle		queue handle
#		adocmd		ADO Command object handle
#		bigintflg	optional flag, to specify trace filter is for bigint
#	return:
#		status		0 - failed
#					1 - success
# ----------------------------------------------------------------------
#	Filter handler for SQL 8 numeric column. Available comaprison 
#	operators are:
#		Value	Comparison operator 		Implemented?
#		0 		= (Equal) 					Yes
#		1 		<> (Not Equal) 				Yes
#		2 		> (Greater Than) 			No
#		3 		< (Less Than) 				No
#		4 		>= (Greater Than Or Equal)	Yes
#		5 		<= (Less Than Or Equal) 	Yes
#		6 		LIKE  						No
#		7 		NOT LIKE  					No
# ----------------------------------------------------------------------

sub fltHdlrSql8num ($$$$\$) {
	my $colmname	= shift;
	my $reqStr		= shift;
	my $qHandle		= shift;
	my $adocmd		= shift;
	my $bigintflg	= shift;
	my $colmid		= $gTrcColumns{$colmname}{SQL8ColmId};
	my $declare		= 0;		# sql statements to declare variable
	my $sql			= '';		# sql command buffer
	my $oper		= '';		# Boolean operator.
	my $operid		= 0;		# SQL 8 trace operator id
	my $logicalop	= 0;		# SQL 8 trace logical operator AND (0) or OR (1), 1 is used only with operator 0 and 6 
	my $val			= 0;
	my $status		= 1;
SUB:
{
	&notifyWSub("Started filter for $colmname.");
	# Verfiy input string.

	if ($reqStr !~ /^([<!>])?\s*(\d+)$/) {
		&errme("Invalid input parameter $reqStr for the filter $colmname.");
		$status = 0;
		last SUB;
	}

	$oper	= ($1)? $1:'=';
	$val	= $2;

	if ($oper eq '<') {
		$operid		= 5;
		$logicalop	= 0;
	} elsif ($oper eq '>') {
		$operid		= 4;
		$logicalop	= 0;
	} elsif ($oper eq '!') {
		$operid		= 1;
		$logicalop	= 0;
	} else {
		$operid		= 0;
		$logicalop	= 1;
	}

	$declare	= ($bigintflg)?
				"declare \@val bigint set \@val = $val":
				"declare \@val int set \@val = $val";
	$sql		= "sp_trace_setfilter $qHandle, $colmid, $logicalop, $operid, \@val";
	&notifyWSub("Apply filter: \n$declare\n$sql");
	unless ($status = &execSQL8tracesp($adocmd, $sql, $declare)) { last SUB; }

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# fltHdlrSql8num


# ----------------------------------------------------------------------
#	fltHdlrSql8str		filter handler for SQL 8 string column
# ----------------------------------------------------------------------
#	arguments:
#		colmname	SQL 8 trace column name
#		reqStr	request string
#		qHandle	queue handle
#		adocmd	ADO Command object handle
#	return:
#		status		0 - failed
#					1 - success
# ----------------------------------------------------------------------
#	Filter handler for SQL 8 string column. Available comaprison 
#	operators are:
#		Value	Comparison operator 		Implemented?
#		0 		= (Equal) 					No
#		1 		<> (Not Equal) 				No
#		2 		> (Greater Than) 			No
#		3 		< (Less Than) 				No
#		4 		>= (Greater Than Or Equal)	No
#		5 		<= (Less Than Or Equal) 	No
#		6 		LIKE  						Yes
#		7 		NOT LIKE  					Yes
# ----------------------------------------------------------------------

sub fltHdlrSql8str () {
	my $colmname	= shift;
	my $reqStr		= shift;
	my $qHandle		= shift;
	my $adocmd		= shift;
	my $colmid		= $gTrcColumns{$colmname}{SQL8ColmId};
	my $sql			= '';		# sql command buffer
	my $oper		= '';		# Boolean operator.
	my $operid		= 0;		# SQL 8 trace operator id
	my $logicalop	= 0;		# SQL 8 trace logical operator AND (0) or OR (1), 1 is used only with operator 0 and 6 
	my $val			= 0;
	my @args		= ();		# arguments, provided in reqStr
	my $arg			= '';		# one of arguments in @args array
	my @incArg		= ();		# list of include arguments
	my @excArg		= ();		# list of exclude arguments
	my $status		= 1;
SUB:
{
	&notifyWSub("Started filter for $colmname.");


	@args = split ';', $reqStr;
	foreach $arg (@args) {
		$arg =~ /^\s*(\!?)\s*N?(.*)\s*$/;
		$oper	= $1;
		$val	= $2;
		$val	=~ s/^\s*['"]//; 
		$val	=~ s/['"]$//;

		if ($val =~ /^\s*$/) {
			&errme("Empty argument for the filter $colmname.");
			$status = 0;
			last SUB;
		}
		($oper eq '!') ? push @excArg, $val:push @incArg, $val;
	}

	# Include strings are using LIKE value operator and OR logical operator:
	$operid		= 6;
	$logicalop	= 1;

	foreach $val (@incArg) {
		$sql	= "sp_trace_setfilter $qHandle, $colmid, $logicalop, $operid, N'$val'\n";

		&notifyWSub("Apply filter: \n$sql");
		unless ($status = &execSQL8tracesp($adocmd, $sql)) { last SUB; }
	}

	# Exclude strings are using NOT LIKE value operator and AND logical operator:
	$operid		= 7;
	$logicalop	= 0;

	foreach $val (@excArg) {
		$sql	= "sp_trace_setfilter $qHandle, $colmid, $logicalop, $operid, N'$val'\n";

		&notifyWSub("Apply filter: \n$sql");
		unless ($status = &execSQL8tracesp($adocmd, $sql)) { last SUB; }
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# fltHdlrSql8str


# ----------------------------------------------------------------------
# getTrcParms
# ----------------------------------------------------------------------
#	arguments:
#		cfgFile			trace parameters file to parse
#		customTrcFlg	0 - default trace, 1 - custom trace.
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Purpose: Read the provided configuration file .
#   Set up global variables with the values read from CFG file.
#	Default trace file populates SQL Trace columns (@gDoColumns), 
#	SQL Trace events (@gDoEvents) and SQL Trace filters (%gDoFilters).
#	The custom trace file populates only filters array.
# ----------------------------------------------------------------------

sub getTrcParms($$) {
	my $cfgFile			= shift;
	my $customTrcFlg	= shift;
	my $key;
	my $trcid			= '';		# string id for SQL Trace column, event or filter.
	my $status	= 1;
SUB:
{
	unless (&readConfigFile($cfgFile)) {
		&warnme("Cannot read configuration file $cfgFile.");
		$gNWarnings++;
		$status = 0; last SUB;
	}

	foreach $key (keys (%gConfigValues) ) {
		if ($key =~ /^(trcFilter:)/) {
			($trcid = $key) =~ s/$1//;
			$gDoFilters{$trcid} = $gConfigValues{$key};
			delete($gConfigValues{$key});
		}
		if ($key =~ /^(trcColumn:)/) {
			($trcid = $key) =~ s/$1//;
			if ($customTrcFlg) {
				&warnme("Trace Column $trcid is ignored for custom trace definition.");
				next;
			}
			push (@gDoColumns, $trcid)	if (uc($gConfigValues{$key}) eq 'Y');
			delete($gConfigValues{$key});
		}
		if ($key =~ /^(trcEvent:)/) {
			($trcid = $key) =~ s/$1//;
			if ($customTrcFlg) {
				&warnme("Trace event $trcid is ignored for custom trace definition.");
				next;
			}
			push (@gDoEvents, $trcid)	if (uc($gConfigValues{$key}) eq 'Y');
			delete($gConfigValues{$key});
		}
	}

	$status	= 1;
	last SUB;
}
	return($status);	
} # getTrcParms


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

	$gScriptName	= "";			# Base name of the current script.
	$gScriptPath	= ".\\";		# Directory path to current script.


	($gScriptPath, $gScriptName, $scriptSuffix) = &T38lib::Common::parseProgramName();

	#-- initialize standard options

	getopts('ha:n:S:s:x:f:');

	use Sys::Hostname;
	$gHostName	= hostname;
	$gSrvrName	= $gHostName;	# SQL Server name
	$gNetName	= $gHostName;	# SQL Server machine name
	$gInstName	= '';			# SQL Server instance name
	$gDebugSQL	= '';
	$gNWarnings	= 0;

	#-- program specific initialization


	$gRunOpt		= 's';
	$gTrcName		= '';
	$gSQLVersion	= '';
	$gNTraceFiles	= 7;

	#-- show help

	if ($Getopt::Std::opt_h) { &showHelp(); exit; }

	# Open log and error files, if needed.

	SUB: {
		unless (&T38lib::Common::setLogFileDir("$gScriptPath\\T38LOG\\$gScriptName")) {
			&errme("Cannot set program log directory.");
			$status = 0;
			last SUB;
		}

		if($Getopt::Std::opt_a) {
			if ( $Getopt::Std::opt_a =~ /\d/) {
				if ( ($Getopt::Std::opt_a < 101) and ($Getopt::Std::opt_a > 0) ) {
					$numArchive = $Getopt::Std::opt_a;
				}
			}
		}

		&T38lib::Common::archiveLogFile($numArchive);
		&logme("Starting $gScriptName from $gScriptPath", "started");

		if($Getopt::Std::opt_x) {
			if ($Getopt::Std::opt_x =~ /^[sx]$/) {
				$gRunOpt = $Getopt::Std::opt_x;
			} else {
				&errme("Invalid -x options. Allowed values are s or x.");
				$status = 0;
				last SUB;
			}
		}

		if($Getopt::Std::opt_s) {
			$gDebugSQL = $Getopt::Std::opt_s;
			&T38lib::Common::archiveFile($gDebugSQL, 7);
		}

		if($Getopt::Std::opt_n) {
			if ($Getopt::Std::opt_n =~ /^\d{1,2}$/ and $Getopt::Std::opt_n > 1) {
				$gNTraceFiles = $Getopt::Std::opt_n;
			} else {
				&errme("Invalid -n options. Only numbers between 2 and 99 are allowed.");
				$status = 0;
				last SUB;
			}
		}

		if ($Getopt::Std::opt_S) {
			$gSrvrName	= uc($Getopt::Std::opt_S);
			$gSrvrName	=~ s/^\./$gHostName/;
			($gNetName, $gInstName)	=	split("\\\\", $gSrvrName);
			$gInstName =~ s/^\s+//g; $gInstName =~ s/\s+$//g;
		}

		if ($#ARGV != 0 ) {
			&errme("Missing standard trace file name.");
			$status = 0;
			last SUB;
		} else {
			$gTrcName	= $ARGV[0];
			$gTrcName	= &T38lib::Common::stripWhitespace($gTrcName);
			$gTrcName	=~ s/\//\\/g;
			if (($gRunOpt eq 's') && !&getTrcParms($gTrcName, 0)) {
				&errme("Cannot get standard trace parameters in $gTrcName.");
				$status = 0;
				last SUB;
			}
			$gTrcName =~ s|\\|/|g;	# Convert DOS directory delimiters to UNIX. 
			$gTrcName = uc(basename($gTrcName,'.*'));
			$gTrcName =~ s/\.[^\.]*$//;	# Remove extension.

			my $t38trcPath	= "\\\\$gNetName\\t38trc";
			unless (-d $t38trcPath) {
				&errme("Trace directory $t38trcPath is missing!");
				$status = 0;
				last SUB;
			}

			$gTrcBaseName = ($gInstName) ?
				uc("$t38trcPath\\${gInstName}_$gTrcName") :
				uc("$t38trcPath\\$gTrcName");

			my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) 
				= localtime(time);

			$gTrcFileName = sprintf ("$gTrcBaseName%04d%02d%02d%02d%02d.trc", $year+1900, $mon+1, $mday, $hour, $min);
			$gTrcFileName = uc($gTrcFileName);
		}

		if($Getopt::Std::opt_f && ($gRunOpt eq 's') && !(&getTrcParms($Getopt::Std::opt_f, 1))) {
			&errme("Cannot get custom trace filters from $Getopt::Std::opt_f.");
			$status = 0;
			last SUB;
		}

		# Check Perl version.

		unless ( &T38lib::Common::chkPerlVer() ) {
			&notifyWSub("Wrong version of Perl!");
			&notifyWSub("This program run on Perl version 5.005 and higher.");
			&notifyWSub("Check the Perl version by running perl -v on command line.");
			$status = 0;
			last SUB;
		}

		$gSQLVersion = &T38lib::Common::getSqlVerReg($gNetName, $gInstName);
		if ($gSQLVersion != 0 ) {
			$gSQLVersion =~ s/\.\d+$//;
		}
		else {
			&errme("Call to &T38lib::Common::getSqlVerReg($gNetName, $gInstName) failed");
			&notifyWSub("Call to &T38lib::Common::getSqlVerReg($gNetName, $gInstName) failed");
			&notifyWSub("Can not get sql version using default $gSQLVersion");
			$status = 0;
			last SUB;
		}

		if ($gSQLVersion !~ /^7\.00|8\.00$/) {
			&errme("The SQL Server version $gSQLVersion cannot be handled by this program.");
			$status = 0;
			last SUB;
		}

		if ($gRunOpt eq 's') {
			# Validate trace parameters.
			my $akey;
			foreach $akey (@gDoEvents) {
				if (!defined $gTrcEvents{$akey} || ($gSQLVersion eq '7.00' && $gTrcEvents{$akey} > SQL7MAXEVENT)) {
					&notifyWSub("Event $akey is invalid for SQL Server version $gSQLVersion.");
					$status = 0;
				}
			}	# foreach gDoEvents
			&errme("Invalid event was given for $gTrcName trace configuration.")	if ($status == 0);

			foreach $akey (keys %gDoFilters) {
				if (!defined $gTrcColumns{$akey} || 
					($gSQLVersion eq '7.00' && !$gTrcColumns{$akey}{SQL7FltrHdlr}) ||
					($gSQLVersion eq '8.00' && !$gTrcColumns{$akey}{SQL8FltrHdlr})
				) {
					&notifyWSub("Filter $akey is invalid for SQL Server version $gSQLVersion.");
					$status = 0;
				}
			}	# foreach gDoFilters
			&errme("Invalid filter was given for $gTrcName trace configuration.")	if ($status == 0);

			foreach $akey (@gDoColumns) {
				if (!defined $gTrcColumns{$akey} || 
					($gSQLVersion eq '7.00' && !$gTrcColumns{$akey}{SQL7ColmId}) ||
					($gSQLVersion eq '8.00' && !$gTrcColumns{$akey}{SQL8ColmId})
				) {
					&notifyWSub("Data column $akey is invalid for SQL Server version $gSQLVersion.");
					$status = 0;
				}
			}	# foreach gDoColumns
			&errme("Invalid data column was given for $gTrcName trace configuration.")	if ($status == 0);

			if ($status == 0) {	last SUB; }
		}


		($gRunOpt eq 'x') ?
			&notifyWSub("$gHostName: Stop SQL Trace for $gTrcName.") :
			&notifyWSub("$gHostName: Start SQL Trace for $gTrcName.")
			;
	}	# SUB
	# ExitPoint:

	return($status);

}	# housekeeping

# ----------------------------------------------------------------------
#	debugPrintTrcConstant		print SQL Trace constants to setup 
#								columns, events and filters
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	print SQL Trace constants to setup columns, events and filters
# ----------------------------------------------------------------------

sub debugPrintTrcConstant () {
	&notifyWSub("Started.");
	&notifyMe("Trace Columns:")
	&notifyMe("============================================================");
	&debugPrintHashHash(\%gTrcColumns);

	&notifyMe("Trace Events:")
	&notifyMe("============================================================");
	&debugPrintHash(\%gTrcEvents);

	&notifyWSub("Done.");
	return;
}	# debugPrintTrcConstant



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


# ----------------------------------------------------------------------
#	debugPrintHashHash		Print hash of hashes
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	Print hash of hashes
# ----------------------------------------------------------------------

sub debugPrintHashHash ($) {
	my $hashRef	= shift;
	my $key;
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");

	foreach $key (keys % { $hashRef }) {
		foreach (keys %{$$hashRef{$key}}) {
			&notifyMe ("\%myHash{$key}{$_} = $$hashRef{$key}{$_}");
		}
	}
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# debugPrintHashHash



# ----------------------------------------------------------------------
#	debugPrintSQL		Print input to debug sql file
# ----------------------------------------------------------------------
#	arguments:
#		msg	input message to print.
#	return:
#		none
# ----------------------------------------------------------------------
#	Print hash of hashes
# ----------------------------------------------------------------------

sub debugPrintSQL($) {
	my ($msg) = shift;			# Get the input parameter

	if ($gDebugSQL) {

		# open the log file

		&notifyWSubcroak("Cannot open file $gDebugSQL")
			unless (open(DBGSQL,">>$gDebugSQL"));

		print DBGSQL "$msg\ngo\n";

	  	close(DBGSQL);
	}

}	# End  of notifyMe

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
#*  t38trace - Configures and controls SQL Trace for MSSQL 7.0 and 2000. 
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/09 22:53:27 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/t38trace/t38trace.pv_  $
#*
#* SYNOPSIS
#*	t38trace -h -a 10 -n nTraces -S server -s debugSQLFile -x{s|x} -f filters trcParms
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-a 10		Number of log file archived, default is 7
#*	-n nTraces	Number of trace files, to keep, default is 7.
#*	-S server	Name of the server where to create SQL Trace. Default is
#*				local server.
#*	-s debugSql	debug file name for sql statements.
#*	-x execOpt	Execution option: 
#*					s -- start SQL Trace
#*					x -- stop SQL Trace
#*				default is to start SQL Trace.
#*	-f filters	Optional configuration file with filters to apply. These
#*				filters will overwrite SQL Trace filters, created by default.
#*	trcParms	configuration file with standard sql trace parameters.
#*	
#*	
#*	This program is managing SQL Traces for SQL 7 and SQL 2000 servers. 
#*	The execution option -x is used to start or stop SQL Trace. The trcParms
#*	file provides list of columns, events and filters to use with SQL Trace
#*	stored procedures. The trcParams files are preconfigured and should not be
#*	modified during day to day operations. The option -f parameter
#*	provides mechanism for customizing standard traces with 
#*	additional filters.
#*
#*	Example 1:
#*		Start tracing, using data columns, events and filters, defined in
#*		SQLTraceStandard.cfg file.
#*
#*		t38trace.pl SQLTraceStandard.cfg
#*
#*	Example 2:
#*		Stop SQL Trace, created by SQLTraceStandard.cfg.
#*
#*		t38trace.pl -xx SQLTraceStandard.cfg
#*
#*	Example 3:
#*		Start tracing, using SQLTraceStandard.cfg file and apply 
#*		filters, defined in SQLTraceStdCustom.cfg file.
#*
#*		t38trace.pl -f \\%computername%\t38tmp\SQLTraceStdCustom.cfg SQLTraceStandard.cfg
#*
#*	The t38trace.pl performs following steps:
#*
#*	Get version of SQL Server.
#*	Read SQL Server trace configuration, defined in trcParms.
#*	Read SQL Server trace configuration, defined in custom filters file.
#*	Resolve collisions between filters and trcParms files.
#*	For SQL 7 server, use xp_trace_getqueuedestination to find queue, matching
#*		trcParms file name.
#*	For SQL 2000 server, stop traces, with the trcParms name.
#*	Archive current trace file, using last 10 copies.
#*	If requested to start trace
#*		Use corresponding version of SQL Server	to configure trace parameters.
#*		Start SQL Trace.
#*
#***
EOT
} #	showHelp


__END__

=pod

=head1 NAME

t38trace - Configures and controls SQL Trace for MSSQL 7.0 and 2000.

=head1 SYNOPSIS

perl t38trace -h -a 10 -n nTraces -S server -x{s|x} -f filters trcParms

=head2 OPTIONS

I<t38trace> accepts the following options:

=over 4

=item [OPTION]

DESCRIPTION OF THE OPTION

=item -h 		(Optional)

Print out a short help message, then exit.

=item -a <number> 		(Optional)

Number of log file archived, default is 7

=item -n <number> 		(Optional)

Number of trace files, to keep, default is 7

=item -S <name> 		(Optional)

Name of the server where to create SQL Trace. Default is
local server.


=item -x execOpt		(Optional)

Execution option: 
	s -- start SQL Trace
	x -- stop SQL Trace
default is to start SQL Trace.

=item -f filters		(Optional)

Optional configuration file with filters to apply. These
filters will overwrite SQL Trace filters, created by default.

=item OTHER OPTION 	(Required)

DESCRIPTION OF THE OPTION

=item trcParms	fileName

Configuration file with standard sql trace parameters.

=back

=head1 DESCRIPTION

This program is managing SQL Traces for SQL 7 and SQL 2000 servers. 
The execution option -x is used to start or stop SQL Trace. The trcParms
file provides list of columns, events and filters to use with SQL Trace
stored procedures. The trcParams files are preconfigured and should not be
modified during day to day operations. The option -f parameter
provides mechanism for customizing standard traces with 
additional filters.

=head1 EXAMPLE

I<Example 1:>
	Start tracing, using data columns, events and filters, defined in
	SQLTraceStandard.cfg file.

	t38trace.pl SQLTraceStandard.cfg

I<Example 2:>
	Stop SQL Trace, created by SQLTraceStandard.cfg.

	t38trace.pl -xx SQLTraceStandard.cfg

I<Example 3:>
	Start tracing, using SQLTraceStandard.cfg file and apply 
	filters, defined in SQLTraceStdCustom.cfg file.

	t38trace.pl -f \\%computername%\t38tmp\SQLTraceStdCustom.cfg SQLTraceStandard.cfg

=head1 COMPILE OPTION

=over 4

=item perl -S PerlApp.pl -f -s t38trace.pl -e t38trace.exe -c -v

=item using perl 5.005_03, ActivePerl Build 522

=back

=head1 BUGS

I<t38trace.pl> has no known bugs.

=head1 REVISION HISTORY

=begin html
$Revision: 1.1 $<br>
$Date: 2011/02/09 22:53:27 $
=end html

=head1 AUTHOR

=begin html
AUTHOR NAME, AUTHOR EMAIL ADDRESS<br>
$Author: A645276 $

=end html

=head1 SEE ALSO

ADD ALL THE MODULES USED IN THIS PROGRAM 
T38lib::Common.pm, T38lib::bbyado, T38lib::t38cfgfile 
ALSO ADD ANY OTHER OS UTILITIES USED IN THIS PROGRAM
File::Basename
File::DosGlob

=head1 COPYRIGHT and LICENSE

This program is copyright by Best Buy Inc.

=cut
