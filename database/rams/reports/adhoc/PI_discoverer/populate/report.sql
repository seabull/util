--alter session set cursor_sharing=force;

set define on
set verify off

set heading off 
set feedback off
set termout off
set linesize 1000
set pagesize 50000
set trimspool on
set newpage 0

define principal=&1

spool &principal
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
		,a.acct_str acct_string
		,decode(lower(c.account_flag), 'l', 'Limbo','i','Internal','b','Limbo-B','Valid') flag
	  from 
		charges c
		,accounts a
		,acct_role ar
		,investigator i
	 where 
		c.acct_id=a.acct_id
	   and a.acct_id=ar.acct_id
	   and i.emp_num=ar.emp_num
	   and i.princ='&principal'
	   --and c.jnl_id < 238
	   and c.jnl_id >= (select min(id) from hostdb.journals where post_date>=to_date('JUL-01-'||to_char(add_months(sysdate, -6), 'YYYY'), 'MON-DD-YYYY'))
	group by c.type
		,c.name
		,a.acct_str
		,decode(lower(c.account_flag), 'l', 'Limbo','i','Internal','b','Limbo-B','Valid') 
) x
/
spool off
set termout on
set heading on
set feedback on
set linesize 80
