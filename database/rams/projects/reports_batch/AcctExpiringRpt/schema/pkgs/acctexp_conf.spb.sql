-- $Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/schema/pkgs/acctexp_conf.spb.sql,v 1.3 2006/05/17 19:52:23 yangl Exp $
--
create or replace package body acctexp_conf 
as
	procedure setConfig (	p_id			IN id_t
				, p_datecount		IN datecount_t
				, p_mflag		IN mflag_t
				, p_effectivedate	IN date
				);


	function getMaxID return id_t
	is
		l_id	id_t := 0;
	begin
		select max(id)
		  into l_id
		  from acctexp_config;

		return l_id;
	end getMaxID;

	procedure setDateCount (p_datecount IN datecount_t)
	is
	begin
		if p_datecount is null then
			traceit.log(traceit.constDEBUGLEVEL_A
				, 'setDataCount: Error - datecount should not be null.');
			-- Should error out here?
			raise_application_error(Error_Codes.err_arg_null
						, 'Invalid datecount argument (null)'
						);
		else
			setNewConfig(p_datecount, null, null);
		end if;
	end setDateCount;

	function  getDateCount (p_id IN id_t default null) return datecount_t
	is
		l_datecount	datecount_t	:= null;
		l_mflag		mflag_t		:= null;
		l_effectivedate	date 		:= null;
	begin
		if p_id is null then
			getCurrentConfig (l_datecount
					, l_mflag
					, l_effectivedate
					);
		else
			getConfig (	p_id
					,l_datecount
					, l_mflag
					, l_effectivedate
					);
		end if;
		return l_datecount;
	end getDateCount;

	procedure setMonthendFlag (p_mflag IN mflag_t)
	is
	begin
		if p_mflag is null then
			traceit.log(traceit.constDEBUGLEVEL_A
				, 'setMonthendFlag: Error - mflag should not be null.');
			-- Should error out here?
			raise_application_error(Error_Codes.err_arg_null
						, 'Invalid mflag argument (null)'
						);
		else
			setNewConfig(null, p_mflag, null);
		end if;
	end setMonthendFlag;

	function  getMonthendFlag (p_id IN id_t default null) return mflag_t
	is
		l_datecount	datecount_t	:= null;
		l_mflag		mflag_t		:= null;
		l_effectivedate	date 		:= null;
	begin
		if p_id is null then
			getCurrentConfig (l_datecount
					, l_mflag
					, l_effectivedate
					);
		else
			getConfig (	p_id
					,l_datecount
					, l_mflag
					, l_effectivedate
					);
		end if;
		return l_mflag;
	end getMonthendFlag;

	procedure setEffectiveDate (p_effectivedate IN date)
	is
		l_maxid		id_t;
		l_olddate	date;
	begin
		if p_effectivedate is null then
			traceit.log(traceit.constDEBUGLEVEL_A
				, 'setMonthendFlag: Error - effectivedate should not be null.');
			-- Should error out here?
			raise_application_error(Error_Codes.err_arg_null
						, 'Invalid effectivedate argument (null)'
						);
		else
			--setNewConfig(null, null, p_effectivedate);
			l_olddate := getEffectiveDate;
			if trunc(l_olddate) < trunc(sysdate) then
				traceit.log(traceit.constDEBUGLEVEL_A
					, 'setMonthendFlag: Error - effectivedate should not be changed if it already took effect.');
				raise_application_error(Error_Codes.err_arg_null
							, 'Startdate should not be changed if it already took effect.');
			elsif trunc(p_effectivedate) < trunc(sysdate) then
				traceit.log(traceit.constDEBUGLEVEL_A
					, 'setMonthendFlag: Error - effectivedate should be changed to a future date only.');
				raise_application_error(Error_Codes.err_arg_null
							, 'Startdate should not be changed to a past date.');
			else
				l_maxid := getMaxID;
				setConfig(l_maxid, null, null, trunc(p_effectivedate));
				traceit.log(traceit.constDEBUGLEVEL_A
					, 'Effectivedate Changed to %s for ID %s.'
					, l_maxid
					, trunc(p_effectivedate)
					);
			end if;
		end if;
	end setEffectiveDate;

	function  getEffectiveDate(p_id IN id_t default null) return date
	is
		l_datecount	datecount_t	:= null;
		l_mflag		mflag_t		:= null;
		l_effectivedate	date 		:= null;
	begin
		if p_id is null then
			getCurrentConfig (l_datecount
					, l_mflag
					, l_effectivedate
					);
		else
			getConfig (	p_id
					,l_datecount
					, l_mflag
					, l_effectivedate
					);
		end if;
		return l_effectivedate;
	end getEffectiveDate;

	procedure setNewConfig (p_datecount		IN datecount_t
				, p_mflag		IN mflag_t
				, p_effectivedate	IN date
				)
	is
		l_id		id_t;
		l_datecount	datecount_t	:= null;
		l_mflag		mflag_t		:= null;
		l_effectivedate	date 		:= null;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
			, 'Enter acctexp_conf.setNewConfig(p_datecount=%s, p_mflag=%s, p_effectivedate=%s)'
			, p_datecount
			, p_mflag
			, p_effectivedate
			);

		setConfig(null, p_datecount, p_mflag, p_effectivedate);

		--select acctexp_config_idseq.nextval
		--  into l_id
		--  from dual;
		--
		--traceit.log(traceit.constDEBUGLEVEL_B, 'Next ID=%s', l_id);
		--
		--if (	p_datecount is null	
		--     or p_mflag is null
		--     or p_effectivedate is null
		--   ) then
		--	getCurrentConfig(l_datecount, l_mflag, l_effectivedate);
		--end if;

		--if p_datecount is not null then
		--	l_datecount := p_datecount;
		--end if;

		--if p_mflag is not null then
		--	l_mflag := p_mflag;
		--end if;

		--if p_effectivedate is not null then
		--	l_effectivedate := p_effectivedate;
		--end if;

		--traceit.log(traceit.constDEBUGLEVEL_B, 'setNewConfig: Inserting new config (%s, %s, %s, %s)'
		--		, l_id, l_datecount, l_mflag, l_effectivedate);

		--insert into acctexp_config
		--	(id, datecount, monthend_flag, startdate)
		--values
		--	(l_id, l_datecount, l_mflag, l_effectivedate);

		--traceit.log(traceit.constDEBUGLEVEL_C, 'setNewConfig: Inserted new config.');

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acctexp_conf.setNewConfig=%s', l_id);
	end setNewConfig;

	procedure getCurrentConfig (p_datecount		OUT datecount_t
				, p_mflag		OUT mflag_t
				, p_effectivedate	OUT date
				)
	is
		l_id		id_t;
		l_datecount	datecount_t;
		l_mflag		mflag_t;
		l_effectivedate	date;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acctexp_conf.getCurrentConfig');

		l_id := getMaxID;

		if l_id < 1 then
			traceit.log(traceit.constDEBUGLEVEL_A
				, 'getCurrentConfig: Max Config ID Suspicious = %s', l_id);
		end if;

		select id, datecount, monthend_flag, startdate
		  into l_id, l_datecount, l_mflag, l_effectivedate
		  from acctexp_config
		 where id=l_id;
	
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'Exit acctexp_conf.getCurrentConfig=%s, %s, %s'
				, p_datecount, p_mflag, p_effectivedate);
	end getCurrentConfig;
	
	--
	-- This is a "private" method.
	--
	procedure setConfig (	p_id			IN id_t
				, p_datecount		IN datecount_t
				, p_mflag		IN mflag_t
				, p_effectivedate	IN date
				)
	is
		l_id		id_t 		:= p_id;
		l_datecount	datecount_t	:= null;
		l_mflag		mflag_t		:= null;
		l_effectivedate	date 		:= null;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B
			, 'Enter acctexp_conf.setConfig(p_id=%s, p_datecount=%s, p_mflag=%s, p_effectivedate=%s)'
			, p_id
			, p_datecount
			, p_mflag
			, p_effectivedate
			);

		if p_id is null then
			select acctexp_config_idseq.nextval
			  into l_id
			  from dual;
		end if;
		
		traceit.log(traceit.constDEBUGLEVEL_B, 'Next ID=%s', l_id);
		
		if (	p_datecount is null	
		     or p_mflag is null
		     or p_effectivedate is null
		   ) then
			if p_id is null then
				getCurrentConfig(l_datecount, l_mflag, l_effectivedate);
			else
				getConfig(p_id, l_datecount, l_mflag, l_effectivedate);
			end if;
		end if;

		if p_datecount is not null then
			l_datecount := p_datecount;
		end if;

		if p_mflag is not null then
			l_mflag := p_mflag;
		end if;

		if p_effectivedate is not null then
			l_effectivedate := p_effectivedate;
		end if;

		if p_id is null then
			traceit.log(traceit.constDEBUGLEVEL_B, 'setConfig: Inserting new config (%s, %s, %s, %s)'
					, l_id, l_datecount, l_mflag, l_effectivedate);
	
			insert into acctexp_config
				(id, datecount, monthend_flag, startdate)
			values
				(l_id, l_datecount, l_mflag, l_effectivedate);
	
			traceit.log(traceit.constDEBUGLEVEL_C, 'setConfig: Inserted new config.');
		else
			traceit.log(traceit.constDEBUGLEVEL_B, 'setConfig: Updating config to (%s, %s, %s, %s)'
					, l_id, l_datecount, l_mflag, l_effectivedate);

			update acctexp_config 
			   set datecount	= l_datecount
				, monthend_flag	= l_mflag
				, startdate	= l_effectivedate
			 where id=l_id;
	
			traceit.log(traceit.constDEBUGLEVEL_C, 'setConfig: Updated config %s.', l_id);
		end if;
	
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit acctexp_conf.setConfig=%s', l_id);
	end setConfig;

	procedure getConfig (	p_id			IN  id_t
				, p_datecount		OUT datecount_t
				, p_mflag		OUT mflag_t
				, p_effectivedate	OUT date
				)
	is
		l_id		id_t;
		l_datecount	datecount_t	:= null;
		l_mflag		mflag_t		:= null;
		l_effectivedate	date		:= null;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter acctexp_conf.getCurrentConfig');

		if p_id is null or p_id < 1 then
			raise_application_error(Error_Codes.err_invalid_reportid
						, 'Invalid Configuration ID '
						||p_id);
		end if;

		select id, datecount, monthend_flag, startdate
		  into l_id, p_datecount, p_mflag, p_effectivedate
		  from acctexp_config
		 where id=p_id;
	
		traceit.log(traceit.constDEBUGLEVEL_B
				, 'Exit acctexp_conf.getCurrentConfig=%s, %s, %s'
				, p_datecount, p_mflag, p_effectivedate);
	exception
		when no_data_found then
			traceit.log(traceit.constDEBUGLEVEL_A, 'Exception: No data found for id=%s'
					, p_id);
		  	p_datecount	:= null;
			p_mflag		:= null;
			p_effectivedate	:= null;
			
	end getConfig;

end acctexp_conf;
/
show errors
