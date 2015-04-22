# $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/lib/perl/CMUCS/Rams/Report/ChargeChange/Users.pm,v 1.13 2006/09/21 14:06:45 yangl Exp $
#
package CMUCS::Rams::Report::ChargeChange::Users;

use 5.006;
use strict;
use Carp;

use base qq(CMUCS::Rams::Report::ChargeChange::Entity);

use Data::Dumper;
use Text::Template;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our $VERSION = '0.01';

my $rpt_template = q!
{$header}
{sprintf('*'x74);}
{$content}
Net changes for users : $ {sprintf "%s", $total}
{$footer}
!;

#my $rpt_section_tmpl = q!
#{sprintf('-'x20)}
#{$title}
#{sprintf('-'x20)}
#{$colheaders}
#{$colseperators}
#{$content}
#{$footer}
#!;

# row = [ val1, val2, ]
# col = { 'col1' => 0, }
# dis = { 'col1' => 'display1', }
# pos = { 0 => 'col1', }
#{$dis->{$pos->{0}} {$row->{$pos->{0}}
#        1         2         3         4         5         6         7
#2345678901234567890123456789012345678901234567890123456789012345678901234567890

my $user_template = q!
User Charges Added
{sprintf '-'x70}
{
	%width = (	0	=> 10,
			1	=> 8,
			2	=> 8,
			3	=> 5,
			4	=> 6,
			5	=> 12,
		);
	$fmt_str = join('', map { '%'.$width{$pos->{$_}}.'s' } sort { $a <=> $b } keys %$pos);
	sprintf $fmt_str, map {$dis->{$pos->{$_} sort { $a <=> $b } keys %$pos);
} {$v[0]} {$t[1]} {$v[1]}
{$t[2]} {$v[2]}

{$t[3]} {$v[3]} {$t[4]} {$v[4]}
{$t[5]} {$v[5]} {$t[6]} {$v[6]}
{$t[7]} {$v[7]}
{$t[8]} {$v[8]} {$t[9]} {$v[9]}
{$t[10]} {$v[10]}
{sprintf('-'x64);}
!;


my $user_displaycols = {
		'PRINC'		=> 'Princ',
		'NAME'		=> 'Name',
		'CHANGE_FLAG'	=> 'Change Flag',
		'REASON'	=> 'Reason',
		'CHARGE_BY'	=> 'CSrc',
		'SPONSOR'	=> 'Sponsor',
		'PCTUSER'	=> '% User',
		'SERVICE_VEC'	=> 'Services',
		'PCT'		=> 'Pct',
		'TOTALCHARGED'	=> 'Unit Charge',
		'AMOUNTCHARGED'	=> 'Amount',
		'LASTCHANGED'	=> 'LastChanged',
	};
		#'LASTCHANGED'	=> 'Date',
		#'ADJUSTEDCHARGE'	=> 'Princ',

my %colwidth = (
		'NAME'		=> 16,
		'PRINC'		=> 8,
		'SPONSOR'	=> 8,
		'PCT'		=> -3,
		'AMOUNTCHARGED'	=> -8,
		'SERVICE_VEC'	=> 12,
		'CHANGE_FLAG'	=> 4,
		'CHARGE_BY'	=> 4,
		'PCTUSER'	=> 6,
		'TOTALCHARGED'	=> -6,
		'AMOUNTCHARGED'	=> -6,
		'LASTCHANGED'	=> 10,
	);

my $position = 
	{
		0	=> 'NAME',
		1	=> 'PRINC',
		2	=> 'SPONSOR',
		3	=> 'CHARGE_BY',
		4	=> 'PCT',
		5	=> 'AMOUNTCHARGED',
	};
		#5	=> 'SERVICE_VEC',
	#6	=> '',
	#7	=> '',
	#8	=> '',
	#9	=> '',
	#10	=> '',

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my $header = "User Charges Changed";
	my $u = {
			type		=> 'User',
			header		=> $header,
			displaynames	=> $user_displaycols,
			position	=> $position,
			colwidths	=> \%colwidth,
			rpt_template	=> { TYPE => 'STRING', SOURCE => $rpt_template },
			#rpt_section_tmpl=> { TYPE => 'STRING', SOURCE => $rpt_section_tmpl },
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

	my $acct_colname = 'ACCT_STRING';
	my $key1_colname = 'REASON';
	my $key2_colname = 'PRINC';
	my $adjcharge_colname = 'ADJUSTEDCHARGE';

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

	#push @$rows, ['fake-acct-string','null','null'];

	#-----------------------------
	# get ('col' => 2, ...) mapping
	#-----------------------------
	my %columnindex;
	my $cntr = 0;
	#shift @$colnames;
	while(my $col = shift(@$colnames))
	{
		$columnindex{$col} = $cntr++ ;
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
		}
		
		if(defined($entries->{$acct_val}->{'_SUMMARY_'}->{$row->[$key1_idx]}))
		{
			$entries->{$acct_val}->{'_SUMMARY_'}->{$row->[$key1_idx]} += $row->[$adjcharge_idx];
		} else {
			$entries->{$acct_val}->{'_SUMMARY_'}->{$row->[$key1_idx]} = $row->[$adjcharge_idx];
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

sub stringify_row
{
	my $self = shift;
	my $row = shift;

	#croak "a row of fields is expected but not found \n" unless $row;
	#croak "Array ref expected but not found \n" unless(ref($row) && (ref($row) eq 'ARRAY'));

	my %chargeby_map = (
			'L'	=> 'Labr',
			'P'	=> 'Hard'
		);

	my $colnames = $self->colnames;
	#my $displaynames = $self->displaynames;
	my $positions = $self->position;
	my $colwidth = $self->colwidths;

	my $fmt =  $self->fmt_string;
	#print Dumper(\$xx);
	#print Dumper($row);
	#print Dumper($colnames);
	#print Dumper($positions);
	#sprintf $self->fmt_string,
		#qq/$xx/,
		#"%-10s %-8s %-8s %-5s %-8s %-12s\n",
			#"%-16s %-8s %-8s %3s %6s %3s\n",
			#"%-16s %-8s %-8s %3s %6s\n",
		#"$fmt\n",
	my @col_vals;
	if(defined($row))
	{
		if(ref($row))
		{
			croak "Array ref expected but not found \n"
				unless((ref($row) eq 'ARRAY'));
			
			@col_vals = map {substr($row->[$colnames->{$positions->{$_}}], 
						0, 
						abs($colwidth->{$positions->{$_}})
						)
					}
					sort { $a <=> $b } keys %$positions;
		} else {
		        @col_vals = map ' ', keys %$positions;
		        $col_vals[$#col_vals] = $row || 0;
		}
	} else {
			@col_vals = map { '-' x abs($colwidth->{$positions->{$_}}) }
					sort {$a <=> $b} keys %$positions;
	}
        
		if(uc($row->[$colnames->{'REASON'}]) eq 'CHANGED')
		{
			if (uc($row->[$colnames->{'CHANGE_FLAG'}]) eq 'NEW')
			{
				sprintf(
					"$fmt %3s\n",
					sprintf("%s",$col_vals[0]),
					sprintf("%s",$col_vals[1]),
					sprintf("%s",$col_vals[2]),
					sprintf("%s",$chargeby_map{$col_vals[3]}),
					sprintf("%3.0f",$col_vals[4]),
					sprintf("%3.02f",$col_vals[5]),
					sprintf("%s",$row->[$colnames->{'CHANGE_FLAG'}])
					);
			} else {
				  sprintf(
					"$fmt %3s\n",
					sprintf(" " x abs($colwidth->{$positions->{0}})),
					sprintf(" " x abs($colwidth->{$positions->{1}})),
					sprintf("%s",$col_vals[2]),
					sprintf("%s",$chargeby_map{$col_vals[3]}),
					sprintf("%3.0f",$col_vals[4]),
					sprintf("%3.02f",$col_vals[5]),
					sprintf("%s",$row->[$colnames->{'CHANGE_FLAG'}])
					);
			}
		#} elsif(uc($col_vals[$colnames->{'REASON'}]) eq 'ADDED' 
		#	|| uc($col_vals[$colnames->{'REASON'}]) eq 'DELETED') {
		} elsif(uc($row->[$colnames->{'REASON'}]) eq 'ADDED' 
			|| uc($row->[$colnames->{'REASON'}]) eq 'DELETED') {
			sprintf(
				"$fmt\n",
					sprintf("%s",$col_vals[0]),
					sprintf("%s",$col_vals[1]),
					sprintf("%s",$col_vals[2]),
					sprintf("%s",$chargeby_map{$col_vals[3]}),
					sprintf("%3.0f",$col_vals[4]),
					sprintf("%3.02f",$col_vals[5])
				);
		} else {
			sprintf(
				"$fmt\n",
					sprintf("%s",$col_vals[0]),
					sprintf("%s",$col_vals[1]),
					sprintf("%s",$col_vals[2]),
					sprintf("%s",$col_vals[3]),
					sprintf("%s",$col_vals[4]),
					sprintf("%s",$col_vals[5])
				);
		}
	

	#if(uc($row->[$colnames->{'REASON'}]) eq 'CHANGED')
	#{
	#	if (uc($row->[$colnames->{'CHANGE_FLAG'}]) eq 'NEW')
	#	{
	#	sprintf(
	#		"$fmt %3s\n",
	#		sprintf("%s",substr($row->[$colnames->{$positions->{0}}], 0, abs($colwidth->{$positions->{0}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{1}}], 0, abs($colwidth->{$positions->{1}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{2}}], 0, abs($colwidth->{$positions->{2}}))),
	#		sprintf("%3.0f",$row->[$colnames->{$positions->{3}}]),
	#		sprintf("%3.02f",$row->[$colnames->{$positions->{4}}]),
	#		sprintf("%s",$row->[$colnames->{'CHANGE_FLAG'}])
	#		);
	#	#sprintf("%s",$row->[$colnames->{$positions->{5}}])
	#	} else {
	#	  sprintf(
	#		"$fmt %3s\n",
	#		sprintf(" " x abs($colwidth->{$positions->{0}})),
	#		sprintf(" " x abs($colwidth->{$positions->{1}})),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{2}}], 0, abs($colwidth->{$positions->{2}}))),
	#		sprintf("%3.0f",$row->[$colnames->{$positions->{3}}]),
	#		sprintf("%3.02f",$row->[$colnames->{$positions->{4}}]),
	#		sprintf("%s",$row->[$colnames->{'CHANGE_FLAG'}])
	#		);
	#	}
	#} else {
	#	sprintf(
	#		"$fmt\n",
	#		sprintf("%s",substr($row->[$colnames->{$positions->{0}}], 0, abs($colwidth->{$positions->{0}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{1}}], 0, abs($colwidth->{$positions->{1}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{2}}], 0, abs($colwidth->{$positions->{2}}))),
	#		sprintf("%3.0f",$row->[$colnames->{$positions->{3}}]),
	#		sprintf("%3.02f",$row->[$colnames->{$positions->{4}}])
	#		);
	#}
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

#sub commify 
#{
#	my $text = reverse $_[0];
#	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
#	return scalar reverse $text;
#}
		
sub stringify_byacct
{
	my $self = shift;
	#my $acct = shift || '';
	my $acct = shift ;
	my ($result, $rpt_result) = ('', '');
	my %result;

	my ($tmpl, $tmpl_entity) = @_ ;

	croak "account string has to be specified." unless $acct;

	if(!defined($tmpl)) 
	{
		#print "Use Default Template for Entity.\n";
		$tmpl = $self->rpt_template || { TYPE => 'STRING', SOURCE => $rpt_template };
	}

	croak "template parameter requires hash reference." unless(ref($tmpl) eq 'HASH');

	if(!defined($tmpl_entity)) 
	{
		#print "Use Default Template for Entity.\n";
		$tmpl_entity = { TYPE => 'STRING', SOURCE => $user_template };
	}

	croak "template parameter requires hash reference." unless(ref($tmpl_entity) eq 'HASH');

	#
	# Each User
	#
	my $allrows = $self->rows;
	my $rows = $allrows->{$acct};

	return $rpt_result unless $rows;

	my $colnames = $self->colnames;
	my $displaynames = $self->displaynames;
	my $positions = $self->position;
	#print Dumper($colnames);
	while(my ($k1, $v1) = each %$rows)
	{
		my $template = Text::Template->new( %$tmpl_entity )
			or croak "Couldn't construct template: $Text::Template::ERROR";
		my $r = $template->fill_in(HASH => {
						row => \$v1, 
						col => \$colnames,
						dis => \$displaynames,
						pos => \$positions,
					}
				);
		defined($r) || croak "Couldn't fill in template: $Text::Template::ERROR.";
	} 

		#unless($k1 eq '_SUMMARY_')
		#{
		#	while(my ($k2, $v2) = each %$v)
		#	{
		#		#$result .= $k1."\r";
		#		foreach my $v3 (@$v2)
		#		{
		#			my $template = Text::Template->new( %$tmpl_entity )
		#				or croak "Couldn't construct template: $Text::Template::ERROR";
		#			my $r = $template->fill_in(HASH => {
		#							row => \$v3, 
		#							col => \$colnames,
		#							dis => \$displaynames,
		#							pos => \$positions,
		#						}
		#					);
		#			defined($r) || croak "Couldn't fill in template: $Text::Template::ERROR.";
		#			$result{$k2} .= $r; 
		#		}
		#	}
		#}

	#
	# User Report
	#
	my $template = Text::Template->new( %$tmpl )
		or croak "Couldn't construct template: $Text::Template::ERROR";
	my $header = $self->header;
	my $footer = '';
	$rpt_result = $template->fill_in(HASH => {
					header	=> \$header,
					content	=> \%result,
					footer	=> \$footer,
							}
				);
					#content	=> \$result,
	$rpt_result || croak "Couldn't fill in template: $Text::Template::ERROR.";
	$rpt_result;
}

1;
__END__

my $rpt_template_detail = q!
{$header}
{sprintf('*'x74);}
{$content}
{$footer}

!;
my $user_template_detail = q!
{	my ($w1, $w2, $w3, $w4) = (11, 40, 10, 11);
	my $ww = 61;
	my %chargeby = ( 'L' => 'Labor', 'P' => 'Project' );
	$t[0] = sprintf "%11s", $dis->{'NAME'};
	$v[0] = sprintf "%-30s", $row->[$col->{'NAME'}];

	$t[1] = sprintf "%11s", $dis->{'PRINC'};
	$v[1] = sprintf "%-11s", $row->[$col->{'PRINC'}];

	$t[2] = sprintf "%11s", $dis->{'SPONSOR'};
	$v[2] = sprintf "%-30s", $row->[$col->{'SPONSOR'}];

	$t[3] = sprintf "%11s", $dis->{'TOTALCHARGED'};
	$v[3] = sprintf "%-29s", sprintf("\$%.2f",$row->[$col->{'TOTALCHARGED'}]);

	$t[4] = sprintf "%11s", $dis->{'CHARGE_BY'};
	$v[4] = sprintf "%-11s", $chargeby{$row->[$col->{'CHARGE_BY'}]};

	$t[5] = sprintf "%11s", $dis->{'PCTUSER'};
	$v[5] = sprintf " %-30s", $row->[$col->{'PCTUSER'}];

	$t[6] = sprintf "%11s", $dis->{'CHANGE_FLAG'};
	$v[6] = sprintf "%-11s", $row->[$col->{'REASON'}].' '.$row->[$col->{'CHANGE_FLAG'}];

	$t[7] = sprintf "%11s", $dis->{'PCT'};
	$v[7] = sprintf " %-30s", $row->[$col->{'PCT'}];

	$t[8] = sprintf "%11s", $dis->{'AMOUNTCHARGED'};
	$v[8] = sprintf "%-29s", sprintf("\$%.2f",$row->[$col->{'AMOUNTCHARGED'}]);

	$t[9] = sprintf "%11s", $dis->{'LASTCHANGED'};
	$v[9] = sprintf "%-11s", substr $row->[$col->{'LASTCHANGED'}], 0, 12;

	$t[10] = sprintf "%11s", $dis->{'SERVICE_VEC'};
	$v[10] = sprintf "%-60s", $row->[$col->{'SERVICE_VEC'}];
	$t[0];
} {$v[0]} {$t[1]} {$v[1]}
{$t[2]} {$v[2]}

{$t[3]} {$v[3]} {$t[4]} {$v[4]}
{$t[5]} {$v[5]} {$t[6]} {$v[6]}
{$t[7]} {$v[7]}
{$t[8]} {$v[8]} {$t[9]} {$v[9]}
{$t[10]} {$v[10]}
{sprintf('-'x64);}
!;

#{sprintf "%11s", $dis->{'NAME'}} {sprintf "%-40s", $row->[$col->{'NAME'}]}   {$dis->{'PRINC'}} {$row->[$col->{'PRINC'}]}
#{sprintf "%11s", $dis->{'SPONSOR'}} {sprintf "%-40s", $row->[$col->{'SPONSOR'}]} 
#
#{sprintf "%11s", $dis->{'TOTALCHARGED'}} {sprintf "%-40s", $row->[$col->{'TOTALCHARGED'}]} {$dis->{'CHARGE_BY'}} {$row->[$col->{'CHARGE_BY'}]}
#{sprintf "%11s", $dis->{'PCTUSER'}} {sprintf "%-40s", $row->[$col->{'PCTUSER'}]}   {$dis->{'CHANGE_FLAG'}} {$row->[$col->{'CHANGE_FLAG'}]} {$row->[$col->{'REASON'}]}
#{sprintf "%11s", $dis->{'PCT'}} {sprintf "%-40s", $row->[$col->{'PCT'}]}   
#{sprintf "%11s", $dis->{'AMOUNTCHARGED'}} {sprintf "%-40s", $row->[$col->{'AMOUNTCHARGED'}]}   {$dis->{'LASTCHANGED'}} {$row->[$col->{'LASTCHANGED'}]}
#{sprintf "%11s", $dis->{'SERVICE_VEC'}} {$row->[$col->{'SERVICE_VEC'}]}   


=head1 NAME

CMUCS::Rams::Report::ChargeChange::Users - Perl extension for blah blah blah

=head1 SYNOPSIS

  use CMUCS::Rams::Report::ChargeChange::Users;
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
