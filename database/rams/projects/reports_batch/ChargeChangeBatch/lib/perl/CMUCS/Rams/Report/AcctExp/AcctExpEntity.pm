# $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/lib/perl/CMUCS/Rams/Report/AcctExp/AcctExpEntity.pm,v 1.9 2007/10/26 18:41:53 costing Exp $
#
package CMUCS::Rams::Report::AcctExp::AcctExpEntity;

use 5.006;
use strict;
use Carp;

use base qq(CMUCS::Rams::Report::ChargeChange::Entity);

use Data::Dumper;
use Text::Template;
use Time::ParseDate;

our $VERSION = '0.01';

my $rpt_template = q!
{$header}
{sprintf('*'x74);}

Sponsor:  U = Primary User, P = Project Supervisor, E = Equipment Admin

ChargeSrc:
		User		= Follow Charge Account(s) of Primary User
		Project	= Charge to specific project account(s)
		Payroll	= Charge to the user's payroll account(s) 
{sprintf('*'x74);}
{$content}
{$footer}
!;

my $rpt_section_tmpl = q!
{sprintf('-'x20)}
{$title}
{sprintf('-'x20)}
{$colheaders}
{$colseperators}
{$content}
{"Net charges for $title : $total" if $total}
{$footer}
!;

#'

my $user_displaycols = {
		'PTA'		=> 'Account',
		'NAME'		=> 'Name',
		'ID'		=> 'ID',
		'CHARGE_SRC'	=> 'Charge Src',
		'SPONSOR'	=> 'Sponsor',
		'CHARGE'	=> 'Unit Charge',
		'AMOUNT'	=> 'Amount',
	};
		#'LASTCHANGED'	=> 'Date',
		#'ADJUSTEDCHARGE'	=> 'Princ',

my %colwidth = (
		'PTA'		=> 20,
		'NAME'		=> 16,
		'ID'		=> 10,
		'SPONSOR'	=> 8,
		'CHARGE'	=> -8,
		'CHARGE_SRC'	=> 10,
		'AMOUNT'	=> -7,
	);

my $position = 
	{
		0	=> 'NAME',
		1	=> 'ID',
		2	=> 'SPONSOR',
		3	=> 'CHARGE_SRC',
		4	=> 'AMOUNT',
	};

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my $header = "Entity Charged to Expiring Oracle String";
	my $u = {
			type		=> 'Entity',
			header		=> $header,
			displaynames	=> $user_displaycols,
			position	=> $position,
			colwidths	=> \%colwidth,
			rpt_template	=> { TYPE => 'STRING', SOURCE => $rpt_template },
			rpt_section_tmpl=> { TYPE => 'STRING', SOURCE => $rpt_section_tmpl },
			@_,
		};
	croak "colnames and rows are required for class $class \n" 
			unless($u->{colnames} && $u->{rows});

	my ($colnames, $rows) = $class->convert($u->{colnames}, $u->{rows});

	my $self = $class->SUPER::new (
			%$u,
			colnames	=> $colnames,
			rows		=> $rows,
		);
	
	return bless $self, $class;
}

sub convert
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my ($colnames, $rows) = @_;

	my %key_colnames = (
				'Acct'		=>	'PTA',
				'Key1'		=>	'ENTITY_TYPE',
				'Key2'		=>	'ID',
				'AdjCharge'	=>	'AMOUNT',
				'Reason'	=>	'REASON',
				'ExpDate'	=>	'EXPDATE_CODE',
			);

	my $acct_colname = 'PTA';
	my $key1_colname = 'ENTITY_TYPE';
	my $key2_colname = 'ID';
	my $adjcharge_colname = 'AMOUNT';
	my $reason_colname = 'REASONCODE';
	my $expdate_colname = 'EXPDATE_CODE';
	my $chargesrc_colname = 'CHARGE_SRC';

	return (undef, undef) unless $colnames;
	croak "Array reference expected for column names\n" unless(ref($colnames) eq 'ARRAY');
	croak "Array ref expected for init_rows while got ."||ref($rows) unless ref($rows) eq 'ARRAY';

	# no acct_string column means either error
	# or structure has been processed.
	# simple return undef here.
	my $cnt = grep { /$acct_colname/ } @$colnames;
	return (undef, undef) unless $cnt > 0;

	$cnt = grep( /$key1_colname/, @$colnames);
	croak "column $key1_colname does not exist.\n" unless $cnt > 0;
	$cnt = grep( /$key2_colname/, @$colnames);
	croak "column $key2_colname does not exist.\n" unless $cnt > 0;
	$cnt = grep( /$adjcharge_colname/, @$colnames);
	croak "column $adjcharge_colname does not exist.\n" unless $cnt > 0;
	$cnt = grep( /$reason_colname/, @$colnames);
	croak "column $reason_colname does not exist.\n" unless $cnt > 0;
	$cnt = grep( /$expdate_colname/, @$colnames);
	croak "column $expdate_colname does not exist.\n" unless $cnt > 0;
	$cnt = grep( /$chargesrc_colname/, @$colnames);
	croak "column $chargesrc_colname does not exist.\n" unless $cnt > 0;

	#push @$rows, ['fake-acct-string','null','null'];

	#-----------------------------
	# get ('col' => 2, ...) mapping
	#-----------------------------
	my %columnindex;
	my $cntr = 0;
	#shift @$colnames;
	while(my $col = shift(@$colnames))
	{
		$columnindex{uc($col)} = $cntr++ ;
	}

	#$self->colnames(\%columnindex);
	#my $acct = $rows->[0][0];
	my $entries = {};

	#
	# entries= { '1234-5-2345' => { 'PRINC' => [[],[]] } }
	#
	my $acct_idx = $columnindex{$acct_colname};
	my $key1_idx = $columnindex{$key1_colname};
	my $key2_idx = $columnindex{$key2_colname};
	my $adjcharge_idx = $columnindex{$adjcharge_colname};
	my $reason_idx = $columnindex{$reason_colname};
	my $expdate_idx = $columnindex{$expdate_colname};
	my $chargesrc_idx = $columnindex{$chargesrc_colname};
	#print "$acct_idx, $key_idx, $adjcharge_idx \n";
	foreach my $row (@$rows)
	{
		#print Dumper($row);
		#my $acct_new = $row->[0];
		my $acct_val = $row->[$acct_idx];
		
		if(defined($entries->{$acct_val}->{'_SUMMARY_'}->{'CHARGE'}))
		{
			$entries->{$acct_val}->{'_SUMMARY_'}->{'CHARGE'} += $row->[$adjcharge_idx];
		} else {
			$entries->{$acct_val}->{'_SUMMARY_'}->{'CHARGE'} = $row->[$adjcharge_idx];
			$entries->{$acct_val}->{'_SUMMARY_'}->{'REASON'} = $row->[$reason_idx];
			$row->[$expdate_idx] =~ /.*:(.*)/;
			my $expdate = $1;
			#my $epoch = parsedate($row->[$expdate_idx]) || parsedate("now");
			my $epoch = parsedate($expdate) || parsedate("now");
			my $epoch_count = $epoch - parsedate("now");
			my @ts = localtime($epoch);
			my @mons = qw/JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC/;
			$entries->{$acct_val}->{'_SUMMARY_'}->{'EXPDATE'} = 
					sprintf("%3s-%02s-%s", $mons[$ts[4]], $ts[3], $ts[5]+1900);
			$entries->{$acct_val}->{'_SUMMARY_'}->{'DAYCOUNT'} = int($epoch_count/(24*3600))+1;


			#TODO: Make them independent of column values
			$entries->{$acct_val}->{'_SUMMARY_'}->{'UCOUNT'}->{'Payroll'} = 0 ;
			#$entries->{$acct_val}->{'_SUMMARY_'}->{'UCOUNT'}->{'Project'} = 0 ;
			$entries->{$acct_val}->{'_SUMMARY_'}->{'UCOUNT'}->{'Hardcoded'} = 0 ;
			$entries->{$acct_val}->{'_SUMMARY_'}->{'MCOUNT'}->{'FollowUser'} = 0 ;
			#$entries->{$acct_val}->{'_SUMMARY_'}->{'MCOUNT'}->{'Project'} = 0 ;
			$entries->{$acct_val}->{'_SUMMARY_'}->{'MCOUNT'}->{'Hardcoded'} = 0 ;
		}
		
		if(defined($entries->{$acct_val}->{'_SUMMARY_'}->{$row->[$key1_idx]}))
		{
			$entries->{$acct_val}->{'_SUMMARY_'}->{$row->[$key1_idx]} += $row->[$adjcharge_idx];
			$entries->{$acct_val}->{'_SUMMARY_'}->{$row->[$key1_idx] . 'COUNT'}->{$row->[$chargesrc_idx]} = 0 
				unless(defined(
				$entries->{$acct_val}->{'_SUMMARY_'}->{$row->[$key1_idx] . 'COUNT'}->{$row->[$chargesrc_idx]}
						)
					);
			$entries->{$acct_val}->{'_SUMMARY_'}->{$row->[$key1_idx]. 'COUNT'}->{$row->[$chargesrc_idx]} += 1; 
		} else {
			$entries->{$acct_val}->{'_SUMMARY_'}->{$row->[$key1_idx]} = $row->[$adjcharge_idx];
			$entries->{$acct_val}->{'_SUMMARY_'}->{$row->[$key1_idx] . 'COUNT'}->{$row->[$chargesrc_idx]} = 1;
		}
		
		if(defined($entries->{$acct_val}->{$row->[$key1_idx]}->{$row->[$key2_idx]}))
		{
			push @{$entries->{$acct_val}->{$row->[$key1_idx]}->{$row->[$key2_idx]}}, $row;
		} else {
			$entries->{$acct_val}->{$row->[$key1_idx]}->{$row->[$key2_idx]} = [$row];
		}
		#push @{$entries->{$acct_val}->{$row->[$key_idx]}}, $row;
	}

	#$self->rows($entries);
	#print Dumper($entries);
	(\%columnindex, $entries);
}

=over

=item stringify

=back

=cut

sub stringify
{
	my $self = shift;
	my $acct = shift ;
	my $section_titles = shift || {
					'U'		=> 'Users',
					'M'		=> 'Machines',
				};

	my ($tmpl, $tmpl_section) = @_ ;
	my ($result, $rpt_result) = ('', '');

	croak "account string has to be specified." unless $acct;

	if(!defined($tmpl)) 
	{
		$tmpl = $self->rpt_template ||
				{ TYPE => 'STRING', SOURCE => $rpt_template };
	}

	croak "template parameter requires hash reference." unless(ref($tmpl) eq 'HASH');

	if(!defined($tmpl_section)) 
	{
		#print "Use Default Template for Entity.\n";
		$tmpl_section = $self->rpt_section_tmpl || 
				{ TYPE => 'STRING', SOURCE => $rpt_section_tmpl };
	}

	croak "template parameter requires hash reference." unless(ref($tmpl_section) eq 'HASH');

	my $colnames = $self->colnames;
	my $displaynames = $self->displaynames;
	my $positions = $self->position;
	my $rows = $self->rows->{$acct} || undef;
	
	#while(my ($k1, $v1) = each %$rows)
	return $rpt_result unless $rows;
	foreach my $k1 (sort sort_sections keys %$rows)
	{
		my $v1 = $rows->{$k1};
		unless($k1 eq '_SUMMARY_')
		{
			my $row_result = '';

			foreach my $k2 (sort sort_ids keys %$v1)
			{
				my $v2 = $v1->{$k2};
				foreach my $v3 (@$v2)
				{
					$row_result .= $self->stringify_row($v3);
				}
			}
			if($row_result ne '')
			{
				my $template = Text::Template->new( %$tmpl_section )
					or croak "Couldn't construct template: $Text::Template::ERROR";

				croak "unknown section $k1 \n" unless $section_titles->{$k1};
				my $title = $section_titles->{$k1};
				my $colheaders = $self->getHeaderStr($k1);
				my $colseperators = $self->getHeaderSepStr($k1);
				#my $colseperators = $self->stringify_row(undef);
				my $footer = '';
				my $tot = $rows->{'_SUMMARY_'}->{$k1} || 0;
				my $total = $self->commify(sprintf("%.02f",$tot));

				$row_result .= $self->stringify_row(undef);
				$row_result .= $self->stringify_row($tot);

				my $r = $template->fill_in(HASH => {
								title		=> \$title,
								colheaders	=> \$colheaders,
								colseperators	=> \$colseperators,
								footer		=> \$footer,
								total		=> \$total,
								content		=> \$row_result,
								}
							);
				$r || croak "Couldn't fill in template: $Text::Template::ERROR.";
				$result .= $r;
			}
		}
	}
	#
	# Entity Report
	#
	my $template = Text::Template->new( %$tmpl )
		or croak "Couldn't construct template: $Text::Template::ERROR";
	my $header = $self->header;
	my $footer = '';
	#my $tot = $rows->{'_SUMMARY_'}->{'CHARGE'} || 0;
	#my $total = $self->commify($tot);
	# Not used.
	my $total = '0.00';
	$rpt_result = $template->fill_in(HASH => {
					header	=> \$header,
					content	=> \$result,
					footer	=> \$footer,
					total	=> \$total,
					type	=> $self->type,
							}
				);
					#content	=> \$result,
	$rpt_result || croak "Couldn't fill in template: $Text::Template::ERROR.";
	$rpt_result;
}

sub stringify_row
{
	my $self = shift;
	my $row = shift;

	#croak "a row of fields is expected but not found \n" unless $row;
	#croak "Array ref expected but not found \n" unless(ref($row) && (ref($row) eq 'ARRAY'));

	my $colnames = $self->colnames;
	#my $displaynames = $self->displaynames;
	my $positions = $self->position;
	my $colwidth = $self->colwidths;

	my $fmt =  $self->fmt_string;
	my @col_vals;
	if(defined($row))
	{
		if(ref($row))
		{
			croak "Array ref expected but not found \n"
				unless((ref($row) eq 'ARRAY'));
		
			@col_vals = map {
					substr($row->[$colnames->{$positions->{$_}}]
						, 0
						, abs( $colwidth->{$positions->{$_}} )
						)
					} sort { $a <=> $b } keys %$positions;
		} else {
			@col_vals = map ' ', keys %$positions;
			$col_vals[$#col_vals] = $row || 0;
		}
	} else {
			@col_vals = map {'-' x abs($colwidth->{$positions->{$_}})}
					sort {$a <=> $b} keys %$positions;
	}
	if(defined($row))
	{
		sprintf(
			"$fmt\n",
			sprintf("%s",$col_vals[0]),
			sprintf("%s",$col_vals[1]),
			sprintf("%s",$col_vals[2]),
			sprintf("%s",$col_vals[3]),
			sprintf("%4.02f",$col_vals[4])
			);
	} else {
		sprintf(
			"$fmt\n",
			sprintf("%s",$col_vals[0]),
			sprintf("%s",$col_vals[1]),
			sprintf("%s",$col_vals[2]),
			sprintf("%s",$col_vals[3]),
			sprintf("%s",$col_vals[4])
			);
	}
}

sub getRows
{
	my $self = shift;

	my ($acct, $type, $id) = @_;

	croak "account string has to be specified.\n" unless $acct;
	my $result = undef;
	my $allrows = $self->rows;
	
	return $result unless(exists $allrows->{$acct});
}

sub hasEntries
{
	my $self = shift;

	my ($acct) = @_;
	my $cnt = 0;

	croak "AcctExpEntity::hasEntries:account string has to be specified.\n"
		unless $acct;

	$cnt = 1 if( defined($self->rows->{$acct}) );

	#$cnt = 1 if( defined($self->rows->{$acct}->{'M'}) 
	#		|| defined($self->rows->{$acct}->{'U'})
	#	);
	#print "*****$acct count=$cnt\n".Dumper($self->rows->{$acct});
	$cnt;
}

sub sort_sections
{
        #$a cmp $b;
	#user first
        $b cmp $a;
}

sub sort_ids
{
        $a cmp $b;
}

#sub commify 
#{
#	my $text = reverse $_[0];
#	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
#	return scalar reverse $text;
#}
		
1;

__END__


=head1 NAME

CMUCS::Rams::Report::AcctExp::AcctExpEntity - Perl extension for blah blah blah

=head1 SYNOPSIS

  use CMUCS::Rams::Report::AcctExp::AcctExpEntity ;
  blah blah blah

=head1 DESCRIPTION

	Stub documentation for CMUCS::Rams::Report::ChargeChange::Users

=head2 EXPORT

	None by default.


=head1 AUTHOR

	Longjiang Yang, E<lt>yangl@cs.cmu.eduE<gt>

=head1 SEE ALSO

L<perl>.

=cut

