
set linesize 1000
spool who_sync.log
--select
--        w.princ
--        ,wa.*
--  from hostdb.who w
--        ,hostdb.who_attr wa
-- where w.princ=wa.princ
--   and w.dist is not null
--   and wa.attr='P'
--/

prompt Creating table to backup who_attr
create table who_attr_oldrates
as
select
        *
  from hostdb.who_attr
/

prompt insert entry into who_attr to trigger service update

insert into hostdb.who_attr
    (princ, sense, attr, notes)
select
        princ
        ,'-'
        ,'AFS'
        ,'New Rates Transition'
  from hostdb.who
 where dist is not null
   and princ not in (select princ from hostdb.who_attr where attr='AFS')
/

prompt purge all entries from who_attr

delete from hostdb.who_attr
/

--
-- Need to make sure only 0 and 100% exist in hostdb.who_service
--
prompt please make sure only 0% and 100% exist in hostdb.who_service

prompt check existing services and charges in wsc
select unique service_id, charge from hostdb.who_service_charge
/

select unique pct from hostdb.who_service;

update hostdb.who_service
   set pct=80
 where pct=100
/

update hostdb.who_service
   set pct=20
 where pct=0
/

select unique pct from hostdb.who_service;

update hostdb.who_service
   set pct=100
 where pct=80
/

update hostdb.who_service
   set pct=0
 where pct=20
/

select unique pct from hostdb.who_service;

prompt check existing services and charges in wsc
select unique service_id, charge from hostdb.who_service_charge
/

spool off
set linesize 80
