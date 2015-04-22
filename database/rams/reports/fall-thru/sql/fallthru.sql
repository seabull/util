--
-- $Author: yangl $
-- $RCSfile: fallthru.sql,v $
-- $Revision: 1.2 $
-- $Date: 2006/11/21 19:59:34 $
--

prompt
prompt Report Actual Charge Sources for non-hardcoded users and machines 
prompt

set linesize 1000

clear breaks

set colsep '|'

column acct_string format a24 truncated
column account_flag heading FLAG format a4
column flag heading FLAG format a6 truncated
column charge_by_type heading charge_src format a10 truncated
column type heading type format a4
column dist_src_type heading actual_src format a10 truncated
column id format a12 truncated
column name format a24 truncated
column dist_src format a8 truncated
column amount format $99,999,999.99


set termout off
--break on acct_string skip 1
--spool fallthru.log
spool &1

select
        c.acct_string
        ,decode(c.account_flag,'l','Limbo','b','BckChg','i','Intnl',null,'Valid','Unknwn') flag
        ,d.charge_by_type
        ,d.dist_src_type
        ,d.type
        ,d.ID
        ,d.name
        ,d.emp_num
        ,d.sponsor
        ,d.dist_src
        ,sum(c.amount) amount
  from entity_distsrc_v d
        ,entity_charged_v c
 where d.type=c.type
   and d.ID=c.ID
   and c.journal=(select id from journals_lastm_v)
   and charge_by_type in ('PrimaryUser','Payroll')
   and dist_src_type not in ('Payroll')
group by 
        c.acct_string
        ,d.charge_by_type
        ,d.dist_src_type
        ,decode(c.account_flag,'l','Limbo','b','BckChg','i','Intnl',null,'Valid','Unknwn') 
        ,d.type
        ,d.ID
        ,d.name
        ,d.emp_num
        ,d.sponsor
        ,d.dist_src
/
spool off
set linesize 80
set colsep ' '
set termout on
