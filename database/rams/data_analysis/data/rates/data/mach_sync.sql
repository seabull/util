
set linesize 1000
spool mach_sync.log

prompt Creating table to backup mach_attr

create table hostdb.mach_attr_oldrates
as
select
        *
  from hostdb.mach_attr
/

update hostdb.services
   set type='X'
 where type='M'
   and (attr in ('S-L','R')
        or id in ( 10 ,11 ,12 ,13 ,14 ,15 ,16 ,17 , 99 ,100 ,101)  -- M-H-*
        )
/

prompt list of all os-specific software supports
select
        *
  from hostdb.services
 where type='M'
   and attr='S'
/

--
-- Leave software supports untouched, unify their rates only.
-- Changing them involving changing mach_equiv/mapped_services etc.
-- 
--prompt expiring all os-specific software support
--update hostdb.services
--   set type='X'
-- where type='M'
--   and attr='S'
--/
--
--prompt adding general software support
---- user general hardware properties
--insert into hostdb.services
--    (
--    ID ,CATEGORY ,ATTR ,DESCRIPTION ,MONTHLY ,TYPE
--    ,SUBTYPE ,OS ,GENERIC ,OTHER ,OS_CLASS ,ATTR2 ,SPECIFIC ,WEBCODE
--    )
--select
--    (select max(id)+1 from hostdb.services) ID
--    ,'M-S'  CATEGORY 
--    ,'S'    ATTR
--    ,DESCRIPTION 
--    ,4 MONTHLY 
--    ,TYPE
--    ,'S' SUBTYPE 
--    ,OS 
--    ,GENERIC 
--    ,OTHER 
--    ,OS_CLASS 
--    ,ATTR2 
--    ,SPECIFIC 
--    ,'S' WEBCODE
--  from hostdb.services
-- where id=9
--/



--prompt existing qual=q assets
--select
--        *
--  from hostdb.capequip
-- where qual='q'
--/
--
--create table capequip_question
--as
--select
--    *
--  from hostdb.capequip
-- where qual='q'
--/
--
------a b d f h i l m n o p q r s t u x z
--
--prompt qual=a
--update hostdb.capequip
--   set qual='q'
-- where qual='a'
--/
--
--update hostdb.capequip
--   set qual='a'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=b
--update hostdb.capequip
--   set qual='q'
-- where qual='b'
--/
--
--update hostdb.capequip
--   set qual='b'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=d
--update hostdb.capequip
--   set qual='q'
-- where qual='d'
--/
--
--update hostdb.capequip
--   set qual='d'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=f
--update hostdb.capequip
--   set qual='q'
-- where qual='f'
--/
--
--update hostdb.capequip
--   set qual='h'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=h
--update hostdb.capequip
--   set qual='q'
-- where qual='h'
--/
--
--update hostdb.capequip
--   set qual='h'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=i
--update hostdb.capequip
--   set qual='q'
-- where qual='i'
--/
--
--update hostdb.capequip
--   set qual='i'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=l
--update hostdb.capequip
--   set qual='q'
-- where qual='l'
--/
--
--update hostdb.capequip
--   set qual='l'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=i
--update hostdb.capequip
--   set qual='q'
-- where qual='m'
--/
--
--update hostdb.capequip
--   set qual='m'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=n
--update hostdb.capequip
--   set qual='q'
-- where qual='n'
--/
--
--update hostdb.capequip
--   set qual='n'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=o
--update hostdb.capequip
--   set qual='q'
-- where qual='o'
--/
--
--update hostdb.capequip
--   set qual='o'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=p
--update hostdb.capequip
--   set qual='q'
-- where qual='p'
--/
--
--update hostdb.capequip
--   set qual='p'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=r
--update hostdb.capequip
--   set qual='q'
-- where qual='r'
--/
--
--update hostdb.capequip
--   set qual='r'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=s
--update hostdb.capequip
--   set qual='q'
-- where qual='s'
--/
--
--update hostdb.capequip
--   set qual='s'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=t
--update hostdb.capequip
--   set qual='q'
-- where qual='t'
--/
--
--update hostdb.capequip
--   set qual='t'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/
--
--prompt qual=u
--update hostdb.capequip
--   set qual='q'
-- where qual='u'
--/
--
--update hostdb.capequip
--   set qual='u'
-- where qual='q'
--   and assetnum not in (select assetnum from capequip_question)
--/

--prompt insert entry into mach_attr to trigger service update

--insert into hostdb.mach_attr
--    (assetno, sense, attr, notes)
--select
--        assetno
--        ,'-'
--        ,'H'
--        ,'New Rates Transition'
--  from hostdb.machtab
-- where dist is not null
--   and assetno not in (select assetno from hostdb.mach_attr where attr='H')
--/

insert into hostdb.mach_attr
    (assetno, sense, attr, notes)
select
        unique
        assetno
        ,'-'
        ,'H'
        ,'New Rates Transition'
  from (select assetno from hostdb.host_service_charge
        union
        select assetno from hostdb.host_service
        )
 where 
    assetno not in (select assetno from hostdb.mach_attr where attr='H')
/

insert into hostdb.mach_attr
    (assetno, sense, attr, notes)
select
        unique
        assetno
        ,'-'
        ,'S'
        ,'New Rates Transition'
  from (select assetno from hostdb.host_service_charge
        union
        select assetno from hostdb.host_service
        )
 where 
    assetno not in (select assetno from hostdb.mach_attr where attr='S')
/

prompt purge all entries from mach_attr

delete from hostdb.mach_attr
-- where attr not in ('B','N','CLR','CLH','CLS','*','MR1')
/

--delete from hostdb.mach_attr
-- where notes = 'New Rates Transition'
--/
insert into hostdb.mach_attr
    (assetno, sense, attr, notes)
select
        assetno
        ,sense
        ,attr
        ,notes
  from hostdb.mach_attr_oldrates
 where attr in ('B','N','CLR','CLH','CLS','*','MR1','S')
/

-- Make sure hsc is in sync with hs
-- Some entries in hs will not be updated (even if changing qual) if 
-- the service entry does not change (search for 'NOT CHANGE' in costing pkg).
select unique service_id, charge from hostdb.host_service_charge
/
update hostdb.host_service
   set pct=80
 where pct=100
/

update hostdb.host_service
   set pct=20
 where pct=0
/

select unique pct from hostdb.host_service;

update hostdb.host_service
   set pct=100
 where pct=80
/
update hostdb.host_service
   set pct=0
 where pct=20
/

select unique pct from hostdb.host_service;

select unique service_id, charge from hostdb.host_service_charge
/
spool off
set linesize 80
