# $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/lib/perl/CMUCS/Rams/Report/AcctExp/AcctExpReport.pm,v 1.25 2007/10/26 18:41:54 costing Exp $
#
package CMUCS::Rams::Report::AcctExp::AcctExpReport;

use 5.006;
use strict;
use Carp;
#use FileHandle;
use Data::Dumper;
use Text::Template;

use CMUCS::Rams::Report::Utils::Utils;

use DBI;
use DBD::Oracle qw(:ora_types);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our $VERSION = '0.01';


#my ($coltitlewidth1, $row_width) = (24, 80);
#---------------------------------------------------
my $rpt_template = q!
{$header} for {$account || ''}
{$entities}
{$footer}
!;

my $mail_template = q!
End of Debugging
-----------------------------------
Account      {$account}
Net change   {sprintf "\$ %.2f", $amount}

Dear Customer,

The account will be expiring {if($reason =~ /PTA.*/) { sprintf "in %d days on %s", $daycount, $expdate } else { sprintf "today"} }. Our record shows that service charge of the following user(s)/machines(s) are currently configured to charge to this account.

Please either
 - provide a valid account string for service charges of the following user(s)/machine(s) or 
 - make sure the account remain valid by the end of the month.

Please refer to the SCS Facilities charging policy, <link>, 
for general information.

Thanks,
Help Desk
SCS Facilities

We recommend using "Courier New" font to view the report. 
{sprintf('-'x80)}
Internal ID: {$reportid}
{$report}
!;

sub numerically { $a <=> $b }

#---------------------------------------------------

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

			#acctstring	=> [],
	my $self = bless {
			reportid	=> undef,
			reportmeta	=> undef,
			acctstring	=> undef,
            projnames   => undef,
			entities	=> undef,
			header		=> 'Expiring Oracle String',
			footer		=> undef,
			email		=> undef,
			rpt_template	=> { TYPE => 'STRING', SOURCE => $rpt_template },
			mail_template	=> { TYPE => 'STRING', SOURCE => $mail_template },
			@_,
		}, $class;

	return $self;
}

sub fetchEmails
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my ($dbh, $id) = @_;
	croak "fetchEmails - Invalid database handle. " unless $dbh;

	my $rpt_id;
	if(ref($invocant))
	{
		my $mails =  $invocant->email;
		#Utils::mylog(2, undef, "fetchEmails\n");
		return $mails if $mails;
		#$rpt_id = $id || $invocant->reportid || 'null';
		$rpt_id = $id || $invocant->reportid || 0;
		Utils::mylog(3, undef, "fetchEmails: rptid=$rpt_id\n");
	} else {
		#$rpt_id = $id || 'null';
		$rpt_id = $id || 0;
	}
	#print "Get emails for rptid=$rpt_id\n";

	my $sth_open = $dbh->prepare(qq{
		begin
			:csr := ccreport.emailinfo.fetchAEEmailInfo(:rpt_id);
		end;
	});
	my $sth_close = $dbh->prepare(q{
		begin
			ccreport.emailinfo.closeCursor(:csr);
		end;
	});
	my ($sth_csr, $rows);
	
	eval {
		$sth_open->bind_param_inout(":csr", \$sth_csr, 0, { ora_type => ORA_RSET });
		$sth_open->bind_param(":rpt_id", $rpt_id);
		$sth_open->execute;
		my $colnames = $sth_csr->{NAME};
		my $colwidths = $sth_csr->{PRECISION};
		
		#print join("|", @$colnames), "\n";
		#print join("|", @$colwidths), "\n";
		
		#$rows = $sth_csr->fetchall_arrayref;
		#assume the first column is ACCT_STRING
		$rows = $sth_csr->fetchall_hashref($colnames->[0]);
		#print Dumper($rows);
		$sth_close->bind_param(":csr", $sth_csr, { ora_type => ORA_RSET });
		$sth_close->execute();
		$sth_csr->finish();
		$sth_open->finish();
		$sth_close->finish();
        };
	if ($@) {
		my $e;
		$e = $@;
		$dbh->disconnect();
		croak "fetchEmails - Error: $e";
	}
	$invocant->email($rows) if ref($invocant);
	$rows;
}

# This method could be invoked by class or object.
#sub fetchAcctList
#{
#	my $invocant = shift;
#	my $class = ref($invocant) || $invocant;
#
#	my ($dbh, $id) = @_;
#
#	croak "fetchAcctList - Invalid database handle. " unless $dbh;
#
#	my ($rpt_sql_open, $rpt_sql_close, $sth_csr);
#	my ($rows);
#
#	my $rpt_id = $id || 'null';
#
#	$rpt_sql_open = qq{
#		begin
#			acct_report.init($rpt_id);
#			:csr := acct_report.fetchAcctStrings;
#		end;
#	};
#
#	$rpt_sql_close = qq{
#		begin
#			acct_report.closeReport(:csr);
#		end;
#	};
#	my $sth_open = $dbh->prepare($rpt_sql_open);
#	my $sth_close = $dbh->prepare($rpt_sql_close);
#
#	eval {
#		$sth_open->bind_param_inout(":csr", \$sth_csr, 0, { ora_type => ORA_RSET });
#		$sth_open->execute;
#
#		my $colnames_u = $sth_csr->{NAME};
#		my $coltypes_u = $sth_csr->{TYPE};
#		my $colwidths_u = $sth_csr->{PRECISION};
#
#		$rows = $sth_csr->fetchall_arrayref;
#
#		$sth_close->bind_param(":csr", $sth_csr, { ora_type => ORA_RSET });
#		$sth_close->execute();
#
#		$sth_csr->finish();
#		$sth_open->finish();
#		$sth_close->finish();
#	};
#	if ($@)
#	{
#		my $e = $@;
#		$dbh->disconnect();
#		croak "Error - $e\n";
#	}
#	[map { $_->[0] } @$rows];
#}

#sub fetchRptMeta
#{
#	my $invocant = shift;
#	my $class = ref($invocant) || $invocant;
#
#	my ($dbh, $id) = @_;
#
#	croak "fetchRptMeta - Invalid database handle. " unless $dbh;
#
#	$id	or { $id = $invocant->reportid } 
#		or $id = '(select max(ccreport_id) from ccreport.ccreport_logs';
#
#	my $query = qq{
#			select 
#				ccreport_id
#				,ts_old
#				,ts_new
#				,rpttype
#				,rptsubtype
#				,generated
#				,status
#			  from ccreport.ccreport_logs
#			 where ccreport_id = $id
#			order by ccreport_id
#		};
#	my $rows;
#
#	eval {
#		$rows = $dbh->selectall_arrayref($query);
#	};
#	if ($@) {
#		my $e = $@;
#		$dbh->disconnect();
#		croak "DBD Error - $e\n";
#	}
#	if(ref($invocant))
#	{
#		croak "fetchRptMeta - No data returned for report $id" unless $rows->[0];
#		my $report_info = {
#				ID	=> $rows->[0]->[0],
#				SINCE	=> $rows->[0]->[1],
#				UNTIL	=> $rows->[0]->[2],
#				TYPE	=> $rows->[0]->[3],
#				SUBTYPE	=> $rows->[0]->[4],
#				GENDATE	=> $rows->[0]->[5],
#				STATUS	=> $rows->[0]->[6],
#			};
#
#		$invocant->reportmeta($report_info);
#	}
#	$rows;
#}

# This should be done in fetchAcctString or fetchEmails for efficiency
# but make it seperate so that it is easier to test.
sub fetchProjNames
{
    my $self = shift;
    my ($dbh, $rpt_id) = @_;

    my $projnames = undef;

    $rpt_id or $rpt_id = $self->reportid;

	if($dbh && $rpt_id)
    {
    	my $query = qq{
    			select 
                        unique
                        p.pta           pta
                        ,p.proj_name    proj_name
    			  from hostdb.pta_status p
                        ,(  select
                                acct_string
                              from ccreport.host_conf_details_v
                             where report_log_id = :rpt_id
                            union
                            select
                                acct_string
                              from ccreport.who_conf_details_v
                             where report_log_id = :rpt_id
                        ) x
                 where p.pta=x.acct_string
    		};
    
    	eval {
            my $sth = $dbh->prepare($query);
            $sth->bind_param(":rpt_id", $rpt_id);
            $sth->execute;
            $projnames = $sth->fetchall_hashref('PTA');
            $sth->finish();
    	};
    
    	if ($@) {
    		my $e = $@;
    		$dbh->disconnect();
    		croak "DBD Error - $e\n";
    	}

    }
    $projnames;
}

sub fetchReport
{
	my $self = shift;
	#my ($dbh, $acct_str) = @_;
	# adhoc has the number of days , asof contains number of days relative to today.
	my ($dbh, $rpt_id, $adhoc, $asof) = @_;

	croak "fetchReport - Invalid database handle. " unless $dbh;

	my ($rpt_sql_open, $rpt_sql_close, $sth_csr);

	##need to check to see whether account is a ref to array.
	#unless($acct_str)
	#{
	#	if(defined($self->{acctstring}))
	#	{
	#		if(ref($self->{acctstring}))
	#		{
	#			croak "scalar or array ref expected for account." unless ref($self->{acctstring}) eq 'ARRAY';
	#			$acct_str = "'".join(",", @{$self->{acctstring}})."'";
	#		} else {
	#			$acct_str = "'".$self->{acctstring}."'";
	#		}
	#	} else {
	#		$acct_str = 'null';
	#	}
	#}
	
	#-------------------------------------------------------------
	# Could use bind variables here but to have one sql variable handle
	# both cases, leave them as is for now.
	#$rpt_id	or $rpt_id =  $self->reportid || undef;
	$rpt_id	or $rpt_id =  $self->reportid || 'null';

			#:csr := acct_status.getAcctstrC('X',sysdate+60);
	$rpt_sql_open = qq{
		begin
			:csr := ccreport.acctexp_rpt.getRptEntries($rpt_id);
		end;
	};

	$rpt_sql_close = qq{
		begin
			ccreport.acctexp_rpt.closeReport(:csr);
		end;
	};

	if(($rpt_id eq 'null') && defined($adhoc))
	{
		$asof = 0 unless(defined($asof));
		croak "fetchReport - Invalid integer for adhoc number of days. $adhoc "
			unless($adhoc =~ /\d+$/);
		croak "fetchReport - Invalid integer for asof number of days. $asof "
			unless($asof && $asof =~ /\d+$/);
		
		# adhoc should contain number of days
		$rpt_sql_open = qq{
			begin
				:csr := ccreport.acctexp_rpt.getAdhocExpEntries($adhoc, $asof);
			end;
		};
	}
	#-------------------------------------------------------------
			
	my $sth_open = $dbh->prepare($rpt_sql_open);
	my $sth_close = $dbh->prepare($rpt_sql_close);

	eval {
		$sth_open->bind_param_inout(":csr", \$sth_csr, 0, { ora_type => ORA_RSET });
		$sth_open->execute;

		#-------------------------------------------------------------
		# Users
		#-------------------------------------------------------------
		my $colnames_u = $sth_csr->{NAME};
		my $coltypes_u = $sth_csr->{TYPE};
		my $colwidths_u = $sth_csr->{PRECISION};

		# should this be moved into processRows?
		my %colwidths ;
		map { $colwidths{$colnames_u->[$_]}=$colwidths_u->[$_]; } @0..$#{$colnames_u};

		my $rows = $sth_csr->fetchall_arrayref;
		##my $rows = $sth_csr_u->fetchall_hashref([ 'ACCT_STRING', 'PRINC', 'CHANGE_FLAG' ]);
		my $xx = new CMUCS::Rams::Report::AcctExp::AcctExpEntity
				colnames	=> $colnames_u,
				rows		=> $rows
				;
		$self->{entities} = $xx;
		
		#-------------------------------------------------------------
		# Close cursors.
		#-------------------------------------------------------------

		$sth_close->bind_param(":csr", $sth_csr, { ora_type => ORA_RSET });
		$sth_close->execute();

		$sth_csr->finish();
		$sth_open->finish();
		$sth_close->finish();
	};
	if ($@)
	{
		my $e = $@;
		$dbh->disconnect();
		croak "Error - $e\n";
	}
	
	my @acctlist = (keys %{$self->{entities}->{rows}});
	my %seen = ();

	foreach my $acct (keys %{$self->{entities}->{rows}})
	{
		$seen{$acct}++;
	}
	$self->acctstring([keys %seen]);

    $self->projnames($self->fetchProjNames($dbh, $rpt_id));

	$self->acctstring;
}

sub getRptTimeRange
{
	my $self = shift;

	my $meta_data = $self->reportmeta;

	if($meta_data)
	{
		return ($meta_data->{SINCE}, $meta_data->{UNTIL});	
	} else {
		return undef;
	}
}

sub getSummary
{
	my $self = shift;
	my $failedlist = shift || ();

	my %summary;

	my $rows = $self->entities->rows;
	my %flags = ();
	map {$flags{$_} = 'FAILED'} (@$failedlist);
	my $flag = 'SUCCEEDED';

	foreach my $acct (keys %$rows)
	{
		if (defined($flags{$acct}))
		{
			$flag = 'FAILED';
		} else {
			$flag = 'SUCCEEDED';
		}
		$summary{$flag}->{$acct}->{'CHARGE'} = $rows->{$acct}->{'_SUMMARY_'}->{'CHARGE'};
		$summary{$flag}->{$acct}->{'USER'} = $rows->{$acct}->{'_SUMMARY_'}->{'U'};
		$summary{$flag}->{$acct}->{'MACHINE'} = $rows->{$acct}->{'_SUMMARY_'}->{'M'};
		$summary{$flag}->{$acct}->{'EXPDATE'} = $rows->{$acct}->{'_SUMMARY_'}->{'EXPDATE'};
		$summary{$flag}->{$acct}->{'EMAIL'} = $self->{'email'}->{$acct};
		$summary{$flag}->{$acct}->{'USERCOUNT'} = $rows->{$acct}->{'_SUMMARY_'}->{'UCOUNT'};
		$summary{$flag}->{$acct}->{'MACHINECOUNT'} = $rows->{$acct}->{'_SUMMARY_'}->{'MCOUNT'};
	}
	\%summary;
}

sub getSummaryStr
{
	my $self = shift;
	my $failedlist = shift || ();

	my $summary = $self->getSummary($failedlist);

	my $linesep = "\n";

	my %colpositions = (
			'1_ACCT' 	=> 1,
			'2_EXPDATE'	=> 26,
			'3_CHARGE'	=> 37,
			'4_UCOUNT'	=> 46,
			'5_MCOUNT'	=> 52,
			'6_EMAIL'	=> 60,
			);
	# field widths could be calculated by the position hash.
	#my $fieldformat = "%-24s %-10s %8s %s";
	my $fieldheaderformat = "%-24s %-10s %8s %6s %6s %s";
	my $fieldformat = "%-24s %-10s %8s %3s/%-2s %3s/%-2s %s";

	my $summary_string =	  '********************************************' . $linesep 
				. 'Notes: U(P/L) - User (Project/Labor)' . $linesep
				. '       M(P/U) - Machine (Project/follow primary User)' . $linesep
				. '********************************************' . $linesep ;
	my $mailto;
	foreach my $flag ('FAILED', 'SUCCEEDED')
	{
		if(defined($summary->{$flag}) && $summary->{$flag})
		{
			$summary_string .= 'Email Notification '.ucfirst(lc($flag)).': ' . "$linesep" x 2 .
				sprintf("$fieldheaderformat$linesep"
						,'OracleString'
						,'ExpDate'
						,'Charge'
						,'U(P/L)'
						,'M(P/U)'
						,'Emails'
					) .
					sprintf("$fieldheaderformat$linesep"
						,'-' x 24
						,'-' x 10
						,'-' x 8
						,'-' x 5
						,'-' x 5
						,'-' x 12
					);

			foreach my $acct (sort keys %{$summary->{$flag}})
			{
				$mailto = join("$linesep".' ' x $colpositions{'6_EMAIL'},
						map {
							if (/\"(.+)\" .*/)
							{	
								$1;
							} elsif (/\s+(.+)\s*/) {
								$1;
							} else {
								$_;
							}
						}
							(split ',', $summary->{$flag}->{$acct}->{'EMAIL'}->{'MAILTO'})
						)
						;
				$summary_string .= 
					sprintf("$fieldformat$linesep"
						,$acct
						,sprintf("%s", $summary->{$flag}->{$acct}->{'EXPDATE'})
						,sprintf("%4.02f", $summary->{$flag}->{$acct}->{'CHARGE'})
						,sprintf("%s", $summary->{$flag}->{$acct}->{'USERCOUNT'}->{'Hardcoded'})
						,sprintf("%s", $summary->{$flag}->{$acct}->{'USERCOUNT'}->{'Payroll'})
						,sprintf("%s", $summary->{$flag}->{$acct}->{'MACHINECOUNT'}->{'Hardcoded'})
						,sprintf("%s", $summary->{$flag}->{$acct}->{'MACHINECOUNT'}->{'FollowUser'})
						,sprintf("%s", $mailto)
						);
		
				if(defined($summary->{$flag}->{$acct}->{'EMAIL'}->{'MAILCC'}))
				{
					my $mailcc = 
						join("$linesep".' ' x $colpositions{'6_EMAIL'},
							map {
								if (/\"(.+)\" .*/)
								{	$1;
								} elsif (/\s+(.+)\s*/) {
									$1;
								} else {
									$_;
								}
							}
								(split ',', $summary->{$flag}->{$acct}->{'EMAIL'}->{'MAILCC'})
						);
					$summary_string .= sprintf("%s%s$linesep"
								,' ' x $colpositions{'6_EMAIL'}
								,sprintf("%s", $mailcc)
								);
				}
			}
			$summary_string .= "$linesep" x 2;
		} #unless
	} #foreach flag
	$summary_string;
}

sub rptPrint
{
	my $self = shift;
	my $acct = shift || $self->acctstring;
	#my $tmpl = shift || { SOURCE => 'ReportTmpl.txt' };

	my $tmpl = shift || $self->rpt_template || { TYPE => 'STRING', SOURCE => $rpt_template };
	my ($tmpl_u, $tmpl_m) = @_;

	croak "Report has to be fetched before printing." unless $acct;
	croak "account array ref expected in rptPrint." unless(ref($acct) && ref($acct) eq 'ARRAY');
	croak "template parameter requires hash reference." unless(ref($tmpl) eq 'HASH');

	my $template = Text::Template->new( %$tmpl )
                        or croak "Couldn't construct template: $Text::Template::ERROR";

	my $result = '';
	foreach my $a (@$acct)
	{
		my $u = $self->entities->stringify($a);

        my $proj_name = '';
        if (defined($self->projnames) && defined($self->projnames->{$a}) )
        {
            $proj_name = $self->projnames->{$a}->{'PROJ_NAME'} || '';
        }

		# escape the objects in the fill in hash.
		my $r = $template->fill_in(HASH => {
							header	=> $self->header,
							account	=> \$a,
						    proj_name	=> \$proj_name,
							entities	=> \$u,
							footer	=> '',
						}
					);
        	$r || croak "$a - Couldn't fill in template: $Text::Template::ERROR.";
		$result .= $r;
	}
	$result;
}

sub rptMailBody
{
	my $self = shift;
	my $acct = shift || $self->acctstring;
	my $mailtmpl = shift || $self->mail_template; 
	my $msg = shift;

	my $content = $self->rptPrint([$acct]);

	unless($content)
        {
		print STDERR "Report is empty. No email notification for $acct ...\n";
		Utils::mylog(1, undef
			, "Report is empty. No email notification for $acct ...\n");

		return undef;
	}

	my $rpt_id = $self->reportid;
	my $template = Text::Template->new( %$mailtmpl )
		or croak "Couldn't construct template: $Text::Template::ERROR"
			.Data::Dumper->Dump([$self], ['rpt_obj']);

	my $a = 0;
	my ($reason, $expdate, $daycount) = ('Unknown', 'today', 0);

	if(defined($self->entities->rows->{$acct})
		&& defined($self->entities->rows->{$acct}->{'_SUMMARY_'}))
	{
		$a = $self->entities->rows->{$acct}->{'_SUMMARY_'}->{'CHARGE'} || 0;

		$reason = $self->entities->rows->{$acct}->{'_SUMMARY_'}->{'REASON'}
			if(defined($self->entities->rows->{$acct}->{'_SUMMARY_'}->{'REASON'}));

		$expdate = $self->entities->rows->{$acct}->{'_SUMMARY_'}->{'EXPDATE'} 
			if(defined($self->entities->rows->{$acct}->{'_SUMMARY_'}->{'EXPDATE'}));

		$daycount = $self->entities->rows->{$acct}->{'_SUMMARY_'}->{'DAYCOUNT'} 
			if(defined($self->entities->rows->{$acct}->{'_SUMMARY_'}->{'DAYCOUNT'}));
	}

	my $amt = Utils::commify(sprintf("%.02f",$a));
	Utils::mylog(3, undef, "Net Change for $acct is $amt");

	if (defined($self->email->{$acct}))
	{
		$msg or $msg = $self->email->{$acct}->{'MSG'};
	}
    my $proj_name = '';
    if (defined($self->projnames) && defined($self->projnames->{$acct}) )
    {
        $proj_name = $self->projnames->{$acct}->{'PROJ_NAME'} || '';
    }

	my $r = $template->fill_in(HASH => {
						reportid	=> \$rpt_id,
						account		=> \$acct,
						proj_name	=> \$proj_name,
						amount		=> \$amt,
						report		=> \$content,
						reason		=> \$reason,
						expdate		=> \$expdate,
						daycount	=> \$daycount,
						rpt_mgr_msg	=> \$msg,
						#timesince	=> \$t_1,
						#timeuntil	=> \$t_2,
						}
			);
	
	unless($r)
	{
		Utils::mylog(1, undef, "$acct - Couldn't fill in template: $Text::Template::ERROR.\n".Data::Dumper->Dump([$self],['rpt_obj'])."\n");
	}
	$r;

}

sub dbRecordRpt
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	#
	# Should type (flag) and subtype be made more restrictive here?
	#
	my ($dbh) = @_;
	#my ($ts_from_q, $ts_to_q, $rpt_flag_q, $rpt_subtype_q, $ts_format_str_q);

	croak "dbRecordRpt - Invalid database handle. " unless $dbh;

	my ($rpt_sql, $rpt_id, $rowcount);

	$rpt_sql = qq{
		declare
			l_id	pls_integer;
		begin
			l_id := ccreport.acctexp_rpt.new;
			:rptid := l_id;
			:rtn := ccreport.acctexp_rpt.record(l_id);
		end;
		};
	
	my $sth = $dbh->prepare($rpt_sql);

	eval {
		#$dbh->do($rpt_sql);	
		$sth->bind_param_inout(":rptid", \$rpt_id, 0);
		$sth->bind_param_inout(":rtn", \$rowcount, 0);
		$sth->execute;
		$sth->finish;

		#
		# WARNING: The side effect of the following line is that 
		# all previous operations will be commited.
		#
		$dbh->commit;
	};

	if ($@) {
		my $e = $@;
		#$dbh->rollback();
		$dbh->disconnect();
		croak "DBD Error - $e\n";
	}

	$invocant->reportid($rpt_id) if ref($invocant);
	$rpt_id;
}

sub dbListRpt
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my ($dbh, $num) = @_;
	$num or $num = 0;

	croak "dbListRpt - Invalid database handle. " unless $dbh;

	my $query = qq{
			select 
				id
				,generate_date
				,status
			  from ccreport.acctexp_logs
			 where id >= (select max(id)-$num from ccreport.acctexp_logs)
			order by id
		};
	my $rows;

	eval {
		$rows = $dbh->selectall_arrayref($query);
	};

	if ($@) {
		my $e = $@;
		$dbh->disconnect();
		croak "DBD Error - $e\n";
	}

	$rows;
}

sub dbListRpt_str
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my ($dbh, $num) = @_;

	my $result = '';
	my %fields = (
			0	=> 'ID',
			1	=> 'Record Date',
			2	=> 'Status',
			);
	my %lengths = (
			0	=> 9,
			1	=> 18,
			2	=> 6,
			);
	my $fmt_str = "%9s %18s %6s\n";

	my $rows = $class->dbListRpt($dbh, $num);

	my $cnt = (keys %fields);
	$result .= sprintf $fmt_str,
			map $fields{$_}, (0..$cnt-1);

			#'ID', 'TS_PREV', 'TS_CURR', 'Flag', 'Type', 'Gen date';

	$result .= sprintf join(' ', map {'-'x$lengths{$_}} (0..$cnt-1))."\n";

	while(my $row=shift(@$rows))
	{
		$result .= sprintf $fmt_str,
			map {substr($row->[$_], 0, $lengths{$_})} (0..$cnt-1); 
	}
	$result;
}

sub AUTOLOAD {
	my $self = shift;
	my $attr = our $AUTOLOAD;

	$attr =~ s/.*:://;
	return if $attr eq 'DESTROY';   
	
	croak "invalid attribute method: ->$attr()" 
		unless exists $self->{$attr};

	my $val = $self->{$attr};
	$self->{$attr} = shift if @_;
	#print "ChargeChange::$attr called\n";
	return $val;

	# do not need to consider base class here.
	#
	#if ($ok_field{$attr}) {
	#	$self->{$attr} = shift if @_;
	#	return $self->{$attr};
	#} else {
	#	my $superior = "SUPER::$attr";
	#	$self->$superior(@_);
	#} 
}

1;

__END__


=head1 NAME

CMUCS::Rams::Report::ChargeChange - Perl extension for blah blah blah

=head1 SYNOPSIS

  use CMUCS::Rams::Report::ChargeChange;
  blah blah blah

=head1 DESCRIPTION

	Stub documentation for CMUCS::Rams::Report::ChargeChange

=head2 EXPORT

	None by default.


=head1 AUTHOR

	Longjiang Yang, E<lt>yangl@cs.cmu.eduE<gt>

=head1 SEE ALSO

L<perl>.

=cut
