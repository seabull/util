#!/usr/local/bin/perl58 -w

#
# $Id: report4pi.pl,v 1.20 2008/04/17 19:51:44 yangl Exp $
#

use Carp;
use Text::Template;
use Pod::Usage;
use Getopt::Long;
use Data::Dumper;
use File::Basename;
use File::Path;
use File::Copy;
use Cwd;
use Cwd 'abs_path';

use lib "/afs/cs.cmu.edu/project/fac-rams/scripts/pireports/lib/omega/perl5";
use mailer;

my $ORAHOME = $ENV{'ORACLE_HOME'} || '/usr1/app/oracle/product/9.2';
my $oraconn = '/@hostdb.fac.cs.cmu.edu';

my $verbose = 0;
my $help = 0;
my $andrew = 0;

my $data_dir = '/afs/cs/project/fac-rams/data/pireport/logs';
my $script_home = abs_path(dirname(abs_path("$0")));
my $sql_template_dir = abs_path("$script_home/../sql");
my $maildomain = 'cs.cmu.edu';
my $xls_templatefile = "$sql_template_dir/template.xls";

my $timestamp = `date "+%Y-%m-%d-%H-%M-%S"`;
my $LOGFD = \*STDERR;

my $mail_content_header = " ";

my $acct_seperator = '-';
my $gm_template = qr/^\s*(\d{3,5})$acct_seperator([0-9a-zA-z\.]{1,4})$acct_seperator(\d){6,8}\s*$/;
my $gl_template = qr/^\s*(\d{6,7})$acct_seperator(\d{3})$acct_seperator(\d{3})$acct_seperator(\d){6}$acct_seperator(\d{2})\s*$/;
my $useracct_template = qr/^[0-9a-zA-Z_]+$/;


=pod

=head1 NAME

report4pi.pl      - Main script to generate PI charge reports

=head1 SYNOPSIS

B<report4pi.pl> [options] <username>

The following common options are supported for all commands.

    --andrew            :
     -a                 : username argument is considered Andrew username
                          it is considered SCS username without this option specified.

    --conn <connstring> :
     -c <connstring>    : specifiy database connection string
        
    --workdir           :
    -d '<directory>'    : working directory, you need to have write access
                          default /afs/cs/project/fac-rams/data/pireport/logs

    --months <integer>  :
     -n  <integer>      : positive integer - number of month to retrieve
                          0                - current Fiscal Year (DEFAULT)
                          negative integer - number of fiscal years before current FY
                          
    --mailto '<email_address>'  :
     -t '<email_address>'       : email address to send reports to

    --mailcc '<email_address>'  : email CC address

    --verbose                   :
     -v                         : verbose output

    --help                      :
     -h                         : This help page.

=head1 DESCRIPTION

Script to generate all details report and charge summary pivot report for specified PI 
and email to Computing Facilities users.

=head1 FUNCTIONS

=cut


        #'SCRIPTDIR' =>  $script_home,
my %rptopts = (
        'CONNECT'   =>  $oraconn,
        'WORKDIR'   =>  $data_dir,
        'MONTHS'    =>  0,
        'MAILTO'    =>  '',
        'MAILCC'    =>  'yangl+pireport@cs.cmu.edu',
    );
        #'PRINC'     =>  '',
        #'PRINCFILE' =>  '',

sub usage(;$) {
    my $msg = shift || "";

    print '*****:'.$msg."*****\n";

    pod2usage( {
                    -message        => $msg,
                    -exitval        => 1,
                    -verbose        => 3,
                }
            );
}

sub parse_opts() {

                        #'scriptdir=s'   => \$rptopts{'SCRIPTDIR'},
        GetOptions( 
                        'conn|c=s'      => \$rptopts{'CONNECT'},
                        'workdir|d=s'   => \$rptopts{'WORKDIR'},
                        'months|n=i'    => \$rptopts{'MONTHS'},
                        'mailto|t=s'    => \$rptopts{'MAILTO'},
                        'mailcc=s'      => \$rptopts{'MAILCC'},
                        'andrew|a'      => \$andrew,
                        'verbose|v+'    => \$verbose,
                        'help|h'        => \$help,
                ) 
                        #'princ|p=s'     => \$rptopts{'PRINC'},
                        #'princfile|f=s' => \$rptopts{'PRINCFILE'},
            or pod2usage( {
                        -message        => 'Option is not supported',
                        -exitval        => 1,
                        -verbose        => 0,
                          }
                        );

        $rptopts{'MAILTO'}  = default_email() unless $rptopts{'MAILTO'};
        if($verbose) {
            logmsg(1, undef, '********' . "\n");
            map { logmsg(1, undef, '**' . $_ . '=' . $rptopts{$_} . "\n"); } (sort keys %rptopts) ;
            logmsg(1, undef, '********' . "\n");
        }

        usage('Usage:') if $help;

        chomp($timestamp);
        $data_dir       = "$rptopts{'WORKDIR'}/$timestamp";
        $oraconn        = "$rptopts{'CONNECT'}";
        $rptopts{'MONTHS'}    = fy2months($rptopts{'MONTHS'});
        #$script_home    = $rptopts{'SCRIPTDIR'};
        chomp($data_dir);

        logmsg(1, undef, "Using connection : oraconn=$oraconn \n");
        logmsg(1, undef, "data_dir=$data_dir \nscript_home=$script_home\n") if $verbose;
        logmsg(1, undef, "sql_template_dir=$sql_template_dir \n") if $verbose;
        logmsg(1, undef, "months=$rptopts{'MONTHS'} \n") if $verbose;
}

sub validateOracleString {
    my $acct_string = shift;

    my $rtn = 0;

    $rtn = 1 if($acct_string =~ $gm_template || $acct_string =~ $gl_template);

    $rtn;
}

sub validateUsername {
    my $username = shift;

    my $rtn = 0;

    $rtn = 1 if($username =~ $useracct_template);

    $rtn;
}

sub isAndrewUsername {
    $andrew > 0;
}

sub pi_rpt_gen {
    my $dirname = shift;
    my $princ   = shift;
    my $sqltemplate = shift;

    my $sqlcmd = 'report.sql';

    if (isAndrewUsername($princ)) {
        $sqlcmd = 'report_byandrew.sql';
        logmsg(1, undef, "Using andrew username... \n");
        #print "Using andrew username...\n";
    }
    $sqlcmd = 'report_byacctstr.sql' if (validateOracleString($princ) > 0);

    $dirname || croak "pi_rpt_gen : Work directory not specified where expected";

    ( -d $dirname && -w $dirname ) 
            or croak "pi_rpt_gen : $dirname is not a directory or not write-able";

    ( -r "$sqltemplate/$sqlcmd" ) 
            or croak "pi_rpt_gen : $sqltemplate/$sqlcmd is not readable";

	$ENV{'ORACLE_HOME'} = "$ORAHOME";
	system("$ORAHOME/bin/sqlplus", "-s", "$oraconn"
                , "\@$sqltemplate/$sqlcmd"
                , "$dirname"
                , "$princ"
                , "$rptopts{'MONTHS'}"
            )
		&& croak "Error executing $ORAHOME/bin/sqlplus $oraconn \@$sqltemplate/$sqlcmd $dirname $princ - $? $! \nMore error data in $dirname";

}

sub details_rpt_gen {
    my $dirname = shift;
    my $princ   = shift;
    my $sqltemplate = shift;

    my $sqlcmd = 'alldetail.sql';
    if (isAndrewUsername($princ)) {
        $sqlcmd = 'alldetail_byandrew.sql';
        logmsg(1, undef, "Using andrew username... \n");
        #print "Using andrew username...\n";
    }
    $sqlcmd = 'alldetail_byacctstr.sql' if (validateOracleString($princ) > 0);

    $dirname || croak "pi_rpt_gen : Work directory not specified where expected";

    ( -d $dirname && -w $dirname ) 
            or croak "pi_rpt_gen : $dirname is not a directory or not write-able";

    ( -r "$sqltemplate/$sqlcmd" ) 
            or croak "details_rpt_gen : $sqltemplate/$sqlcmd is not readable";

	$ENV{'ORACLE_HOME'} = "$ORAHOME";
	system("$ORAHOME/bin/sqlplus", "-s", "$oraconn"
                , "\@$sqltemplate/$sqlcmd"
                , "$dirname"
                , "$princ"
                , "$rptopts{'MONTHS'}"
            )
		&& croak "Error executing $ORAHOME/bin/sqlplus $oraconn \@$sqltemplate/$sqlcmd $dirname $princ - $? $! \nMore error data in $dirname";
}


sub default_email() {
    return getpwuid("$<") . '+@' ."$maildomain";
}

# do some simple email validation
# we could use Data::Validate::Email instead
sub validate_email($) {
    my $mailaddr = shift;

    $mailaddr and 
        $mailaddr =~ /\b[A-Z0-9._%-]+\+?[A-Z0-9._%-]*@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}\b/i ;
}

#
#   non-positive numbers : fiscal years i.e.    0   : current FY
#                                               -1  : last FY
#   positive numbers    : number of months      0   : current month
#                                               1   : last month
#
sub fy2months {
    my $months = shift || 0;
    
    #TODO: should make sure months is numeric here.

    #
    # we could use DateTime::Fiscal::Year module but do it manually for now.
    #
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = localtime();

    $months > 0 ?
                $months : ( $mon < 6 ? 
                            -$months * 12 + (6 + $mon) : -$months * 12 + $mon - 6
                        );
}

sub test_oraconn {
    my $ora_home = shift || "$ORAHOME";
    my $conn_str = shift || "$oraconn";

    my $test_result=17;

    my $sqlcode=<<"END_SQL";
whenever sqlerror exit 1
set heading off
set feedback off
select 15+2 from dual;
END_SQL

    my ($rtn, $rtn_code);

    $rtn = `echo "$sqlcode" | $ORAHOME/bin/sqlplus -s $conn_str 2>&1 > /dev/null`;
    #logmsg(1, undef, "$ORAHOME/bin/sqlplus -s /\@$conn_str \n");

    $rtn_code = $?;

    !$rtn_code;
}

sub krbccfile()
{
    return $ENV{'KRB5CCNAME'} || "/tkt/".getuid()."-krbcc.krb5";
}

sub get_tkt(;$$)
{
    my ($kinit, $user) = @_;

    $user = ($ENV{'USER'} || getlogin() || getpwuid($<) )  unless $user;
    $kinit = "/usr/local/bin/kinit --fcache-version=3 " unless $kinit;

    #$keytab = "" unless $keytab;

    print "Please authenticate:\n" ;
    # system(" okdstry ") ;

    system(" $kinit $user " ) ;
}

sub logmsg {
        my $level = shift;
        my $FD = shift || $LOGFD || \*STDERR;
        my @msg = @_;

        $level  or $level = 0;

        $verbose or $verbose = 0;

        #$| = 1;
        #if($level <= $CmdOptions{'VERBOSE'} + 1)
        if($level <= $verbose + 1)
        {
                #my $timestr = DateTime::str2ts_neat("now", "%02s-%3s-%s %02s.%02s.%02s : ");

                #print $FD "\n$timestr".join("\n$timestr", @msg);
                print $FD join("\n\t", @msg);
        }
}


#main
{
    parse_opts;

    my $l_princ = shift @ARGV;
    my $l_workdir = "$data_dir";
    my $tries = 3;
    my $wd_created = 0;

    usage("princ (user name) or oracle string is required:") unless $l_princ;
    usage("argument is not a valid username or oracle string:")
        unless (validateOracleString($l_princ) > 0 || validateUsername($l_princ) > 0);

    logmsg(1, undef, "Testing oracle connections... \n");

    # need to check connection here first
    unless (test_oraconn()) {
        $tries--;
        get_tkt();
    }

    if (!$tries) {
        logmsg(1, undef, "Failed connecting to database ");
        croak "Failed connecting to database ";
    }
    
    logmsg(1, undef, "Succeeded connecting to oracle... \n");

    # validate emails?


    # prepare work directories
    
    logmsg(1, undef, "Using work directory $l_workdir\n");

    unless ( -d $l_workdir ) {
        logmsg(1, undef, "Creating working directory $l_workdir\n");
        mkdir $l_workdir 
            or croak "Error creating work directory $l_workdir - $!";
        $wd_created = 1;
    }

    # generate reports for each PI
    logmsg(1, undef, "Generating PI report for $l_princ\n");
    pi_rpt_gen($l_workdir, $l_princ, $sql_template_dir);

    #copy over the xls template file
    copy("$xls_templatefile","$l_workdir/$l_princ.xls");   

    # generate all details reports
    logmsg(1, undef, "Generating details report for $l_princ\n");
    details_rpt_gen($l_workdir, $l_princ, $sql_template_dir);

    # zip and mail the reports
    my $l_cwd = getcwd();
    my $l_workdir_base = basename("$l_workdir");
    my $l_workdir_home = dirname("$l_workdir");

    chdir "$l_workdir/.." or croak "Failed changing directory to $l_workdir - $!";
    
    logmsg(1, undef, "Packing all reports for $l_princ\n");
    if ( -x "/usr/local/bin/gtar" ) {
            `/usr/local/bin/gtar zcvf $l_workdir_base.tgz $l_workdir_base`;
    } elsif ( -x "/bin/gtar" ) {
            `/bin/gtar zcvf $l_workdir_base.tgz $l_workdir_base`;
    } elsif (-x "/usr/bin/gtar" ) {
            `/usr/bin/gtar zcvf $l_workdir_base.tgz $l_workdir_base`;
    } else {
            logmsg(1, undef, "Couldn't find gtar!\n");
            croak "Couldn't find gtar!";
    }

    if ($wd_created) {
        logmsg(1, undef, "Removing work directory $l_workdir\n") if $verbose;
        rmtree($l_workdir);
    }

    my $l_eol       = "\r";
    my $mailfrom    = default_email() || 'longjiang.yang@cs.cmu.edu';
    my $subject     = "Reports for PI $l_princ generated - $timestamp";
    my $mailcontent = << "END_MAILCONTENT";
$mail_content_header
The attachment contains the reports for PI $l_princ.$l_eol
Please unzip and _extract_ the attached file to your local harddisk.$l_eol
Brief description of the files:$l_eol
$l_princ.xls            - PI report $l_eol
${l_princ}_u1.csv         - All user details report for $l_princ $l_eol
${l_princ}_m1_withos.csv  - All machine details report for $l_princ $l_eol
${l_princ}_u1_adjustments.csv
                          - All user details report adjustment transactions for $l_princ $l_eol
${l_princ}_m1_withos_adjustments.csv
                          - All machine details report adjustment transactions for $l_princ $l_eol
END_MAILCONTENT

    logmsg(1, undef, "Email result file: $l_workdir_home/$l_workdir_base"."_tar\n");
    my $rtn = mailer::mail_attachments(
                        {
                                'Return-Path'   => "$mailfrom",
                                To              => "$rptopts{'MAILTO'}",
                                From            => "$mailfrom",
                                Sender          => "$mailfrom",
                                Cc              => "$rptopts{'MAILCC'}",
                                Bcc             => 'ramscya+@cs.cmu.edu',
                                'Reply-To'      => "$mailfrom",
                                'X-Rams-Mode'   => 'beta',
                                Type            => 'Text',
                                Subject         => "$subject",
                                Data            => "$mailcontent",
                        },
                        {
                                Type            => 'application/x-compressed',
                                Disposition     => 'attachment',
                                Path            => "$l_workdir_home/$l_workdir_base".".tgz",
                                Filename        => "$l_workdir_base".".tgz"
                        }
                        );
                                #Type            => 'x-gzip',
                                #Encoding        => 'base64',

    logmsg(1, undef, "Email result : $rtn\n");

    chdir "$l_cwd" 
            or logmsg(1, undef, "Failed changing directory back to $l_cwd - $!");

}

1;

__END__

=pod

=head1 EXAMPLES

0. this help page

report4pi -h

1. retrieve reports for PI abc  for current Fiscal Year

report4pi abc

2. retrieve reports for PI abc  for last month

report4pi -n 1 abc

3. retrieve reports for PI abc  for last FY and current FY

report4pi -n -1 abc

4. retrieve reports for PI abc  for current FY and send email to johndoe@cs.cmu.edu

report4pi -t 'johndoe@cs.cmu.edu' abc


=head1 AUTHOR

Longjiang Yang, E<lt>yangl+@cs.cmu.eduE<gt>

=head1 COPYRIGHT

        School of Computer Science
        Carnegie Mellon University

=head1 SEE ALSO

L<Perl>

=cut

