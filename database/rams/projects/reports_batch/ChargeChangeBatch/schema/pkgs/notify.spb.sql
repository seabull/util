-- $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/schema/pkgs/notify.spb.sql,v 1.9 2006/07/19 02:44:12 yangl Exp $
--
create or replace package body acct_report
as
	-- This variable is for a workaround of pipelined function.
	-- It is only used by fetchEmailInfo and fetchEmailInfo_pipe
	gAsOf	date	:= sysdate;

	-- Private
	procedure set_AsOf(p_asof IN date) is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.init(p_asof=%s)', p_asof);
		if p_asof is null then
			gAsOf := sysdate;
		else
			gAsOf := p_asof;
		end if;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.set_AsOf=%s', gAsOf);
	end set_AsOf;

	-- Public
	procedure setEmailMode(p_Mode IN varchar2 default null)
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.setEmailMode(p_Mode=%s)', p_Mode);

		if p_Mode is null then
			--gEmailMode := hostdb.Account_Report_Email.mReportManagerOnly;
			gEmailMode := hostdb.Account_Report_Email.mProduction;
		elsif (p_Mode = hostdb.Account_Report_Email.mDevelopment
			or p_Mode = hostdb.Account_Report_Email.mProduction
			or p_Mode = hostdb.Account_Report_Email.mReportManagerOnly
			) then
			gEmailMode := p_Mode;
		else
			traceit.log(traceit.constDEBUGLEVEL_A
				, 'Error : Invalid Mode parameter - acct_report.setEmailMode(p_Mode=%s)', p_Mode);
			raise_application_error(Error_Codes.err_reportid_notfound, 'Invalid Email Mode in acct_report.setEmailMode('||p_Mode||')');
		end if;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_report.setEmailMode(p_Mode=%s)', p_Mode);
	end setEmailMode;

	procedure init(p_id IN varchar2 default null)
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.init(p_id=%s)', p_id);
		if p_id is null then
			begin
				select
					max(ccreport_id)
				  into gReportID
				  from ccreport_logs_r;
			exception
				when others then
					traceit.log(traceit.constDEBUGLEVEL_A, 'No Report ID found');
					raise_application_error(Error_Codes.err_reportid_notfound, 'No Report ID found in table ccreport_logs');
			end;
			if gReportID is null then
				traceit.log(traceit.constDEBUGLEVEL_A, 'Error - No Regular Report ID found');
				raise_application_error(Error_Codes.err_reportid_notfound, 'No Regular Report ID found, Please make sure one exists or specify the Report ID.');
			end if;
		else
			gReportId := p_id;
		end if;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_report.init=%s', gReportId);
	end init;

	procedure setTimestampFormat(p_ts_format IN varchar2) is
	begin
		gTimestampFormat := substr(p_ts_format, 1, 100);
	end setTimestampFormat;

	function getTimestampFormat return varchar2 is
	begin
		return gTimestampFormat;
	end getTimestampFormat;

	function getReportID return number
	is
	begin
		return gReportID;
	end;

	function strip_string (
			 p_expression_in    IN   VARCHAR2
			,p_characters_in    IN   VARCHAR2
			,p_placeholder_in   IN   VARCHAR2 DEFAULT CHR(1)
		) RETURN VARCHAR2
	is
	begin
		RETURN TRANSLATE (      p_expression_in
					, p_placeholder_in || p_characters_in
					, p_placeholder_in
					);
	end strip_string;

	procedure closeReport(p_csr IN sys_refcursor)
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.closeReport');
		if p_csr%isopen then
			close p_csr;
		end if;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_report.closeReport');
	end closeReport;

	function fetchAcctStrings_cl return accts_tc
	is
		cursor l_accts_csr is
			select
			        distinct
			        acct_string
			  from
			(
			select
			        acct_string
			        ,assetno
			        ,pri
			        ,count(distinct change_flag) over (partition by report_log_id, assetno, hostname, pri, acct_string, ipaddress, charge_by, qual, service_vec,location ,PrimaryUser, os, pct, protocol, dept, ChargeAmount) cnt
			  from host_conf_details_v h
			 where
			        report_log_id=gReportID
			union
			select
			        acct_string
			        ,princ
			        ,0
			        ,count(distinct change_flag) over (partition by report_log_id, princ, charge_by, acct_string, sponsor, PctUser, service_vec ,pct, ChargeAmount) cnt
			  from who_conf_details_v h
			 where
			        report_log_id=gReportID
			) x
			 where x.cnt<2
			;
		l_accts		accts_tc;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.fetchAcctStrings');

		open l_accts_csr;
		fetch l_accts_csr bulk collect into l_accts;
		close l_accts_csr;

		traceit.log(traceit.constDEBUGLEVEL_C, 'l_accts.count=%s', l_accts.count);
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_report.fetchAcctStrings');

		return l_accts;
	end fetchAcctStrings_cl;

	function fetchAcctStrings return sys_refcursor
	is
		l_csr		sys_refcursor;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.fetchAcctStrings');
		if getReportID = 0 then
			init(null);
		end if;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Use ReportID=%s', gReportID);
		open l_csr for
			select
			        distinct
			        acct_string
			  from
			(
			select
			        acct_string
			        ,assetno
			        ,pri
			        ,count(distinct change_flag) over (partition by report_log_id, assetno, hostname, pri, acct_string, ipaddress, charge_by, qual, service_vec,location ,PrimaryUser, os, pct, protocol, dept, ChargeAmount) cnt
			  from host_conf_details_v h
			 where
			        report_log_id=gReportID
			union
			select
			        acct_string
			        ,princ
			        ,0
			        ,count(distinct change_flag) over (partition by report_log_id, princ, charge_by, acct_string, sponsor, PctUser, service_vec ,pct, ChargeAmount) cnt
			  from who_conf_details_v h
			 where
			        report_log_id=gReportID
			) x
			 where x.cnt<2
			;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_report.fetchAcctStrings');
		return l_csr;
	end fetchAcctStrings;

	function fetchEmailInfo_pipe(p_AsOf IN date) return EmailRecTbl
	pipelined
	is
		l_accts_csr	sys_refcursor;
		l_accts		accts_tc;
		l_acct		acct_string_t;
		l_email		EmailRec;
		l_errmsg	varchar2(4000);
		l_asof		date;
		l_emailmode	varchar2(30)	:= gEmailMode;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.fetchEmailInfo_pipe');
		--if p_AsOf is null then
		if p_AsOf is null then
			l_asof := sysdate;
		else
			l_asof := p_AsOf;
		end if;
		l_accts_csr := fetchAcctStrings;
		loop
			fetch l_accts_csr bulk collect into l_accts limit 300;

			traceit.log(traceit.constDEBUGLEVEL_C, 'l_accts.count=%s', l_accts.count);
			-- Remember: BULK COLLECT will NOT raise NO_DATA_FOUND if no rows
			-- are queried. Instead, check the contents of the collection to
			-- see if you have anything left to process.
			exit when l_accts.count = 0;
			traceit.log(traceit.constDEBUGLEVEL_C, 'l_accts.count=%s, mode=%s', l_accts.count, l_emailmode);
			
			for i in 1..l_accts.count 
			loop
				l_email.acct_string := l_accts(i);
				-- process it
				--l_email.acct_string := l_acct;
				--l_email.mailto := l_acct||'_to';
				--l_email.mailfrom := l_acct||'_from';
				--l_email.mailcc := l_acct||'_cc';
				hostdb.Account_Report_Email.Get_Addresses( 
								xAccount_String => l_email.acct_string
								,xMode		=> l_emailmode
								,xAsOfDate	=> l_asof
								,xSender	=> l_email.mailFrom
								--,xFrom		=> l_email.mailFrom
								--,xReplyTo	=> l_email.mailReplyTo
								,xTO		=> l_email.mailTo
								,xCC		=> l_email.mailCC
								,xBCC		=> l_email.mailBCC
								,xErrorMsg	=> l_email.msg
								--l_errmsg
								);
				l_email.mailReplyTo := l_email.mailFrom;

				--pipe row (EmailRec(l_acct
				pipe row (l_email);
			end loop;
		end loop; 
		closeReport(l_accts_csr);

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_report.fetchEmailInfo_pipe');
		return;
	end fetchEmailInfo_pipe;

	function fetchEmailInfo_pipe return EmailRecTbl
	pipelined
	is
		l_accts_csr	sys_refcursor;
		l_accts		accts_tc;
		l_acct		acct_string_t;
		l_email		EmailRec := EmailRec(null, null, null, null, null, null, null);
		l_errmsg	varchar2(4000);
		l_asof		date;
		l_emailmode	varchar2(30)	:= gEmailMode;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.fetchEmailInfo_pipe');
		--if p_AsOf is null then
		if gAsOf is null then
			l_asof := sysdate;
		else
			--l_asof := p_AsOf;
			l_asof := gAsOf;
		end if;
		l_accts_csr := fetchAcctStrings;
		loop
			fetch l_accts_csr bulk collect into l_accts limit 300;

			traceit.log(traceit.constDEBUGLEVEL_C, 'l_accts.count=%s', l_accts.count);
			-- Remember: BULK COLLECT will NOT raise NO_DATA_FOUND if no rows
			-- are queried. Instead, check the contents of the collection to
			-- see if you have anything left to process.
			exit when l_accts.count = 0;
			traceit.log(traceit.constDEBUGLEVEL_C, 'l_accts.count=%s', l_accts.count);
			
			for i in 1..l_accts.count 
			loop
				l_email.acct_string := l_accts(i);
				-- process it
				--l_email.acct_string := l_acct;
				--l_email.mailto := l_acct||'_to';
				--l_email.mailfrom := l_acct||'_from';
				--l_email.mailcc := l_acct||'_cc';
				traceit.log(traceit.constDEBUGLEVEL_D, 'process acct %s as of %s in mode %s', l_email.acct_string, l_asof, l_emailmode);
				hostdb.Account_Report_Email.Get_Addresses( 
								xAccount_String => l_email.acct_string
								,xMode		=> l_emailmode
								,xAsOfDate	=> l_asof
								,xSender	=> l_email.mailFrom
								--,xFrom		=> l_email.mailFrom
								--,xReplyTo	=> l_email.mailReplyTo
								,xTO		=> l_email.mailTo
								,xCC		=> l_email.mailCC
								,xBCC		=> l_email.mailBCC
								,xErrorMsg	=> l_email.msg
								--,xErrorMsg	=> l_errmsg
								);
				l_email.mailReplyTo := l_email.mailFrom;
				traceit.log(traceit.constDEBUGLEVEL_D, 'Got email info %s:%s:%s:%s:%s:%s', l_email.mailFrom, l_email.mailReplyTo, l_email.mailTo, l_email.mailCC, l_email.mailBCC, l_errmsg);

				--pipe row (EmailRec(l_acct
				pipe row (l_email);
			end loop;
		end loop; 
		closeReport(l_accts_csr);

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_report.fetchEmailInfo_pipe');
		return;
	end fetchEmailInfo_pipe;

	--function fetchEmailInfo_cl return EmailRecTbl
	function fetchEmailInfo_cl(p_AsOf IN date default sysdate) return EmailRecTbl
	is
		l_accts_csr	sys_refcursor;
		l_accts		accts_tc;
		l_acct		acct_string_t;
		l_emails	EmailRecTbl := EmailRecTbl();
		l_errmsg	varchar2(4000);
		l_asof		date;
		l_emailmode	varchar2(30)	:= gEmailMode;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.fetchEmailInfo_cl(p_AsOf=%s', p_AsOf);

		if p_AsOf is null then
			l_asof := sysdate;
		else
			l_asof := p_AsOf;
		end if;
		l_accts_csr := fetchAcctStrings;
		loop
			fetch l_accts_csr bulk collect into l_accts limit 300;
			-- Remember: BULK COLLECT will NOT raise NO_DATA_FOUND if no rows
			-- are queried. Instead, check the contents of the collection to
			-- see if you have anything left to process.
			exit when l_accts.count = 0;
			
			l_emails.extend(l_accts.count);
			for i in 1..l_accts.count 
			loop
				l_emails(i).acct_string := l_accts(i);
				traceit.log(traceit.constDEBUGLEVEL_C
					, 'l_accts.count=%s, mode=%s', l_accts.count, l_emailmode);
				-- process it
				--l_emails(i).acct_string := l_acct ;
				--l_emails(i).mailto := l_acct||'_to';
				--l_emails(i).mailfrom := l_acct||'_from' ;
				--l_emails(i).mailcc := l_acct||'_cc' ;
				hostdb.Account_Report_Email.Get_Addresses(
								xAccount_String => l_emails(i).acct_string
								,xMode		=> l_emailmode
								,xAsOfDate	=> l_asof
								,xSender	=> l_emails(i).mailFrom
								--,xFrom		=> l_emails(i).mailFrom
								--,xReplyTo	=> l_emails(i).mailReplyTo
								,xTO		=> l_emails(i).mailTo
								,xCC		=> l_emails(i).mailCC
								,xBCC		=> l_emails(i).mailBCC
								,xErrorMsg	=> l_emails(i).msg
								--,xErrorMsg	=> l_errmsg
								);
				l_emails(i).mailReplyTo := l_emails(i).mailFrom;
			end loop;
		end loop; 

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_report.fetchEmailInfo_cl');
		return l_emails;
	end fetchEmailInfo_cl;

	function fetchEmailInfo(p_rptid IN pls_integer) return sys_refcursor
	is
		l_csr	sys_refcursor;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.fetchEmailInfo(p_rptid=%s)', p_rptid);
		if p_rptid is null then
			l_csr := fetchEmailInfo(EntityChanged.getDB_Ts_New(p_rptid));
		else
			l_csr := fetchEmailInfo(trunc(sysdate));
		end if;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_report.fetchEmailInfo');
		return l_csr;
	end fetchEmailInfo;

	-- pipelined function with parameter does not seem to work.
	-- A workaround is to using SQL type and do a cast
	-- but for now always use sysdate.
	--function fetchEmailInfo IN date default sysdate) return sys_refcursor
	function fetchEmailInfo(p_AsOf IN date default sysdate) return sys_refcursor
	is
		l_csr	sys_refcursor;
		--l_data	EmailRecTbl;
	begin
		--l_data := fetchEmailInfo_cl;
		set_AsOf(p_AsOf);
		open l_csr for 
			select *
			  from table( cast (
					acct_report.fetchEmailInfo_pipe as EmailRecTbl
					)
				) ;
			  --from table(acct_report.fetchEmailInfo_pipe(p_AsOf)) ;
		return l_csr;
	end fetchEmailInfo;

	--
	-- p_acctstr can be
	-- 	null			- query all accounts
	--	'123-4-567'		- one single account
	--	'1-2-3,4-5-6,...'	- list of accounts, SPACES ARE BEING STRIPPED OUT 
	--
	function fetchUserReport(p_acctstr IN varchar2) return sys_refcursor
	is
		l_csr		sys_refcursor;
		l_qstr		varchar2(32767);
		l_acctstr_c	varchar2(32767);
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.fetchUserReport(p_acctstr=%s)', p_acctstr);
	
		if getReportID = 0 then
			init(null);
		end if;

		if p_acctstr is null then
			l_acctstr_c := '';
		else
			-- should validate the string here?
			--l_acctstr_c := '		   and acct_string in ('''||p_acctstr||''')';
			l_acctstr_c := strip_string(p_acctstr, ' ');
			l_acctstr_c := ' and acct_string in ('''||replace(l_acctstr_c, ',', ''',''')||''')';
		end if;

		-- open the cursor
		l_qstr :=	'select '
			||'	unique '
			||'	acct_string '
			||'	,princ '
			||'	,name '
			||'	,change_flag '
			||'	,case when count(unique change_flag) over (partition by princ, acct_string, report_log_id) > 1 then '
			||'		''Changed'' '
			||'	else '
			||'		case when change_flag=''Old'' then '
			||'			''Deleted'' '
			||'		else '
			||'			''Added'' '
			||'		end '
			||'	end Reason '
			||'	,charge_by      '
			||'	,sponsor '
			||'	,PctUser '
			||'	,service_vec '
			||'	,pct '
			||'	,ChargeAmount           TotalCharged '
			--||'	,round(ChargeAmount*pct/100, 2)       AmountCharged '
			||'	,AmountCharged '
			||'	,AdjustedCharge '
			||'	,to_char(LastChanged, '''||getTimestampFormat||''') LastChanged '
			--||'	,to_char(LastChanged, '':fmt'') '
			||'	,report_log_id '
			||'  from ( '
			||'		select '
			||'			acct_string '
			||'			,princ '
			||'			,name '
			||'			,change_flag '
			||'			,count(unique change_flag) over  '
			||'				(partition by report_log_id, princ, name, acct_string, charge_by, sponsor, PctUser, service_vec, pct, ChargeAmount) cnt   '
			||'			,charge_by      '
			||'			,sponsor '
			||'			,PctUser '
			||'			,service_vec '
			||'			,pct '
			||'			,ChargeAmount '
			||'			,case when change_flag=''Old'' then '
			||'				0-AmountCharged '
			||'			else '
			||'				AmountCharged '
			||'			end AdjustedCharge '
			||'			,LastChanged '
			||'			,AmountCharged '
			||'			,report_log_id '
			||'		  from who_conf_details_v '
			||'		 where '
			||'		        report_log_id=:id '
			||l_acctstr_c
			||'        ) x '
			||' where x.cnt<2 '
			||'order by acct_string, Reason, princ, change_flag '
			;
		traceit.log(traceit.constDEBUGLEVEL_D, 'Using query %s - %s', l_qstr, gReportID);
		open l_csr for l_qstr
			using gReportID
			;
			--using gTimestampFormat, gReportID
			--using p_id, p_acctstr;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_report.fetchUserReport');
		return l_csr;

	end fetchUserReport;

	function fetchMachineReport(p_acctstr IN varchar2) return sys_refcursor
	is
		l_csr	sys_refcursor;
		l_qstr		varchar2(32767);
		l_acctstr_c	varchar2(32767);
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.fetchMachineReport(p_acctstr=%s)', p_acctstr);

		if p_acctstr is null then
			l_acctstr_c := '';
		else
			-- should validate the string here?
			-- l_acctstr_c := '		   and acct_string in ('''||p_acctstr||''')';
			l_acctstr_c := strip_string(p_acctstr, ' ');
			l_acctstr_c := ' and acct_string in ('''||replace(l_acctstr_c, ',', ''',''')||''')';
		end if;

		l_qstr :=	'select '
			||'	unique '
			||'	acct_string '
			||'	,assetno '
			||'	,hostname '
			||'	,pri '
			||'	,change_flag '
			||'	,case when count(unique change_flag) over (partition by report_log_id, assetno, hostname, pri, acct_string)>1 then '
			||'		''Changed'' '
			||'	else '
			||'		case when change_flag=''Old'' then '
			||'			''Deleted'' '
			||'		else '
			||'			''Added'' '
			||'		end '
			||'	end Reason '
			--||'	,count(change_flag) over (partition by report_log_id, assetno, hostname, pri, acct_string) '
			||'	,ipaddress '
			||'	,charge_by '
			||'	,qual '
			||'	,service_vec '
			||'	,location '
			||'	,PrimaryUser '
			||'	,os '
			||'	,dist_id '
			||'	,pct '
			||'	,protocol '
			||'	,dept '
			||'	,ChargeAmount TotalCharged '
			||'	,AmountCharged '
			||'	,AdjustedCharge '
			--||'	,LastChanged '
			-- could use bind variable here but the format remains the same in most cases anyway.
			||'	,to_char(LastChanged, '''||getTimestampFormat||''') LastChanged '
			||'	,report_log_id '
			||'  from ( '
			||'		select '
			||'			acct_string '
			||'			,assetno '
			||'			,hostname '
			||'			,pri '
			||'			,change_flag '
			||'			,count(unique change_flag) over  '
			||'				(partition by report_log_id, assetno, hostname, pri, acct_string, ipaddress, charge_by, qual, service_vec,location ,PrimaryUser, os, pct, protocol, dept, ChargeAmount) cnt '
			||'		        ,ipaddress	 '
			||'		        ,charge_by '
			||'		        ,qual '
			||'		        ,service_vec '
			||'		        ,location '
			||'		        ,PrimaryUser '
			||'		        ,os '
			||'		        ,dist_id '
			||'		        ,pct '
			||'		        ,protocol '
			||'		        ,dept '
			||'		        ,ChargeAmount '
			||'			,case when change_flag=''Old'' then '
			||'				0-AmountCharged '
			||'			else '
			||'				AmountCharged '
			||'			end AdjustedCharge '
			||'			,AmountCharged '
			||'		        ,LastChanged '
			--||'			,to_char(LastChanged, '''||getTimestampFormat||''') LastChanged '
			||'		        ,report_log_id '
			||'		  from host_conf_details_v '
			||'		 where report_log_id=:id '
			--||'		   and acct_string in ('':acctstr'') '
			||l_acctstr_c
			||'	) '
			||' where cnt<2 '
			||'order by acct_string, Reason, assetno, pri, hostname, change_flag '
			;
		traceit.log(traceit.constDEBUGLEVEL_D, 'Using query %s - %s', l_qstr, gReportID);
		open l_csr for l_qstr
			using gReportID
			;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_report.fetchMachineReport');
		return l_csr;
	end fetchMachineReport;

end acct_report;
/
show error

