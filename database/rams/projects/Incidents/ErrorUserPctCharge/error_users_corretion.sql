-- $Id: error_users_corretion.sql,v 1.4 2005/09/01 18:41:49 yangl Exp $
-- Usage:	sqlplus / @error_users_corretion.sql
-- 		sqlplus / @correctit.sql

set heading off
set termout on
set linesize 1000
set feedback off
set timing off
spool correctit.sql
prompt set linesize 1000
prompt set feedback on
prompt set heading on
prompt set termout off
prompt whenever sqlerror exit failure rollback
prompt whenever oserror exit failure rollback
prompt spool correctit.log

prompt prompt BEFORE UPDATE
prompt select
prompt unique
prompt	w.princ
prompt	,w.pct pct_configured
prompt	,x.pct pct_charged
prompt	,w.charge_by
prompt	,w.dist_src
prompt	,w.project
prompt	,w.subproject
prompt	,w.dist
prompt  from hostdb.who w
prompt	,( 
prompt		select 
prompt			unique
prompt			princ
prompt			,sum(pct) pct
prompt			,service_id
prompt		  from
prompt			hostdb.who_service_charge wsc
prompt		group by princ, service_id
prompt	) x
prompt where w.princ=x.princ
prompt   and w.pct != x.pct
prompt   and w.dist is not null
prompt order by w.princ
prompt /

prompt prompt UPDATING
select 
	'select * from hostdb.who where princ='''
	||princ
	||''';'
	||chr(10) 
	||'select * from hostdb.who_service_charge where princ=''' 
	||princ 
	||''';'
	||chr(10) 
	||'  -- from '
	||pct_charged
	||' to '
	||pct_configured
	||chr(10) 
	||'update hostdb.who set pct='
	||(pct_configured-0.5)
	||' where princ='''
	||princ
	||''''
	||';'
	||chr(10)
	||'update hostdb.who set pct='
	||pct_configured
	||' where princ='''
	||princ
	||''''
	||';'
	||chr(10)
  from
(
select
	unique
	w.princ
	,w.pct pct_configured
	,x.pct pct_charged
	,w.charge_by
	,w.dist_src
	,w.project
	,w.subproject
	,w.dist
  from hostdb.who w
	,( 
		select 
			unique
			princ
			,sum(pct) pct
			,service_id
		  from
			hostdb.who_service_charge wsc
		group by princ, service_id
	) x
 where w.princ=x.princ
   and w.pct != x.pct
   and w.dist is not null
order by w.princ
)
/
prompt prompt AFTER UPDATE
prompt select
prompt unique
prompt	w.princ
prompt	,w.pct pct_configured
prompt	,x.pct pct_charged
prompt	,w.charge_by
prompt	,w.dist_src
prompt	,w.project
prompt	,w.subproject
prompt	,w.dist
prompt  from hostdb.who w
prompt	,( 
prompt		select 
prompt			unique
prompt			princ
prompt			,sum(pct) pct
prompt			,service_id
prompt		  from
prompt			hostdb.who_service_charge wsc
prompt		group by princ, service_id
prompt	) x
prompt where w.princ=x.princ
prompt   and w.pct != x.pct
prompt   and w.dist is not null
prompt order by w.princ
prompt /

prompt spool off
prompt set termout on
spool off

@correctit.sql
alter trigger hostdb.who_pct_chgd disable;
alter trigger hostdb.who_pct_chgs disable;

set linesize 80
