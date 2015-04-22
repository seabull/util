create or replace package EntityChanged as
	-- types
	subtype ReportIdType is ccreport_logs.ccreport_id%TYPE;

	-- global variables
	g_last_ts	timestamp;
	--g_last_id	ReportIdType := 0;
	g_current_ts	timestamp;
	g_current_id	ReportIdType := 0;
	constTypeRegular	char(1)	:= 'R';
	constTypeAdhoc		char(1)	:= 'A';

	constSubTypeRegular	char(1)	:= 'W';
	constSubTypeLabor	char(1)	:= 'L';

	constStatusInit		char(1)	:= 'I';
	constStatusProcess	char(1)	:= 'P';
	constStatusRecorded	char(1)	:= 'R';
	constWSCMVPREV		varchar2(16)	:= 'wsc_aggr_hist_mv';
	constWSCMVCURR		varchar2(16)	:= 'wsc_aggr_curr_mv';
	
	function getLast_Ts return timestamp;
	function getCurrent_Ts return timestamp;
	function getCurrent_Id return number;

	function getDB_Last_Id(p_type IN char default null) return number;
	function getDB_Ts_New(p_id number default 0) return timestamp;
	function getDB_Ts_Old(p_id number default 0) return timestamp;

	--procedure new;
	procedure new(p_subtype char default null) ;
	procedure new(p_previous IN timestamp, p_current IN timestamp, p_type IN char default null, p_subtype IN char default null);
	procedure deleteid(p_id IN number default 0) ;
	--procedure init(p_reportid in number) ;
	procedure init(p_reportid in number, p_type in char default 'R') ;
	procedure prepare_session ;
	function record_entity_changed return pls_integer;
	function rptRecord(p_recapture IN boolean, p_rpt_id IN number default null) return pls_integer;

	function rptRecordNew return pls_integer;
	--function rptRecordNew(p_previous IN timestamp, p_current IN timestamp) return pls_integer;
	function rptRecordNew(p_previous IN timestamp, p_current IN timestamp, p_type IN char default 'R', p_subtype IN char default 'W') return pls_integer;
	--procedure rptRecordNew;
	--procedure rptRecordNew(p_current IN timestamp, p_previous IN timestamp);
end EntityChanged;
.
run
show error

create or replace package body EntityChanged as

	procedure purge(p_rpt_id IN number);
	procedure purge;
	function getDB_idByTS(p_previous IN timestamp, p_current IN timestamp) return number;
	function incDB_reportid(p_previous IN timestamp, p_current IN timestamp, p_type IN char, p_subtype IN char, p_status IN char) return pls_integer;

	function incDB_reportid(p_previous IN timestamp, p_current IN timestamp, p_type IN char, p_subtype IN char, p_status IN char) return pls_integer
	is
		l_id	pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter incDB_reportid(p_prev=%s, p_current=%s, p_type=%s, psubtype=%s, p_status=%s)', p_previous,p_current,p_type, p_subtype, p_status);

		select ccreport_id_seq.nextval
		  into l_id
		  from dual;

		traceit.log(traceit.constDEBUGLEVEL_A, 'Inserting ID=%s', l_id);
		insert into ccreport_logs (ccreport_id, ts_old, ts_new, type, subtype, status)
				values	( l_id , p_previous , p_current, p_type, p_subtype, p_status);
		
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter getDB_idByTS(p_current=%s, p_previous=%s)', p_current, p_previous);
		return l_id;
	end incDB_reportid;
	/*
	 * Internal procedures
	 */
	/*
	procedure fetch_last is
		l_last_id	number;
	begin
		--select max(ccreport_id)
		--  into l_last_id
		--  from ccreport_logs_r;

		--select ts_new
		--  into g_last_ts
		--  from ccreport_logs_r
		-- where ccreport_id=l_last_id;
		g_last_ts := getDB_Ts_New(getDB_Last_Id(constTypeRegular));
	exception
		when no_data_found then
			g_last_ts	:= systimestamp;
	end fetch_last;
	*/

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

	function getCurrent_Id return number
	is
	begin
		return g_current_id;
	end getCurrent_Id;

	function getDB_idByTS(p_previous IN timestamp, p_current IN timestamp) return number
	is
		l_exist_id	pls_integer := 0;
		l_status	char(1);
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter getDB_idByTS(p_current=%s, p_previous=%s)', p_current, p_previous);
		begin
			select max(ccreport_id)
			  into l_exist_id
			  from ccreport_logs
			 where ts_old = p_previous
			   and ts_new = p_current;
			 --  and status = constStatusRecorded;

			if l_exist_id is null then
				l_exist_id := 0;
				traceit.log(traceit.constDEBUGLEVEL_B, 'No Matching Report exists set id to 0 ');
			else
				select status
				  into l_status
				  from ccreport_logs
				 where ccreport_id = l_exist_id;
				
			end if;
		exception
			when no_data_found then
				l_exist_id := 0;
				traceit.log(traceit.constDEBUGLEVEL_B, 'No Matching Report exists - %s : %s', sqlcode, sqlerrm);
		end;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit getDB_idByTS=%s', l_exist_id);
		return l_exist_id;
	end getDB_idByTS;

	/*
	 */
	function getDB_Last_Id(p_type IN char default null) return number
	is
		l_last_id	number;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter getDB_Last_Id(p_type=%s)', p_type);
		begin
			if (p_type = constTypeRegular or p_type = constTypeAdhoc) then
				select max(ccreport_id)
				  into l_last_id
				  from ccreport_logs
				 where type=p_type;
			else
				select max(ccreport_id)
				  into l_last_id
				  from ccreport_logs;
			end if;
		exception
			when no_data_found then
				l_last_id := 0;
				traceit.log(traceit.constDEBUGLEVEL_A, 'No Last Report exists - %s : %s', sqlcode, sqlerrm);
		end;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit getDB_Last_Id=%s', l_last_id);
		return l_last_id;	
	end getDB_Last_Id;

	function getDB_Ts_New(p_id number default 0) return timestamp
	is
		l_id	number;
		l_ts	timestamp;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.getDB_Ts_New(p_id=%s)', p_id);
		if p_id <= 0 then
			l_id := getDB_Last_Id(constTypeRegular);
			if l_id <= 0 then
				traceit.log(traceit.constDEBUGLEVEL_A, 'No previous regular report id found.');
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

	function getDB_Ts_Old(p_id number default 0) return timestamp
	is
		l_id	number;
		l_ts	timestamp;
	begin
		if p_id <= 0 then
			l_id := getDB_Last_Id(constTypeRegular);
			if l_id <= 0 then
				traceit.log(traceit.constDEBUGLEVEL_A, 'No previous regular report id found.');
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
				traceit.log(traceit.constDEBUGLEVEL_A, 'No report found in getDB_Ts_Old - %s : %s', sqlcode, sqlerrm);
				l_ts := sysdate - 7;
			when others then
				traceit.log(traceit.constDEBUGLEVEL_A, 'Error in getDB_Ts_Old - %s : %s', sqlcode, sqlerrm);
				raise_application_error(-20100, 'No report id='||l_id||' found of type.'||SQLCODE);
		end;

		return l_ts;
	end getDB_Ts_Old;

	procedure deleteid(p_id IN number default 0) is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.deleteid(p_id=%s)', p_id);
		if p_id = 0 then
			init(null);
		end if;
		purge(g_current_id);
		delete from ccreport_logs where ccreport_id=g_current_id;
		traceit.log(traceit.constDEBUGLEVEL_B, '%s is purged and deleted from ccreport_logs', g_current_id);

		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.deleteid');
	end deleteid;
	/*
	 * create new report ids using systimestamp and last report id
	 */
	--procedure new is
	procedure new(p_subtype char default null) is
		--l_last_id	ReportIdType := 0;
		l_last_ts	timestamp;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.new');
		--fetch_last;
		g_last_ts := getDB_Ts_New(0);

		g_current_ts	:= systimestamp;

		new(g_last_ts ,g_current_ts, constTypeRegular);
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.new');
	end new;

	/*
	 * create new report ids using timestamp arguments
	 */
	procedure new(p_previous IN timestamp, p_current IN timestamp, p_type IN char default null, p_subtype IN char default null)
	is
		l_type	char(1);
		l_subtype	char(1);
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.new(p_type=%s, p_curr=%s, p_prev=%s, p_type=%s', p_type, p_current, p_previous, p_type);

		g_current_ts	:= p_current;
		g_last_ts	:= p_previous;

		if p_type is null then
			l_type := constTypeRegular;
			if p_subtype is null then
				l_subtype := constSubTypeRegular;
			else
				l_subtype := p_subtype;
			end if;
		else
			l_type := p_type;
			l_subtype := constSubTypeRegular;
		end if;

		if g_last_ts is null then
			--fetch_last;
			g_last_ts := getDB_Ts_New(0);
		end if;

		--select ccreport_id_seq.nextval
		--  into g_current_id
		--  from dual;

		--insert into ccreport_logs (ccreport_id, ts_old, ts_new, type)
		--		values	( g_current_id , g_last_ts , g_current_ts, l_type);

		g_current_id := incDB_reportid(g_last_ts, g_current_ts, l_type, l_subtype, constStatusInit);
		
		--prepare_session;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.new(p_type, p_curr, p_prev)');
	--exception
	--	when others then
	--		null;
	end new;

	procedure init(p_reportid in number, p_type in char default 'R') is
		l_id		number;
		l_tshist	timestamp;
		l_tscurr	timestamp;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.init(p_reportid=%s)', p_reportid);
		if p_reportid is null then
			--begin
			l_id := getDB_Last_Id(p_type);
			--exception
			--	when no_data_found then
			if (l_id < 1) then
					traceit.log(traceit.constDEBUGLEVEL_A, 'Error in init - %s : %s', sqlcode, sqlerrm);
					raise_application_error(-20100, 'No report id found of type '||p_type||' '||SQLCODE);
			end if;
			--end;
		else
			l_id := p_reportid;
		end if;
			
		g_current_id	:= l_id;
		g_last_ts	:= getDB_Ts_Old(l_id);
		g_current_ts	:= getDB_Ts_New(l_id);
		--select
		--	ts_old, ts_new
		--  into g_last_ts, g_current_ts
		--  from ccreport_logs
		-- where ccreport_id=l_id;
	
		--prepare_session;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.init(), g_last_ts=%s, g_current_ts=%s', g_last_ts, g_current_ts);
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
		dbms_mview.refresh('wsc_aggr_hist_mv');
		dbms_mview.refresh('hsc_aggr_hist_mv');
	end prepare_prev;

	procedure prepare_curr is
	begin 
		dbms_mview.refresh('wsc_aggr_curr_mv');
		dbms_mview.refresh('hsc_aggr_curr_mv');
	end prepare_curr;

	--
	-- populate the data
	--
	--procedure record_entity_changed is
	function record_entity_changed return pls_integer is
		--cursor w_changed_c (p_last_ts timestamp) is
		--	select princ
		--	  from aud_hostdb.who_service_charge
		--	 where aud_ts >= p_last_ts
		--	   and princ not in ( select princ
		l_cnt	pls_integer := 0;		
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.record_entity_changed');
		-- Should existing ones be purged?
		--
		delete from who_charge_changed
		 where report_log_id = g_current_id;
		traceit.log(traceit.constDEBUGLEVEL_A, '%s entries purged from who_charge_changed', SQL%ROWCOUNT);

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
				) ;

		traceit.log(traceit.constDEBUGLEVEL_A, '%s entries inserted into who_charge_changed', SQL%ROWCOUNT);
		l_cnt := SQL%ROWCOUNT;
		delete from host_charge_changed
		 where report_log_id = g_current_id;
		traceit.log(traceit.constDEBUGLEVEL_A, '%s entries purged from who_charge_changed', SQL%ROWCOUNT);

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
				) ;

		traceit.log(traceit.constDEBUGLEVEL_A, '%s entries inserted into host_charge_changed', SQL%ROWCOUNT);
		l_cnt := l_cnt + SQL%ROWCOUNT;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.record_entity_changed=%s', l_cnt);
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
		traceit.log(traceit.constDEBUGLEVEL_A, '%s rows inserted into who_conf_changed as old conf.', SQL%ROWCOUNT);
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
		traceit.log(traceit.constDEBUGLEVEL_A, '%s rows inserted into who_conf_changed as new conf.', SQL%ROWCOUNT);
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
			,os 
			,dist_id 
			,dept 
			,ChargeAmount 
			,greatest(LastChanged_c, LastChanged_m, LastChanged_h)  
			,flag 
			,ipaddress 
			,protocol
		  from host_config_hist_v
		 where assetno in (select assetno from host_charge_changed where report_log_id=g_current_id);
		traceit.log(traceit.constDEBUGLEVEL_A, '%s rows inserted into host_conf_changed as old conf.', SQL%ROWCOUNT);
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
			,os 
			,dist_id 
			,dept 
			,ChargeAmount 
			,greatest(LastChanged_c, LastChanged_m, LastChanged_h)  
			,flag 
			,ipaddress 
			,protocol
		  from host_config_curr_v
		 where assetno in (select assetno from host_charge_changed where report_log_id=g_current_id);
		traceit.log(traceit.constDEBUGLEVEL_A, '%s rows inserted into host_conf_changed as new conf.', SQL%ROWCOUNT);
		l_cnt := l_cnt + SQL%ROWCOUNT;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.record_entity_conf=%s', l_cnt);
		return l_cnt;
	end record_entity_conf;

	procedure purge_entity(p_rpt_id IN number) is
		l_rpt_id	number;
	begin
		if (p_rpt_id is null or p_rpt_id=0) then
			l_rpt_id := g_current_id;
		else
			l_rpt_id := p_rpt_id;
		end if;

		delete from who_charge_changed
		where report_log_id=l_rpt_id;
		traceit.log(traceit.constDEBUGLEVEL_A, '%s rows purged from who_charge_changed for report_log_id=%s', SQL%ROWCOUNT, l_rpt_id);
		delete from host_charge_changed
		where report_log_id=l_rpt_id;
		traceit.log(traceit.constDEBUGLEVEL_A, '%s rows purged from host_charge_changed for report_log_id=%s', SQL%ROWCOUNT, l_rpt_id);
	end purge_entity;

	procedure purge_conf(p_rpt_id IN number) is
		l_rpt_id	number;
	begin
		if (p_rpt_id is null or p_rpt_id=0) then
			l_rpt_id := g_current_id;
		else
			l_rpt_id := p_rpt_id;
		end if;
		delete from who_conf_changed
		where report_log_id=l_rpt_id;
		traceit.log(traceit.constDEBUGLEVEL_B, '%s rows purged from who_conf_changed for report_log_id=%s', SQL%ROWCOUNT, l_rpt_id);
		delete from host_conf_changed
		where report_log_id=l_rpt_id;
		traceit.log(traceit.constDEBUGLEVEL_B, '%s rows purged from host_conf_changed for report_log_id=%s', SQL%ROWCOUNT, l_rpt_id);
	end purge_conf;

	procedure purge(p_rpt_id IN number) is
		--l_rpt_id	number;
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

	--procedure rptRecord(p_recapture IN boolean, p_rpt_id IN number default null) is
	function rptRecord(p_recapture IN boolean, p_rpt_id IN number default null) return pls_integer is
		l_ucount		pls_integer := 0;
		l_mcount		pls_integer := 0;
		l_cnt			pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.record');
		if g_last_ts is null or g_current_ts is null then
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

		select count(*)
		  into l_mcount
		  from host_charge_changed
		 where report_log_id=g_current_id;

		if l_ucount <= 0 and l_mcount <= 0 then
			l_cnt := record_entity_changed;
			if l_cnt <= 0 then
				return l_cnt;
			end if;
		else
			traceit.log(traceit.constDEBUGLEVEL_A, 'ccreport.record - %s, %s rows already in who and host _charge_changed, no recording.', l_ucount, l_mcount);
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
		if l_ucount <= 0 and l_mcount <= 0 then
			l_cnt := record_entity_conf;
		else
			traceit.log(traceit.constDEBUGLEVEL_A, 'ccreport.record - %s, %s rows already in who/host_conf_changed, no recording.', l_ucount, l_mcount);
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
	function rptRecordNew return pls_integer is
		l_rtn	pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.rptRecordNew');
		new();
		l_rtn := rptRecord(false);	
		if l_rtn > 0 then
			l_rtn := getCurrent_id;
		end if;	
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.rptRecordNew=%s', l_rtn);
		return l_rtn;
	end rptRecordNew;

	--procedure rptRecordNew(p_previous IN timestamp, p_current IN timestamp) is
	function rptRecordNew(p_previous IN timestamp, p_current IN timestamp, p_type IN char default 'R', p_subtype IN char default 'W') return pls_integer
	is
		--l_exist_id	pls_integer := 0;
		l_rtn		pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.rptRecordNew(p_current=%s, p_previous=%s)', p_current, p_previous);
		l_rtn := getDB_idByTS(p_previous, p_current);
		if l_rtn < 1 then
			new(p_previous , p_current, constTypeAdhoc);
			l_rtn := rptRecord(false);	
			if l_rtn > 0 then
				l_rtn := getCurrent_id;
			end if;
		else
			null;
		end if;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.rptRecordNew');
		return l_rtn;
	end rptRecordNew;

	procedure rptInit is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter ccreport.rptInit');
		new;
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit ccreport.rptInit');
	end rptInit;
end EntityChanged;
.
run
show error
