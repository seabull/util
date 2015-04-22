-- $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/schema/pkgs/report.spb.sql,v 1.9 2006/09/21 16:54:08 yangl Exp $
create or replace package body EntityChanged as

	procedure purge(p_rpt_id	IN ReportIdType);
	procedure purge;
	function getDB_idByTS(p_previous	IN timestamp
				, p_current	IN timestamp)
		return ReportIdType;

	procedure new(p_previous	IN timestamp
			, p_current	IN timestamp
			, p_type	IN RptTypeType 
			, p_subtype	IN RptSubtypeType );

	function incDB_reportid(p_previous	IN timestamp
				, p_current	IN timestamp
				, p_type	IN RptTypeType
				, p_subtype	IN RptSubtypeType
				, p_status	IN RptStatusType)
		return pls_integer;

	/*
	 * Internal procedures
	 */
	function incDB_reportid(p_previous	IN timestamp
				, p_current	IN timestamp
				, p_type	IN RptTypeType
				, p_subtype	IN RptSubtypeType
				, p_status	IN RptStatusType)
	return pls_integer
	is
		l_id	pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 
			'Enter incDB_reportid(p_prev=%s, p_current=%s, p_type=%s, psubtype=%s, p_status=%s)'
			, p_previous,p_current,p_type, p_subtype, p_status);

		select ccreport_id_seq.nextval
		  into l_id
		  from dual;

		traceit.log(traceit.constDEBUGLEVEL_A, 'Inserting ID=%s', l_id);
		insert into ccreport_logs 
			(ccreport_id, ts_old, ts_new, rpttype, rptsubtype, status)
			values	( l_id , p_previous , p_current, p_type, p_subtype, p_status);
		
		traceit.log(traceit.constDEBUGLEVEL_B, 
				'Enter getDB_idByTS(p_current=%s, p_previous=%s)'
				, p_current, p_previous);
		return l_id;
	end incDB_reportid;

	/*
	 * Getters
	 */
	function getLast_Ts return timestamp
	is
	begin
		return g_last_ts;
	end getLast_Ts;

	function getCurrent_Ts return timestamp
	is
	begin
		return g_current_ts;
	end getCurrent_Ts;

	function getCurrent_Id return ReportIdType
	is
	begin
		return g_current_id;
	end getCurrent_Id;

	function getDB_idByTS(p_previous IN timestamp, p_current IN timestamp) 
	return ReportIdType
	is
		l_exist_id	pls_integer := 0;
		l_status	RptStatusType;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 
			'Enter getDB_idByTS(p_current=%s, p_previous=%s)'
			, p_current, p_previous);
		begin
			select max(ccreport_id)
			  into l_exist_id
			  from ccreport_logs
			 where ts_old = p_previous
			   and ts_new = p_current;
			 --  and status = constStatusRecorded;

			if l_exist_id is null then
				l_exist_id := 0;
				traceit.log(traceit.constDEBUGLEVEL_B
					, 'No Matching Report exists set id to 0 ');
			else
				select status
				  into l_status
				  from ccreport_logs
				 where ccreport_id = l_exist_id;
				
			end if;
		exception
			when no_data_found then
				l_exist_id := 0;
				traceit.log(traceit.constDEBUGLEVEL_B, 
					'No Matching Report exists - %s : %s'
					, sqlcode, sqlerrm);
		end;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit getDB_idByTS=%s', l_exist_id);
		return l_exist_id;
	end getDB_idByTS;

	/*
	 */
	function getDB_Last_Id(	p_type		IN OUT  RptTypeType	
				, p_subtype	IN OUT  RptSubtypeType 
				, p_ts_since	OUT timestamp
				, p_ts_until	OUT timestamp
				, p_generated	OUT date
				, p_status	OUT RptStatusType)
	return ReportIdType is
		l_id		ReportIdType	:= 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'Enter getDB_Last_Id(p_type=%s, p_subtype=%s)' ,p_type, p_subtype);

		begin
			if p_type is not null then
				if p_subtype is not null then
					select max(ccreport_id)
					  into l_id
					  from ccreport_logs
					 where rptType = p_type
					   and rptSubtype = p_subtype;
				else
					select max(ccreport_id)
					  into l_id
					  from ccreport_logs
					 where rptType = p_type;
				end if;
			else 
				if p_subtype is not null then
					select max(ccreport_id)
					  into l_id
					  from ccreport_logs
					 where rptSubtype = p_subtype;
				else
					select max(ccreport_id)
					  into l_id
					  from ccreport_logs;
				end if;
			end if;

			traceit.log(traceit.constDEBUGLEVEL_A , 'Found report ID=%s', l_id);

			select ccreport_id, ts_old, ts_new, rpttype, rptsubtype, generated, status
			  into l_id, p_ts_since, p_ts_until, p_type, p_subtype, p_generated, p_status
			  from ccreport_logs
			 where ccreport_id = l_id;

		exception
			when no_data_found then
				traceit.log(traceit.constDEBUGLEVEL_A
					, 'No ID found, use Id=0');
				l_id           := 0;
				p_ts_since     := null;
				p_ts_until     := null;
				p_type         := null;
				p_subtype      := null;
				p_generated    := null;
				p_status       := null;
		end;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit getDB_Last_Id=%s)', l_id);
		return l_id;
	end getDB_Last_Id;

	--
	-- OUT values are valid only if return value > 0;
	--
	function getDB_Last_Id(	p_rptid		IN  ReportIdType 
				, p_ts_since	OUT timestamp
				, p_ts_until	OUT timestamp
				, p_type	OUT RptTypeType
				, p_subtype	OUT RptSubtypeType
				, p_generated	OUT date
				, p_status	OUT RptStatusType)
	return ReportIdType is
		l_id	ReportIdType	:= 0;
		l_type	RptTypeType	:= constTypeRegular;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'Enter getDB_Last_Id(p_rptid=%s)' ,p_rptid);
		if(p_rptid is not null and p_rptid <> 0) then
			l_id := p_rptid;
		end if;
		
		begin
			if l_id = 0 then
				select ccreport_id, ts_old, ts_new, rpttype, rptsubtype, generated, status
				  into l_id, p_ts_since, p_ts_until, p_type, p_subtype, p_generated, p_status
				  from ccreport_logs;
			else
				select ts_old, ts_new, rpttype, rptsubtype, generated, status
				  into p_ts_since, p_ts_until, p_type, p_subtype, p_generated, p_status
				  from ccreport_logs
				 where ccreport_id = l_id;
			end if;
		exception
			when no_data_found then
				traceit.log(traceit.constDEBUGLEVEL_A , 'No ID found, use Id=0');
				l_id       := 0;
				p_ts_since := null;
				p_ts_until := null;
				p_type     := null;
				p_subtype  := null;
				p_generated:= null;
				p_status   := null;
		end;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit getDB_Last_Id=%s)', l_id);
		return l_id;
	end getDB_Last_Id;

	function getDB_Last_Id(p_type IN RptTypeType default null) return ReportIdType
	is
		l_id		ReportIdType;
		l_type		RptTypeType    := p_type;
		l_subtype	RptSubtypeType := null;
		l_ts_since	timestamp;
		l_ts_until	timestamp;
		l_generated	date;
		l_status	RptStatusType;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter getDB_Last_Id(p_type=%s)', p_type);

		l_id := getDB_Last_Id(	l_type
					, l_subtype
					, l_ts_since
					, l_ts_until
					, l_generated
					, l_status);

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit getDB_Last_Id=%s', l_id);
		return l_id;	
	end getDB_Last_Id;

	function getDB_Ts_New(p_id ReportIdType default 0) return timestamp
	is
		l_id	ReportIdType;
		l_ts	timestamp;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'Enter ccreport.getDB_Ts_New(p_id=%s)', p_id);
		if p_id <= 0 then
			l_id := getDB_Last_Id(constTypeRegular);
			if l_id <= 0 then
				traceit.log(traceit.constDEBUGLEVEL_A
					, 'No previous regular report id found.');
				return sysdate - 7;
			end if;
		else
			l_id := p_id;
		end if;

		select ts_new
		  into l_ts
		  from ccreport_logs
		 where ccreport_id=l_id
		;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.getDB_Ts_New=%s', l_ts);
		return l_ts;
	exception
		when no_data_found then
			traceit.log(traceit.constDEBUGLEVEL_A, 'getDB_Ts_New - %s : %s', sqlcode, sqlerrm);
			raise_application_error(-20100, 'No report id='||l_id||' found of type.'||SQLCODE);
			
		when others then
			traceit.log(traceit.constDEBUGLEVEL_A, 'Error in getDB_Ts_New - %s : %s', sqlcode, sqlerrm);
			raise_application_error(-20100, 'No report id='||l_id||' found of type.'||SQLCODE);
	end getDB_Ts_New;

	function getDB_Ts_Old(p_id ReportIdType default 0) return timestamp
	is
		l_id	ReportIdType;
		l_ts	timestamp;
	begin
		if p_id <= 0 then
			l_id := getDB_Last_Id(constTypeRegular);
			if l_id <= 0 then
				traceit.log(traceit.constDEBUGLEVEL_A
						, 'No previous regular report id found.');
				return sysdate - 7;
			end if;
		else
			l_id := p_id;
		end if;
		begin
			select ts_Old
			  into l_ts
			  from ccreport_logs
			 where ccreport_id = l_id;
		exception
			when no_data_found then
				traceit.log(traceit.constDEBUGLEVEL_A
					, 'No report found in getDB_Ts_Old - %s : %s'
					, sqlcode, sqlerrm);
				l_ts := sysdate - 7;
			when others then
				traceit.log(traceit.constDEBUGLEVEL_A
					, 'Error in getDB_Ts_Old - %s : %s'
					, sqlcode, sqlerrm);
				raise_application_error(-20100, 'No report id='
						||l_id
						||' found of type.'
						||SQLCODE);
		end;

		return l_ts;
	end getDB_Ts_Old;

	procedure deleteid(p_id IN ReportIdType default 0) is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.deleteid(p_id=%s)', p_id);
		if p_id = 0 then
			init(null);
		end if;
		purge(g_current_id);
		delete from ccreport_logs where ccreport_id=g_current_id;
		traceit.log(traceit.constDEBUGLEVEL_B
				, '%s is purged and deleted from ccreport_logs'
				, g_current_id);

		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.deleteid');
	end deleteid;
	/*
	 * create new report ids using systimestamp and last report id
	 */
	--
	-- create new regular reports
	--
	procedure new(p_subtype RptSubtypeType default null) is
		--l_last_id	ReportIdType := 0;
		--l_last_ts	timestamp;
		l_subtype	RptSubtypeType;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.new');

		--l_last_id := getDB_Last_Id(constTypeRegular);
		
		--g_last_ts := getDB_Ts_New(0);

		--g_current_ts	:= systimestamp;

		if p_subtype is null then
			l_subtype := constSubTypeRegular;
		else
			l_subtype := p_subtype;
		end if;

		new(	p_previous => null , p_current => null
			, p_type => constTypeRegular, p_subtype => l_subtype);

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.new');
	end new;

	--
	-- create new ad hoc reports
	--
	procedure new(p_type RpttypeType, p_previous timestamp, p_current timestamp) is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
			, 'Enter ccreport.new(p_type=%s, p_prev=%s, p_curr=%s'
			, p_type, p_previous, p_current);
		
		if p_type = constTypeRegular then
			traceit.log(traceit.constDEBUGLEVEL_A
				, 'This is not the procedure intended to create new regular reports.'
				||'new(p_type, p_prev, p_curr) ');
			raise_application_error(Error_Codes.err_method_call
				, 'The procedure is not intended to create new regular reports.'
				||'try other overloaded methods.'
				);
		end if;

		new(	p_previous => p_previous , p_current => p_current
			, p_type => p_type, p_subtype => constSubTypeNA);
		
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.new');
	end new;

	/*
	 * create new report ids using timestamp arguments
	 */
	procedure new(	p_previous	IN timestamp 
			, p_current	IN timestamp 
			, p_type	IN RptTypeType 
			, p_subtype	IN RptSubtypeType )
	is
		l_type		RptTypeType	:= p_type;
		l_subtype	RptSubtypeType	:= p_subtype;

		-- used for search last ID
		ll_id		ReportIdType    := 0;
		ll_type		RptTypeType	:= p_type;
		ll_subtype	RptSubtypeType	:= p_subtype;
		ll_ts_since	timestamp;
		ll_ts_until	timestamp;
		ll_generated	date;
		ll_status	RptStatusType;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
			, 'Enter ccreport.new(p_curr=%s, p_prev=%s, p_type=%s, p_subtype=%s'
			, p_current, p_previous, p_type, p_subtype);

		if ll_type is not null then
			--
			-- set the search subtype to null if type is not null
			-- This is to handle the case that regular report should
			-- be based on the previous regular report no matter whether
			-- the previous one was Labor or Regular subtype.
			--
			ll_subtype := null;
		end if;

		if p_current is null then
			g_current_ts := systimestamp;
		else
			g_current_ts := p_current;
		end if;

		if p_previous is null then

			ll_id := getDB_Last_Id(ll_type, ll_subtype, ll_ts_since
					, ll_ts_until, ll_generated, ll_status);

			if ll_id = 0 then
				-- use a week time span
				g_last_ts := g_current_ts - 7;
				--g_last_ts := sysdate - 7;
				l_type    := constTypeRegular;
				l_subtype := constSubTypeRegular;

				traceit.log(traceit.constDEBUGLEVEL_B
					, 'No previous report ID found, use current_ts-7=%s'
					, g_last_ts);
			else
				g_last_ts := ll_ts_until;
				traceit.log(traceit.constDEBUGLEVEL_B, 'Use g_last_ts=%s', g_last_ts);
			end if;
			traceit.log(traceit.constDEBUGLEVEL_B, 'Use last report TS_NEW=%s', g_last_ts);
		else
			g_last_ts	:= p_previous;
		end if;

		if l_type is null then
			l_type := constTypeRegular;
		end if;

		if l_subtype is null then
			if l_type = constTypeRegular then
				l_subtype := constSubTypeRegular;
			else
				l_subtype := constSubTypeNA;
			end if;
		end if;

		traceit.log(traceit.constDEBUGLEVEL_A
					, 'Inserting report id (%s, %s, %s, %s, %s)'
					,  g_last_ts, g_current_ts
					, l_type, l_subtype, constStatusInit);

		g_current_id := incDB_reportid(g_last_ts, g_current_ts, l_type, l_subtype, constStatusInit);
		
		traceit.log(traceit.constDEBUGLEVEL_A
					, 'Inserted report id = %s', g_current_id);
		--prepare_session;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.new(p_curr, p_prev, p_type, p_subtype)');
	end new;

	procedure init(p_reportid IN ReportIdType, p_type IN RptTypeType default 'R') is
		l_id		ReportIdType;
		l_type		RptTypeType    := p_type;
		l_subtype	RptSubtypeType := null;
		l_ts_since	timestamp;
		l_ts_until	timestamp;
		l_generated	date;
		l_status	RptStatusType;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'Enter ccreport.init(p_reportid=%s, p_type=%s)'
				, p_reportid, p_type);
		if p_reportid is null then
			--l_id := getDB_Last_Id(p_type);
			l_id := getDB_Last_Id(l_type, l_subtype, l_ts_since
						, l_ts_until, l_generated, l_status);

		else
			--l_id := p_reportid;
			l_id := getDB_Last_Id(p_reportid, l_ts_since, l_ts_until
						, l_type, l_subtype,  l_generated, l_status);
		end if;

		if (l_id < 1) then
				traceit.log(traceit.constDEBUGLEVEL_A
						, 'Could not find related report ID. p_type=%s');
				raise_application_error(Error_Codes.err_reportid_notfound
						, 'No report id found of type '
						||p_type||' '||SQLCODE);
		end if;
			
		g_current_id	:= l_id;
		g_last_ts	:= l_ts_since;
		g_current_ts	:= l_ts_until;
		--g_last_ts	:= getDB_Ts_Old(l_id);
		--g_current_ts	:= getDB_Ts_New(l_id);

		--prepare_session;
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'Enter ccreport.init(), g_current_id=%s, g_last_ts=%s, g_current_ts=%s'
				, g_current_id, g_last_ts, g_current_ts);
	end init;

	procedure prepare_session 
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.prepare_session');
		-- Assume g_last and g_current have been populated, i.e. init-ed.
		histview_utils.new(g_last_ts, g_current_ts);
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.prepare_session');
	end prepare_session;

	--
	-- prepare the materialized view
	--
	-- Assume materialized views have been created.
	--
	procedure prepare_prev is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.prepare_prev');
		dbms_mview.refresh('wsc_aggr_hist_mv');
		dbms_mview.refresh('hsc_aggr_hist_mv');
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.prepare_prev');
	end prepare_prev;

	procedure prepare_curr is
	begin 
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.prepare_curr');
		dbms_mview.refresh('wsc_aggr_curr_mv');
		dbms_mview.refresh('hsc_aggr_curr_mv');
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.prepare_curr');
	end prepare_curr;

	--
	-- populate the data
	--
	--procedure record_entity_changed is
	function record_entity_changed return pls_integer is
		l_cnt	pls_integer := 0;		
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.record_entity_changed');
		-- Should existing ones be purged?
		--
		delete from who_charge_changed
		 where report_log_id = g_current_id;
		traceit.log(traceit.constDEBUGLEVEL_A
				, '%s entries purged from who_charge_changed'
				, SQL%ROWCOUNT);

		insert into who_charge_changed 
			(
				report_log_id
				, princ
			)
			select
				g_current_id
				,princ
			  from (
				select
					unique princ
				  from aud_hostdb.who_service_charge
				 where aud_ts > g_last_ts
				   and aud_ts <= g_current_ts
				   and princ not in ( select h.princ
							from wsc_aggr_hist_mv h
								,wsc_aggr_curr_mv c
							where h.princ=c.princ
							  and h.dist_vec=c.dist_vec
							  and h.services=c.services
							)
				union
				select
					c.princ
				  from who_hist_v h
					,who_curr_v c
				 where c.princ=h.princ
				   and nvl(c.charge_by, 'L')!=nvl(h.charge_by, 'L')
				) ;

		traceit.log(traceit.constDEBUGLEVEL_A
				, '%s entries inserted into who_charge_changed'
				, SQL%ROWCOUNT);
		l_cnt := SQL%ROWCOUNT;
		delete from host_charge_changed
		 where report_log_id = g_current_id;
		traceit.log(traceit.constDEBUGLEVEL_A
				, '%s entries purged from who_charge_changed'
				, SQL%ROWCOUNT);

		insert into host_charge_changed 
			(
				report_log_id
				, assetno
				, pri
			)
			select
				g_current_id
				,assetno
				,pri
			  from (
				select
					unique assetno
						,pri
				  from aud_hostdb.host_service_charge
				 where aud_ts > g_last_ts
				   and aud_ts <= g_current_ts
				   and assetno not in ( select h.assetno
							from hsc_aggr_hist_mv h
								,hsc_aggr_curr_mv c
							where h.assetno=c.assetno
							  and h.dist_vec=c.dist_vec
							  and h.services=c.services
							  and h.pri=c.pri
							)
				union
				select
					assetno
					,nvl(pri, 0)
				  from (
					select
						c.assetno
						,(select min(pri) from hoststab_curr_v x where x.assetno=c.assetno) pri
					  from machtab_hist_v h
						,machtab_curr_v c
					 where c.assetno=h.assetno
					   and nvl(c.charge_by, 'L')!=nvl(h.charge_by, 'L')
					)
				) ;

		traceit.log(traceit.constDEBUGLEVEL_A
				, '%s entries inserted into host_charge_changed'
				, SQL%ROWCOUNT);
		l_cnt := l_cnt + SQL%ROWCOUNT;
		--update host_charge_changed
		--   set pri=0
		-- where report_log_id=g_current_id
		--   and pri is null;
		--traceit.log(traceit.constDEBUGLEVEL_A
		--		, '%s entries updated in host_charge_changed to pri 0'
		--		, SQL%ROWCOUNT);
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'Exit ccreport.record_entity_changed=%s', l_cnt);
		return l_cnt;
	end record_entity_changed;
	
	--procedure record_entity_conf is
	function record_entity_conf return pls_integer is
		l_cnt	pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.record_entity_conf');
		--
		-- Users
		--
		insert into who_conf_changed
		(report_log_id, princ,name ,charge_by,sponsor,PctUser,service_vec,dist_id,ChargeAmount,LastChanged,change_flag)
		select
			g_current_id
			,princ
			,name
			,charge_by
			,sponsor
			,PercentUser
			,services
			,dist_id
			,ChargeAmount
			,LastChanged
			,flag
		  from who_config_hist_v
		 where princ in (select princ from who_charge_changed where report_log_id=g_current_id);

		traceit.log(traceit.constDEBUGLEVEL_A
			, '%s rows inserted into who_conf_changed as old conf.'
			, SQL%ROWCOUNT);
		l_cnt := SQL%ROWCOUNT;

		insert into who_conf_changed
		(report_log_id, princ, name ,charge_by,sponsor,PctUser,service_vec,dist_id,ChargeAmount,LastChanged,change_flag)
		select
			g_current_id
			,princ
			,name
			,charge_by
			,sponsor
			,PercentUser
			,services
			,dist_id
			,ChargeAmount
			,LastChanged
			,flag
		  from who_config_curr_v
		 where princ in (select princ from who_charge_changed where report_log_id=g_current_id);

		traceit.log(traceit.constDEBUGLEVEL_A
				, '%s rows inserted into who_conf_changed as new conf.'
				, SQL%ROWCOUNT);
		l_cnt := l_cnt + SQL%ROWCOUNT;
		--
		-- Machines
		--
		insert into host_conf_changed
		(report_log_id ,assetno ,hostname ,pri ,charge_by ,qual ,service_vec,location,primaryUser ,os ,dist_id ,dept ,ChargeAmount ,LastChanged ,change_flag ,ipaddress ,protocol)
		select
			g_current_id
			,assetno 
			,hostname 
			,pri 
			,charge_by 
			,qual 
			,services 
			,nvl(location, 'unknown')
			,primaryUser 
			,nvl(os, 'unknown')
			,dist_id 
			,dept 
			,ChargeAmount 
			,greatest(nvl(LastChanged_c, to_date('01-JAN-2000'))
					, nvl(LastChanged_m, to_date('01-JAN-2000'))
					, nvl(LastChanged_h, to_date('01-JAN-2000'))
				)  
			,flag 
			,nvl(ipaddress,'na')
			,nvl(protocol,'na')
		  from host_config_hist_v
		 where assetno in (select assetno from host_charge_changed where report_log_id=g_current_id);
		traceit.log(traceit.constDEBUGLEVEL_A
				, '%s rows inserted into host_conf_changed as old conf.'
				, SQL%ROWCOUNT);
		l_cnt := l_cnt + SQL%ROWCOUNT;

		insert into host_conf_changed
		(report_log_id ,assetno ,hostname ,pri ,charge_by ,qual ,service_vec,location,primaryUser ,os ,dist_id ,dept ,ChargeAmount ,LastChanged ,change_flag ,ipaddress ,protocol)
		select
			g_current_id
			,assetno 
			,hostname 
			,pri 
			,charge_by 
			,qual 
			,services 
			,nvl(location, 'unknown')
			,primaryUser 
			,nvl(os ,'unknown')
			,dist_id 
			,dept 
			,ChargeAmount 
			--,greatest(LastChanged_c, LastChanged_m, LastChanged_h)  
			,greatest(nvl(LastChanged_c, to_date('01-JAN-2000'))
					, nvl(LastChanged_m, to_date('01-JAN-2000'))
					, nvl(LastChanged_h, to_date('01-JAN-2000'))
				)  
			,flag 
			,nvl(ipaddress ,'na')
			,nvl(protocol,'na')
		  from host_config_curr_v
		 where assetno in (select assetno from host_charge_changed where report_log_id=g_current_id);
		traceit.log(traceit.constDEBUGLEVEL_A
				, '%s rows inserted into host_conf_changed as new conf.'
				, SQL%ROWCOUNT);
		l_cnt := l_cnt + SQL%ROWCOUNT;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.record_entity_conf=%s', l_cnt);
		return l_cnt;
	end record_entity_conf;

	procedure purge_entity(p_rpt_id IN ReportIdType) is
		l_rpt_id	ReportIdType;
	begin
		if (p_rpt_id is null or p_rpt_id=0) then
			l_rpt_id := g_current_id;
		else
			l_rpt_id := p_rpt_id;
		end if;

		delete from who_charge_changed
		where report_log_id=l_rpt_id;

		traceit.log(traceit.constDEBUGLEVEL_A
			, '%s rows purged from who_charge_changed for report_log_id=%s'
			, SQL%ROWCOUNT, l_rpt_id);
		delete from host_charge_changed
		where report_log_id=l_rpt_id;
		traceit.log(traceit.constDEBUGLEVEL_A
				, '%s rows purged from host_charge_changed for report_log_id=%s'
				, SQL%ROWCOUNT, l_rpt_id);
	end purge_entity;

	procedure purge_conf(p_rpt_id IN ReportIdType) is
		l_rpt_id	ReportIdType;
	begin
		if (p_rpt_id is null or p_rpt_id=0) then
			l_rpt_id := g_current_id;
		else
			l_rpt_id := p_rpt_id;
		end if;

		delete from who_conf_changed
		where report_log_id=l_rpt_id;

		traceit.log(traceit.constDEBUGLEVEL_B
				, '%s rows purged from who_conf_changed for report_log_id=%s'
				, SQL%ROWCOUNT, l_rpt_id);

		delete from host_conf_changed
		where report_log_id=l_rpt_id;

		traceit.log(traceit.constDEBUGLEVEL_B
				, '%s rows purged from host_conf_changed for report_log_id=%s'
				, SQL%ROWCOUNT, l_rpt_id);
	end purge_conf;

	procedure purge(p_rpt_id IN ReportIdType) is
		--l_rpt_id	ReportIdType;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.record.purge(p_rpt_id=%s)', p_rpt_id);
		purge_entity(p_rpt_id);
		purge_conf(p_rpt_id);

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.purge');
	end purge;

	procedure purge is
	begin
		purge(null);
	end purge;

	--procedure rptRecord(p_recapture IN boolean, p_rpt_id IN ReportIdType default null) is
	function rptRecord(	p_recapture	IN boolean
				, p_rpt_id	IN ReportIdType default null)
	return pls_integer is
		l_ucount		pls_integer := 0;
		l_mcount		pls_integer := 0;
		l_cnt			pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.record');
		if p_rpt_id is not null or g_last_ts is null or g_current_ts is null then
			init(p_rpt_id);
		end if;

		if p_recapture then
			purge;
		end if;

		prepare_session;
		prepare_prev;
		prepare_curr;
		
		select count(*)
		  into l_ucount
		  from who_charge_changed
		 where report_log_id=g_current_id;

		traceit.log(traceit.constDEBUGLEVEL_A
				, '%s entries found in who_charge_changed'
				, l_ucount);

		select count(*)
		  into l_mcount
		  from host_charge_changed
		 where report_log_id=g_current_id;

		traceit.log(traceit.constDEBUGLEVEL_A
				, '%s entries found in host_charge_changed'
				, l_mcount);

		if l_ucount <= 0 and l_mcount <= 0 then
			l_cnt := record_entity_changed;
			if l_cnt <= 0 then
				update ccreport_logs
				   set status=constStatusRecorded
				 where ccreport_id=g_current_id;
				traceit.log(traceit.constDEBUGLEVEL_A
						, 'No entries recorded for report %s'
						, g_current_id);
				return l_cnt;
			end if;
		else
			traceit.log(traceit.constDEBUGLEVEL_A
				, 'ccreport.record - %s, %s rows already in who and host _charge_changed, no recording.'
				, l_ucount, l_mcount);
		end if;

		select count(*)
		  into l_ucount
		  from who_conf_changed
		 where report_log_id=g_current_id;

		select count(*)
		  into l_mcount
		  from host_conf_changed
		 where report_log_id=g_current_id;

		l_cnt := l_ucount + l_mcount;

		traceit.log(traceit.constDEBUGLEVEL_A
				, '%s entries found in who_conf_changed'
				||' %s entries found in host_conf_changed'
				, l_ucount, l_mcount);

		if l_ucount <= 0 and l_mcount <= 0 then
			l_cnt := record_entity_conf;
		else
			traceit.log(traceit.constDEBUGLEVEL_A
				, 'ccreport.record - %s, %s rows already in who/host_conf_changed, no recording.'
				, l_ucount, l_mcount);
		end if;

		update ccreport_logs
		   set status=constStatusRecorded
		 where ccreport_id=g_current_id;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.record=%s', l_cnt);
		return l_cnt;
	end rptRecord;

	-- return report id if change records exist
	-- otherwise return 0
	--procedure rptRecordNew is
	--function rptRecordNew return pls_integer is
	function rptRecordNew(p_subtype	IN RptSubtypeType default 'W')
	return pls_integer is
		l_rtn	pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.rptRecordNew');

		new(p_subtype);

		l_rtn := rptRecord(false);	

		--if l_rtn > 0 then
			l_rtn := getCurrent_id;
		--end if;	

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.rptRecordNew=%s', l_rtn);

		return l_rtn;
	end rptRecordNew;

	--procedure rptRecordNew(p_previous IN timestamp, p_current IN timestamp) is
	function rptRecordNew(	p_previous	IN timestamp
				, p_current	IN timestamp
				, p_type	IN RptTypeType default 'R'
				, p_subtype	IN RptSubtypeType default 'W')
	return pls_integer
	is
		--l_exist_id	pls_integer := 0;
		l_rtn		pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
			, 'Enter ccreport.rptRecordNew(p_current=%s, p_previous=%s)'
			, p_current, p_previous);

		if p_type = constTypeRegular then

			-- always record if it is a regular report.
			traceit.log(traceit.constDEBUGLEVEL_B, 'Create regular report.');

			new(	p_previous => p_previous , p_current => p_current
				, p_type => p_type, p_subtype => p_subtype);
			l_rtn := rptRecord(false);	
			--if l_rtn > 0 then
				l_rtn := getCurrent_id;
			--end if;
			traceit.log(traceit.constDEBUGLEVEL_B, 'Regular report id=%s completed.', l_rtn);

		else
			l_rtn := getDB_idByTS(p_previous, p_current);

			if l_rtn < 1 then
				traceit.log(traceit.constDEBUGLEVEL_B, 'Create Adhoc report.');
				--new(p_previous , p_current, constTypeAdhoc);
				new(constTypeAdhoc, p_previous , p_current);

				l_rtn := rptRecord(false);	
				--if l_rtn > 0 then
					l_rtn := getCurrent_id;
				--end if;
				traceit.log(traceit.constDEBUGLEVEL_B, 'Adhoc report id=%s completed.', l_rtn);
			else
				traceit.log(traceit.constDEBUGLEVEL_B
					, 'Match report id=%s found. Reuse the recorded report.'
					, l_rtn);
			end if;
		end if;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.rptRecordNew=%s', l_rtn);

		return l_rtn;
	end rptRecordNew;

	procedure rptInit is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.rptInit');
		new;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.rptInit');
	end rptInit;

end EntityChanged;
/
show error
