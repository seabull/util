

--
-- make sure all assets in host_service
-- is sync-ed using the new rates in hostdb.cost
--

--
-- IMPORTANT: 
-- make sure only 0 and 100 values in hostdb.host_service.pct
-- select unique pct from hostdb.host_service;
--        PCT
--    -------
--          0
--        100
--

spool sync_hsc.log
set linesize 200
set pagesize 50000
set define on

set verify off
define effective_date='Jan-01-2007'

select unique service_id, charge from hostdb.host_service_charge
/

update hostdb.host_service
   set pct=80
 where pct=100
   and service_id in (select service_id from hostdb.cost where period_begin=to_date('&effective_date','MON-DD-YYYY'))
/

update hostdb.host_service
   set pct=20
 where pct=0
   and service_id in (select service_id from hostdb.cost where period_begin=to_date('&effective_date','MON-DD-YYYY'))
/

select unique pct from hostdb.host_service;

update hostdb.host_service
   set pct=100
 where pct=80
   and service_id in (select service_id from hostdb.cost where period_begin=to_date('&effective_date','MON-DD-YYYY'))
/
update hostdb.host_service
   set pct=0
 where pct=20
   and service_id in (select service_id from hostdb.cost where period_begin=to_date('&effective_date','MON-DD-YYYY'))
/

select unique pct from hostdb.host_service;

select unique service_id, charge from hostdb.host_service_charge
/
spool off
set linesize 80
