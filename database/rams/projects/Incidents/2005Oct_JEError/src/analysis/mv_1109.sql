
-- create those materialized views now. 11/09/05
create materialized view nov09_wsc_mv
pctfree 0
tablespace costing_lg
--parallel
build immediate
refresh on demand
disable query rewrite
as
select
	rowid
	,PRINC
	,PCT
	,CHARGE
	,AMOUNT
	,ACCOUNT
	,SERVICE_ID
  from hostdb.who_service_charge
/

create materialized view nov09_hsc_mv
pctfree 0
tablespace costing_lg
--parallel
build immediate
refresh on demand
disable query rewrite
as
select
	rowid
	,* 
  from hostdb.host_service_charge
/
