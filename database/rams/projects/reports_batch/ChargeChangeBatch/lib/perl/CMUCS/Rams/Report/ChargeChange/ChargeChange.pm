# $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/lib/perl/CMUCS/Rams/Report/ChargeChange/ChargeChange.pm,v 1.24 2007/08/06 14:45:41 costing Exp $
#
package CMUCS::Rams::Report::ChargeChange::ChargeChange;

use 5.006;
use strict;
use Carp;
#use FileHandle;
use Data::Dumper;
use Text::Template;

use DBI;
use DBD::Oracle qw(:ora_types);

use CMUCS::Rams::Report::Utils::Utils;

#use CMUCS::Rams::Report::ChargeChange::Entity;
#use CMUCS::Rams::Report::ChargeChange::Machines;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our $VERSION = '0.01';


#my ($coltitlewidth1, $row_width) = (24, 80);
#---------------------------------------------------
my $rpt_template = q!
{$header} for {$account || ''}
{$user}
{$machine}
{$footer}
!;

my $mail_template = q!

Account      {$account}
Net change   {sprintf "\$ %.02f", $amount}

Dear Customer,

Service Charges to the above account were affected due to changes
made to the following user(s)/machines(s) since <date>.

Please respond to help+@costing.cs.cmu.edu within 30 days
if any of the changes are not valid.

Please refer to the SCS Facilities charging policy, <link>,
for general information.

Thanks,
Help Desk
SCS Facilities

We recommend using "Courier New" font to view the report.

{sprintf('-'x80)}
Internal ID: {$reportid}
Account    : {$account}
{$report}
!;

sub numerically { $a <=> $b }

#my $ora_quote = sub
#{
#	my $invocant = shift;
#
#	my $dbh = shift;
#	my $val = shift;
#	
#	$dbh->quote($val);
#};

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
			users		=> undef,
			machines	=> undef,
			header		=> 'Service Charge Change',
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

	my ($dbh, $id, $asof) = @_;
	croak "fetchEmails - Invalid database handle. " unless $dbh;

	my $rpt_id;
	if(ref($invocant))
	{
		$rpt_id = $id || $invocant->reportid || undef;
	} else {
		$rpt_id = $id || undef;
	}

			#acct_report.init($rpt_id);
	my $sth_open = $dbh->prepare(qq{
		begin
			ccreport.acct_report.init(:rpt_id);
			:csr := ccreport.acct_report.fetchEmailInfo;
			--:csr := ccreport.acct_report.fetchEmailInfo(:asof);
		end;
	});
	my $sth_close = $dbh->prepare(q{
		begin
			ccreport.acct_report.closeReport(:csr);
		end;
	});
	my ($sth_csr, $rows);
	
	eval {
		$sth_open->bind_param(":rpt_id", $rpt_id);
		# ora_type 12 (ORA_DATE) is not supported by current version of DBD
		#$sth_open->bind_param(":asof", $asof, { ora_type => ORA_DATE });
		#$sth_open->bind_param(":asof", $asof, { ora_type => ORA_DATE });
		$sth_open->bind_param_inout(":csr", \$sth_csr, 0, { ora_type => ORA_RSET });
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
		$dbh && $dbh->disconnect();
		croak "fetchEmails - Error while fetching emails. $e";
	}
	$invocant->email($rows) if ref($invocant);
	$rows;
}

# This method could be invoked by class or object.
sub fetchAcctList
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my ($dbh, $id) = @_;

	croak "fetchAcctList - Invalid database handle. " unless $dbh;

	my ($rpt_sql_open, $rpt_sql_close, $sth_csr);
	my ($rows);

	my $rpt_id = $id || undef;

	$rpt_sql_open = qq{
		begin
			ccreport.acct_report.init(:rpt_id);
			:csr := ccreport.acct_report.fetchAcctStrings;
		end;
	};

	$rpt_sql_close = qq{
		begin
			ccreport.acct_report.closeReport(:csr);
		end;
	};
	my $sth_open = $dbh->prepare($rpt_sql_open);
	my $sth_close = $dbh->prepare($rpt_sql_close);

	eval {
		$sth_open->bind_param(":rpt_id", $rpt_id);
		$sth_open->bind_param_inout(":csr", \$sth_csr, 0, { ora_type => ORA_RSET });
		$sth_open->execute;

		my $colnames_u = $sth_csr->{NAME};
		my $coltypes_u = $sth_csr->{TYPE};
		my $colwidths_u = $sth_csr->{PRECISION};

		$rows = $sth_csr->fetchall_arrayref;

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
	[map { $_->[0] } @$rows];
}

sub fetchRptMeta
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my ($dbh, $id) = @_;

	croak "fetchRptMeta - Invalid database handle. " unless $dbh;

	$id	or { $id = $invocant->reportid } 
		or $id = '(select max(ccreport_id) from ccreport.ccreport_logs';

	my $query = qq{
			select 
				ccreport_id
				,ts_old
				,ts_new
				,rpttype
				,rptsubtype
				,generated
				,status
			  from ccreport.ccreport_logs
			 where ccreport_id = $id
			order by ccreport_id
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
	if(ref($invocant))
	{
		croak "fetchRptMeta - No data returned for report $id" unless $rows->[0];
		my $report_info = {
				ID	=> $rows->[0]->[0],
				SINCE	=> $rows->[0]->[1],
				UNTIL	=> $rows->[0]->[2],
				TYPE	=> $rows->[0]->[3],
				SUBTYPE	=> $rows->[0]->[4],
				GENDATE	=> $rows->[0]->[5],
				STATUS	=> $rows->[0]->[6],
			};

		$invocant->reportmeta($report_info);
	}
	$rows;
}

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
	my ($dbh, $id) = @_;

	croak "fetchReport - Invalid database handle. " unless $dbh;

	#my $rpt_id = $id || $self->reportid || 'null';
	#my $rpt_id = $id || $self->reportid || 0;
	my $rpt_id = $id || $self->reportid || undef;
	my $acct_str;

	#if (($rpt_id ne 'null') && ($rpt_id <= 0))
	if ((!defined($rpt_id)) && ($rpt_id <= 0))
	{
		print "There is no change entries in this report.\n";
		return undef;
	}
	my ($rpt_sql_open, $rpt_sql_close, $sth_csr_u, $sth_csr_m);
	#my ($user_rows, $user_colnames, $machine_rows, $machine_colnames);

	##need to check to see whether account is a ref to array.
	if(defined($self->{acctstring}))
	{
		if(ref($self->{acctstring}))
		{
			croak "scalar or array ref expected for account." unless ref($self->{acctstring}) eq 'ARRAY';
			$acct_str = "'".join(",", @{$self->{acctstring}})."'";
		} else {
			$acct_str = "'".$self->{acctstring}."'";
		}
	} else {
		$acct_str = 'null';
	}
	
	#-------------------------------------------------------------
	$rpt_sql_open = qq{
		begin
			ccreport.acct_report.init(:rpt_id);
			:csr_u := ccreport.acct_report.fetchUserReport($acct_str);
			:csr_m := ccreport.acct_report.fetchMachineReport($acct_str);
		end;
	};

	$rpt_sql_close = qq{
		begin
			ccreport.acct_report.closeReport(:csr_u);
			ccreport.acct_report.closeReport(:csr_m);
		end;
	};
	#-------------------------------------------------------------
			
	my $sth_open = $dbh->prepare($rpt_sql_open);
	my $sth_close = $dbh->prepare($rpt_sql_close);

	eval {
		#my ($sth_csr_u, $sth_csr_m);

		$sth_open->bind_param(":rpt_id", $rpt_id);
		#$sth_open->bind_param(":acct_str_u", \$acct_str);
		#$sth_open->bind_param(":acct_str_m", \$acct_str);
		$sth_open->bind_param_inout(":csr_u", \$sth_csr_u, 0, { ora_type => ORA_RSET });
		$sth_open->bind_param_inout(":csr_m", \$sth_csr_m, 0, { ora_type => ORA_RSET });
		$sth_open->execute;

		#-------------------------------------------------------------
		# Users
		#-------------------------------------------------------------
		my $colnames_u = $sth_csr_u->{NAME};
		my $coltypes_u = $sth_csr_u->{TYPE};
		my $colwidths_u = $sth_csr_u->{PRECISION};

		# should this be moved into processRows?
		my %colwidths_u ;
		map { $colwidths_u{$colnames_u->[$_]}=$colwidths_u->[$_]; } @0..$#{$colnames_u};

		my $rows = $sth_csr_u->fetchall_arrayref;
		#my $rows = $sth_csr_u->fetchall_hashref([ 'ACCT_STRING', 'PRINC', 'CHANGE_FLAG' ]);
		my $xx = new CMUCS::Rams::Report::ChargeChange::Users
				colnames	=> $colnames_u,
				rows		=> $rows
				;
		$self->{users} = $xx;
		#my $yy = $xx->stringify_byacct('8928-1-1120295');
		
		#-------------------------------------------------------------
		# Machines
		#-------------------------------------------------------------
		my $colnames_m = $sth_csr_m->{NAME};
		my $coltypes_m = $sth_csr_m->{TYPE};
		my $colwidths_m = $sth_csr_m->{PRECISION};

		my %colwidths_m ;
		map { $colwidths_m{$colnames_m->[$_]}=$colwidths_m->[$_] } @0..$#{$colnames_m};

		$rows = $sth_csr_m->fetchall_arrayref;

		#$xx = new CMUCS::Rams::Report::ChargeChange::Machines
		$self->{machines} = new CMUCS::Rams::Report::ChargeChange::Machines
				colnames	=> $colnames_m,
				rows		=> $rows
				;
		#-------------------------------------------------------------
		# Close cursors.
		#-------------------------------------------------------------

		$sth_close->bind_param(":csr_u", $sth_csr_u, { ora_type => ORA_RSET });
		$sth_close->bind_param(":csr_m", $sth_csr_m, { ora_type => ORA_RSET });
		$sth_close->execute();

		$sth_csr_u->finish();
		$sth_csr_m->finish();
		$sth_open->finish();
		$sth_close->finish();
	};
	if ($@)
	{
		my $e = $@;
		$dbh->disconnect();
		croak "Error - $e\n";
	}
	
	$self->fetchRptMeta($dbh, $rpt_id);

	$self->reportid($rpt_id);

	my @acctlist = (keys %{$self->{users}->{rows}}, keys %{$self->{machines}->{rows}});
	my %seen = ();

	foreach my $acct (keys %{$self->{users}->{rows}}, keys %{$self->{machines}->{rows}})
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
# 
# columnindex = { 'princ' => 0, 'col_name2' => 1, ...};
# rows	= {
#		'000001-000-000-260007-01' => [ [ [ 'ccamacho', 'Carlos Camacho', 'New', 'Added', 'L', 'zivbj', '3.5', 'AFS,D-L,D-S,G,P,TPI', '100', '3.19', '3.19', '01-DEC-2005 041229 PM', '3' ],
#
#	}
#
#sub processRows
#{
#	my $self = shift;
#	my ($colnames, $rows) = @_;
#
#	my $entries = {};
#
#	croak "array ref expected for processRows while got ."||ref($rows) unless ref($rows) eq 'ARRAY';
#
#	return (undef, undef) if (scalar(@$rows) < 1);
#
#	croak "AoA is expected in processRows." unless ref($rows->[0]) eq 'ARRAY';
#
#	push @$rows, ['fake-acct-string','null','null'];
#
#	my %columnindex;
#	my $cntr = 0;
#	shift @$colnames;
#	while(my $col = shift(@$colnames))
#	{
#		#$columnindex{$cntr++} = $col;
#		$columnindex{$col} = $cntr++ ;
#	}
#
#	my $all_acct_rows = {};
#
#	my $acct = $rows->[0][0];
#	#my $acct_rows = [];
#	my @acct_rows ;
#
#	foreach my $row (@$rows)
#	{
#		my $acct_new = $row->[0];
#		
#		if ($acct eq $acct_new)
#		{
#			shift @$row;
#			#push @acct_rows, [@$row];
#			push @acct_rows, $row;
#			#push $entries->{$acct};
#		} else
#		{
#			$all_acct_rows->{$acct} = [@acct_rows];
#
#			$acct = $acct_new;
#			@acct_rows = ();
#			shift @$row;
#			#$acct_rows = [[@$row]];
#			push @acct_rows, $row;
#		}
#	}
#
#	return (\%columnindex, $all_acct_rows);
#}

sub rptPrint
{
	my $self = shift;
	my $acct = shift || $self->acctstring;
	#my $tmpl = shift || { SOURCE => 'ReportTmpl.txt' };

	my $tmpl = shift || $self->rpt_template || { TYPE => 'STRING', SOURCE => $rpt_template };
	# To change the templates for User/Machine
	# Call setters.
	#my ($tmpl_u, $tmpl_m) = @_;

	croak "Report has to be fetched before printing." unless $acct;
	croak "account array ref expected in rptPrint." unless(ref($acct) && ref($acct) eq 'ARRAY');
	croak "template parameter for mail requires hash reference." unless(ref($tmpl) eq 'HASH');
	#croak "template parameter for user requires hash reference."
	#	unless( $tmpl_u && (ref($tmpl_u) eq 'HASH') );
	#croak "template parameter machine requires hash reference."
	#	unless( $tmpl_u && (ref($tmpl_m) eq 'HASH') );

	my $template = Text::Template->new( %$tmpl )
                        or croak "Couldn't construct template: $Text::Template::ERROR";

	my $result = '';
	foreach my $a (@$acct)
	{
		my $u = $self->users->stringify($a);
		my $m = $self->machines->stringify($a);
		#my $m = '';
			#$self->machines->stringify_byacct($a);

        my $proj_name = '';

        if (defined($self->projnames) && defined($self->projnames->{$a}) )
        {
            $proj_name = $self->projnames->{$a}->{'PROJ_NAME'} || '';
        }

		# escape the objects in the fill in hash.
		my $r = $template->fill_in(HASH => {
							header	=> $self->header,
							account	=> \$a,
                            proj_name   => \$proj_name,
							user	=> \$u,
							machine => \$m,
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
	my ($t_since, $t_until) = $self->getRptTimeRange;
	$t_since or $t_since = 'Unknown';
	$t_until or $t_until = 'Unknown';

	my $t_1 = substr($t_since, 0, 9);
	my $t_2 = substr($t_until, 0, 9);

	my $template = Text::Template->new( %$mailtmpl )
		or croak "Couldn't construct template: $Text::Template::ERROR";

	my $amt_u = $self->users->rows->{$acct}->{'_SUMMARY_'}->{'CHARGE'} || 0;
	my $amt_m = $self->machines->rows->{$acct}->{'_SUMMARY_'}->{'CHARGE'} || 0;
	my $a = $amt_u + $amt_m;
	#my $amt = Utils::commify(sprintf("%.02f",abs($a)));
	my $amt = Utils::commify(sprintf("%.02f",$a));
    my $proj_name = '';

    if (defined($self->projnames) && defined($self->projnames->{$acct}) )
    {
        $proj_name = $self->projnames->{$acct}->{'PROJ_NAME'} || '';
    }

	if (defined($self->email->{$acct}))
	{
		$msg or $msg = $self->email->{$acct}->{'MSG'};
	}

	my $r = $template->fill_in(HASH => {
						reportid	=> \$rpt_id,
						account		=> \$acct,
                        proj_name   => \$proj_name,
						amount		=> \$a,
						amount_str	=> \$amt,
						report		=> \$content,
						timesince	=> \$t_1,
						timeuntil	=> \$t_2,
						rpt_mgr_msg	=> \$msg,
						}
			);
	unless($r)
	{
		Utils::mylog(1, undef, "$acct - Couldn't fill in template: $Text::Template::ERROR.\n".Data::Dumper->Dump([$self],['report'])."\n");
	}
	$r;
}

#
# This is a class/static method
# return report id
#
sub dbRecordRegularRpt
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my ($type_regular, $subtype_regular) = ('R', 'W');

	my ($dbh, $ts_from, $ts_to, $rpt_subtype, $ts_format_str) = @_;

	$rpt_subtype or $rpt_subtype = $subtype_regular;

	croak "Unknown report subtype $rpt_subtype." 
			unless($rpt_subtype eq 'W' || $rpt_subtype eq 'L');

	$invocant->dbRecordRpt($dbh, $ts_from, $ts_to, $type_regular, $rpt_subtype, $ts_format_str);
}

sub dbRecordAdhocRpt
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my ($dbh, $ts_from, $ts_to, $ts_format_str) = @_;

	my ($type_adhoc, $subtype_adhoc) = ('A', 'N');

	$invocant->dbRecordRpt($dbh
				, $ts_from
				, $ts_to
				, $type_adhoc
				, $subtype_adhoc
				, $ts_format_str
			);
}

sub dbReRecordRpt
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my ($dbh, $rpt_id) = @_;

	croak "dbReRecordRpt - Invalid database handle. " unless $dbh;
	croak "dbReRecordRpt - Invalid Report ID. " unless $rpt_id;

	my $rpt_sql = qq{
		begin
			:rtn := ccreport.EntityChanged.rptRecord(true, $rpt_id);
		end;
		};

	my $sth = $dbh->prepare($rpt_sql);
	my $cnt;

	eval {
		$sth->bind_param_inout(":rtn", \$cnt, 0);
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
		$dbh->disconnect();
		croak "DBD Error - $e\n";
	}
	$cnt;
}
#
# Make it private?
#my $dbRecordRpt = 
#
sub dbRecordRpt
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	#
	# Should type (flag) and subtype be made more restrictive here?
	#
	my ($dbh, $ts_from, $ts_to, $rpt_flag, $rpt_subtype, $ts_format_str) = @_;
	my ($ts_from_q, $ts_to_q, $rpt_flag_q, $rpt_subtype_q, $ts_format_str_q);

	croak "dbRecordRpt - Invalid database handle. " unless $dbh;

	$rpt_flag_q	= $dbh->quote($rpt_flag);
	$rpt_subtype_q	= $dbh->quote($rpt_subtype);

	#$rpt_flag = 'null' unless $rpt_flag;
	#$rpt_subtype = 'null' unless $rpt_subtype;

	my ($rpt_sql, $rpt_id);
	#my $ts_format = "'".'DD-MON-YYYY HH24.MI.SS'."'";

	if($ts_format_str)
	{
		$ts_format_str_q = $dbh->quote($ts_format_str);
	} else {
		$ts_format_str_q = $dbh->quote("DD-MON-YYYY HH24.MI.SS");
	}

	if (!defined($ts_from) && !defined($ts_to))
	{
		$rpt_sql = qq{
			begin
				:rtn := ccreport.EntityChanged.rptRecordNew($rpt_subtype_q);
			end;
			};
	} else {
		#croak "from and to time have to be both defined." if (!defined($ts_from) || !defined($ts_to));
		
		#if($ts_from)
		#{
		#	$ts_from = "'".$ts_from."'";
		#} else {
		#	$ts_from = 'null';
		#}
		#if($ts_from)
		#{
		#	$ts_to = "'".$ts_to."'";
		#} else {
		#	$ts_to = 'null';
		#}

		$ts_from_q	= $dbh->quote($ts_from);
		$ts_to_q	= $dbh->quote($ts_to);

		$rpt_sql = qq{
			begin
				:rtn := ccreport.EntityChanged.rptRecordNew(to_timestamp($ts_from_q, $ts_format_str_q), to_timestamp($ts_to_q, $ts_format_str_q), $rpt_flag_q, $rpt_subtype_q);
			end;
			};
	}
	
	my $sth = $dbh->prepare($rpt_sql);

	eval {
		#$dbh->do($rpt_sql);	
		$sth->bind_param_inout(":rtn", \$rpt_id, 0);
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
				ccreport_id
				,ts_old
				,ts_new
				,rpttype
				,rptsubtype
				,generated
				,status
			  from ccreport.ccreport_logs
			 where ccreport_id >= (select max(ccreport_id)-$num from ccreport.ccreport_logs)
			order by ccreport_id
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
	#$num or $num = 0;

	my $result = '';
	my %fields = (
			0	=> 'ID',
			1	=> 'TS_PREV',
			2	=> 'TS_CURR',
			3	=> 'Flag',
			4	=> 'Type',
			5	=> 'Record Date',
			);
	my %lengths = (
			0	=> 9,
			1	=> 18,
			2	=> 18,
			3	=> 4,
			4	=> 7,
			5	=> 12,
			);
	my $fmt_str = "%9s %18s %18s %4s %7s %12s\n";

	my $rows = $class->dbListRpt($dbh, $num);

	$result .= sprintf $fmt_str,
			map $fields{$_}, (0..5);

			#'ID', 'TS_PREV', 'TS_CURR', 'Flag', 'Type', 'Gen date';

	$result .= sprintf join(' ', map {'-'x$lengths{$_}} (0..5))."\n";

	while(my $row=shift(@$rows))
	{
		$result .= sprintf $fmt_str,
			map {substr($row->[$_], 0, $lengths{$_})} (0..5); 
	}
	$result;
}

sub hasEntries
{
	my $self = shift;

	my ($acct) = @_;
	my $cnt = 0;

	croak "ChargeChange::hasEntries:account string has to be specified.\n"
		unless $acct;

	$cnt = 1 if( 
			( $self->users && $self->users->hasEntries($acct) )
			|| ( $self->machines && $self->machines->hasEntries($acct) )
		);

	#$cnt = 1 if( defined($self->rows->{$acct}->{'M'}) 
	#		|| defined($self->rows->{$acct}->{'U'})
	#	);
	#print "*****$acct count=$cnt\n".Dumper($self->rows->{$acct});
	$cnt;
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
