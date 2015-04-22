-- $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/schema/histview_utils.sql,v 1.5 2006/02/27 16:53:12 yangl Exp $
create or replace package histview_utils 
	authid definer
as
	--
	constHISTFLAG	char(1)	:= 'h';
	constCURRFLAG	char(1) := 'c';

	e_TIMESTAMPSEQ	pls_integer := -20100;

	procedure new(p_history_ts in timestamp, p_current_ts in timestamp);
	procedure clear;

	function get_curr return timestamp;
	function get_hist return timestamp;
	--procedure set_hist;
	--procedure set_curr;
	procedure set_hist(p_ts in timestamp);
	procedure set_curr(p_ts in timestamp);

end histview_utils;
.
run
show error

create or replace package body histview_utils as
	--
	-- Assuming the temp table has been created
	--
	--create global temporary table histview_param
	-- (
	-- 	id      number          primary key
	-- 	,flag   char(1)         not null
	-- 	,ts     timestamp       not null
	-- ) on commit preserve rows;
	-- 
	-- grant select, insert, delete, update on histview_param to public;
	--

	procedure clear is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter histview_utils.clear');

		execute immediate 'truncate table histview_param';
		--delete from histview_param;
		traceit.log(traceit.constDEBUGLEVEL_A, '%s entries truncated from histview_param', SQL%ROWCOUNT);

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit histview_utils.clear');
	end clear;

	procedure new (p_history_ts in timestamp, p_current_ts in timestamp) is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter histview_utils.new(p_history_ts=%s, p_current_ts=%s)', p_history_ts, p_current_ts);

		if (p_history_ts > p_current_ts) then
			traceit.log(traceit.constDEBUGLEVEL_A, 'Error - p_history_ts %s is newer than p_current_ts %s', p_history_ts, p_current_ts);
			raise_application_error(e_TIMESTAMPSEQ, 'History timestamp '||p_history_ts||' is newer than current timestamp '||p_current_ts);
		end if;
		set_hist(p_history_ts);
		set_curr(p_current_ts);
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit histview_utils.new');
	end new;

	procedure set_hist(p_ts in timestamp) is
		l_ts	timestamp;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter histview_utils.set_hist(p_ts=%s)', p_ts);
		if p_ts is null then
			l_ts := systimestamp;
		else
			l_ts := p_ts;
		end if;
		
		insert into histview_param (id, flag, ts)
		select nvl(max(id)+1, 1), constHISTFLAG, l_ts
		  from histview_param;

		--dbms_output.put_line();
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit histview_utils.set_hist(p_ts)');
	--exception
	end set_hist;

	procedure set_curr(p_ts in timestamp) is
		l_ts	timestamp;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter histview_utils.set_curr(p_ts=%s)', p_ts);
		if p_ts is null then
			l_ts := systimestamp;
		else
			l_ts := p_ts;
		end if;
		
		insert into histview_param (id, flag, ts)
		select nvl(max(id)+1, 1), constCURRFLAG, l_ts
		  from histview_param;
		
		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit histview_utils.set_curr(p_ts)');
	end set_curr;

	function get_curr return timestamp
	is
		l_ts	timestamp;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter histview_utils.get_curr');
		select ts
		  into l_ts
		  from histview_param
		 where flag=constCURRFLAG
		   and id=(select max(id) from histview_param);
		
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter histview_utils.get_curr');
		return l_ts;
	end get_curr;

	function get_hist return timestamp
	is
		l_ts	timestamp;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter histview_utils.get_hist');
		select ts
		  into l_ts
		  from histview_param
		 where flag=constHISTFLAG
		   and id=(select max(id) from histview_param);
		
		traceit.log(traceit.constDEBUGLEVEL_B, 'Enter histview_utils.get_hist');
		return l_ts;
	end get_hist;

end histview_utils;
.
run
show error

--
grant execute on histview_utils to public;
