# $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/lib/perl/CMUCS/Rams/Report/AcctExp/AcctExpConfig.pm,v 1.1 2006/04/24 20:35:57 yangl Exp $
#
package CMUCS::Rams::Report::AcctExp::AcctExpConfig;

use 5.006;
use strict;
use Carp;
#use Data::Dumper;
#use Text::Template;

use DBI;
use DBD::Oracle qw(:ora_types);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our $VERSION = '0.01';


#---------------------------------------------------
#my $rpt_template = q!
#{$header} for {$account || ''}
#{$entities}
#{$footer}
#!;
#
#my $mail_template = q!
#!;
#
#sub numerically { $a <=> $b }
#
#---------------------------------------------------

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

			#acctstring	=> [],
	my $self = bless {
			ID		=> undef,
			DateCount	=> undef,
			MonthendFlag	=> undef,
			EffectiveDate	=> undef,
			@_,
		}, $class;

	return $self;
}

sub updateEffectDate
{
	croak "updateEffectDate - Not implemented. It is not advisable to change Effective Date." ;
}

sub setConfig
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	#
	# Should type (flag) and subtype be made more restrictive here?
	#
	my ($dbh) = shift_;
	my ($dcount, $mflag, $edate) = @_;

	croak "setConfig - Invalid database handle. " unless $dbh;

	if(ref($invocant))
	{
		$dcount or $dcount = $invocant->DateCount;
		$mflag or $mflag = $invocant->MonthendFlag;
		$edate or $edate = $invocant->EffectiveDate;
	}

	my ($rpt_sql, $conf_id);

	$rpt_sql = qq{
		begin
			ccreport.acctexp_conf.setNewConfig(:datecount, :mflag, :effectiveDate);
			:id := getMaxID;
		end;
		};
	
	my $sth = $dbh->prepare($rpt_sql);

	eval {
		#$dbh->do($rpt_sql);	
		#$sth->bind_param_inout(":rptid", \$rpt_id, 0);
		$sth->bind_param(":datecount", $dcount);
		$sth->bind_param(":mflag", $mflag);
		$sth->bind_param(":effectiveDate", $edate);
		$sth->bind_param_inout(":id", \$conf_id, 0);
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

	$invocant->ID($conf_id) if ref($invocant);
	$conf_id;
}

sub ListConfig
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my ($dbh, $num) = @_;
	$num or $num = 0;

	croak "ListConfig - Invalid database handle. " unless $dbh;

	my $query = qq{
			select 
				id
				,datecount
				,monthend_flag
				,startdate
			  from ccreport.acctexp_config
			 where id >= (select max(id)-$num from ccreport.acctexp_config)
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

sub ListConfig_str
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my ($dbh, $num) = @_;

	my $result = '';
	my %fields = (
			0	=> 'ID',
			1	=> 'Number of Days',
			2	=> 'Monthend Flag',
			3	=> 'Effective Date',
			);
	my %lengths = (
			0	=> 2,
			1	=> 16,
			2	=> 14,
			3	=> 15,
			);
	my $fmt_str = "%9s %16s %14s %15s\n";

	my $rows = $class->ListConfig($dbh, $num);

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

}

1;

__END__


=head1 NAME

CMUCS::Rams::Report::AcctExp::AcctExpConfig - Perl extension for blah blah blah

=head1 SYNOPSIS

  use CMUCS::Rams::Report::AcctExp::AcctExpConfig;
  blah blah blah

=head1 DESCRIPTION

	Stub documentation for CMUCS::Rams::Report::AcctExp::AcctExpConfig

=head2 EXPORT

	None by default.


=head1 AUTHOR

	Longjiang Yang, E<lt>yangl@cs.cmu.eduE<gt>

=head1 SEE ALSO

L<perl>.

=cut
