#!/usr/local/bin/perl5 -w
# $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/schema/t/rptTest.pl,v 1.1 2006/01/11 19:22:57 yangl Exp $
#

use strict;
use lib '/usr/local/lib/perl5/site_perl/5.6.1/arch/auto';
use DBI;
use Getopt::Long;

use DBD::Oracle qw(:ora_types);

BEGIN {
	$ENV{ORACLE_HOME} = '/usr1/app/oracle/product/9.2' unless $ENV{ORACLE_HOME};
	#$ENV{ORACLE_SID} = 'fac_03' unless $ENV{ORACLE_SID};
	$ENV{TWO_TASK} = 'fac_03.apogee' unless $ENV{TWO_TASK};
}

my $dbh;

sub ora_connect($)
{
	#my ($conn,$attr) = @_;
	my ($conn) = @_;
	
	my %ora_attr = (
			AutoCommit	=> 0,
			PrintError	=> 0,
			RaiseError	=> 0,
			);
			#$attr
	my $data_source = 'DBI:Oracle:';

	my $dbh = DBI->connect($data_source, $conn, "", \%ora_attr) 
		or die "Unable to connect to DB $data_source and $conn \n", $DBI::errstr, "\n";
	# turn on either one.
	$dbh->{RaiseError} = 1;
	#$dbh->{PrintError} = 1;
	
	$dbh;
}


sub entityChanged_t
{
	my $sth = $dbh->prepare(qq{
	begin 
		--entityChanged.rptRecordNew;
		entityChanged.rptRecordNew(to_date('01-DEC-05'), to_date('03-DEC-05'));
	end;
	});
	
	$sth->execute;
}

sub report_t($)
{
	my ($dbh) = @_;
			#:csr := acct_report.fetchUserReport('9100-1-1010309');
			#:csr := acct_report.fetchAcctStrings;
	my $sth_open = $dbh->prepare(q{
		begin
			acct_report.init(3);
			:csr := acct_report.fetchUserReport('9100-1-1010309');
			:csr_m := acct_report.fetchMachineReport('9100-1-1010309');
		end;
	});
	my $sth_close = $dbh->prepare(q{
		begin
			acct_report.closeReport(:csr);
			acct_report.closeReport(:csr_m);
		end;
	});
	my ($sth_csr, $sth_csr_m);

	eval {
		#$sth_open->execute();
		#$sth_open->finish();
		#my $sth2 = $dbh->prepare(q{
		#	begin
		#		:csr := acct_report.fetchUserReport('9100-1-1010309');
		#	end;
		#});
		$sth_open->bind_param_inout(":csr", \$sth_csr, 0, { ora_type => ORA_RSET });
		$sth_open->bind_param_inout(":csr_m", \$sth_csr_m, 0, { ora_type => ORA_RSET });
		$sth_open->execute;
		while( my @row = $sth_csr->fetchrow_array )
		{
			print join("|",@row),"\n";
		}
		while( my @row = $sth_csr_m->fetchrow_array )
		{
			print join("|",@row),"\n";
		}
		#$sth_csr->dump_results;
		#print "completed\n";
		$sth_close->bind_param(":csr", $sth_csr, { ora_type => ORA_RSET });
		$sth_close->bind_param(":csr_m", $sth_csr_m, { ora_type => ORA_RSET });
		$sth_close->execute();
		$sth_csr->finish();
		$sth_csr_m->finish();
		$sth_open->finish();
		$sth_close->finish();
	}; 
	if ($@) {
		my $e = $@;
		$dbh->disconnect();
		die "Error - $e\n";
	}
}

sub foo_t
{
	my $sth_open = $dbh->prepare(q{
		begin
			open :csr for select 'test', id, funding, function, activity, org, entity from hostdb.accounts where id=52335;
		end;
	});
	my $sth_csr;

	eval {
		$sth_open->bind_param_inout(":csr", \$sth_csr, 0, { ora_type => ORA_RSET });
		$sth_open->execute();
		while( my @row = $sth_csr->fetchrow_array )
		{
			print join("|",@row),"\n";
		}
		#print "completed\n";
	};
	if ($@) {
		my $e;
		$e = $@;
		$dbh->disconnect();
		die "Error - $e\n";
	}
}

my $debug = 0;

GetOptions("d=s" => \$debug) or die "Usage: $0 [-d <number>] \n";
if ($debug > 0)
{
	DBI->trace($debug);
}
$dbh = ora_connect('ccreport/ccreport');
report_t($dbh);
#foo_t;
$dbh->disconnect();

1;

__END__
			#	open :csr for select unique  acct_string     
			#			,princ  
			#			,name   
			#			,change_flag    
			#			,case when count(unique change_flag) over (partition by princ, acct_string, report_log_id) > 1 then             
			#				'Changed'       
			#			else            
			#				case when change_flag='Old' then                        
			#					'Deleted'               
			#				else                    
			#					'Added'                 
			#				end     
			#			end Reason      
			#			,report_log_id   
			#			,to_char(LastChanged, 'MON-DD-YYYY') LastChanged
			#			,charge_by              
			#			,sponsor        
			#			,PctUser        
			#			,service_vec    
			#			,pct
			#			,ChargeAmount
			#			,round(ChargeAmount*pct/100 , 2)
			#		  from (                 
			#			select                  
			#				acct_string                     
			#				,princ                  
			#				,name                   
			#				,change_flag                    
			#				,count(unique change_flag) over (partition by report_log_id, princ, name, acct_string, charge_by, sponsor, PctUser, service_vec, pct, ChargeAmount) cnt                         
			#				,charge_by                              
			#				,sponsor                        
			#				,PctUser                        
			#				,service_vec                    
			#				,pct                    
			#				,ChargeAmount                   
			#				,LastChanged                    
			#				,report_log_id            
			#			  from who_conf_details_v                
			#			 where                  
			#				report_log_id=3
			#			   and acct_string in ('9100-1-1010309')        
			#			) x  
			#		 where x.cnt<2 
			#		order by acct_string, Reason, princ, change_flag
			#		;
