-- $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/schema/pkgs/report.sps.sql,v 1.2 2006/05/17 18:02:01 yangl Exp $
create or replace package EntityChanged 
	authid definer
as
	-- types
	subtype ReportIdType	is ccreport_logs.ccreport_id%TYPE;
	subtype RptTypeType	is ccreport_logs.RptType%TYPE;
	subtype RptSubtypeType	is ccreport_logs.RptSubtype%TYPE;
	subtype RptStatusType	is ccreport_logs.Status%TYPE;

	-- global variables
	g_last_ts		timestamp;
	--g_last_id		ReportIdType := 0;
	g_current_ts		timestamp;
	g_current_id		ReportIdType := 0;

	-- Constants
	constTypeRegular	char(1)	:= 'R';
	constTypeAdhoc		char(1)	:= 'A';

	constSubTypeRegular	char(1)	:= 'W';
	constSubTypeLabor	char(1)	:= 'L';
	constSubTypeNA		char(1)	:= 'N';

	constStatusInit		char(1)	:= 'I';
	constStatusProcess	char(1)	:= 'P';
	constStatusRecorded	char(1)	:= 'R';
	
	function getLast_Ts	return timestamp;
	function getCurrent_Ts	return timestamp;
	function getCurrent_Id	return ReportIdType;

	function getDB_Last_Id(	p_rptid		IN  ReportIdType 
				, p_ts_since	OUT timestamp
				, p_ts_until	OUT timestamp
				, p_type	OUT RptTypeType
				, p_subtype	OUT RptSubtypeType
				, p_generated	OUT date
				, p_status	OUT RptStatusType)
		return ReportIdType;

	function getDB_Last_Id(	p_type		IN OUT  RptTypeType	
				, p_subtype	IN OUT  RptSubtypeType 
				, p_ts_since	OUT timestamp
				, p_ts_until	OUT timestamp
				, p_generated	OUT date
				, p_status	OUT RptStatusType)
		return ReportIdType ;

	function getDB_Last_Id(p_type IN RptTypeType default null)	return ReportIdType;

	function getDB_Ts_New(p_id ReportIdType default 0)		return timestamp;
	function getDB_Ts_Old(p_id ReportIdType default 0)		return timestamp;

	--procedure new;
	--procedure new(p_subtype char default null) ;
	procedure new(p_subtype RptSubtypeType default null) ;
	procedure new(p_type RpttypeType, p_previous timestamp, p_current timestamp) ;

	procedure deleteid(p_id IN ReportIdType default 0) ;

	--procedure init(p_reportid in ReportIdType) ;
	procedure init(p_reportid in ReportIdType, p_type in RptTypeType default 'R') ;
	procedure prepare_session ;

	function record_entity_changed return pls_integer;

	function rptRecord(	p_recapture IN boolean
				, p_rpt_id IN ReportIdType default null
			)
		return pls_integer;

	function rptRecordNew(p_subtype IN RptSubtypeType default 'W')
		return pls_integer;

	--function rptRecordNew(p_previous IN timestamp, p_current IN timestamp) return pls_integer;
	function rptRecordNew(p_previous IN timestamp
				, p_current IN timestamp
				, p_type IN RptTypeType default 'R'
				, p_subtype IN RptSubtypeType default 'W')
		return pls_integer;

	--procedure rptRecordNew;
	--procedure rptRecordNew(p_current IN timestamp, p_previous IN timestamp);
end EntityChanged;
/
show error

grant execute on ccreport.EntityChanged to		"COSTING@CS.CMU.EDU";
