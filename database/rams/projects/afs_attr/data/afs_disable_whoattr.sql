-- $Id: afs_disable_whoattr.sql,v 1.2 2006/12/11 17:12:08 yangl Exp $

--delete 
--  from hostdb.who_attr
-- where sense='+'
--   and attr='AFS'
--/

insert into hostdb.who_attr
    (princ, sense, attr, notes)
select
        unique
        princ
        ,'-'
        ,'AFS'
        ,'Disable initially 12/2006'
  from hostdb.who_service
 where princ not in (select princ from hostdb.who_service where service_id=1)
   and princ not in (select princ from hostdb.who_attr where sense='-' and attr='AFS')
/
