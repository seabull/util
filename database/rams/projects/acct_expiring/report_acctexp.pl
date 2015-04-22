#!/usr/local/bin/perl5 -w
# $Id: report_acctexp.pl,v 1.6 2005/09/13 14:55:55 yangl Exp $

use strict;
use IO::File;
use Getopt::Long;
use Pod::Usage;

=pod

=head1 NAME

report_acctexp.pl	- Generate the expiring accounts report batch.

=head1 SYNOPSIS

B<report_acctexp.pl> [options] <file>

	The following options allowed.
	--oraconn | -c <arg>	Oracle connection string to connect to Oracle database. 
				You need to set ORACLE_HOME in your environment 
				or the default (/usr1/app/oracle/product/9.2) is used.

	--noreport | -r		Do not generate report from DB. 
	--file | -f		report file name. 
	--nomail | -m		Do not send email. Generate report only.
	--to | -t <arg>		Send report to the email address <arg>
	--cc <arg>		CC to the email address arg
	--verbose | -v		print verbose information
	--help | -h		this help 

=head1 DESCRIPTION

Script to generate expiring account report and email to users.

=head1 FUNCTIONS

=cut

my $DEFAULT_ORAHOME = defined($ENV{'ORACLE_HOME'}) ? "$ENV{'ORACLE_HOME'}" : "/usr1/app/oracle/product/9.2";
my $SQLPLUS = "$ENV{'ORACLE_HOME'}/bin/sqlplus";
my $SQLOPTS = "-s";
my $MAILER = "/usr/costing/bin/metasend";
my $report_file = '/tmp/acctexp.txt';

#Things that can be overriden by command line options
my $ora_conn = "/\@hostdb.fac.cs.cmu.edu";
my $mailto = "kzm+\@cs.cmu.edu";
my $mailcc = 'nikithse+@cs.cmu.edu,yangl+@cs.cmu.edu';
my $verbose = 0;
my $nomail = 0;
my $noreport = 0;
my @pta_list = undef;

my %CmdOptions = (
	'CONN'		=>	undef,
	'NOREPORT'	=>	undef,
	'NOMAIL'	=>	undef,
	'MAILTO'	=>	undef,
	'MAILCC'	=>	undef,
	'REPORTFILE'	=>	undef,
	'VERBOSE'	=>	undef,
	'HELP'		=>	undef
);


=over 

=item init_ora()	- init ORACLE_HOME 

=back

=cut

sub init_ora() {

	$ENV{'ORACLE_HOME'} = $DEFAULT_ORAHOME unless defined($ENV{'ORACLE_HOME'});
	print "ORACLE_HOME=$ENV{'ORACLE_HOME'}\n" if $verbose;

#	#Oracle Connection String should contain ORACLE_HOME
#	#But if local naming method is used, the real ORACLE_HOME is in tnsname.ora
#	#what if other naming methods are used?
#	#So, to make it simple, I simple depend on the user to set his/her environment.
#	#Otherwise, the default ORACLE_HOME is used.
#
#	my $orahome = undef;
#	my $pid = undef;
#	my $orasid = undef;
#	
#	die "Cannot fork:$!" unless defined($pid = open(DBHOME, "-|"));
#	if ($pid) {	# parent
#		while (<DBHOME>) {
#			# do something interesting
#			$orahome .= $_;
#		}
#		unless (close(DBHOME)) {
#			my $rtn = $?;
#			$orahome = $DEFAULT_ORAHOME;
#			print "Use default oracle home - $orahome. - $rtn\n";
#		}
#
#	} else {      # child
#		# we may not be able to find dbhome 
#		exec("dbhome", $orasid);
#			#or die "can't exec program: $!";
#	}
}

=over 

=item parse_opts()	- Parse the command line options

=back

=cut

sub parse_opts() {
	GetOptions(
		'oraconn|c=s'	=>	\$CmdOptions{'CONN'},
		'nomail|m'	=>	\$CmdOptions{'NOMAIL'},
		'noreport|r'	=>	\$CmdOptions{'NOREPORT'},
		'to|t=s'	=>	\$CmdOptions{'MAILTO'},
		'cc=s'		=>	\$CmdOptions{'MAILCC'},
		'file|f=s'	=>	\$CmdOptions{'REPORTFILE'},
		'verbose|v'	=>	\$CmdOptions{'VERBOSE'},
		'help|h'	=>	\$CmdOptions{'HELP'}
		) 
	or pod2usage( {
			-message	=> 'Option is not supported',
			-exitval	=> 1,
			-verbose	=> 0,
			}
	);

	usage('Usage:') if ($CmdOptions{'HELP'}) ;
	$ora_conn	= $CmdOptions{'CONN'}		if $CmdOptions{'CONN'};
	$noreport	= $CmdOptions{'NOREPORT'}	if $CmdOptions{'NOREPORT'};
	$nomail		= $CmdOptions{'NOMAIL'}		if $CmdOptions{'NOMAIL'};
	$mailto		= $CmdOptions{'MAILTO'}		if $CmdOptions{'MAILTO'};
	$mailcc		= $CmdOptions{'MAILCC'}		if $CmdOptions{'MAILCC'};
	$verbose	= $CmdOptions{'VERBOSE'}	if $CmdOptions{'VERBOSE'};
	$report_file	= $CmdOptions{'REPORTFILE'}	if $CmdOptions{'REPORTFILE'};

	print "CONN=$ora_conn\n"	if $verbose;
	print "NOREPORT=$noreport\n"	if $verbose;
	print "NOMAIL=$nomail\n"	if $verbose;
	print "MAILTO=$mailto\n"	if $verbose;
	print "MAILCC=$mailcc\n"	if $verbose;
	print "REPORTFILE=$report_file\n" if $verbose;
}

=over 

=item usage()		- Usage information

=back

=cut

sub usage(;$) {
	my ($msg) = @_;
	
	$msg = "" unless $msg;

	print $msg."\n";
	pod2usage( {
			-message	=> $msg,
			-exitval	=> 0,
			-verbose	=> 3,
			}
	);
}

=over

=item report_gen()	- Generate the report using SQL

=back

=cut

sub report_gen($;$) {
	my ($file, $ptas) = @_;

	my $sql = new IO::File('.acct_expiring.sql', O_RDWR|O_CREAT|O_TRUNC, 0644)
		or die ".acct_expiring.sql: $!\n";

	#
	# This should be done in both queries.
	#
	my $PTA_FILTER = "";
	if ($ptas) {
		$PTA_FILTER = ' AND pta.pta IN ('.join(',',map("'".$_."'",@$ptas));
		$PTA_FILTER .= ") \n";
	}
#select 
#	*
#  from hostdb.journals
# where id>233;
#spool off
#quit
#
#END

	print $sql <<"END";
set feedback off
set heading off
set termout off
set linesize 150
set newpage none
spool $file.csv
select 
	'pta'
	||','||'name'
	||','||'ID'
	||','||'case'
	||','||'amount'
	||','||'charge'
	||','||'proj_status'
	||','||'task_charge_flag'
	||','||'Award_Status'
	||','||'Date_Check'
  from dual
/
with acct_charged as
	(
		select wsc.account
			,n.name name
			,wsc.princ ID
			,decode(w.charge_by, 'P', 'Hardcode', NULL, 'Payroll', 'Unknown') case
			,wsc.amount
			,wsc.charge
		  from hostdb.who_service_charge wsc
			,hostdb.name n
			,hostdb.who w
		 where wsc.princ=n.princ
		   and n.pri=0
		   and w.princ=n.princ
		   and w.dist is not null
		union
		select hsc.account
			,h.hostname 
			,hsc.assetno 
			,decode(m.charge_by, 'P', 'hardcode-'||decode(m.prjprinc, null, m.usrprinc, m.prjprinc), NULL, nvl(m.usrprinc, 'defaultProject'), 'Unknown')
			,hsc.amount
			,hsc.charge
		  from hostdb.host_service_charge hsc
			,hostdb.hoststab h
			,hostdb.machtab m
		 where hsc.assetno=h.assetno
		   and hsc.assetno=m.assetno
	)
select
	x.pta
	||','||x.name
	||','||x.ID
	||','||x.case
	||','||x.amt
	||','||x.chg
	||','||p.proj_status_code
	||','||p.TASK_CHARGE_FLAG
	||','||p.Award_Status
	||','||case 
		when	(NVL(P.PROJ_CLOSED_DATE,to_date('31-DEC-2057','DD-MON-YYYY'))<=add_months(last_day(sysdate),3)) then
				P.PROJ_CLOSED_DATE||'-Proj-Close'
		when	NVL(P.TASK_COMPLETION_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) < add_months(last_day(sysdate),3) then
				P.TASK_COMPLETION_DATE||'-Task-Complete'
		when	NVL(P.AWARD_END_DATE_ACTIVE,to_date('31-DEC-2057','DD-MON-YYYY')) < add_months(last_day(sysdate),3) then
				P.AWARD_END_DATE_ACTIVE||'-Award-End'
		when	NVL(P.AWARD_CLOSED_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) <= add_months(last_day(sysdate),3) then
				P.AWARD_CLOSED_DATE||'-Award-Close'
		when	NVL(P.proj_completion_date,to_date('31-DEC-2057','DD-MON-YYYY')) < add_months(last_day(sysdate),3) then
				P.proj_completion_date||'-Proj-Complete'
		when	NVL(P.PROJ_START_DATE,to_date('31-DEC-1900','DD-MON-YYYY')) > last_day(sysdate) then
				P.PROJ_START_DATE||'-Proj-Start'
		when	NVL(P.AWARD_START_DATE_ACTIVE,to_date('31-DEC-1900','DD-MON-YYYY')) > last_day(sysdate) then
				P.AWARD_START_DATE_ACTIVE||'-Award-Start'
		else	'Date-In-Range'
	end 
  from
	hostdb.pta_status p
,(
select 
	pta.pta 
	,b.name
	,b.ID
	,b.case
	,sum(b.amount) amt
	,sum(b.charge) chg
  from hostdb.pta_status pta
	,hostdb.accounts a
	, acct_charged b
 where 
	a.project=pta.project_number
  and a.task=pta.task_number
  and a.award=pta.award_number 
  and b.account=a.id
 $PTA_FILTER  AND (
		pta.TASK_CHARGE_FLAG='Y'
	  AND pta.Award_Status not in ('CLOSED','ON_HOLD')
	  AND pta.proj_status_code not IN ('CLOSED','PENDING_CLOSE','SUBMITTED','UNAPPROVED')
	  AND
	(
			NVL(PTA.PROJ_CLOSED_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) <= add_months(last_day(sysdate),3)
	  OR NVL(PTA.TASK_COMPLETION_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) < add_months(last_day(sysdate),3)
  	  OR NVL(PTA.AWARD_END_DATE_ACTIVE,to_date('31-DEC-2057','DD-MON-YYYY')) < add_months(last_day(sysdate),3)
  	  OR NVL(PTA.AWARD_CLOSED_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) <= add_months(last_day(sysdate),3)
  	  OR NVL(PTA.proj_completion_date,to_date('31-DEC-2057','DD-MON-YYYY')) < add_months(last_day(sysdate),3)
  	  OR NVL(PTA.PROJ_START_DATE,to_date('31-DEC-1900','DD-MON-YYYY')) > last_day(sysdate)
  	  OR NVL(PTA.AWARD_START_DATE_ACTIVE,to_date('31-DEC-1900','DD-MON-YYYY')) > last_day(sysdate)
	)
  )
group by pta.pta, b.name, b.id, b.case
) x
 where
	p.pta=x.pta
/
set termout on
set feedback on
set heading on
spool off
quit

END

	$sql->close();
	print "Generate report using command $SQLPLUS $SQLOPTS $ora_conn @.acct_expiring.sql\n" if $verbose;

	system($SQLPLUS, $SQLOPTS, $ora_conn, '@.acct_expiring.sql') == 0
		or die "Error executing .acct_expiring.sql:$?\n";
	unlink('.acct_expiring.sql');
}

=over

=item mail_report()	- Send report thru email

=back

=cut

sub mail_report($$$;$) {
	my ($file, $to, $cc, $mailer) = @_;

	my $replyto = "yangl+\@cs.cmu.edu";
	die "Cannot execute email client $mailer.\n" unless (-x $mailer);
	die "Cannot read file $file.\n" unless (-e $file);
	my @mail_args = 
		(
			$mailer,
			"-b -t ".'"'."$to".'"',
			"-c ".'"'."$cc".'"' ,
			"-s ".'"'."Account Expiring Report - ${file}".'"' ,
			"-m ".'"'."application/octet-stream".'"' ,
			"-A ".'"'."attachment;filename=${file}".'"' ,
			"-f ${file}" ,
			"-F ${replyto}" ,
			"-S 5242880",
		);

	print "Sending report using command $mailer ".join(' ',@mail_args)."\n" if $verbose;
	system(join(' ', @mail_args)) == 0
		or die "Error sending email notification : $?\n" ;

	print "report sent thru email.\n" if $verbose;
}

=over

=item acct_fmt_check()		

=back

=cut

sub acct_fmt_check ($;$) {
	my ($accts, $acct_sep) = @_;

	my $acct_seperator = '-';
	$acct_seperator = $acct_sep if $acct_sep;

	my $GM_FMT = qr/^\s*(\d{3,5})$acct_seperator([0-9a-zA-z\.]{1,4})$acct_seperator(\d){6,8}\s*$/;
	my $GL_FMT = qr/^\s*(\d{6,7})$acct_seperator(\d{3})$acct_seperator(\d{3})$acct_seperator(\d){6}$acct_seperator(\d{2})\s*$/;

	foreach $a (@$accts) {
		usage("Account $a does not seem to be in general GMS account format. \n") unless ($a =~ $GM_FMT);
	}
	#print "PTAs ".join(' ', @$accts);
}

=over

=item acct2id()		- Lookup the PTAs and return their internal IDs.

=back

=cut

sub acct2id($) {
	# Look up the IDs for the account in the list.
}

#
#Main
#
parse_opts();

#
# Process accounts if any
@pta_list=@ARGV;

print "PTAs=".join(' ',@pta_list)."\n" if $verbose;

acct_fmt_check(\@pta_list);

init_ora();

##$report_file = shift @ARGV;

usage("***Report File is not specified.***") unless $report_file;

print "Generate report into file $report_file.csv.\n" if $verbose;

report_gen($report_file, \@pta_list) unless $noreport;

mail_report($report_file.'.csv', $mailto, $mailcc, $MAILER) unless $nomail;

print "Done.\n" if $verbose;

1;

__END__

=pod

=head1 EXAMPLES

report_acctexp.pl -c '/@tns_entry' -v foo

=head1 AUTHOR

Longjiang Yang, E<lt>yangl+@cs.cmu.eduE<gt>

=head1 COPYRIGHT
	
	School of Computer Science
	Carnegie Mellon University

=head1 SEE ALSO

L<Perl>

=cut
