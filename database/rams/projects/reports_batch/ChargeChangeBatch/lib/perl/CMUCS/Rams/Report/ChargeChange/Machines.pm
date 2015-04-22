# $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/lib/perl/CMUCS/Rams/Report/ChargeChange/Machines.pm,v 1.14 2006/09/21 14:06:45 yangl Exp $
#
package CMUCS::Rams::Report::ChargeChange::Machines;

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

Contact:  U = Primary User, P = Project Supervisor, E = Equipment Admin
{$content}
Net changes for machines : $ {sprintf "%s", $total}
{$footer}
!;

# default but will be set by caller.
#my $rpt_section_tmpl = q!
#{sprintf('-'x20)}
#{$title}
#{sprintf('-'x20)}
#{$colheaders}
#{$colseperators}
#{$content}
#{$footer}
#!;

my $machine_displaycols = {
		'HOSTNAME'	=> 'Hostname',
		'ASSETNO'	=> 'Asset #',
		'PRIMARYUSER'	=> 'Contact',
		'LOCATION'	=> 'Location',
		'OS'		=> 'OS',
		'DEPT'		=> 'Dept',
		'IPADDRESS'	=> 'IP Address',
		'CHARGE_BY'	=> 'CSrc',
		'PCT'		=> 'Pct',
		'QUAL'		=> 'Status',
		'PRI'		=> 'Host #',
		'CHANGE_FLAG'	=> 'Change Flag',
		'REASON'	=> 'Reason',
		'SERVICE_VEC'	=> 'Services',
		'TOTALCHARGED'	=> 'Unit Charge',
		'AMOUNTCHARGED'	=> 'Amount',
		'LASTCHANGED'	=> 'LastChanged',
	};
		#'ADJUSTEDCHARGE'	=> 'Princ',

# negative number means right alignment for the column.
my %colwidth = (
		'HOSTNAME'	=> 13,
		'ASSETNO'	=> -9,
		'PRIMARYUSER'	=> 10,
		'LOCATION'	=> 10,
		'OS'		=> 4,
		'DEPT'		=> 10,
		'IPADDRESS'	=> 10,
		'CHARGE_BY'	=> 4,
		'PCT'		=> -3,
		'QUAL'		=> 10,
		'PRI'		=> 2,
		'CHANGE_FLAG'	=> 10,
		'REASON'	=> 10,
		'SERVICE_VEC'	=> 10,
		'TOTALCHARGED'	=> -6,
		'AMOUNTCHARGED'	=> -6,
		'LASTCHANGED'	=> 10,
	);

my $position = {
		0	=> 'HOSTNAME',
		1	=> 'ASSETNO',
		2	=> 'PRIMARYUSER',
		3	=> 'CHARGE_BY',
		4	=> 'OS',
		5	=> 'LOCATION',
		6	=> 'SERVICE_VEC',
		7	=> 'PCT',
		8	=> 'AMOUNTCHARGED',
	};
	#{
	#0	=> 'PRINC',
	#1	=> 'NAME',
	#2	=> '',
	#3	=> '',
	#4	=> '',
	#5	=> '',
	#6	=> '',
	#7	=> '',
	#8	=> '',
	#9	=> '',
	#10	=> '',
	#};

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my $header = "Machine Charges Changed";
	my $u = {
			type		=> 'Machine',
			header		=> $header,
			displaynames	=> $machine_displaycols,
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
	my $key2_colname = 'ASSETNO';
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
	# entries= { '1234-5-2345' => { 'ASSETNO' => [[],[]] } }
	#
	my $acct_idx = $columnindex{$acct_colname};
	my $key1_idx = $columnindex{$key1_colname};
	my $key2_idx = $columnindex{$key2_colname};
	my $adjcharge_idx = $columnindex{$adjcharge_colname};
	#print "$acct_idx, $key1_idx, $adjcharge_idx \n";
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
		
		#push @{$entries->{$acct_val}->{$row->[$key1_idx]}->{$row->[$key2_idx]}}, $row;
		if(defined($entries->{$acct_val}->{$row->[$key1_idx]}->{$row->[$key2_idx]}))
		{
			push @{$entries->{$acct_val}->{$row->[$key1_idx]}->{$row->[$key2_idx]}}, $row;
		} else {
			$entries->{$acct_val}->{$row->[$key1_idx]}->{$row->[$key2_idx]} = [$row];
		}
	}

	#$self->rows($entries);
	#print Dumper($entries);
	(\%columnindex, $entries);
}

sub getHeaderStr
{
	my $self = shift;
	my $type = shift;
	my $result = '';

	croak "please specify type of entries for header string. " unless $type;

	#$result .= sprintf "%-4s", 'Desc';

	$result .= $self->SUPER::getHeaderStr;
}

sub getHeaderSepStr
{
	my $self = shift;
	my $type = shift;
	my $result = '';

	croak "please specify type of entries for header string. " unless $type;

	#$result .= sprintf('-'x4).' ';

	$result .= $self->SUPER::getHeaderSepStr;
}

sub stringify
{
	my $self = shift;
	#my $acct = shift || '';
	my $acct = shift ;
	my $section_titles = shift || {
					'Added'		=> 'Machine Charges Added for ' . $acct,
					'Changed'	=> 'Machine Charges Changed for ' . $acct,
					'Deleted'	=> 'Machine Charges No Longer Charged to ' . $acct,
				};

	my ($tmpl, $tmpl_section) = @_ ;
	my ($result, $rpt_result) = ('', '');

	croak "account string has to be specified." unless $acct;

	if(!defined($tmpl)) 
	{
		$tmpl = $self->rpt_template || { TYPE => 'STRING', SOURCE => $rpt_template };
	}

	croak "template parameter requires hash reference." unless(ref($tmpl) eq 'HASH');

	#if(!defined($tmpl_section)) 
	#{
	#	#print "Use Default Template for Entity.\n";
	#	$tmpl_section = { TYPE => 'STRING', SOURCE => $rpt_section_tmpl };
	#}

	#croak "template parameter requires hash reference." unless(ref($tmpl_section) eq 'HASH');

	$self->SUPER::stringify($acct, $section_titles, $tmpl, $tmpl_section);
#
#	my $colnames = $self->colnames;
#	my $displaynames = $self->displaynames;
#	my $positions = $self->position;
#	my $rows = $self->rows->{$acct} || undef;
#	
#	#while(my ($k1, $v1) = each %$rows)
#	return $rpt_result unless $rows;
#	foreach my $k1 (sort sort_sections keys %$rows)
#	{
#		my $v1 = $rows->{$k1};
#		unless($k1 eq '_SUMMARY_')
#		{
#			my $row_result = '';
#
#			foreach my $k2 (sort sort_ids keys %$v1)
#			{
#				my $v2 = $v1->{$k2};
#				foreach my $v3 (@$v2)
#				{
#					$row_result .= $self->stringify_row($v3);
#				}
#			}
#			if($row_result ne '')
#			{
#				my $template = Text::Template->new( %$tmpl_section )
#					or croak "Couldn't construct template: $Text::Template::ERROR";
#
#				croak "unknown section $k1 \n" unless $section_titles->{$k1};
#				my $title = $section_titles->{$k1};
#				my $colheaders = $self->getHeaderStr($k1);
#				my $colseperators = $self->getHeaderSepStr($k1);
#				my $footer = '';
#				my $r = $template->fill_in(HASH => {
#								title		=> \$title,
#								colheaders	=> \$colheaders,
#								colseperators	=> \$colseperators,
#								footer		=> \$footer,
#								content		=> \$row_result,
#								}
#							);
#				$r || croak "Couldn't fill in template: $Text::Template::ERROR.";
#				$result .= $r;
#			}
#		}
#	}
#	#
#	# Machine Report
#	#
#	my $template = Text::Template->new( %$tmpl )
#		or croak "Couldn't construct template: $Text::Template::ERROR";
#	my $header = $self->header;
#	my $footer = '';
#	my $tot = $rows->{'_SUMMARY_'}->{'CHARGE'} || 0;
#	my $total = commify($tot);
#	$rpt_result = $template->fill_in(HASH => {
#					header	=> \$header,
#					content	=> \$result,
#					footer	=> \$footer,
#					total	=> \$total,
#							}
#				);
#					#content	=> \$result,
#	$rpt_result || croak "Couldn't fill in template: $Text::Template::ERROR.";
#	$rpt_result;
}

#sub commify 
#{
#	my $text = reverse $_[0];
#	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
#	return scalar reverse $text;
#}

sub sort_sections
{
	$a cmp $b;
}

sub sort_ids
{
	$a cmp $b;
}

sub stringify_row
{
	my $self = shift;
	my $row = shift;

	#croak "a row of fields is expected but not found \n" unless $row;
	#croak "Array ref expected but not found \n" unless(ref($row) && (ref($row) eq 'ARRAY'));

	my $os_unknown = 'NA';
	my %os_map = (
			'unknown'	=> 'NA',
			'UNKNOWN'	=> 'NA',
			'AIX'		=> 'Unix',
			'A/UX'		=> 'Unix',
			'Amiga-DOS'	=> 'Unix',
			'Andrew'	=> 'Unix',
			'BSDI'		=> 'Unix',
			'DUX'		=> 'Unix',
			'DomainOS'	=> 'Unix',
			'FreeBSD'	=> 'Unix',
			'HP-UX'		=> 'Unix',
			'IOS'		=> 'Unix',
			'Irix'		=> 'Unix',
			'KSTAR'		=> 'Unix',
			'Linux'		=> 'Lnx',
			'LynxOS'	=> 'Unix',
			'MS-DOS/Win'	=> 'Win',
			'MacOS'		=> 'Mac',
			'Mach'		=> 'Unix',
			'NetBSD'	=> 'Unix',
			'NetWare'	=> 'Netw',
			'NewsOS'	=> 'None',
			'NONE'		=> 'None',
			'OS/2'		=> 'None',
			'OSF/1'		=> 'Unix',
			'OpenVMS'	=> 'VMS',
			'QNX'		=> 'None',
			'Solaris'	=> 'Unix',
			'SunOS'		=> 'Unix',
			'System-V'	=> 'Unix',
			'Ultrix'	=> 'Unix',
			'Unix'		=> 'Unix',
			'VMS'		=> 'VMS',
			'VxWorks'	=> 'None',
			'Windows'	=> 'Win',
			'Windows-2K'	=> 'Win',
			'Windows-95'	=> 'Win',
			'Windows-98'	=> 'Win',
			'Windows-NT'	=> 'Win',
			'Windows-XP'	=> 'Win',
			'Windows95'	=> 'Win',
		);
	my %chargeby_map = (
			'L'	=> 'User',
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
			#"%-18s %9s %-10s %-4s %-10s %-12s %3s %6s %3s\n",
			#"%-18s %9s %-10s %-4s %-10s %-12s %3s %6s\n",
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
				sprintf("%s",substr( ($os_map{$row->[$colnames->{$positions->{4}}]} || $os_unknown), 0, abs($colwidth->{$positions->{4}}))),
				sprintf("%s",$col_vals[5]),
				sprintf("%s",$col_vals[6]),
				sprintf("%3.0f",$col_vals[7]),
				sprintf("%3.02f",$col_vals[8]),
				sprintf("%s",$row->[$colnames->{'CHANGE_FLAG'}])
				);
		} else {
			  sprintf(
				"$fmt %3s\n",
				sprintf(" " x abs($colwidth->{$positions->{0}})),
				sprintf(" " x abs($colwidth->{$positions->{1}})),
				sprintf("%s",$col_vals[2]),
				sprintf("%s",$chargeby_map{$col_vals[3]}),
				sprintf("%s",substr( ($os_map{$row->[$colnames->{$positions->{4}}]} || $os_unknown), 0, abs($colwidth->{$positions->{4}}))),
				sprintf("%s",$col_vals[5]),
				sprintf("%s",$col_vals[6]),
				sprintf("%3.0f",$col_vals[7]),
				sprintf("%3.02f",$col_vals[8]),
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
				sprintf("%s",substr( ($os_map{$row->[$colnames->{$positions->{4}}]} || $os_unknown), 0, abs($colwidth->{$positions->{4}}))),
				sprintf("%s",$col_vals[5]),
				sprintf("%s",$col_vals[6]),
				sprintf("%3.0f",$col_vals[7]),
				sprintf("%3.02f",$col_vals[8])
			);
	} else {
		sprintf(
			"$fmt\n",
				sprintf("%s",$col_vals[0]),
				sprintf("%s",$col_vals[1]),
				sprintf("%s",$col_vals[2]),
				sprintf("%s",$col_vals[3]),
				sprintf("%s",$col_vals[4]),
				sprintf("%s",$col_vals[5]),
				sprintf("%s",$col_vals[6]),
				sprintf("%3.0f",$col_vals[7]),
				sprintf("%3.02f",$col_vals[8])
			);
	}
	
	#if(uc($row->[$colnames->{'REASON'}]) eq 'CHANGED')
	#{
	#	if (uc($row->[$colnames->{'CHANGE_FLAG'}]) eq 'NEW')
	#	{
	#	  sprintf(
	#		"$fmt %3s\n",
	#		sprintf("%s",substr($row->[$colnames->{$positions->{0}}], 0, abs($colwidth->{$positions->{0}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{1}}], 0, abs($colwidth->{$positions->{1}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{2}}], 0, abs($colwidth->{$positions->{2}}))),
	#		sprintf("%s",substr( ($os_map{$row->[$colnames->{$positions->{3}}]} || $os_unknown), 0, abs($colwidth->{$positions->{3}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{4}}], 0, abs($colwidth->{$positions->{4}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{5}}], 0, abs($colwidth->{$positions->{5}}))),
	#		sprintf("%3.0f",$row->[$colnames->{$positions->{6}}]),
	#		sprintf("%3.02f",$row->[$colnames->{$positions->{7}}]),
	#		sprintf("%s",$row->[$colnames->{'CHANGE_FLAG'}])
	#		);
	#	} else {
	#	  sprintf(
	#		"$fmt %3s\n",
	#		sprintf(" " x abs($colwidth->{$positions->{0}})),
	#		sprintf(" " x abs($colwidth->{$positions->{1}})),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{2}}], 0, abs($colwidth->{$positions->{2}}))),
	#		sprintf("%s",substr( ($os_map{$row->[$colnames->{$positions->{3}}]} || $os_unknown), 0, abs($colwidth->{$positions->{3}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{4}}], 0, abs($colwidth->{$positions->{4}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{5}}], 0, abs($colwidth->{$positions->{5}}))),
	#		sprintf("%3.0f",$row->[$colnames->{$positions->{6}}]),
	#		sprintf("%3.02f",$row->[$colnames->{$positions->{7}}]),
	#		sprintf("%s",$row->[$colnames->{'CHANGE_FLAG'}])
	#		);
	#	}
	#} else {
	#	  sprintf(
	#		"$fmt\n",
	#		sprintf("%s",substr($row->[$colnames->{$positions->{0}}], 0, abs($colwidth->{$positions->{0}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{1}}], 0, abs($colwidth->{$positions->{1}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{2}}], 0, abs($colwidth->{$positions->{2}}))),
	#		sprintf("%s",substr( ($os_map{$row->[$colnames->{$positions->{3}}]} || $os_unknown), 0, abs($colwidth->{$positions->{3}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{4}}], 0, abs($colwidth->{$positions->{4}}))),
	#		sprintf("%s",substr($row->[$colnames->{$positions->{5}}], 0, abs($colwidth->{$positions->{5}}))),
	#		sprintf("%3.0f",$row->[$colnames->{$positions->{6}}]),
	#		sprintf("%3.02f",$row->[$colnames->{$positions->{7}}])
	#		);
	#}
}


1;
__END__


=head1 NAME

CMUCS::Rams::Report::ChargeChange::Machines - Perl extension for blah blah blah

=head1 SYNOPSIS

  use CMUCS::Rams::Report::ChargeChange::Machines;
  blah blah blah

=head1 DESCRIPTION

	Stub documentation for CMUCS::Rams::Report::ChargeChange::Machines

=head2 EXPORT

	None by default.


=head1 AUTHOR

	Longjiang Yang, E<lt>yangl@cs.cmu.eduE<gt>

=head1 SEE ALSO

L<perl>.

=cut
