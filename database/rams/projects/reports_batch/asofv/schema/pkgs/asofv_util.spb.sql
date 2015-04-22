-- $Id: asofv_util.spb.sql,v 1.5 2006/08/07 18:01:53 yangl Exp $
--
create or replace package body utility.asofv_util
as
	procedure clear_time is
	begin
		traceit.log(traceit.constDEBUGLEVEL_C, 'Enter asofv_util.clear_time');

		execute immediate 'truncate table :param_schema.:param_tbl' 
				using PARAMTBLSCHEMA
					,PARAMTBLNAME;

		traceit.log(traceit.constDEBUGLEVEL_C, 'Exit asofv_util.clear_time');
	end clear_time;

	procedure set_time(	pTS		in timestamp
				,pParamTblFlag	in varchar2	default ParamTblFlag
			)
	is
		l_ts	timestamp;
		l_flag	utility.asofv_param.flag%TYPE := nvl(pParamTblFlag, ParamTblFlag);
	begin
		traceit.log(traceit.constDEBUGLEVEL_C, 'Enter asofv_util.set_time(pTs=%s)', pTs);
		if pTs is null then
			l_ts := systimestamp;
		else
			l_ts := pTs;
		end if;
		
		insert into utility.asofv_param (id, flag, ts)
			select nvl(max(id)+1, 1), l_flag, l_ts
			  from utility.asofv_param;

		traceit.log(traceit.constDEBUGLEVEL_C, 'Exit asofv_util.set_time(pTs)');
	end set_time;

	function get_time(	
				pParamTblFlag	in varchar2	default ParamTblFlag
			) return timestamp
	is
		l_ts	timestamp;
		l_flag	utility.asofv_param.flag%TYPE := nvl(pParamTblFlag, ParamTblFlag);
	begin
		traceit.log(traceit.constDEBUGLEVEL_C, 'Enter asofv_util.get_time(flag=%s', l_flag);

		select ts
		  into l_ts
		  from utility.asofv_param
		 where flag=l_flag
		   and id=(select max(id) from utility.asofv_param where flag=l_flag);
		
		traceit.log(traceit.constDEBUGLEVEL_C, 'Exit asofv_util.get_time=%s', l_ts);

		return l_ts;
	end get_time;

end asofv_util;
/
show error
grant execute on utility.asofv_util to public;
create public synonym asofv_util for utility.asofv_util;
