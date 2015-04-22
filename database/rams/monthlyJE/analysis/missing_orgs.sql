set linesize 1000
spool missing_orgs.txt
select 
        unique 
        org
        ,desc1
        ,org_e 
  from accounting.hris_org 
 where org_e not in (select org from hostdb.charge_sources where org is not null)
/


select 
        kind
        ,description
        ,attr
        ,org
  from hostdb.charge_sources
order by org
/

select
        unique
        l.home_org
        ,h.org_e
  from hostdb.labor_ldr l
        ,accounting.hris_org h
 where l.home_org = h.desc1(+)
   and h.org_e not in (select org from hostdb.charge_sources where org is not null)
/
spool off
set linesize 80
