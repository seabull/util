-- $Id: charge_byservices_refresh.sql,v 1.1 2005/10/11 14:08:49 yangl Exp $
--
--set termout on feedback on linesize 120

create or replace package util_adhoc is

	X_NO_DATA	number(5) := -20201;
	X_UNKNOWN	number(5) := -20202;

	constWhatUser	varchar2(4)	:= 'USER';
	constWhatMach	varchar2(4)	:= 'MACH';
	constWhatBoth	varchar2(4)	:= 'BOTH';
	
	procedure wc_svc_fastrefresh(p_jnl IN number default 0);
	procedure hc_svc_fastrefresh(p_jnl IN number default 0);
	procedure user_hist_fastfresh(p_jnl IN number default 0);
	procedure mach_hist_fastfresh(p_jnl IN number default 0);
	procedure populate_confighist(p_jnl IN number default 0, p_what IN varchar2 default constWhatBoth);
	procedure populate_chgsvc_hist(p_jnl IN number default 0, p_what IN varchar2 default constWhatBoth);

end util_adhoc;
/
show errors

create or replace package body util_adhoc is

	procedure wc_svc_fastrefresh(p_jnl IN number default 0)
	as
		l_max_jnl	wc_by_services.journal%TYPE;
	begin
		traceit.log(traceit.constDEBUGLEVEL_A, 'Enter wc_svc_fastrefresh, p_jnl=%s', p_jnl);
		if (p_jnl < 1)
		then
			select max(journal)
			  into l_max_jnl
			  from wc_by_services;
		else
			l_max_jnl := p_jnl;
		end if;
	
		insert /*+ append */ 
		  into wc_by_services 
			(NID, wid, service_id, journal, dist_vec)
			select
				wc_by_services_seq.nextval
				,xx.id
				,xx.service_id
				,xx.journal
				,xx.dist_vec
			  from (
				select 
					id
					,service_id
					,journal
					,case when row_number() over (partition by journal, id, service_id order by acct)=1 then
						stragg(x.acct||'@'||pct) over (partition by journal, id, service_id order by acct 
									rows between unbounded preceding and unbounded following) 
					end dist_vec
				  from (
					select
						wc.wr_id id
						,hostdb.account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, decode(wc.account_flag,'b','s','l','l','i','i',null),null) acct
						,wc.pct
						,wc.service_id
						,nvl(lower(wc.account_flag),'V') account_flag
						,wc.journal
					  from hostdb.who_charged wc
						,hostdb.accounts a
					 where
						wc.journal>l_max_jnl
					   and wc.account=a.id
					order by 
						journal
						, id
						, service_id
						, acct
						, pct
						, wc.account_flag
					) x
				) xx
			where xx.dist_vec is not null;
						-- , hostdb.account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, null,null) 
		traceit.log(traceit.constDEBUGLEVEL_A, 'Exit wc_svc_fastrefresh, Inserted #rows=%s', sql%rowcount);
	exception
		when no_data_found then
			traceit.log(traceit.constDEBUGLEVEL_A, 'No data found in wc_by_services. %s', sqlcode);
			raise_application_error(X_NO_DATA, 'No data found in wc_by_services. '||
										substr(sqlerrm,1,20));
	end wc_svc_fastrefresh;
				
	procedure hc_svc_fastrefresh(p_jnl IN number default 0)
	as
		l_max_jnl	hc_by_services.journal%TYPE;
	begin
		traceit.log(traceit.constDEBUGLEVEL_A, 'Enter hc_svc_fastrefresh, p_jnl=%s', p_jnl);
		if (p_jnl < 1) then
			select max(journal)
			  into l_max_jnl
			  from hc_by_services;
		else
			l_max_jnl := p_jnl;
		end if;
	
		insert /*+ append */ into hc_by_services 
			(NID, hid, service_id, journal, dist_vec)
			select
				hc_by_services_seq.nextval
				,xx.*
			  from (
				select 
					id
					,service_id
					,journal
					,case when row_number() over (partition by journal, id, service_id order by acct)=1 then
						stragg(x.acct||'@'||pct) over (partition by journal, id, service_id order by acct 
									rows between unbounded preceding and unbounded following) 
					end dist_vec
				  from (
					select
						hc.hr_id id
						,account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, decode(hc.account_flag,'b','s','l','l','i','i',null),null) acct
						,hc.pct
						,hc.service_id
						,nvl(lower(hc.account_flag),'V') account_flag
						,hc.journal
					  from hostdb.host_charged hc
						,hostdb.accounts a
					 where
						hc.journal>l_max_jnl
					   and hc.account=a.id
					order by 
						journal
						, id
						, service_id
						,account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, null,null) 
						, pct
						, hc.account_flag
					) x
				) xx
			where xx.dist_vec is not null;
		traceit.log(traceit.constDEBUGLEVEL_A, 'Exit hc_svc_fastrefresh, Inserted #rows=%s', sql%rowcount);
	exception
		when no_data_found then
			traceit.log(traceit.constDEBUGLEVEL_A, 'No data found in hc_by_services. %s', sqlcode);
			raise_application_error(X_NO_DATA, 'No data found in hc_by_services. '||
										substr(sqlerrm,1,20));
	end hc_svc_fastrefresh;
	
	/*
	 * fast refresh user history
	 */
	procedure user_hist_fastfresh(p_jnl IN number default 0)
	as
		l_max_jnl	user_hist.journal%TYPE;
		l_curr_jnl	hostdb.journals.id%TYPE;
	begin
		traceit.log(traceit.constDEBUGLEVEL_A, 'Enter user_hist_fastfresh, p_jnl=%s', p_jnl);

		if (p_jnl < 1) then
			select max(journal)
			  into l_max_jnl
			  from wc_by_services;
		else
			l_max_jnl := p_jnl;
		end if;

		traceit.log(traceit.constDEBUGLEVEL_C, 'l_max_jnl = %s', l_max_jnl);
		begin
			select 
				max(id)
			  into l_curr_jnl
			  from hostdb.journals
			 where JE_IN_PROCESS_FLAG='Y';
			traceit.log(traceit.constDEBUGLEVEL_C, 'jnl-in-progress: l_curr_jnl = %s', l_curr_jnl);
		exception
			when no_data_found then
				select 
					max(id)-1
				  into l_curr_jnl
				  from hostdb.journals;
				traceit.log(traceit.constDEBUGLEVEL_C, 'No journal-in-progress: l_curr_jnl = %s', l_curr_jnl);
			when others then
				raise_application_error(X_UNKNOWN, 'Error happend when retrieving journal. '
						|| sqlerrm );

		end;

		if (l_curr_jnl <= l_max_jnl) then
			traceit.log(traceit.constDEBUGLEVEL_A, 'Current user state jnl=%s  has been populated into user_hist max_jnl=%s', l_curr_jnl, l_max_jnl);
			raise_application_error(X_UNKNOWN, 'Current user state has been populated into user_hist.');
		end if;

		insert /*+ append */
		  into user_hist (NID, princ, journal, charge_by, dist_src)
			select 
				userhist_idseq.nextval
				,princ
				,l_curr_jnl
				,charge_by
				,dist_src
			  from hostdb.who
			 where dist is not null;
		traceit.log(traceit.constDEBUGLEVEL_B, '%s entries populated into user_hist_fastfresh', SQL%ROWCOUNT);
		traceit.log(traceit.constDEBUGLEVEL_A, 'Exit user_hist_fastfresh');
	end user_hist_fastfresh;

	/*
	 * fast refresh machine history
	 */
	procedure mach_hist_fastfresh(p_jnl IN number default 0)
	as
		l_max_jnl	mach_hist.journal%TYPE;
		l_curr_jnl	hostdb.journals.id%TYPE;
	begin
		traceit.log(traceit.constDEBUGLEVEL_A, 'Enter mach_hist_fastfresh, p_jnl=%s', p_jnl);

		if (p_jnl < 1) then
			select max(journal)
			  into l_max_jnl
			  from hc_by_services;
		else
			l_max_jnl := p_jnl;
		end if;

		traceit.log(traceit.constDEBUGLEVEL_C, 'l_max_jnl = %s', l_max_jnl);
		begin
			select 
				max(id)
			  into l_curr_jnl
			  from hostdb.journals
			 where JE_IN_PROCESS_FLAG='Y';
			traceit.log(traceit.constDEBUGLEVEL_C, 'jnl-in-progress: l_curr_jnl = %s', l_curr_jnl);
		exception
			when no_data_found then
				select 
					max(id)-1
				  into l_curr_jnl
				  from hostdb.journals;
				traceit.log(traceit.constDEBUGLEVEL_C, 'No journal-in-progress: l_curr_jnl = %s', l_curr_jnl);
			when others then
				raise_application_error(X_UNKNOWN, 'Error happend when retrieving journal. '
						|| sqlerrm );

		end;

		if (l_curr_jnl <= l_max_jnl) then
			traceit.log(traceit.constDEBUGLEVEL_A, 'Current machine state jnl=%s  has been populated into mach_hist max_jnl=%s', l_curr_jnl, l_max_jnl);
			raise_application_error(X_UNKNOWN, 'Current user state has been populated into mach_hist.');
		end if;

		insert /*+ append */
		  into mach_hist (NID, assetid, journal, charge_by, dist_src)
			select 
				machhist_idseq.nextval
				,assetno
				,l_curr_jnl
				,charge_by
				,dist_src
			  from hostdb.machtab
			 where dist is not null;
		traceit.log(traceit.constDEBUGLEVEL_B, '%s entries populated into mach_hist_fastfresh', SQL%ROWCOUNT);
		traceit.log(traceit.constDEBUGLEVEL_A, 'Exit mach_hist_fastfresh');
	end mach_hist_fastfresh;

	procedure populate_confighist(p_jnl IN number default 0, p_what IN varchar2 default constWhatBoth)
	as
	begin
		traceit.log(traceit.constDEBUGLEVEL_A, 'Enter populate_confighist p_jnl=%s, p_what=%s', p_jnl, p_what);
		if ( p_what = constWhatBoth or p_what = constWhatUser ) then
			user_hist_fastfresh(p_jnl);
		end if;
		
		if ( p_what = constWhatBoth or p_what = constWhatMach ) then
			mach_hist_fastfresh(p_jnl);
		end if;
		traceit.log(traceit.constDEBUGLEVEL_A, 'Exit populate_confighist');
	end populate_confighist;

	procedure populate_chgsvc_hist(p_jnl IN number default 0, p_what IN varchar2 default constWhatBoth)
	as
	begin
		traceit.log(traceit.constDEBUGLEVEL_A, 'Enter populate_chgsvc_hist p_jnl=%s, p_what=%s', p_jnl, p_what);
		if ( p_what = constWhatBoth or p_what = constWhatUser ) then
			user_hist_fastfresh(p_jnl);
		end if;
		
		if ( p_what = constWhatBoth or p_what = constWhatMach ) then
			mach_hist_fastfresh(p_jnl);
		end if;
		traceit.log(traceit.constDEBUGLEVEL_A, 'Exit populate_chgsvc_hist');
	end populate_chgsvc_hist;

end util_adhoc;
/
show errors
