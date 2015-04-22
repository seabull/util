-- $Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/schema/pkgs/emailinfo.spb.sql,v 1.8 2006/07/17 20:32:53 yangl Exp $
create or replace package body emailinfo as

	constDateFmt	varchar2(20)	:= 'DD-MON-YYYY';
	constMaxDate	date		:= to_date('31-DEC-2060', constDateFmt);
	constMinDate	date		:= to_date('01-JAN-1900', constDateFmt);

	procedure closeCursor(p_csr IN sys_refcursor)
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter emailinfo.closeCursor');
		if p_csr%isopen then
			close p_csr;
		end if;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit emailinfo.closeCursor');
	end closeCursor;

	procedure setEmailMode(p_Mode IN varchar2 default null)
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter emailinfo.setEmailMode(p_Mode=%s)', p_Mode);
		
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
				, 'Error : Invalid Mode parameter - emailinfo.setEmailMode(p_Mode=%s)', p_Mode);

			raise_application_error(Error_Codes.err_reportid_notfound
				, 'Invalid Email Mode in emailinfo.setEmailMode('
				||p_Mode||')'
				);
		end if;
		
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit emailinfo.setEmailMode(p_Mode=%s)', p_Mode);
	end setEmailMode;

	function fetchAEEmailInfo(p_numofdays IN pls_integer, p_asof IN date) return sys_refcursor
	is
		l_csr		sys_refcursor;
		l_acctstr_csr	sys_refcursor;
		l_asof		date	:= p_asof;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'enter fetchAEEmailInfo(p_asof=%s)', p_asof);
		if l_asof is null then
			l_asof := sysdate;
		end if;
		l_acctstr_csr := acctexp_rpt.fetchExpAcctStrings( p_numofdays, l_asof );
		open l_csr for 
			select *
			  from table( cast( 
					fetchEmailInfo_cl(l_acctstr_csr, l_asof) as EmailRecTbl 
					)
				) ;
					--fetchEmailInfo_pipe(l_acctstr_csr, l_asof) as EmailRecTbl 
			  --from table(emailinfo.fetchEmailInfo_pipe) ;
		return l_csr;
	end fetchAEEmailInfo;

	function fetchAEEmailInfo(p_rptid IN acctexp_rpt.rptid_type default null)
		return sys_refcursor
	is
		l_csr		sys_refcursor;
		l_acctstr_csr	sys_refcursor;
		l_asof		date := sysdate;
		l_rptid		acctexp_rpt.rptid_type := p_rptid;
		l_temp		varchar2(24);
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'enter fetchAEEmailInfo(p_rptid=%s)', p_rptid);

		if(p_rptid is null or p_rptid = 0) then
			l_rptid := acctexp_rpt.last;
		end if;

		l_acctstr_csr := acctexp_rpt.fetchExpAcctStrings(l_rptid);

		--if l_acctstr_csr%isopen then
		--	traceit.log(traceit.constDEBUGLEVEL_B , 'Cursor l_acctstr_csr is open.');
		--	fetch l_acctstr_csr into l_temp;
		--	traceit.log(traceit.constDEBUGLEVEL_B , 'l_temp=%s', l_temp);
		--else
		--	traceit.log(traceit.constDEBUGLEVEL_B , 'Cursor l_acctstr_csr is not open.');
		--end if;

		-- get the date of the p_rptid
		begin
			select generate_date
			  into l_asof
			  from acctexp_logs
			 where id=l_rptid;
		exception
			when no_data_found then
				l_asof := trunc(sysdate);
				traceit.log(traceit.constDEBUGLEVEL_B, 'Use current date asof=%s', l_asof);
		end;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Use asof=%s', l_asof);

		open l_csr for 
			select *
			  from table( cast( 
					fetchEmailInfo_cl(l_acctstr_csr, l_asof) as EmailRecTbl 
					)
				) ;
					--fetchEmailInfo_pipe(l_rptid) as EmailRecTbl 
					--fetchEmailInfo_pipe(l_acctstr_csr, l_asof) as EmailRecTbl 
		traceit.log(traceit.constDEBUGLEVEL_B, 'exit fetchAEEmailInfo');
		return l_csr;
	end fetchAEEmailInfo;

	--function fetchCCEmailInfo(p_AsOf IN date default sysdate)
	--		return sys_refcursor
	--is
	--	l_csr	sys_refcursor;
	--	--l_data	EmailInfo_tc;
	--	l_acctstr_csr	sys_refcursor;
	--begin
	--	--l_data := fetchEmailInfo_cl;
	--	--set_AsOf(p_AsOf);
	--	l_acctstr_csr := acct_report.fetchAcctStrings(p_asof);
	--	open l_csr for 
	--		select *
	--		  from table( cast( 
	--				fetchEmailInfo_pipe(l_acctstr_csr, p_asof) as EmailRecTbl 
	--				)
	--			) ;
	--		  --from table(fetchEmailInfo_pipe) ;
	--		  --from table(acct_report.fetchEmailInfo_pipe(p_AsOf)) ;
	--	traceit.log(traceit.constDEBUGLEVEL_B, 'exit fetchCCEmailInfo');
	--	return l_csr;
	--end fetchCCEmailInfo;

	function fetchEmailInfo_cl(p_acctstr_csr IN sys_refcursor, p_asof IN date)
		return EmailRecTbl
	is
		l_acctstr_csr	sys_refcursor;
		l_accts		accts_tc;
		l_acct		acctstring_t;
		--l_email		EmailRec;
		l_emails	EmailRecTbl := EmailRecTbl();
		--l_errmsg	varchar2(100);
		l_asof		date;
		l_emailmode	varchar2(30)	:= gEmailMode;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
			, 'Enter emailinfo.fetchEmailInfo_cl(p_acctstr_csr, p_asof=%s)'
			, p_asof);

		--if p_AsOf is null then
		if p_AsOf is null then
			l_asof := sysdate;
		else
			l_asof := p_asOf;
		end if;

		traceit.log(traceit.constDEBUGLEVEL_B , 'Use l_asof=%s', p_asof);

		--l_acctstr_csr := p_acctstr_csr;
		if p_acctstr_csr%isopen then
			traceit.log(traceit.constDEBUGLEVEL_B , 'Cursor p_acctstr_csr is open.');
		else
			traceit.log(traceit.constDEBUGLEVEL_B , 'Cursor p_acctstr_csr is not open.');
			--open p_acctstr_csr;
		end if;


		--l_acctstr_csr := acctexp_rpt.fetchExpAcctStrings(l_asof);

		fetch p_acctstr_csr bulk collect into l_accts ; --limit 300;
		--fetch l_acctstr_csr bulk collect into l_accts limit 300;

		traceit.log(traceit.constDEBUGLEVEL_C, 'l_accts.count=%s', l_accts.count);
		-- Remember: BULK COLLECT will NOT raise NO_DATA_FOUND if no rows
		-- are queried. Instead, check the contents of the collection to
		-- see if you have anything left to process.
		--exit when l_accts.count = 0;
		
		l_emails.extend(l_accts.count);
		for i in 1..l_accts.count 
		loop
			--l_emails(i).acct_string := l_accts(i);
			l_emails(i) := EmailRec(l_accts(i), null, null, null, null, null, null);

			-- process it
			--l_emails(i).acct_string := l_acct;
			--l_emails(i).mailto := l_acct||'_to';
			--l_emails(i).mailfrom := l_acct||'_from';
			--l_emails(i).mailcc := l_acct||'_cc';

			traceit.log(traceit.constDEBUGLEVEL_D
				, 'Retrieving email information for l_acct_string=%s, mode=%s'
				, l_emails(i).acct_string, l_emailmode);
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
							);
			l_emails(i).mailReplyTo := l_emails(i).mailFrom;
			traceit.log(traceit.constDEBUGLEVEL_D
				, 'l_acct_string=%s, mailFrom=%s,'
				||chr(10)||'replyto=%s,'
				||chr(10)||'to=%s,'
				||chr(10)||'cc=%s,'
				||chr(10)||'bcc=%s,'
				||chr(10)||'errormsg=%s,'
					, l_emails(i).acct_string
					, l_emails(i).mailFrom
					, l_emails(i).mailReplyTo
					, l_emails(i).mailTO
					, l_emails(i).mailCC
					, l_emails(i).mailBCC
					, l_emails(i).msg
				);
			--pipe row (l_emails(i));
		end loop;
		--closeCursor(l_accts_csr);

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit emailinfo.fetchEmailInfo_cl');
		return l_emails;
	end fetchEmailInfo_cl;

	function fetchEmailInfo_pipe(p_acctstr_csr IN sys_refcursor, p_asof IN date)
		return EmailRecTbl
		pipelined
	is
		l_acctstr_csr	sys_refcursor;
		l_accts		accts_tc;
		l_acct		acctstring_t;
		l_email		EmailRec;
		--l_errmsg	varchar2(100);
		l_asof		date;
		l_emailmode	varchar2(30)	:= gEmailMode;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
			, 'Enter emailinfo.fetchEmailInfo_pipe(p_acctstr_csr, p_asof=%s)'
			, p_asof);

		--if p_AsOf is null then
		if p_AsOf is null then
			l_asof := sysdate;
		else
			l_asof := p_asOf;
		end if;

		traceit.log(traceit.constDEBUGLEVEL_B , 'Use l_asof=%s', p_asof);

		--l_acctstr_csr := acctexp_rpt.fetchExpAcctStrings;
		--l_acctstr_csr := p_acctstr_csr;
		if p_acctstr_csr%isopen then
			traceit.log(traceit.constDEBUGLEVEL_B , 'Cursor p_acctstr_csr is open.');
			--fetch p_acctstr_csr into l_acct;
			--traceit.log(traceit.constDEBUGLEVEL_C, 'l_acct=%s', l_acct);
		else
			traceit.log(traceit.constDEBUGLEVEL_B , 'Cursor p_acctstr_csr is not open.');
			--open p_acctstr_csr;
		end if;

		loop

			fetch p_acctstr_csr bulk collect into l_accts limit 300;
			--fetch l_acctstr_csr bulk collect into l_accts limit 300;

			traceit.log(traceit.constDEBUGLEVEL_C, 'l_accts.count=%s', l_accts.count);
			-- Remember: BULK COLLECT will NOT raise NO_DATA_FOUND if no rows
			-- are queried. Instead, check the contents of the collection to
			-- see if you have anything left to process.
			exit when l_accts.count = 0;
			traceit.log(traceit.constDEBUGLEVEL_C, 'l_accts.count=%s, modes=%s'
					, l_accts.count, l_emailmode);
			
			for i in 1..l_accts.count 
			loop
				--l_email.acct_string := l_accts(i);
				l_email := EmailRec(l_accts(i), null, null, null, null, null, null);

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
								);
				l_email.mailReplyTo := l_email.mailFrom;
				traceit.log(traceit.constDEBUGLEVEL_D
					, 'l_acct_string=%s, mailFrom=%s,'
					||chr(10)||'replyto=%s,'
					||chr(10)||'to=%s,'
					||chr(10)||'cc=%s,'
					||chr(10)||'bcc=%s,'
					||chr(10)||'errormsg=%s,'
						, l_email.acct_string
						, l_email.mailFrom
						, l_email.mailReplyTo
						, l_email.mailTO
						, l_email.mailCC
						, l_email.mailBCC
						, l_email.msg
					);
				pipe row (l_email);
			end loop;
		end loop; 
		--closeCursor(l_accts_csr);

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit emailinfo.fetchEmailInfo_pipe');
		return;
	end fetchEmailInfo_pipe;

	--function fetchEmailInfo_pipe(p_acctstr_csr IN sys_refcursor
	--			, p_rptid IN acctexp_rpt.rptid_type default null)
	--	return EmailRecTbl pipelined
	--is
	--	l_accts_csr	sys_refcursor;
	--	l_accts		accts_tc;
	--	l_acct		acctstring_t;
	--	l_email		EmailRec;
	--	l_errmsg	varchar2(100);
	--	l_asof		date	:= sysdate;
	--begin
	--	traceit.log(traceit.constDEBUGLEVEL_B, 'Enter emailinfo.fetchEmailInfo_pipe');
	--	--l_accts_csr := acctexp_rpt.fetchExpAcctStrings;
	--	l_accts_csr := p_acctstr_csr;
	--	loop
	--		fetch l_accts_csr bulk collect into l_accts limit 300;

	--		traceit.log(traceit.constDEBUGLEVEL_C, 'l_accts.count=%s', l_accts.count);
	--		-- Remember: BULK COLLECT will NOT raise NO_DATA_FOUND if no rows
	--		-- are queried. Instead, check the contents of the collection to
	--		-- see if you have anything left to process.
	--		exit when l_accts.count = 0;
	--		traceit.log(traceit.constDEBUGLEVEL_C, 'l_accts.count=%s', l_accts.count);
	--		
	--		for i in 1..l_accts.count 
	--		loop
	--			l_email.acct_string := l_accts(i);
	--			-- process it
	--			--l_email.acct_string := l_acct;
	--			--l_email.mailto := l_acct||'_to';
	--			--l_email.mailfrom := l_acct||'_from';
	--			--l_email.mailcc := l_acct||'_cc';
	--			hostdb.Account_Report_Email.Get_Addresses( xAccount_String => l_email.acct_string
	--							,xAsOfDate	=> l_asof
	--							,xFrom		=> l_email.mailFrom
	--							,xReplyTo	=> l_email.mailReplyTo
	--							,xTO		=> l_email.mailTo
	--							,xCC		=> l_email.mailCC
	--							,xBCC		=> l_email.mailBCC
	--							,xErrorMsg	=> l_errmsg
	--							);

	--			--pipe row (email_rec(l_acct
	--			pipe row (l_email);
	--		end loop;
	--	end loop; 
	--	--closeCursor(l_accts_csr);

	--	traceit.log(traceit.constDEBUGLEVEL_B, 'Exit emailinfo.fetchEmailInfo_pipe');
	--	return;
	--end fetchEmailInfo_pipe;

end emailinfo;
/
show error;
