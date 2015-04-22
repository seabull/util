-- $Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/schema/pkgs/acctexp_rpt.spb.sql,v 1.10 2006/06/27 18:58:01 yangl Exp $
create or replace package body acctexp_rpt as

	constDateFmt	varchar2(20)	:= 'DD-MON-YYYY';
	constMaxDate	date		:= to_date('31-DEC-2060', 'DD-MON-YYYY');
	constMinDate	date		:= to_date('01-JAN-1900', 'DD-MON-YYYY');

	function getFactCount (p_rptid IN rptid_type) return pls_integer;
	function purgeFactEntries(p_rptid IN rptid_type) return pls_integer;

	procedure closeReport(p_csr IN sys_refcursor)
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acctexp_rpt.closeReport');
		if p_csr%isopen then
		        close p_csr;
		end if;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acctexp_rpt.closeReport');
	end closeReport;

	procedure complete(p_rptid IN rptid_type)
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acctexp_rpt.complete(p_rptid=%s)', p_rptid);
		-- should make sure rptid is valid.
		update acctexp_logs
		   set status = constRptStatusRecorded
		 where id=p_rptid;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acctexp_rpt.complete');
	end complete;
	
	function new return rptid_type
	is
		l_id	rptid_type := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acctexp_rpt.new');
		insert into acctexp_logs (id, generate_date, status)
		values (acctexp_logs_seq.nextval, sysdate, constRptStatusInit)
			returning id into l_id;
		
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acctexp_rpt.new=%s', l_id);
		return l_id;
	end new;

	function record(p_rptid IN rptid_type) return pls_integer
	is
		l_currdate	date	:= trunc(sysdate);
		l_transdate	date	:= trunc(sysdate);
		l_postdate	date	:= trunc(sysdate);

		l_configid		pls_integer;
		l_datecount	pls_integer;
		l_monthend_flag	acctexp_config.monthend_flag%type;
		--l_startdate	acctexp_config.startdate%type;
		l_rowcount	pls_integer;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acctexp_rpt.record(p_rptid=%s)', p_rptid);
		if p_rptid < 1 then
			raise_application_error(Error_Codes.err_invalid_reportid, 'Invalid Report ID '||p_rptid);
		end if;

		--
		-- This SQL could be merged with the insert below.
		--
		select id, datecount, monthend_flag
		  into l_configid, l_datecount, l_monthend_flag
		  from acctexp_config
		 where id = (select max(id) from acctexp_config where startdate <= trunc(sysdate))
		;

		traceit.log(traceit.constDEBUGLEVEL_C, 'get config data datecount=%s, monthend_flag=%s'
				, l_datecount, l_monthend_flag);

		if l_monthend_flag = 'Y' then
			l_postdate := last_day(l_currdate + l_datecount);
			l_transdate := last_day(l_currdate + l_datecount);
		else
			l_postdate := l_currdate + l_datecount;
			l_transdate := l_currdate + l_datecount;
		end if;

		traceit.log(traceit.constDEBUGLEVEL_C, 'postdate=%s, transdate=%s'
				, l_postdate, l_transdate);

		insert into acctexp_fact
			( id, log_id, pta, name, entity_id
				,entity_type, sponsor, charge_src, amount
				,unitcharge, reasoncode, expdate_code
			)
		select
			acctexpfact_seq.nextval
			,p_rptid
			,pta
			,name
			,ID
			,UserMachine
			,sponsor
			,Charge_Src
			,amount
			,charge
			,ReasonCode
			,expdate_code
		  from (
			select
				unique
				pta
				,nvl(name, '#'||ID) name
				,ID
				,UserMachine
				,sponsor
				,Charge_Src
				,sum(amount) amount
				,sum(charge) charge
				,ReasonCode
				,expdate_code
			  from (
				select
					unique
					pta.pta
					,b.name
					,b.ID
					,b.pri
					,b.sponsor
					,b.Charge_src Charge_Src
					,b.etype UserMachine
					,b.amount
					,b.charge
					,case	when (pta.task_charge_flag!='Y') then
							--'Task Not Chargeable'
							3
						when (pta.Award_Status in ('CLOSED','ON_HOLD')) then
							--'Award Status'
							2
						when (pta.proj_status_code IN ('CLOSED','PENDING_CLOSE','SUBMITTED','UNAPPROVED')) then
							--'Prj Status'
							1
						else
							--'PTA Date'
							4
					end ReasonCode
					,case	when (NVL(PTA.PROJ_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) <= l_postdate 
							and NVL(PTA.PROJ_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) > l_currdate) then
							'Project Closed:'||PTA.PROJ_CLOSED_DATE
						when (NVL(PTA.TASK_COMPLETION_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate
							and NVL(PTA.TASK_COMPLETION_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) > l_currdate ) then
							'Task Completion:'||PTA.TASK_COMPLETION_DATE
						when ( NVL(PTA.AWARD_END_DATE_ACTIVE,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate
							and NVL(PTA.AWARD_END_DATE_ACTIVE,to_date('31-DEC-2060','DD-MON-YYYY')) > l_currdate) then
							'Award End:'||PTA.AWARD_END_DATE_ACTIVE
						when ( NVL(PTA.AWARD_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) <= l_postdate
							and NVL(PTA.AWARD_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) > l_currdate ) then
							'Award Closed:'||PTA.AWARD_CLOSED_DATE
						when ( NVL(PTA.proj_completion_date,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate
							and NVL(PTA.proj_completion_date,to_date('31-DEC-2060','DD-MON-YYYY')) > l_currdate ) then
							'Project Completion:'||PTA.proj_completion_date
						when ( NVL(PTA.PROJ_START_DATE,to_date('01-JAN-1900','DD-MON-YYYY')) > l_postdate) then
							'Project Start:'||PTA.PROJ_START_DATE
						when ( NVL(PTA.AWARD_START_DATE_ACTIVE,to_date('01-JAN-1900','DD-MON-YYYY')) > l_postdate) then
							'Award Start:'||PTA.AWARD_START_DATE_ACTIVE
						else
							'Today:'||trunc(sysdate)
					end expdate_code
	       			  from hostdb.pta_status pta
					,hostdb.accounts a
					,acct_charged_v b
				 where
					a.project=pta.project_number
				   and a.task=pta.task_number
				   and a.award=pta.award_number
				   and b.account=a.id
				   and (
					-- Should current invalid PTAs reported?
					-- According to Liz, those PTAs will not be included in
					-- the notification but could be reported to admins. 3/20/2006
				   		pta.TASK_CHARGE_FLAG!='Y'
				 	OR pta.Award_Status in ('CLOSED','ON_HOLD')
				  	OR pta.proj_status_code IN ('CLOSED','PENDING_CLOSE','SUBMITTED','UNAPPROVED')
				  	OR
				        	(
							NVL(PTA.PROJ_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) <= l_postdate
							OR NVL(PTA.TASK_COMPLETION_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate
							OR NVL(PTA.AWARD_END_DATE_ACTIVE,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate
							OR NVL(PTA.AWARD_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) <= l_postdate
							OR NVL(PTA.proj_completion_date,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate
							OR NVL(PTA.PROJ_START_DATE,to_date('01-JAN-1900','DD-MON-YYYY')) > l_transdate
							OR NVL(PTA.AWARD_START_DATE_ACTIVE,to_date('01-JAN-1900','DD-MON-YYYY')) > l_transdate
						)
					)
				)
			group by pta, name, id, Charge_src, UserMachine, sponsor, ReasonCode, expdate_code
			order by pta, UserMachine, name, id
		)
		;
		l_rowcount := SQL%ROWCOUNT;
		traceit.log(traceit.constDEBUGLEVEL_B, 'set report status to r for id=%s', p_rptid);
		complete(p_rptid);
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acctexp_rpt.record=%s', l_rowcount );
		return l_rowcount;
	end record;

	function getFactCount (p_rptid IN rptid_type)
		return pls_integer
	is
		l_cnt	pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acctexp_rpt.getFactCount(p_rptid=%s)', p_rptid);
		select count(*) 
		  into l_cnt
		  from acctexp_fact
		 where log_id=p_rptid
		;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acctexp_rpt.getFactCount=%s', l_cnt);
		return l_cnt;
	end getFactCount;

	function purgeFactEntries(p_rptid IN rptid_type)
		return pls_integer
	is
		l_cnt	pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acctexp_rpt.purgeFactEntries(p_rptid=%s)', p_rptid);

		delete from acctexp_fact
		 where log_id=p_rptid;

		l_cnt := SQL%ROWCOUNT;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acctexp_rpt.purgeFactEntries=%s', l_cnt);
		return l_cnt;
	end purgeFactEntries;

	function last return rptid_type
	is
		l_id	pls_integer := 0;
	begin
		select max(id)
		  into l_id
		  from acctexp_logs
		;
		
		return l_id;
	end;

	function getRptEntries(p_id IN rptid_type default null)
		return sys_refcursor
	is
		l_acct_csr	sys_refcursor;
		l_id		rptid_type	:= p_id;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'enter acctexp_rpt.getRptEntries(%s)'
				,p_id);

		if p_id is null then
			l_id := last;
		end if;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Use report id=%s', l_id);

		--
		-- Should use cursor for entity data since they are not 
		-- acct string properties but for simplicity, use flat rows.
		--
		open l_acct_csr for
		select
			pta
			,name
			,entity_id ID
			,sponsor
			,Charge_Src
			,entity_type
			,amount
			,unitcharge
			,ReasonCode
			,expdate_code
		  from acctexp_fact
		 where log_id=l_id
		   and reasoncode = 4
		   and expdate_code not like 'Today:%'
		order by pta, entity_type, name, entity_id
		;

		traceit.log(traceit.constDEBUGLEVEL_B
				, 'exit acctexp_rpt.getRptEntries');
		return l_acct_csr;
	end getRptEntries;

	function getRptEntriesAll(p_id IN rptid_type default null)
		return sys_refcursor
	is
		l_acct_csr	sys_refcursor;
		l_id		rptid_type	:= p_id;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'enter acctexp_rpt.getRptEntries(%s)'
				,p_id);

		if p_id is null then
			l_id := last;
		end if;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Use report id=%s', l_id);

		--
		-- Should use cursor for entity data since they are not 
		-- acct string properties but for simplicity, use flat rows.
		--
		open l_acct_csr for
		select
			pta
			,name
			,entity_id ID
			,sponsor
			,Charge_Src
			,entity_type
			,amount
			,unitcharge
			,ReasonCode
			,expdate_code
		  from acctexp_fact
		 where log_id=l_id
		order by pta, entity_type, name, entity_id
		;

		traceit.log(traceit.constDEBUGLEVEL_B
				, 'exit acctexp_rpt.getRptEntries');
		return l_acct_csr;
	end getRptEntriesall;

	function getRptEntriesExpd(p_id IN rptid_type default null)
		return sys_refcursor
	is
		l_acct_csr	sys_refcursor;
		l_id		rptid_type	:= p_id;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'enter acctexp_rpt.getRptEntries(%s)'
				,p_id);

		if p_id is null then
			l_id := last;
		end if;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Use report id=%s', l_id);

		--
		-- Should use cursor for entity data since they are not 
		-- acct string properties but for simplicity, use flat rows.
		--
		open l_acct_csr for
		select
			pta
			,name
			,entity_id ID
			,sponsor
			,Charge_Src
			,entity_type
			,amount
			,unitcharge
			,ReasonCode
			,expdate_code
		  from acctexp_fact
		 where log_id=l_id
		   and reasoncode != 4
		order by pta, entity_type, name, entity_id
		;

		traceit.log(traceit.constDEBUGLEVEL_B
				, 'exit acctexp_rpt.getRptEntries');
		return l_acct_csr;
	end getRptEntriesExpd;

	function matchReportByDate(p_gendate IN date) 
		return rptid_type
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_A
				, 'acctexp_rpt.matchReportByDate not implemented.');
		return 0;
	end matchReportByDate;

	function getAdhocExpEntries(p_numdays IN pls_integer default 30
				, p_asof IN pls_integer default 0)
		return sys_refcursor
	is
	begin
		return getAdhocExpEntries(p_numdays, trunc(sysdate)+nvl(p_asof, 0));
	end getAdhocExpEntries;

	-- TODO: implement asof for the query (views).
	function getAdhocExpEntries(p_numdays IN pls_integer default 30
				, p_asof IN date )
				--, p_asof IN date default trunc(sysdate))
		return sys_refcursor
	is
		l_acct_csr	sys_refcursor;
		l_asof		date := nvl(p_asof, trunc(sysdate));
		--l_date_fmt	varchar2(11)	:= 'DD-MON-YYYY';
		--l_max_date	date := constMaxDate;
		--l_min_date	date := '01-JAN-1900';
		l_postdate	date := p_asof+p_numdays;
		l_transdate	date := p_asof+p_numdays;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'enter acctexp_rpt.getAdhocExpEntries(%s, %s)'
				,p_numdays, p_asof);
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
			,sum(charge) unitcharge
			,ReasonCode
			,expdate_code
			--,pta_expdate 
		  from (
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
						--'Task Not Chargeable'
						3
					when (pta.Award_Status in ('CLOSED','ON_HOLD')) then
						--'Award Status'
						2
					when (pta.proj_status_code IN ('CLOSED','PENDING_CLOSE','SUBMITTED','UNAPPROVED')) then
						--'Prj Status'
						1
					else
						--'PTA Date'
						4
				end ReasonCode
				,case	when (NVL(PTA.PROJ_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) <= l_postdate) then
						'Project Closed:'||PTA.PROJ_CLOSED_DATE
					when (NVL(PTA.TASK_COMPLETION_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate) then
						'Task Completion:'||PTA.TASK_COMPLETION_DATE
					when ( NVL(PTA.AWARD_END_DATE_ACTIVE,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate) then
						'Award End:'||PTA.AWARD_END_DATE_ACTIVE
					when ( NVL(PTA.AWARD_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) <= l_postdate) then
						'Award Closed:'||PTA.AWARD_CLOSED_DATE
					when ( NVL(PTA.proj_completion_date,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate) then
						'Project Completion:'||PTA.proj_completion_date
					when ( NVL(PTA.PROJ_START_DATE,to_date('01-JAN-1900','DD-MON-YYYY')) > l_postdate) then
						'Project Start:'||PTA.PROJ_START_DATE
					when ( NVL(PTA.AWARD_START_DATE_ACTIVE,to_date('01-JAN-1900','DD-MON-YYYY')) > l_postdate) then
						'Award Start:'||PTA.AWARD_START_DATE_ACTIVE
					else
						'Today:'||trunc(sysdate)
				end expdate_code
				--,case	when (NVL(PTA.PROJ_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) <= last_day(l_postdate)) then
				--		PTA.PROJ_CLOSED_DATE
				--	when (NVL(PTA.TASK_COMPLETION_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate) then
				--		PTA.TASK_COMPLETION_DATE
				--	when ( NVL(PTA.AWARD_END_DATE_ACTIVE,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate) then
				--		PTA.AWARD_END_DATE_ACTIVE
				--	when ( NVL(PTA.AWARD_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) <= l_postdate) then
				--		PTA.AWARD_CLOSED_DATE
				--	when ( NVL(PTA.proj_completion_date,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate) then
				--		PTA.proj_completion_date
				--	when ( NVL(PTA.PROJ_START_DATE,to_date('01-JAN-1900','DD-MON-YYYY')) > l_transdate) then
				--		PTA.PROJ_START_DATE
				--	when ( NVL(PTA.AWARD_START_DATE_ACTIVE,to_date('01-JAN-1900','DD-MON-YYYY')) > l_transdate) then
				--		PTA.AWARD_START_DATE_ACTIVE
				--	else
				--		sysdate
				--end pta_expdate
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
						NVL(PTA.PROJ_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) <= l_postdate
						OR NVL(PTA.TASK_COMPLETION_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate
						OR NVL(PTA.AWARD_END_DATE_ACTIVE,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate
						OR NVL(PTA.AWARD_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) <= l_postdate
						OR NVL(PTA.proj_completion_date,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate
						OR NVL(PTA.PROJ_START_DATE,to_date('01-JAN-1900','DD-MON-YYYY')) > l_transdate
						OR NVL(PTA.AWARD_START_DATE_ACTIVE,to_date('01-JAN-1900','DD-MON-YYYY')) > l_transdate
					)
				)
			)
		group by pta, name, id, Charge_src, UserMachine, sponsor, ReasonCode, expdate_code
		order by pta, UserMachine, name, id
		;

		traceit.log(traceit.constDEBUGLEVEL_B
				, 'exit acctexp_rpt.getAdhocExpEntries');
		return l_acct_csr;
	end getAdhocExpEntries;

	-- asof parameter is not really used.
	--function fetchAcctStrings(p_date IN date default sysdate+60, p_asof IN date default sysdate) return sys_refcursor
	function fetchExpAcctStrings(p_numdays IN pls_integer 
				, p_asof IN date)
		return sys_refcursor
	is
		l_acct_csr	sys_refcursor;
		l_asof		date := p_asof;
		l_postdate	date ;
		l_transdate	date ;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'enter acctexp_rpt.fetchExpAcctStrings(%s, %s)'
				,p_numdays, p_asof);

		if p_asof is null then
			l_asof := trunc(sysdate);
		end if;
		l_postdate	:= l_asof + p_numdays;
		l_transdate	:= l_asof + p_numdays;

		open l_acct_csr for
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
					NVL(PTA.PROJ_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) <= l_postdate
					OR NVL(PTA.TASK_COMPLETION_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate
					OR NVL(PTA.AWARD_END_DATE_ACTIVE,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate
					OR NVL(PTA.AWARD_CLOSED_DATE,to_date('31-DEC-2060','DD-MON-YYYY')) <= l_postdate
					OR NVL(PTA.proj_completion_date,to_date('31-DEC-2060','DD-MON-YYYY')) < l_transdate
					OR NVL(PTA.PROJ_START_DATE,to_date('01-JAN-1900','DD-MON-YYYY')) > l_transdate
					OR NVL(PTA.AWARD_START_DATE_ACTIVE,to_date('01-JAN-1900','DD-MON-YYYY')) > l_transdate
				)
			)
		order by pta.pta
		;
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'exit acctexp_rpt.fetchExpAcctStrings, rows=%s', SQL%ROWCOUNT);
		return l_acct_csr;
	end fetchExpAcctStrings;

	function fetchExpAcctStrings(p_rptid IN rptid_type default null)
		return sys_refcursor
	is
		l_pta_csr	sys_refcursor;
		l_rptid		rptid_type	:= p_rptid;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'enter acctexp_rpt.fetchExpAcctStringsByRpt(p_rptid=%s)', p_rptid);

		if p_rptid is null then
			l_rptid := last;
		end if;
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'Use report id = %s', l_rptid);

		open l_pta_csr for
		select
			unique
			pta
		  from acctexp_fact
		 where log_id=l_rptid
		--order by pta
		;
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'exit acctexp_rpt.fetchExpAcctStringsByRpt');

		return l_pta_csr;
	end fetchExpAcctStrings;

end acctexp_rpt;
/
show error;
