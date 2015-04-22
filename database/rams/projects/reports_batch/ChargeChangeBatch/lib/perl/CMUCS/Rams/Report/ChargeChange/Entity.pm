package CMUCS::Rams::Report::ChargeChange::Entity;

use 5.006;
use strict;
use Carp;

use Data::Dumper;
use Text::Template;

our $VERSION = '0.01';

my $rpt_template = q!
{$header}
{sprintf('*'x74);}
{$content}
Net changes for users : $ {sprintf "%s", $total}
{$footer}
!;

my $rpt_section_tmpl = q!
{sprintf('-'x20)}
{$title}
{sprintf('-'x20)}
{$colheaders}
{$colseperators}
{$content}
{$footer}
!;

=pod

=head1 NAME

CMUCS::Rams::Report::ChargeChange::Entity - Perl extension for blah blah blah

=head1 SYNOPSIS

  use CMUCS::Rams::Report::ChargeChange::Entity;
  blah blah blah

=head1 DESCRIPTION

	Stub documentation for CMUCS::Rams::Report::ChargeChange::Entity

=head1 EXPORT

=over

=item new

=back

=cut

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my $header = "Entity Charges Changed";

	#--------------------------------------- 
	#
	# colnames	= { 'colname1' => 0, 'colname2' => 1, ...};
	#
	# displaynames	= { 	'colname1' => 'dispname1', 
	#			'colname2' => displayname2', ...};
	#
	# position	= { 0 => 'colname1', 1 => 'colname1', ... };
	#
	# colwidths	= { 'colname1' => 5, 'colname2' => 20, ...};
	#
	# rows		= { '3584-2-5001121' => [ 
	#						[ 'col1_data', 'col2_data',...  ], 
	#						[ ... ], 
	#						[...], 
	#						...
	#					],
	#			'other acct' => [ [],[], ]
	#		};
	#	
	#--------------------------------------- 
	my $self = {
			type		=> 'Entity',
			header		=> $header,
			colnames	=> undef,
			displaynames	=> {},
			position	=> undef,
			rows		=> {},
			colwidths	=> undef,
			rpt_template	=> { TYPE => 'STRING', SOURCE => $rpt_template },
			rpt_section_tmpl=> { TYPE => 'STRING', SOURCE => $rpt_section_tmpl },
			@_,
		};
	
	#populate default position and displaynames
	if (defined($self->{colnames})) 
	{
		croak "expect hash reference for colnames." unless (ref($self->{colnames}) eq 'HASH');

		map	{ defined($self->{displaynames}->{$_}) 
				or $self->{displaynames}->{$_} = $_;
			} keys %{$self->{colnames}};

		if (!defined($self->{position}))
		{
			my $pos = {};
			map { $pos->{$self->{colnames}->{$_}} = $_;} keys %{$self->{colnames}};
			$self->{position} = $pos;
		}
		if(!defined($self->{colwidths}))
		{
			map	{ $self->{colwidths}->{$_} = 12; } keys %{$self->{colnames}};
		}
	}
	return bless $self, $class;
}

=over

=item commify		- add commas in numeric values, class method

=back

=cut

# add commas in number
sub commify {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my $text = reverse $_[0];
	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
	return scalar reverse $text;
}

sub numerically
{
	$a <=> $b;
}

=over

=item adjustColwidths

=back

=cut

sub adjustColwidths
{
	my $self = shift;

	map { my $len = length($self->{displaynames}->{$_}); $self->{colwidths}->{$_} = 
			( $self->{colwidths}->{$_} > $len ) ? 
					$self->{colwidths}->{$_} : $len ; 
					#$self->{colwidths}->{$_} : length($self->{displaynames}->{$_}); 
		} keys %{$self->{displaynames}};

	$self->{colwidths};
}

=over

=item getHeaderStr

=back

=cut

sub getHeaderStr
{
	my $self = shift;
	my $type = shift || 'Default';
	my %type_map = (
				'Default'	=> '',
				'Changed'	=> 'Notes',
			);

	my $fmt = $self->fmt_string;

	sprintf $fmt, map { qq/$self->{displaynames}->{$self->{position}->{$_}}/ } sort {$a <=> $b} (keys %{$self->{position}});

}

=over

=item getHeaderSepStr

=back

=cut

sub getHeaderSepStr
{
	my $self = shift;
	my $type = shift || 'Default';
	my %type_map = (
				'Default'	=> '',
				'Changed'	=> 'Notes',
			);

	join(' ', 
		map("-" x abs($self->{colwidths}->{$self->{position}->{$_}}), 
			sort {$a <=> $b} (keys %{$self->{position}})
		)
	);
}

=over

=item fmt_string

=back

=cut

sub fmt_string
{
	my $self = shift;

	#print map('%-'.$self->{colwidths}->{$self->position->{$_}}.'s', sort{$a <=> $b} (keys %{$self->{position}}));

	my $pos = $self->position;
	my $width = $self->colwidths;

	croak "position or colwidth not defined" unless($pos && $width);

	#negative width means RIGHT alignment
	join(' ', 
		map { '%'.-$width->{$pos->{$_}}.'s' } 
			sort { $a <=> $b } keys %$pos
		);
}

sub rows_dump
{
	my $self = shift;

	print Dumper($self->rows);
}

sub sort_sections
{
	$a cmp $b;
}

sub sort_ids
{
	$a cmp $b;
}

=over

=item convert

=back

=cut

sub convert
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;

	my ($colnames, $rows, $acct_colname, $key1_colname, $key2_colname, $adjcharge_colname) = @_;

	$acct_colname or $acct_colname = 'ACCT_STRING';
	$key1_colname or $key1_colname = 'REASON';
	$key2_colname or $key2_colname = 'PRINC';
	$adjcharge_colname or $adjcharge_colname = 'ADJUSTEDCHARGE';

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

=over

=item stringify

=back

=cut

# Used by Users only, Machines use their own.
sub stringify
{
	my $self = shift;
	#my $acct = shift || '';
	my $acct = shift ;
	my $section_titles = shift || {
					'Added'		=> $self->type . ' Charges Added for ' . $acct,
					'Changed'	=> $self->type . ' Charges Changed for ' . $acct,
					'Deleted'	=> $self->type . ' Charges No Longer Charged to ' . $acct,
				};
					#'Deleted'	=> $self->type . ' Removed',

	my ($tmpl, $tmpl_section) = @_ ;
	my ($result, $rpt_result) = ('', '');

	croak "account string has to be specified." unless $acct;

	if(!defined($tmpl)) 
	{
		$tmpl = $self->rpt_template || { TYPE => 'STRING', SOURCE => $rpt_template };
	}

	croak "template parameter requires hash reference." unless(ref($tmpl) eq 'HASH');

	if(!defined($tmpl_section)) 
	{
		#print "Use Default Template for Entity.\n";
		$tmpl_section = $self->rpt_section_tmpl || { TYPE => 'STRING', SOURCE => $rpt_section_tmpl };
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
				my $footer = '';
				my $r = $template->fill_in(HASH => {
								title		=> \$title,
								colheaders	=> \$colheaders,
								colseperators	=> \$colseperators,
								footer		=> \$footer,
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
	my $tot = $rows->{'_SUMMARY_'}->{'CHARGE'} || 0;
	#my $total = $self->commify(sprintf("%.02f",abs($tot)));
	my $total = $self->commify(sprintf("%.02f",$tot));
	$rpt_result = $template->fill_in(HASH => {
					header	=> \$header,
					content	=> \$result,
					footer	=> \$footer,
					total	=> \$tot,
					total_str	=> \$total,
					type	=> $self->type,
							}
				);
					#content	=> \$result,
	$rpt_result || croak "Couldn't fill in template: $Text::Template::ERROR.";
	$rpt_result;
}

sub hasEntries
{
	my $self = shift;

	my ($acct) = @_;
	my $cnt = 0;

	croak "Entity::hasEntries:account string has to be specified.\n"
		unless $acct;

	$cnt = 1 if( $self->rows && defined($self->rows->{$acct}) );

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

	#print "Entity::$attr called\n";
	return $val;
}

1;

__END__

=pod

=head1 AUTHOR

	Longjiang Yang, E<lt>yangl@cs.cmu.eduE<gt>

=head1 SEE ALSO

L<perl>.

=cut
