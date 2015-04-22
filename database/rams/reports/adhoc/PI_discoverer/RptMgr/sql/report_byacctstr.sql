
whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

set define on
set verify off

set heading off 
set feedback off
set termout off
set linesize 1000
set pagesize 50000
set trimspool on
set newpage none

alter session set cursor_sharing=force;

define lx_directory=&1
define lx_acctstring=&2
define lx_num_months=-&3

spool &lx_directory/&lx_acctstring..csv
select 
	'type'
	||','||'name'
	||','||'charge'
	||','||'amount'
	||','||'acct_string'
	||','||'acct_flag'
  from  dual
/

select 
	x.type
	||','||x.name
	||','||x.chg
	||','||x.amt
	||','||x.acct_string
	||','||x.flag
  from 
(
	select
		c.type
		,c.name
		,sum(charge) chg
		,sum(amount) amt
		,'"'||decode(a.proj_name, null, '',a.proj_name||' ')||a.acct_str||'"' acct_string
		,decode(lower(c.account_flag), 'l', 'Limbo','i','Internal','b','Limbo-Bck','f','Forgiven','Valid') flag
	  from 
		pireport.charges c
		,pireport.accts a
		--,pireport.acct_role_valid_v ar
		--,pireport.investigator i
	 where 
		c.acct_id=a.acct_id
	   --and a.acct_id=ar.acct_id
	   --and ( i.emp_num=ar.emp_num or i.princ = ar.princ )
	   and a.acct_str='&lx_acctstring'
	   and c.jnl_id >= (select min(id) from hostdb.journals 
                    where post_date>=trunc(last_day(add_months(sysdate, &lx_num_months-1))+1)
                      and JOURNAL_TYPE_FLAG='M'
                        )
	group by c.type
		,c.name
		--,a.acct_str
		,'"'||decode(a.proj_name, null, '',a.proj_name||' ')||a.acct_str||'"'
		,decode(lower(c.account_flag), 'l', 'Limbo','i','Internal','b','Limbo-Bck','f','Forgiven','Valid') 
	union
	select
		c.type
		,c.name
		,0-sum(charge) chg
		,0-sum(amount) amt
		--,a.acct_str acct_string
		,'"'||decode(a.proj_name, null, '',a.proj_name||' ')||a.acct_str||'"' acct_string
		,decode(lower(c.account_flag), 'l', 'Limbo','i','Internal','b','Limbo-Bck','f','Forgiven','Valid') flag
	  from 
		pireport.charges c
		,pireport.accts a
		--,pireport.acct_role_valid_v ar
		--,pireport.investigator i
	 where 
		c.acct_id=a.acct_id
	   --and a.acct_id=ar.acct_id
	   --and ( i.emp_num=ar.emp_num or i.princ = ar.princ )
	   and a.acct_str='&lx_acctstring'
	   and c.jnl_id >= (
            select min(id) from hostdb.journals 
             where post_date >=
                    trunc(last_day(add_months(sysdate, &lx_num_months-1))+1)
               and JOURNAL_TYPE_FLAG='M'
                        )
	   and lower(c.account_flag)='b'
	group by c.type
		,c.name
		--,a.acct_str
		,'"'||decode(a.proj_name, null, '',a.proj_name||' ')||a.acct_str||'"'
		,decode(lower(c.account_flag), 'l', 'Limbo','i','Internal','b','Limbo-Bck','f','Forgiven','Valid')
) x
/
spool off
set termout on
set heading on
set feedback on
set linesize 80
quit
