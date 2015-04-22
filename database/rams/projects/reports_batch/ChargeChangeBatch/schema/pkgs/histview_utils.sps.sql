-- $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/schema/pkgs/histview_utils.sps.sql,v 1.2 2006/05/17 18:05:30 yangl Exp $
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
/
show error
