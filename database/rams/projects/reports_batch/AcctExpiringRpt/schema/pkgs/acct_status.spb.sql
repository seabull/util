-- $Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/schema/pkgs/acct_status.spb.sql,v 1.2 2006/04/26 20:41:25 yangl Exp $
--
create or replace package body ccreport.acct_status
as

	function getStatus(p_acct IN acctstring_t) return acctstatus_t
	is
	begin
		null;
		return 'A';
	end getStatus;

	function getStatus(p_acct IN acctid_t) return acctstatus_t
	is
	begin
		null;
		return 'A';
	end getStatus;

	procedure getStatus(p_acct IN acctstring_t, p_reason OUT varchar2)
	is
	begin
		null;
	end getStatus;

	procedure getStatus(p_acct IN acctstring_t, p_reason OUT varchar2, p_date OUT date)
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'enter acct_status.getStatus(int=%s)'
				,p_acct);
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'exit acct_status.getStatus(reason=%s, date=%s)'
				, 'x', 'y');
	end getStatus;
	
	function getAcctstrC(p_status IN pls_integer) return sys_refcursor
	is
		l_acct_csr	sys_refcursor;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'enter acct_status.getAcctstrC(int=%s)'
				,p_status);
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'exit acct_status.getAcctstrC');

		return l_acct_csr;
	end getAcctstrC;

	function getAcctstrC(p_status IN acctstatus_t) return sys_refcursor
	is
		l_acct_csr	sys_refcursor;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'enter acct_status.getAcctstrC(%s)'
				,p_status);
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'exit acct_status.getAcctstrC');
		return l_acct_csr;
	end getAcctstrC;

	function getAcctstrC(p_status IN pls_integer
				, p_date IN date
				, p_asof IN date default sysdate) 
		return sys_refcursor
	is
		l_acct_csr	sys_refcursor;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'enter acct_status.getAcctstrC(int=%s, %s, %s)'
				,p_status, p_date, p_asof);
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'exit acct_status.getAcctstrC');
		return l_acct_csr;
	end getAcctstrC;

	function getAcctstrC(p_status IN acctstatus_t
				, p_date IN date
				, p_asof IN date default sysdate) 
		return sys_refcursor
	is
	begin
		return getExpAcctstrDataC(p_status, p_date, p_asof);
	end getAcctstrC;

	function getExpAcctstrDataC(p_status IN acctstatus_t
				, p_date IN date
				, p_asof IN date default sysdate) 
		return sys_refcursor
	is
		l_acct_csr	sys_refcursor;
		l_date_fmt	varchar2(11)	:= 'DD-MON-YYYY';
		l_max_date	date := to_date('31-DEC-2057',l_date_fmt);
		l_min_date	date := to_date('01-JAN-1900',l_date_fmt);
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'enter acct_status.getAcctstrC(%s, %s, %s)'
				,p_status, p_date, p_asof);

		--
		-- Should use cursor for entity data since they are not 
		-- acct string properties but for simplicity, use flat rows.
		--
		open l_acct_csr for
		select
			pta
			,name
			,ID
			,sponsor
			,Charge_Src
			,UserMachine
			,sum(amount) amount
			,sum(charge) charge
			,ReasonCode
			,pta_expdate
		  from (
			--with acct_charged as
			--(
			--	select wsc.account
			--		,n.name name
			--		,wsc.princ ID
			--		,decode(w.charge_by, 'P', 'Project', NULL, 'Payroll', 'Unknown') Charge_Src
			--		,nvl(w.sponsor, 'unknown') sponsor
			--		,wsc.amount
			--		,wsc.charge
			--		,'U' etype
			--	  from hostdb.who_service_charge wsc
			--		,hostdb.name n
			--		,hostdb.who w
			--	 where wsc.princ=n.princ
			--	   and n.pri=0
			--	   and w.princ=n.princ
			--	   and w.dist is not null
			--	union
			--	select hsc.account
			--		,h.hostname
			--		,hsc.assetno
			--		,decode(m.charge_by, 'P', 'Project', 'FollowUser')
			--		,decode(m.usrprinc, null, decode(c.princ, null, decode(m.prjprinc, null, 'unknown', 'P-'||m.prjprinc), 'E-'||c.princ), 'U-'||m.usrprinc) 
			--		,hsc.amount
			--		,hsc.charge
			--		,'M' etype
			--	  from hostdb.host_service_charge hsc
			--		,hostdb.hoststab h
			--		,hostdb.machtab m
			--		,hostdb.capequip c
			--	 where hsc.assetno=h.assetno
			--	   and hsc.assetno=m.assetno
			--	   and c.assetnum(+)=m.assetno
			--)
			select
				pta.pta
				,b.name
				,b.ID
				,b.sponsor
				,b.Charge_src Charge_Src
				,b.etype UserMachine
				,b.amount
				,b.charge
				,case	when (pta.task_charge_flag!='Y') then
						'Task Not Chargeable'
					when (pta.Award_Status in ('CLOSED','ON_HOLD')) then
						'Award Status'
					when (pta.proj_status_code IN ('CLOSED','PENDING_CLOSE','SUBMITTED','UNAPPROVED')) then
						'Prj Status'
					else
						'PTA Date'
				end ReasonCode
				,case	when (NVL(PTA.PROJ_CLOSED_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) <= last_day(p_date)) then
						PTA.PROJ_CLOSED_DATE
					when (NVL(PTA.TASK_COMPLETION_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) < last_day(p_date)) then
						PTA.TASK_COMPLETION_DATE
					when ( NVL(PTA.AWARD_END_DATE_ACTIVE,to_date('31-DEC-2057','DD-MON-YYYY')) < last_day(p_date)) then
						PTA.AWARD_END_DATE_ACTIVE
					when ( NVL(PTA.AWARD_CLOSED_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) <= last_day(p_date)) then
						PTA.AWARD_CLOSED_DATE
					when ( NVL(PTA.proj_completion_date,to_date('31-DEC-2057','DD-MON-YYYY')) < last_day(p_date)) then
						PTA.proj_completion_date
					when ( NVL(PTA.PROJ_START_DATE,to_date('31-DEC-1900','DD-MON-YYYY')) > last_day(p_asof)) then
						PTA.PROJ_START_DATE
					when ( NVL(PTA.AWARD_START_DATE_ACTIVE,to_date('31-DEC-1900','DD-MON-YYYY')) > last_day(p_asof)) then
						PTA.AWARD_START_DATE_ACTIVE
					else
						sysdate
				end pta_expdate
       			  from hostdb.pta_status pta
				,hostdb.accounts a
				,acct_charged_v b
			 where
				a.project=pta.project_number
			   and a.task=pta.task_number
			   and a.award=pta.award_number
			   and b.account=a.id
			   and (
			   		pta.TASK_CHARGE_FLAG='Y'
			 	AND pta.Award_Status not in ('CLOSED','ON_HOLD')
			  	AND pta.proj_status_code not IN ('CLOSED','PENDING_CLOSE','SUBMITTED','UNAPPROVED')
			  	AND
			        	(
						NVL(PTA.PROJ_CLOSED_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) <= last_day(p_date)
						OR NVL(PTA.TASK_COMPLETION_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) < last_day(p_date)
						OR NVL(PTA.AWARD_END_DATE_ACTIVE,to_date('31-DEC-2057','DD-MON-YYYY')) < last_day(p_date)
						OR NVL(PTA.AWARD_CLOSED_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) <= last_day(p_date)
						OR NVL(PTA.proj_completion_date,to_date('31-DEC-2057','DD-MON-YYYY')) < last_day(p_date)
						OR NVL(PTA.PROJ_START_DATE,to_date('31-DEC-1900','DD-MON-YYYY')) > last_day(p_asof)
						OR NVL(PTA.AWARD_START_DATE_ACTIVE,to_date('31-DEC-1900','DD-MON-YYYY')) > last_day(p_asof)
					)
				)
			)
		group by pta, name, id, Charge_src, UserMachine, sponsor, ReasonCode, pta_expdate
		order by pta, UserMachine, name, id
		;
				--,decode(m.charge_by, 'P', 'hardcode-'||decode(m.prjprinc, null, m.usrprinc, m.prjprinc), NULL, nvl(m.usrprinc, 'defaultProject'), 'Unknown')

		traceit.log(traceit.constDEBUGLEVEL_B
				, 'exit acct_status.getAcctstrC');
		return l_acct_csr;
	end getExpAcctstrDataC;

	function fetchEmailInfo(p_AsOf IN date default sysdate) return sys_refcursor
	is
		l_csr	sys_refcursor;
		--l_data	EmailInfo_tc;
	begin
		--l_data := fetchEmailInfo_cl;
		--set_AsOf(p_AsOf);
		open l_csr for 
			select *
			  from table(acct_status.fetchEmailInfo_pipe) ;
			  --from table(acct_status.fetchEmailInfo_pipe(p_AsOf)) ;
		return l_csr;
	end fetchEmailInfo;

	function fetchEmailInfo(p_AsOf IN date default sysdate) return sys_refcursor
	is
		l_csr	sys_refcursor;
		--l_data	EmailInfo_tc;
	begin
		--l_data := fetchEmailInfo_cl;
		--set_AsOf(p_AsOf);
		open l_csr for 
			select *
			  from table(acct_status.fetchEmailInfo_pipe) ;
			  --from table(acct_status.fetchEmailInfo_pipe(p_AsOf)) ;
		return l_csr;
	end fetchEmailInfo;

	function fetchEmailInfo_pipe(p_AsOf IN date) return acct_report.EmailInfo_tc
	pipelined
	is
		l_accts_csr	sys_refcursor;
		l_accts		acct_report.accts_tc;
		l_acct		acct_report.acct_string_t;
		l_email		acct_report.email_rec;
		l_errmsg	varchar2(100);
		l_asof		date;
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
			traceit.log(traceit.constDEBUGLEVEL_C, 'l_accts.count=%s', l_accts.count);
			
			for i in 1..l_accts.count 
			loop
				l_email.acct_string := l_accts(i);
				-- process it
				--l_email.acct_string := l_acct;
				--l_email.mailto := l_acct||'_to';
				--l_email.mailfrom := l_acct||'_from';
				--l_email.mailcc := l_acct||'_cc';
				hostdb.Account_Report_Email.Get_Addresses( xAccount_String => l_email.acct_string
								,xAsOfDate	=> l_asof
								,xFrom		=> l_email.mailFrom
								,xReplyTo	=> l_email.mailReplyTo
								,xTO		=> l_email.mailTo
								,xCC		=> l_email.mailCC
								,xBCC		=> l_email.mailBCC
								,xErrorMsg	=> l_errmsg
								);

				--pipe row (email_rec(l_acct
				pipe row (l_email);
			end loop;
		end loop; 
		closeReport(l_accts_csr);

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_report.fetchEmailInfo_pipe');
		return;
	end fetchEmailInfo_pipe;

	function fetchEmailInfo_pipe return acct_report.EmailInfo_tc
	pipelined
	is
		l_accts_csr	sys_refcursor;
		l_accts		acct_report.accts_tc;
		l_acct		acct_report.acct_string_t;
		l_email		acct_report.email_rec;
		l_errmsg	varchar2(100);
		l_asof		date	:= sysdate;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_report.fetchEmailInfo_pipe');
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
				hostdb.Account_Report_Email.Get_Addresses( xAccount_String => l_email.acct_string
								,xAsOfDate	=> l_asof
								,xFrom		=> l_email.mailFrom
								,xReplyTo	=> l_email.mailReplyTo
								,xTO		=> l_email.mailTo
								,xCC		=> l_email.mailCC
								,xBCC		=> l_email.mailBCC
								,xErrorMsg	=> l_errmsg
								);

				--pipe row (email_rec(l_acct
				pipe row (l_email);
			end loop;
		end loop; 
		closeReport(l_accts_csr);

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_report.fetchEmailInfo_pipe');
		return;
	end fetchEmailInfo_pipe;

	function fetchAcctStrings(p_date IN date default sysdate+60, p_asof IN date default sysdate) return sys_refcursor
	is
		l_acct_csr	sys_refcursor;
	begin
		open l_acct_csr for
		--with acct_charged as
		--(
		--	select wsc.account
		--		,n.name name
		--		,wsc.princ ID
		--		,decode(w.charge_by, 'P', 'Hardcode', NULL, 'Payroll', 'Unknown') Charge_Src
		--		,nvl(w.sponsor, 'unknown') sponsor
		--		,wsc.amount
		--		,wsc.charge
		--		,'U' etype
		--	  from hostdb.who_service_charge wsc
		--		,hostdb.name n
		--		,hostdb.who w
		--	 where wsc.princ=n.princ
		--	   and n.pri=0
		--	   and w.princ=n.princ
		--	   and w.dist is not null
		--	union
		--	select hsc.account
		--		,h.hostname
		--		,hsc.assetno
		--		,decode(m.charge_by, 'P', 'Project', 'User')
		--		,decode(m.usrprinc, null, decode(c.princ, null, decode(m.prjprinc, null, 'unknown', 'P-'||m.prjprinc), 'E-'||c.princ), 'U-'||m.usrprinc) 
		--		,hsc.amount
		--		,hsc.charge
		--		,'M' etype
		--	  from hostdb.host_service_charge hsc
		--		,hostdb.hoststab h
		--		,hostdb.machtab m
		--		,hostdb.capequip c
		--	 where hsc.assetno=h.assetno
		--	   and hsc.assetno=m.assetno
		--	   and c.assetnum(+)=m.assetno
		--)
		select
			unique
			pta.pta
		  from hostdb.pta_status pta
			,hostdb.accounts a
			,acct_charged_v b
		 where
			a.project=pta.project_number
		   and a.task=pta.task_number
		   and a.award=pta.award_number
		   and b.account=a.id
		   and (
		   		pta.TASK_CHARGE_FLAG='Y'
		 	AND pta.Award_Status not in ('CLOSED','ON_HOLD')
		  	AND pta.proj_status_code not IN ('CLOSED','PENDING_CLOSE','SUBMITTED','UNAPPROVED')
		  	AND
		        	(
					NVL(PTA.PROJ_CLOSED_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) <= last_day(p_date)
					OR NVL(PTA.TASK_COMPLETION_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) < last_day(p_date)
					OR NVL(PTA.AWARD_END_DATE_ACTIVE,to_date('31-DEC-2057','DD-MON-YYYY')) < last_day(p_date)
					OR NVL(PTA.AWARD_CLOSED_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) <= last_day(p_date)
					OR NVL(PTA.proj_completion_date,to_date('31-DEC-2057','DD-MON-YYYY')) < last_day(p_date)
					OR NVL(PTA.PROJ_START_DATE,to_date('31-DEC-1900','DD-MON-YYYY')) > last_day(p_asof)
					OR NVL(PTA.AWARD_START_DATE_ACTIVE,to_date('31-DEC-1900','DD-MON-YYYY')) > last_day(p_asof)
				)
			)
		order by pta.pta
		;
		return l_acct_csr;
	end fetchAcctStrings;

	procedure closeReport(p_csr IN sys_refcursor)
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acct_status.closeReport');
		if p_csr%isopen then
			close p_csr;
		end if;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acct_status.closeReport');
	end closeReport;

end acct_status;
/
show error
