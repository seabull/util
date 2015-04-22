-- $Id: aud_change_session.views.sql,v 1.3 2006/09/11 21:00:21 yangl Exp $
--

create or replace view aud.change_session_log_details_v
as
select
	cl.change_id
	,cl.ts change_ts
	,cl.schema_log_id
	,cl.table_log_id
	,pl.principal_uid
	--,pl.start_ts
	--,pl.stop_ts
	--,pl.elapsed_time
	,sl.session_userid
	,sl.logon_ts
	,sl.AUTH_TYPE
	,sl.OS_USER_NAME
	,sl.hostname
	,sl.ip_address
	,sl.last_program
	,sl.last_module
	,sl.last_action
  from aud.change_log cl
	,aud.session_log sl
	,aud.principal_log pl
 where cl.principal_log_id=pl.principal_log_id
   and pl.session_log_id=sl.session_log_id
/

grant select on aud.change_log to ccreport with grant option;
grant select on aud.session_log to ccreport with grant option;
grant select on aud.principal_log to ccreport with grant option;
grant select on aud.change_session_log_details_v to ccreport with grant option;

--  Name                                                  Null?    Type
--  ----------------------------------------------------- -------- ------------------------------------
--  SCHEMA_LOG_ID                                         NOT NULL NUMBER
--  CHANGE_ID                                             NOT NULL NUMBER
--  TABLE_LOG_ID                                          NOT NULL NUMBER
--  PRINCIPAL_LOG_ID                                      NOT NULL NUMBER
--  AUDIT_ROW_ID                                          NOT NULL ROWID
--  ACTION                                                NOT NULL CHAR(1)
--  TS                                                    NOT NULL TIMESTAMP(6)
-- 
-- yangl@cs.cmu.edu@FACQA.CRESCENT.FAC.CS.CMU.EDU> desc aud.session_log
--  Name                                                  Null?    Type
--  ----------------------------------------------------- -------- ------------------------------------
--  SESSION_LOG_ID                                        NOT NULL NUMBER
--  SESSION_AUDSID                                        NOT NULL NUMBER
--  SESSION_USERID                                        NOT NULL NUMBER
--  LOGON_TS                                              NOT NULL TIMESTAMP(6)
--  HOSTNAME                                                       VARCHAR2(120)
--  IP_ADDRESS                                                     VARCHAR2(30)
--  AUTH_TYPE                                                      VARCHAR2(26)
--  OS_USER_NAME                                                   VARCHAR2(30)
--  LOGOFF_TS                                                      TIMESTAMP(6)
--  ELAPSED_TIME                                                   INTERVAL DAY(2) TO SECOND(6)
--  LAST_PROGRAM                                                   VARCHAR2(48)
--  LAST_ACTION                                                    VARCHAR2(32)
--  LAST_MODULE                                                    VARCHAR2(32)
-- 
-- yangl@cs.cmu.edu@FACQA.CRESCENT.FAC.CS.CMU.EDU> desc aud.principal_log
--  Name                                                  Null?    Type
--  ----------------------------------------------------- -------- ------------------------------------
--  PRINCIPAL_LOG_ID                                      NOT NULL NUMBER
--  SESSION_LOG_ID                                        NOT NULL NUMBER
--  PRINCIPAL_UID                                         NOT NULL NUMBER(38)
--  START_TS                                              NOT NULL TIMESTAMP(6)
--  STOP_TS                                                        TIMESTAMP(6)
--  ELAPSED_TIME                                                   INTERVAL DAY(2) TO SECOND(6)
-- 
