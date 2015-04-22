#!perl -w

use strict;
#
# ADO doesn't support multiple statements/SQL batches.
# use ODBC which supports SQL batches.
#
use DBD::ODBC;
#use DBD::ADO;
use DBI qw(:sql_types);
use Data::Dumper;
use Getopt::Long;
use File::Basename;
use Text::Template;

#use lib 'c:\data\Work\perl\lib';
use lib 'C:\Data\misc\Perl\src\lib';

#use BBY::DBCommon qw(td_connect td_show %gTeradata_Data_Type_Map);
use BBY::DBCommon qw(%gTeradata_Data_Type_Map);
use BBY::Common qw($gLogFileDir notifyMe setLogFileDir getLogFileName strUnix2Dos);
use BBY::mailer qw/mail_user $mail_suppress/;


my $debug = 0;
my $gTPTTemplateFile = 'template_sql2csv.tpt';
my $gPrintDDL = 0;
my $gDDLTemplateFile = 'template_ddl.sql';

my $gDatafile = 'get_ddl.dat';
my $gErrfile = 'get_ddl.err';

my $gMailer = 'C:\BBY\OUTPOST\EXE\SmtpEmailer.exe';
my $gMyEmail = 'longjiang.yang@bestbuy.com';
my $gAdminEmail = 'RASCDBMonitor@bestbuy.com';


sub main
{
	my $tbl = shift;
	my $printDDL = shift || 0;

	$tbl =~ /(\w+)\.(\w+)$/;
	my ($dbname, $tblname) = ($1, $2);

	print "DB=$dbname, TBL=$tblname, $tbl\n" if $debug;

	#my @drivers = DBI->available_drivers;
	#print Dumper(\@drivers);

        #TBEND_OF_DGTL_ITEM_RATING 
        #my @tbl_list=qw(TBEND_OF_DGTL_ITEM_AVL TBEND_OF_DGTL_ITEM TBEND_OF_DGTL_ITEM_ATTR TBEND_OF_DGTL_ITEM_CURR_PRC   TBEND_OF_DGTL_ITEM_GAME       TBEND_OF_DGTL_ITEM_MOV TBEND_OF_DGTL_ITEM_MOV_ARTIST TBEND_OF_DGTL_ITEM_MOV_AWRD        TBEND_OF_DGTL_ITEM_MOV_RATING TBEND_OF_DGTL_ITEM_REG_PRC    TBEND_OF_DGTL_ITEM_RGHT       TBEND_OF_DGTL_ITEM_RQRMT      TBEND_OF_DGTL_ITEM_UPC        TBEND_OF_DGTL_MULT_OCC        TBEND_OF_DGTL_RELSHP);
        #my @tbl_list=qw(TBEND_OF_DGTL_ITEM_AVL TBEND_OF_DGTL_ITEM);
        #my @tbl_list=qw(TBEND_SA_DCNT);

	
	my $dsn = 'Provider=TdOleDb.1;Data Source=BBY2;User ID=A645276;Password=hjkbnm;Connect Timeout=120;Session Character Set=UTF8;Enable Parser=No;';
	
	# DBD::ODBC has bugs which messes up encoding
	my $dbh = DBCommon::connect('DBI:ODBC:Production Teradata', 'A645276', 'hjkbnm');
	#my $dbh = DBCommon::connect("DBI:ADO:$dsn", '', '');
	#my $dbh = DBCommon::connect('dbi:ODBC:Driver={SQL Server Native Client 10.0};Server=DVQ17DB02,63519;Database=PRFDB001;Trusted_Connection=yes;', '', '');
	#my $dbh = DBCommon::connect('dbi:ADO:Provider=msdaora;Data Source=MKTG_PROD;User ID=U29PRPA;Password=iom;', '', '');
	
	
	Common::setLogFileDir('C:\temp');
	
	#print Common::getLogFileName($0);
	
	#   my $sth = $dbh->prepare("
	#SELECT 'create table prodbbyRASCTMECC.' || trim(x.TableName) 
	#|| ' AS ' || trim(x.TableName) 
	#|| ' With data and statistics' 
	#|| '; /*** ' || x.CreatorName || ' */'
	#  FROM DBC.TABLES x
	# WHERE x.DatabaseName = ?
	#   AND x.CreatorName = user
	#   ");


	# delete existing data file if exists.
	#unlink $gDatafile if -e $gDatafile;

		#print STDERR "table=$tbl\n"; #if($verbose);
		#print STDERR "MAIN-", Dumper($dependent), "\n";
        #print STDERR DBCommon::getDDL($dbh, $tbl, 'Table', 'ProdBBYDB');
	my @columns = DBCommon::td_desc($dbh, $tbl);
	print STDERR Dumper(\@columns) if $debug;

	$dbh->commit();
	
		#select databasename, tablename, creatorName from dbc.tables where 
	
	$dbh->disconnect();

	my %TypeMapping = (
			'INTEGER'	=> 'VARCHAR(16)',
			'SMALLINT'	=> 'VARCHAR(8)',
			'BYTEINT'	=> 'VARCHAR(3)',
			'BIGINT'	=> 'VARCHAR(24)',
			'FLOAT'		=> 'VARCHAR(24)',
			'TIMESTAMP'	=> 'VARCHAR(30)',
			'DATE'		=> 'VARCHAR(16)',
		);

	if ($printDDL)
	{
		(-f $gDDLTemplateFile) or die "Template file $gDDLTemplateFile doesn't exist!";

		my $template = Text::Template->new(TYPE => 'FILE', SOURCE => "$gDDLTemplateFile" );

		my $ddl_script_text = $template->fill_in(HASH => { columns	=> \@columns, table => $tblname });

		$ddl_script_text || die "Couldn't fill in template: $Text::Template::ERROR.";

		print $ddl_script_text, "\n";
	} else {

		foreach my $col (@columns)
		{
				if (defined($TypeMapping{$col->{'Type'}}) )
				{
					$col->{'TPT_Schema_Type'} = $TypeMapping{$col->{'Type'}};
				} elsif ($col->{'Type'} =~ /^VARCHAR/) {
					$col->{'TPT_Schema_Type'} = $col->{'Type'};
				} elsif ($col->{'Type'} =~ /^CHAR/) {
					$col->{'TPT_Schema_Type'} = 'VAR' . $col->{'Type'};
				} elsif ($col->{'Type'} =~ /^DECIMAL/) {
					$col->{'TPT_Schema_Type'} = 'VARCHAR(' . ( $col->{'Decimal Total Digits'} + 2 ) . ')';
				} else {
					$col->{'TPT_Schema_Type'} = 'VARCHAR(' . ( $col->{'Max Length'} <= 30 ? 30 : $col->{'Max Length'} ) . ')';
				}
		}

		print STDERR Dumper(\@columns) if $debug;

		(-f $gTPTTemplateFile) or die "Template file $gTPTTemplateFile doesn't exist!";

		my $template = Text::Template->new(TYPE => 'FILE', SOURCE => "$gTPTTemplateFile" );

		my $tpt_script_text = $template->fill_in(HASH => { columns	=> \@columns, table => $tbl });

		$tpt_script_text || die "Couldn't fill in template: $Text::Template::ERROR.";

		print $tpt_script_text, "\n";
	}

}	# end of main

if ($#ARGV < 0 ) {
	print "usage: $0 [-d] databasename.tablename\n";
	print "-d	: print DDL";
	exit;
}

#print $ARGV[0];
my $dbtbl = shift;

if($dbtbl eq '-d')
{
	$gPrintDDL = 1 ;
	$dbtbl = shift;
}
 
#main($ARGV[0]) ;
main($dbtbl, $gPrintDDL) ;

1;
# vim:ts=4 sw=4 ft=perl
