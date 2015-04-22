
spool fix.log

create table hostdb.account_subs_save
as
select
        *
  from hostdb.account_subs
/

delete from hostdb.account_subs
/

spool off
