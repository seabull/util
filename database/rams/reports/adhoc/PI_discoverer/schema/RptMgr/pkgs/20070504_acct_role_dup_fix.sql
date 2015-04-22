-- $Id: 20070504_acct_role_dup_fix.sql,v 1.1 2007/05/04 21:18:11 yangl Exp $

set linesize 1000
spool 20070504_acct_role_dup_fix.log
select
        *
  from pireport.acct_role
 where (acct_id, princ, role) in
(
    select 
            acct_id
            , princ
            , role
      from pireport.acct_role 
    group by acct_id, princ, role 
    having count(nid)>1
)
/

delete from pireport.acct_role
where nid in 
(
    select
            max_id
      from 
            (
                select
                        acct_id
                        , princ
                        , role
                        ,count(nid)
                        ,max(nid) max_id
                  from pireport.acct_role
                group by acct_id, princ, role
                having count(nid)>1
            )
)
/ 

select
        *
  from pireport.acct_role
 where (acct_id, princ, role) in
(
    select 
            acct_id
            , princ
            , role
      from pireport.acct_role 
    group by acct_id, princ, role 
    having count(nid)>1
)
/

spool off
set linesize 80
