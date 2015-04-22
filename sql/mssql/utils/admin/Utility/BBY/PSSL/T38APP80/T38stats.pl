#! perl
#
# PVCS header information
# $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL65/T38stats.pv_  $
# $Author: A645276 $
# $Date: 2011/02/09 22:51:59 $
# $Revision: 1.1 $
#
#* Purpose:  T38stats.pl Updates stats on database
#* Program must be executed from within the directory it is located.
#*
#* SYNOPSIS
#*
#*	t38stats.pl -h | -S server name
#*
#*	Command line:
#*
#*	-S	optional server name
#*
#*
#*	Example: 
#*	1. Not specifying the server
#*		perl T38stats.pl
#*
#*		
#*	2. Specifying a server
#*       perl T38stats.pl -S ServerName
#*	
#*	
#*
#***

#use strict;

# Modules used.
use Win32::EventLog;
use Getopt::Std;


my ($gscript, $gserverName, $glogFile, $gsqlVer, $gstat);

# check the command line arguments
getopts('hS:');

if ($opt_h) {	 # exit if h option exists
	&showHelp;
    exit 0;	}
    
if($Getopt::Std::opt_S){
  $gserverName = $Getopt::Std::opt_S;
  $gisql = "osql -E -S$gserverName -dmaster -n -w300"; 
  # $gisql = "isql -E -S$gserverName -dmaster -n -w300"; 
}else{
  $gisql = "osql -E -dmaster -n -w300"; 
  # $gisql = "isql -E -dmaster -n -w300"; 
}

# Get the name of the program for log file
# Log file name is equal to name of the program.log
#
($gscript = $0)  =~ s/\.\w*$//;
$glogFile = "$gscript.log";

# Open log file 
unless (open(RunLog,">$glogFile")) {
	print ("** ERROR ** [main]: Cannot open file $glogFile: $!");
	exit 1;
}
&notifyme ("Start DB Stats \n");
&dbStat;
&notifyme ("Finish DB Stats \n");
# Clean-up: Delete temp work files
unlink("$gscript.sql");

# Close files
close(RunLog);

#  Check for error, if finds error returns status of 1 so Maestro abends
&chk4errs;
     


###   Subroutines  #######################################################################

#--------------------------------------------------
#
#     notifyme -- log a message
#
#-------------------------------------------------

sub
notifyme {
	my($msg)  = @_;
	my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	print "$msg\n";
	printf RunLog ("%02d/%02d/%02d %02d:%02d \n %s\n", $mon+1, $mday, $year, $hour, $min, $msg);
} # END sub notifyme

#----------------------------------------------------------------------
#
# Consistency checker on SQL 6.5, 7.0, and 2000 Servers
#
#
#----------------------------------------------------------------------

sub dbStat {

my ($cmd, $status);
my (@dbnames); 

# Open a temp file 
	unless (open(SQL,">$gscript.sql")) {
		print ("** ERROR ** [main]: Cannot open file $gscript.sql: $!");
		&notifyme ("** ERROR ** [main]: Cannot open file $gscript.sql: $!");
		exit 1;
	}
# Write the SQL to get the dbnames
	print SQL "use master\n";
	print SQL "go\n";
	print SQL "set nocount on\n";
	print SQL "go\n";
	print SQL "EXEC sp_T38LOGERROR 3, 'T38STATS', 'Started.'\n";
    print SQL "DECLARE	\@cnt	smallint \n";
    print SQL "DECLARE  \@msg	varchar(255) \n";
	print SQL "DECLARE  \@databasename   varchar(128) \n";
	print SQL "DECLARE dbnames_cursor CURSOR FOR SELECT name FROM sysdatabases \n";
	print SQL "WHERE name NOT IN ('tempdb','model','master','pubs','msdb') \n";
	print SQL "OPEN dbnames_cursor \n";
	print SQL "FETCH NEXT FROM dbnames_cursor INTO \@databasename \n";


    print SQL "select \@cnt = 0 \n";
    print SQL "WHILE \@\@fetch_status = 0 \n";
	print SQL "BEGIN \n";
	print SQL "EXEC (\"sp_T38LOGERROR 3, 'T38STATS', 'Updating statistics for database \" + \@databasename + \"'\") \n";
	print SQL "EXEC (\"USE \" + \@databasename + \" exec sp_T38UPSTATS\") \n";
	print SQL "select \@cnt = \@cnt + 1 \n";
	print SQL "FETCH NEXT FROM dbnames_cursor INTO \@databasename \n";
	print SQL "END \n";
	print SQL "DEALLOCATE dbnames_cursor \n";
	print SQL "select \@msg = \"Updated statistics for \" + convert(varchar(4), \@cnt) + \" databases\" \n";
	print SQL "exec sp_T38LOGERROR 3, 'T38STATS', \@msg \n";
	print SQL "set nocount off \n";
	print SQL "GO \n";
    print SQL "EXEC sp_T38LOGERROR 3, 'T38STATS', 'Finished.' \n";

	close(SQL);

$cmd="$gisql -i $gscript.sql -o $gscript.out";

# Run the SQL
	$status = system($cmd);
#	print "status = $status\n";

	unless (open(OUT,"<$gscript.out")) {
		print ("** ERROR ** [getdbnames]: Cannot open file $gscript.out: $!");
		exit 1;
	}
# Read the output file created by SQL command and look for 
# databases names.
	while (<OUT>) {
		chomp;
		if ( (/\w+/) ) {
				$_ = StripWhitespace($_);

				if ( /Unable to Connect/i ) {
					@dbnames = (); 
					push (@dbnames,"Error");
					last;
				}
				push (@dbnames,$_) if (! /name/ );
			
		}
	}
	close(OUT);

# Sort and return the database names.
	return (sort (@dbnames) );

}

#------------------------------------------------------------------------------
#	Purpose: Stripe leading and trailing white spaces of a given string.
#
#	Input: A string with trailing or leading spaces
#	Output: Retrun the string after removing all the trailing
#			and leading spaces
#
# Use of regular expresion to search for spaces and remove them
# by using the subsitute command.
#------------------------------------------------------------------------------
sub StripWhitespace {
  my $str = shift;
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  return $str;
}
#-----------------------------------------------------------------------
###	showHelp -- show help information from the current perl script.
#-----------------------------------------------------------------------

sub
showHelp {
	local($inhelp) = 0;

unless (open(PLFILE, $0)) { errme("Cannot open $0: $!\n"); die "Died"; } 

	while (<PLFILE>) {
		$inhelp = 1 if (!$inhelp && /^#\*\s/);
		if ($inhelp) {
			if (/^#\*\s/) {
				s/^#\*//;
				print;
			} else {
				last;
			}
		}
	}
	close(PLFILE);
} #	showHelp

#----------------------------------------------------------------------
#
# Check for errors in logfile#
#
#----------------------------------------------------------------------

sub chk4errs {

################### Variables of errors to include/exclude ##########################
my $lowersev = 17;			# Lowest severity level that we will report on.
					# possible serverity values are
					#	 0 - 10 are informational
					#	11 - 16 are user generated
					#	17 - 19 are hardware issues
					#	20 - +  are system fatal errors

my @XErr = (219, 1104, 2540, 15023, 15024, 15025, 15026, 15027, 15028, 15029, 
	15029, 15030, 15031, 15032, 15034);	# errors we're not interested in

my @IErr = ();		# Error we always want to include
							# regardless of sev. level.
my ($err,$sev);

#########################  Optional Variable Conditions  ##########################

##############################  Program Variables  ##############################

$gstat = 0;
my $noterr = join("|",@XErr);
my $iserr  = join("|",@IErr);

unless (open(OUTFILE,"$gscript.out")) {
	print ("** ERROR ** [errorcheck]: Cannot open file $gscript.tmp: $!");
	exit 1;
}
foreach (<OUTFILE>)	{
	if (m/Msg\s* (\d+),\s* Level\s*(\d+),/i) {
		($err, $sev) = ($1, $2);
		if (($sev >= $lowersev) || ($err =~ m/$iserr/))	{
			$gstat = 1 unless ($err =~ m/$noterr/);
		} 
	}

}
close(OUTFILE);
ExitPoint:
( $gstat == 0) ?
   logme("Finished with status $gstat") :
   warnme("Finished with status $gstat");
print("\nFinished with status $gstat \n");
exit($gstat);

}

###logme -- issue an informative message
#
###

sub logme {

   logEvent("Info", $_[0]);

} #logme


###	warnme -- issue a warning message
#
###

sub
warnme {
	logEvent("Warn", $_[0]);
} #	warnme

###	errme -- issue a warning message
#
###

sub
errme {
	logEvent("Error", $_[0]);
} #	errme


###	logEvent -- log an event in Windows NT Event Log.
#
###

sub
logEvent {
	my ($errtype, $errmsg) = @_;
	my $eventype;
	my $EventLog;
	my $appname = $gscript;
	my $data	= "";
    my $perlflag = 0;
	my $badwrite;

	$eventype = 	($errtype =~ m/Info/i) ? EVENTLOG_INFORMATION_TYPE :
			($errtype =~ m/Warn/i) ? EVENTLOG_WARNING_TYPE :
			EVENTLOG_ERROR_TYPE;

	my %event=(
		'Category',  NULL,
		'Source', $appname,
		'Computer', '',
		'Length', length($data),
		'RecordNumber', NULL,
		'TimeGenerated', NULL,
		'Timewritten', NULL,
		'EventID', 9000,
		'EventType', $eventype,
		'ClosingRecordNumber',NULL,
		'Strings',$errmsg,
		'Data',$data,
	);
    

@perlv = `perl -v`;
	foreach $perlv(@perlv) {
	  if($perlv =~ /110/){
            Open Win32::EventLog($EventLog, '', "Application") || die "$! ";
 	    if( ! $EventLog->Report(\%event) ){
		   print "Warning *** Fail to write to Event Log\n";
	    }
		    $perlflag = 1;
            last;
			$perlflag = 1;
	  }elsif (($perlv =~ /613/) || ($perlv =~ /522/)){
	       Win32::EventLog::Open($EventLog, $appnam, '') || die "$! ";

	    if ( ! $EventLog->Report(\%event) ){
           print "Warning *** Fail to write to Event Log\n";
	    }             
		$perlflag = 1;
		last;
	  }
    }
  if($perlflag ==0){
    print "This does not fit our standard for perl \n";
	$badwrite =`$gisql "Exec sp_T38LOGERROR 2, \'t38stats\', \'Error can't write to Event Log because it can't interpret perl version, check problem\'"`;
  }
} #	logEvent
