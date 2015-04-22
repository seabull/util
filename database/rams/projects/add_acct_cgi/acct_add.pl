#!/usr/local/bin/perl5 -w
# $Id: acct_add.pl,v 1.4 2005/09/01 15:34:48 yangl Exp $
############################################################

use strict;
use lib qw(lib/perl5);
use lib qw(/usr/local/lib/perl5/site_perl/5.6.1/arch/auto);
use CGI qw/:standard :html :cgi/;
use DBI;
use POSIX qw(strftime);
use IO::Socket;

my $DEBUG = 0;
my @errors=();

my $debug_contents = "";
my $acct_seperator = '-';
my $gm_template = qr/^\s*(\d{3,5})$acct_seperator([0-9a-zA-z\.]{1,4})$acct_seperator(\d){6,8}\s*$/;
my $gl_template = qr/^\s*(\d{6,7})$acct_seperator(\d{3})$acct_seperator(\d{3})$acct_seperator(\d){6}$acct_seperator(\d{2})\s*$/;


####################################
#  access control checking

my $check_access = 1;
my @host_access_list = qw(\.FAC\.CS\.CMU\.EDU$ \.NET\.CS\.CMU\.EDU$);
#my @ip_access_list = qw(^128\.2\.1\.2$ ^128\.2\.1\.3$);
my @ip_access_list = qw();


####################################
#  logging

my $do_logging = 1;
my $logfile = "/usr/costing/log/account_add.log";
#my $logfile = "/tmp/account_add.log";
####################################


############################

my $template_file = "lib/template/acct_add.html";
my $html_space = '&nbsp;';

my $form_action = 
'<form action="acct_add" method="post">';
my $form_action_end = 
' </form>';

my $template_html = "";
my $now = localtime(time());
my %fields;
my $form = new CGI;



sub check_log(;$)
{
	my $file = @_;

	$file = $logfile unless ($file);
	# check that logfile is writable right away
	#if (($do_logging) && ! (-w $logfile)) {
	if (($do_logging) && ! (-w $file)) {
		$do_logging = 0;    # internal_error() calls logit()
		internal_error("Cannot open logfile $file\n");
	}        
}

sub internal_error($) {
	my $error = shift;
	logit($logfile, "INTERNAL ERROR:\n$error\n") if ($do_logging);

	print header;
	print start_html(-Title=>'Internal error in form',
			-BGCOLOR=>'white');
	print h1('Internal error in application');
	print <<END;

An internal error occurred when processing the account add form:
<p>
<strong>$error</strong>
</p>
Please report this error to <a href="mailto:yangl+costing\@cs.cmu.edu">Rams team</a>. 
</p>
<p>
<strong>Your information has not been submitted to SCS Facilities.</strong>
</p>
END
	print end_html;

	exit(0);
}

sub acct_parse($;$)
{
	my ($acct, $sep)=@_;
	my (@acct);

	$sep=$acct_seperator unless defined($sep);

	#my $pta_re=qr/\s*\d+$sep[0-9a-zA-Z\.]{1,4}$sep\d+\s*/;
	#my $gl_re=qr/\s*(\d+)$sep(\d+)$sep(\d+)$sep(\d+)$sep(\d+)\s*/;
	my $pta_re=$gm_template;
	my $gl_re=$gl_template;

	#push @error 'Account format invalid.' unless ($acct =~ $pta_re || $acct =~ $gl_re);
	die 'Account format invalid.' unless ($acct =~ $pta_re || $acct =~ $gl_re);
	@acct=split($sep, $acct);
	#push @error, 'Unrecognized number of segment ('.($#acct+1).') in account string '.$acct
	die 'Unrecognized number of segment ('.($#acct+1).') in account string '.$acct
		unless ($#acct == 4 || $#acct == 2 );
	@acct;
}

# Get the user name from REMOTE_USER environment.
sub get_remoteuser
{
	my $user = $ENV{REMOTE_USER};
	my $domain='CS.CMU.EDU';

	if ($user =~ /^\s*([A-Za-z0-9-+]+)@([A-Za-z0-9-\.]+)\s*$/) {
		#($user,$domain) = split('@', $user, 2);
		$user = $1;
		$domain = $2;
	} elsif ($user =~ /([A-Za-z0-9-+]+)/) {
		$user = $1;
	} else {
		die "bad user name: $user \n", join("\n<br>", map { "$_=".$ENV{$_} } sort keys %ENV), "\n";
	}
	($user, $domain);
}

sub db_connect {
	my $HOME="/usr/costing";
	my $sid;
	$ENV{PATH}="$HOME/bin:/bin:/usr/bin:/usr/ucb:/usr/local/bin";

	# Remote user can be passed to Oracle for audit
	my $user = $ENV{REMOTE_USER};
	my ($CostingHost, $ora_conn);
	my %ora_attr = (
			AutoCommit      => 0,
			PrintError      => 1,
			RaiseError      => 0,
 	);

	if (defined($ENV{COSTING_HOST})) {
		$CostingHost = $ENV{COSTING_HOST};
	} else {
		$CostingHost = 'hostdb.fac.cs.cmu.edu';
	}

	if (defined($ENV{ORA_CONN})) {
		$ora_conn = $ENV{ORA_CONN};
	} else {
		$ora_conn = defined($ENV{ORACLE_SID}) ? $ENV{ORACLE_SID} : 'fac_03';
	}

	#my $data_source = 'DBI:Oracle:'.$sid;
	my $data_source = 'DBI:Oracle:';

	# Turn off auto commit
	my $dbh = DBI->connect($data_source, "/\@$ora_conn", "", \%ora_attr)
		or internal_error("Unable to connect to DB $ora_conn on $CostingHost\n".$DBI::errstr."\n");

	$dbh->{RaiseError} = 1; #turn on automatic error handling

	$dbh;
}

sub insert_acct ($$$) {
	my ($dbh, $acct, $user) = @_;

	my $sql = 'insert into hostdb.accounts (created_by, creation_date, ';

	if ( $#{$acct} == 2 ) {
		$sql .= "project, task, award) values (?,?,?,?,?)";
	} elsif ($#{$acct} == 4 ) {
		$sql .= "funding, function, activity, org, entity) values (?,?,?,?,?,?,?)";
	} else {
		die "Unknown number of account segments in (@{$acct}).";
	}

	my $date = strftime("%d-%b-%Y\n", localtime);

	my $sth = $dbh->prepare($sql);
	unless(defined($sth)) {
		$dbh->disconnect();
		internal_error("Error obtaining statement handle from Database.");
	}
	logit($logfile, $sql."-$user-$date:".join('-',@$acct));
	$sth->execute(($user, $date, @$acct));	#or die sth->errstr;
}

sub update_acct ($$$$) {
	my ($dbh, $acct, $flag, $user) = @_;
	my $sql = "update hostdb.accounts set (flag,last_update_date,last_updated_by)=(";
		#."select ".$dbh->quote($flag), sysdate, $user from dual) ";

	if ($flag eq "v") {
		$sql .= "select null, sysdate, ? from dual) ";
	} else {
		$sql .= "select ".$dbh->quote($flag).", sysdate, ? from dual) ";
	}

	if ( $#{$acct} == 2 ) {
		$sql .= " where project=? and task=? and award=?";
	} elsif ($#{$acct} == 4 ) {
		$sql .= " Where funding=? and function=? and activity=? and org=? and entity=? ";
	} else {
		die "Unknown number of account segments in (@{$acct}).";
	}

	my $sth = $dbh->prepare($sql);
	unless(defined($sth)) {
		$dbh->disconnect();
		internal_error("Error obtaining statement handle from Database.");
	}
	logit($logfile, $sql."-$user:".join('-',@$acct));
	$sth->execute(($user, @$acct));	#or die sth->errstr;
}

sub query_acct
{
	my ($dbh, $acct) = @_;
	my $acct_q = '';

	if ( $#{$acct} == 2 ) {
		$acct_q .= "select project||'-'||task||'-'||award from hostdb.accounts Where project=? and task=? and award=? ";
	} elsif ($#{$acct} == 4 ) {
		$acct_q .= "select funding||'-'||function||'-'||activity||'-'||org||'-'||entity from hostdb.accounts Where funding=? and function=? and activity=? and org=? and entity=? ";
	} else {
		die "Unknown number of account segments in (@{$acct}).";
	}
	unless (defined($dbh)) {
		die "Undefined database handle.";
	}

	#my $acctq_quoted=$dbh->quote($acct_q);
	my $sth = $dbh->prepare($acct_q);

	unless(defined($sth)) {
		$dbh->disconnect();
		internal_error("Error obtaining statement handle from Database.");
	}

	logit($logfile, $acct_q.join('-',@$acct));
	#need to check return value if RaiseError is not set.
	$sth->execute(@$acct);	#or die sth->errstr;

	my ($result) = $sth->fetchrow_array;
	$sth->finish;
	$result;
}

sub query_pta
{
	my ($dbh, $acct)=@_;

	my $PTA_Q =	'SELECT pta '.
			'  FROM HOSTDB.PTA_STATUS '.
			' WHERE pta=?';
	
	die "PTA account @{$acct} does not seem to be in correct format. " unless ($#{$acct} == 2);

	unless (defined($dbh)){
		push @errors,"Undefined database handle.";
		return undef;
	}

	#my $pta_quoted=$dbh->quote($PTA_Q);
	#my $sth = $dbh->prepare($pta_quoted);
	my $sth = $dbh->prepare($PTA_Q);

	unless(defined($sth)) {
		$dbh->disconnect();
		internal_error("Error obtaining statement handle from Database.");
	}
	logit($logfile, $PTA_Q.join('-',@$acct));
	#need to check return value if RaiseError is not set.
	$sth->execute( join($acct_seperator,@{$acct}) );	# or die sth->errstr;

	my ($result) = $sth->fetchrow_array;

	$sth->finish;
	# We know only one row is returned
	$result;
}

#
# slurp in HTML page template file
#
sub slurp_template {
	my $template_file = shift;
	my $lines;
	open(TF, $template_file) or die "Cannot open $template_file\n";
	while (<TF>) {
		$lines .= $_;
	}
	close TF;
	return $lines;
}

#
# accessors to the fields
#
sub getName($) {
	my $f = shift;
	return defined($fields{$f}) ? $fields{$f}->{'name'} : undef;
}

sub getValue($) {
	my $f = shift;

	return defined($fields{$f}) ? $fields{$f}->{'value'} : undef;
}
sub getValid($) {
	my $f = shift;

	return defined($fields{$f}) ? $fields{$f}->{'valid'} : undef;
}
sub getHidden($) {
	my $f = shift;

	return defined($fields{$f}) ? $fields{$f}->{'hidden'} : undef;
}
sub getForm($) {
	my $f = shift;

	return defined($fields{$f}) ? $fields{$f}->{'form'} : undef;
}
sub getDescription($) {
	my $f = shift;

	return defined($fields{$f}) ? $fields{$f}->{'description'} : undef;
}
sub setName($$) {
	my ($f,$val) = @_;
	$fields{$f}->{'name'} = $val;
}

sub setValue($$) {
	my ($f,$val) = @_;

	$fields{$f}->{'value'} = $val;
}
sub setValid($$) {
	my ($f,$val) = @_;

	$fields{$f}->{'valid'} = $val;
}
sub setValidate($$) {
	my ($f,$val) = @_;

	$fields{$f}->{'validate'} = $val;
}
sub setHiddenValue($$) {
	my ($f,$val) = @_;

	update_val($f, 'hidden', $val);
}
sub setFormValue($$) {
	my ($f,$val) = @_;

	update_val($f,'form',$val);
}

sub update_val($$$) {
	my ($f1, $f2, $val) = @_;
	my $h;

	if (exists($fields{$f1}->{$f2})) {
		$h = $fields{$f1}->{$f2};
		$h =~ s/!_value_!/$val/;
		$fields{$f1}->{$f2} = $h;
	} else {
		$h = undef;
	}
	return $h;
}    

# update hidden html for a field using 'value'
# this is different from setHiddenValue
sub update_hidden($) {
	my $f = shift;
	setHiddenValue($f, getValue($f) );
}    

sub initialize_fields {
	my $f = 'acct_string';

	setName($f, 'Acct_String');

	my $val = param(getName($f));
	setValue($f, $val);
	setValid($f, 0);
	setValidate($f, \&validate_acct);

	#$fields{'acct_string'}->{'validate'} = \&validate_acct;
	$fields{$f}->{'description'} = <<'END';
The Oracle Account String to be added. Either a Grant Management account or a General Ledger account should be entered. You can only enter one account at a time. <BR>
e.g. <BR>
12345-1-6789012 or <BR>
000001-001-001-27000-01  
END

	#hidden and form are mutual exclusive since they use the same name
	$fields{$f}->{'hidden'} = 
		'<input type="hidden" name="'.getName($f).'" value="!_value_!">';

	$fields{$f}->{'form'} = 
		'<input type="text" name="'.getName($f).'" value="!_value_!" size="30">';

}

#convert field into html
sub field_html($$;$) {
	my ($blank,$field, $extra_html) = @_;
	my $html = "";
	my $opt = "";
	my $val="";
	my $ff = getForm($field);	

	#$val = $fields{$field}->{'value'} if (!defined($blank));
	$val = getValue($field) if (!defined($blank));
	$val = "" unless defined($val);
	$html .= '<h2>' . getName($field) . '</h2>';
	$html .= '<p>' . getDescription($field) . '</p>';
	$ff =~ s/!_value_!/$val/;
	$html .= $ff . $extra_html . '<br />';
	return $html;
}

sub blank_field_html($) {
	my $field = shift;
	return field_html("blank", $field);
}

sub validate_acct {
	my $oracle_string = $form->param('Acct_String');
	return 0 unless ($oracle_string);

	update_val('acct_string','value',$oracle_string);
	update_hidden('acct_string');

	#if ( $oracle_string =~ m/^(\d{3,5})-([0-9a-zA-z\.]{1,4})-(\d){6,8}\s*$/ 
		#|| $oracle_string =~ m/^(\d{6,7})-(\d{3})--(\d{3})-(\d){6}-(\d{2})\s*$/ 
		#)
	if ($oracle_string =~ $gm_template || $oracle_string =~ $gl_template)
	{
		#$fields{'acct_string'}->{'valid'} = 1;
		update_val('acct_string','valid',1);
		return 1;
	} else {
		#$fields{'acct_string'}->{'valid'} = 0;
		update_val('acct_string','valid',0);
		$fields{'acct_string'}->{'description'} .= <<END;
<p><b>The value you entered:</b><I>  $oracle_string </I><b>  does not appear to be a valid-formatted Oracle string</b></p>
<P>Please contact the RAMS team if you believe the format is valid.</p>
END
		return 0;
	}
}

sub validate_acct_db {
	my $ora_string = $form->param('Acct_String');
	my $ora_string_hidden = getValue('acct_string');

	my $dbh = db_connect();
	
	die "Oracle String changed from $ora_string_hidden to $ora_string unexpectedly." unless ($ora_string eq $ora_string_hidden);
	my @acct = acct_parse($ora_string);

	my $result = query_acct($dbh, \@acct);

	$dbh->disconnect;
}

sub results_to_table_html($;$) {
	my ($results, $titles) = @_;
	my $html = "";
	
	$html .= "\n".'<table valign="top">' . "\n";
	$html .= join(' ',map '<thead valign="top">'.$_.'</thead>\n',@{$titles}) if defined($titles);
	foreach my $f ($results) {
		$html .= "<tr>\n";
		$html .= join(' ',map $_='<td nowrap valign="top"><b>'.$_.'</td>',($f));
		$html .= "</tr>\n";
	}
	$html .= "</table>";
	return $html;
}

sub print_html($$$$) {
	my ($title, $breadcrumb, $h1, $content) = @_;
	my $template = slurp_template($template_file);

	$template =~ s/!_accttitle_!/$title/;
	$template =~ s/!_acctbreadcrumb_!/$breadcrumb/;
	$template =~ s/!_accth1_!/$h1/;
	$template =~ s/!_acctcontent_!/$content/;
	print header;
	print $template;
	return 1;
}    

#
# Views
#
sub page_field_html ($) {
	my ($page_value) = @_;
	my $html = "";

	$html .= '<input type="hidden"  name="page" id="page" value="'.$page_value.'">';
}

sub page_submit_html ($;$) {
	my ($value, $name) = @_;
	$name = defined($name) ? $name : "Submit";
	
	submit(-name=>$name, -value=>$value);
}

sub page1_html(;$) {
	my $page=@_;
	my $html = "";
	my $preamble = <<'END';
<p>
Use this form to add an Oracle Account String into SCS Facility Oracle database.
Once added, you can use the account string in Jeeves costing operations. 
</p>
<p>
This form will do some simple validation check for the account string being added. 
But you should make sure no typos in the account string to avoid polluting the database.
</p>
END

	$html .= $preamble;
	$html .= $form_action;
	my @fields = ('acct_string');

	if (defined($page)) {
		foreach my $f (@fields) {
			$html .= '<hr />' . field_html(undef,$f) . "\n";
		}
	} else {
		foreach my $f (@fields) {
			$html .= '<hr />' . blank_field_html($f) . "\n";
		}
	}
	#$html .= '<input type="hidden"  name="page" id="page" value="1">';
	$html .= page_field_html(1);
	#$html .= '<hr /><input type="submit" name="Submit" Value="Add Acct">';
	$html .= hr.page_submit_html("Add Acct");
	$html .= $html_space.page_submit_html("Unlimbo");
	$html .= $form_action_end;
	return $html;
}

sub page1_error_html {
	my $html = "";
	my $preamble = <<'END';
<p>
Use this form to add an Oracle Account String into SCS Facility Oracle database.
Once added, you can use the account string in Jeeves costing operations. 
</p>
<p>
This form will do some simple validation check for the account string being added. 
But you should make sure no typos in the account string to avoid polluting the database.
</p>
END

	$html .= $preamble;
	$html .= $form_action;
	my @fields = ('acct_string');

	foreach my $f (@fields) {
		my $indicator = "";
		if (!getValid($f)) {
			$indicator = '<font color=#FF0000>*</font>';
		}
		$html .= '<hr />' . field_html(undef, $f, $indicator) . "\n";
	}
	#$html .= '<input type="hidden"  name="page" id="page" value="error1">';
	$html .= page_field_html('error1');
	#$html .= '<hr /><input type="submit" name="Submit" Value="Add Acct">';
	$html .= hr.page_submit_html("Add Acct");
	$html .= $html_space.page_submit_html("Unlimbo");
	$html .= $form_action_end;
	return $html;
}

sub page2a_html {
	my $html = "";
	my $preamble = <<'END';
<p>
The account string you requested.
</p>
END
	$html .= $preamble;
	$html .= $form_action;
	my @fields1 = ('acct_string');
	$html .= fields_to_table_html( @fields1 );
	$html .= "<p>is already in the database. Do you mean <strong>unlimbo</strong>?</P>";
	$html .= $fields{'acct_string'}->{'hidden'};
	#$html .= '<input type="hidden"  name="page" id="page" value="2a">';
	$html .= page_field_html('2a');
	#$html .= '<hr /><input type="submit" name="Submit" Value="Return">';
	$html .= hr.page_submit_html("Return");
	$html .= page_submit_html("Unlimbo");
	$html .= $form_action_end;
	return $html;    
}    

sub page2b_html {
	my ($results) = @_;
	my $html = "";
	my $preamble = <<'END';
<p>
The account string you requested.
</p>
END
	$html .= $preamble;
	$html .= $form_action;
	my @fields1 = ('acct_string');
	$html .= fields_to_table_html( @fields1 );

	if (defined($results)) {
		$html .= "<p>will be added into Fac Oracle Database.</p><hr /><p><BR>Click <b>INSERT</b> button to insert or <BR>use the <b>Cancel</b> button in to cancel..</p>";
		$html .= results_to_table_html($results);
		#$html .= '<input type="hidden"  name="page" id="page" value="2b">';
		$html .= page_field_html('2b');
		#$html .= '<hr /><input type="submit" name="Submit" Value="Insert">';
		$html .= hr.page_submit_html("Insert");
		$html .= $html_space.page_submit_html("Cancel");
	} else {
		$html .= "<p>does <strong>not</strong> seem to be a valid account.";
		$html .= " Please verify with the customer or contact <b>RAMS</B> group if you want to add it anyway.</P>";
		#$html .= '<input type="hidden"  name="page" id="page" value="2a">';
		$html .= page_field_html('2a');
		#$html .= '<hr /><input type="submit" name="Submit" Value="Return to Previous Page">';
		$html .= hr.page_submit_html("Return to Previous Page");
	}
	foreach my $f (@fields1) {
		$html .= $fields{$f}->{'hidden'};
	}            
	$html .= $form_action_end;
	return $html;    
}    

sub confirmation_unlimbo_html {
	my $html = "";
	my ($user, $domain) = get_remoteuser();
	my $preamble = << 'END';
<p>
The following account string has been <strong>unlimbo-ed</strong> (i.e. made valid).
Please send comments or report any problems to RAMS group.
</p>
END

	$html .= $preamble;
	$html .= 'Your user ID:'.$user.'@'.$domain;
	$html .= $form_action;
	$html .= '<p><b>'.getValue('acct_string').'</b></p>';
	$html .= page_field_html('confirmation_page');
	$html .= hr.page_submit_html("Return to First Page");
	$html .= $form_action_end;
	return $html;
}
sub confirmation_page_html {
	my $html = "";
	my ($user, $domain) = get_remoteuser();
	my $preamble = << 'END';
<p>
The following account string has been added to the FAC Oracle database.
Please send comments or report any problems to RAMS group.
</p>
END

	$html .= $preamble;
	$html .= 'Your user ID:'.$user.'@'.$domain;
	$html .= $form_action;
	$html .= '<p><b>'.getValue('acct_string').'</b></p>';
	#$html .= '<br /><input type="hidden" name="page" value="confirmation_page">';
	$html .= page_field_html('confirmation_page');
	#$html .= '<hr /><input type="submit" name="Submit" Value="Return to First Page">';
	$html .= hr.page_submit_html("Return to First Page");
	$html .= $form_action_end;
	return $html;
}

sub page2_errorpage_html {
	my $html = "";
	
	$html .= $form_action;
	$html .= <<'END';
<p>
Error happened while updating the database. Please contact the Rams team.
Use &quot;back&quot button on your browser to go back.</p>
END

	$html .= '<hr />';
	#$html .= '<input type="hidden" name="page" value="2a">';
	$html .= page_field_html('2a');
	#$html .= '<hr /><input type="submit" name="Submit" Value="Cancel">';
	$html .= hr.page_submit_html("Cancel");
	$html .= $form_action_end;
	return $html;
}

sub access_denied {
	my $reason = shift;

	print header;
	print start_html(-Title=>'Access denied', -BGCOLOR=>'white');
	print h1('Access denied');
	print <<END;
<p>

Access to this form has been denied for the following reason:
</p>
<p>
<b>
$reason
</b>
</p>
END
	print end_html;
	logit($logfile, "Access denied:\n$reason\n") if ($do_logging);
	exit(0);
}

# some ip-based access control
sub access_check {
	my $ip = $ENV{'REMOTE_ADDR'};
	access_denied("Unable to find out your IP address.\n") unless ($ip);
	#my $hname = gethostbyaddr(inet_aton($ip), 'AF_INET');
	my $hname = gethostbyaddr(inet_aton($ip), AF_INET);
	my ($ok_host, $ok_ip) = (0,0);

	unless (defined $hname) {
		access_denied("Unable to resolve your IP address, $ip\n");
	}
	$hname = uc($hname);
	$ok_host = 0;
	foreach my $h (@host_access_list) {
		if ($hname =~ m/$h/) {
			$ok_host = 1;
			last;
		}
	}
	$ok_ip = 0;
#	foreach my $i (@ip_access_list) {
#		if ($ip =~ m/$i/) {
#			$ok_ip = 1;
#			last;
#        	}
#	}
	unless ($ok_host or $ok_ip) {
		access_denied("Access denied for hostname: $hname\n") unless ($ok_host);
		access_denied("Access denied for ip address: $ip\n") unless ($ok_ip);
	}        
	return 1;
}

# logging
# 
sub logit {
	return 0 unless ($do_logging);

	my ($logfile, $message) = @_;
	$message = "logit() called with no message\n" unless ($message);

	unless (open(LOGFILE, ">>$logfile")) {
		$do_logging = 0;    # internal_error calls logit():
		internal_error("Cannot open logfile\n");
	}        
	my $now = localtime(time());
	my $host = $ENV{'REMOTE_ADDR'};
	$host = 'UNKNOWN' unless ($host);
	my ($user, $domain) = get_remoteuser();
	print LOGFILE "\n\n+++++ $now - User:$user\@$domain - From: $host - Account Add\n\n";
	print LOGFILE $message;
	close LOGFILE;
}    

sub verify_fields($) {
	my $f = shift;
	
	my $field_ok = &{$fields{$f}->{'validate'}};
	return $field_ok;
}    

sub fields_to_table_html {
	my @fields = @_;
	my $html = "";
	$html .= '<table valign="top">' . "\n";
	foreach my $f (@fields) {
		$html .= "<tr>\n";
		$html .= '<td nowrap valign="top"><b>' . $fields{$f}->{'name'} . ': </td>' .
			'<td>' . $fields{$f}->{'value'} . "</td>\n";
		$html .= "</tr>\n";
	}
	$html .= "</table>\n";
	return $html;
}

####################################
# MAIN
####################################
check_log();

access_check() if ($check_access);

initialize_fields();

sub submission_page_html();
my $submit = $form->param('Submit');
my $page = $form->param('page');

my ($user, $domain) = get_remoteuser();

#controller
#if ( $submit eq "Add Acct" ) {
if ( $submit eq "Unlimbo" ) {
	my $title = "Account Add: Unlimbo an existing account string - CMU/SCS Computing Facilities";
	my $bc = "Account Add: Un-limbo an existing account string";
	
	my $contents = confirmation_unlimbo_html();
	my $ok = verify_fields('acct_string');       
	my $dbh = db_connect();
	my $ora_string = getValue('acct_string');
	my @acct = acct_parse($ora_string);
	my $h1 = "Unlimbo an existing account string - ".join('-',@acct);
	my $result = update_acct($dbh, \@acct, "v", "$user\@$domain");

	$dbh->commit();
	$dbh->disconnect();
	print_html($title, $bc, $h1, $contents . $debug_contents);
} else {
if ( $submit eq "Cancel" || (! $page) or ($page eq "3") or ($page eq "2a") or ($page eq "confirmation_page")) {

	my $title =
"Account Add: Add an Oracle Account String to RAMS Oracle Database - CMU/SCS Computing Facilities";

	my $bc = "Account Add: Add an Oracle Account String - ";
	my $h1 = "Add or Un-limbo an Oracle Account String - $user\@$domain";

	my $contents = page1_html($page eq "2a" ? "2a" : undef);

	print_html($title, $bc, $h1, $contents . $debug_contents);

} elsif (($page eq "1") or ($page eq "error1")) {

	#Simple verification without connecting to the DB.
	my $ok = verify_fields('acct_string');       

	if ($ok) {
		my $title =
"Account Add: Request adding an account string - CMU/SCS Computing Facilities";
		my $bc = "Account Add: Request an account string - ";
 		my $contents = '';

		#Need to check database
		my $msg_html = '';
		my $dbh = db_connect();
		my $ora_string = getValue('acct_string');
		my @acct = acct_parse($ora_string);
		my $h1 = "Request a new account string by $user\@$domain - ".join('-',@acct);
		my $result = query_acct($dbh, \@acct);
		
		if (defined($result)) {
			$contents = page2a_html($result);
			#$debug_contents .= '<p>account in Fac</p>'.$result;
		} elsif ($#acct == 2) {
			$result = query_pta($dbh, \@acct);
			$contents = page2b_html($result);
			#$debug_contents .= '<p>account not in Fac</p>';
		} elsif ($#acct == 4) {
			$result = join '-', @acct;
			$contents = page2b_html($result);
		} else {
			my $bc = "Account Add: Incorrect Account information ";
			my $h1 = "Add or Un-limbo an Oracle Account String : Invalid Account - $user\@$domain"; 
			my $contents = page1_error_html();
		}
		$dbh->rollback();
		$dbh->disconnect;

		print_html($title, $bc, $h1, $contents . $debug_contents);    
	} else {
		my $title =
			"Account Add:  Incorrect Account information - CMU/SCS Computing Facilities";
		my $bc = "Account Add: Incorrect Account information ";
		my $h1 = "Add or Un-limbo an Oracle Account String : Invalid Account - $user\@$domain"; 
		my $contents = page1_error_html();
		print_html($title, $bc, $h1, $contents . $debug_contents);
	}

} elsif ($page eq "2b")  {
	# Insert into DB, just do a quick verification since 
	# the real verification have been done in previous page.

	my $ok = verify_fields('acct_string');

	if ($ok) {
		my $dbh = db_connect();
		my $ora_string = getValue('acct_string');
		my @acct = acct_parse($ora_string);
		#my ($user, $domain) = get_remoteuser();

		# submission page
		my $title = 
		"Account Add: CMU/SCS Computing Facilities";
		my $bc = "Acct Add: Account Added ";
		my $h1 = "Account Added by $user\@domain - $ora_string";
		my $contents = confirmation_page_html();

		my $result = insert_acct($dbh, \@acct, $user.'@'.$domain);
		my $debug_content = $result;
		$debug_content .= $dbh->commit;
		$dbh->disconnect;
 		print_html($title,$bc,$h1,$contents . $debug_contents);
	} else {
		my $title =
"Account Add: Error happened while doing database update.";
		my $bc = "Account Add: Error ";
		my $h1 = "Error updating database ";
		my $contents = page2_errorpage_html();
		print_html($title, $bc, $h1, $contents . $debug_contents);
	}        
} else {
	internal_error("The action is not defined, please report to Rams team.\n");
}    
}

#------------------------------------------------------------------
# The subprograms below are not used currently. 
#------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

acct_add	- Web Form to Add Account Strings into Facility Oracle Database

=head1 SYNOPSIS

=head1 DESCRIPTION

This is the web form utility to allow certain users adding account strings
into Facility Oracle Database (fac).

=head1 AUTHOR

Longjiang Yang E<lt>yangl@cs.cmu.eduE<gt>

=head1 COPYRIGHT

School of Computer Science
Carnegie Mellon

=head1 SEE ALSO

=cut
