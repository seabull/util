-- $Id: pi_pkg.sql,v 1.1 2005/10/18 14:41:55 yangl Exp $
--
Create or Replace package PI_pkg as
	function charge_wo_svc (p_princ		IN varchar2
				, p_jnl_l	IN number
				, p_jnl_h	IN number
				)
		return sys_refcursor;
end PI_pkg;
/
show errors

Create or Replace package body PI_pkg
as
	function charge_wo_svc (p_princ		IN varchar2
				, p_jnl_l	IN number 
				, p_jnl_h	IN number default 99999
				)
	return sys_refcursor
	is
		l_results	sys_refcursor;
	begin
		open l_results for
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
				,a.string acct_string
				,decode(lower(c.account_flag), 'l', 'Limbo','i','Internal','b','Limbo-B','Valid') flag
			  from 
				charges c
				,accts a
				,acct_role ar
				,investigator i
			 where 
				c.acct_id=a.acct_id
			   and a.acct_id=ar.acct_id
			   and i.emp_num=ar.emp_num
			   and i.princ=p_princ
			   and c.jnl_id < p_jnl_high
			   and c.jnl_id > p_jnl_low
			group by c.type
				,c.name
				,a.string
				,decode(lower(c.account_flag), 'l', 'Limbo','i','Internal','b','Limbo-B','Valid') 
		) x
		;
		return l_results;
	end charge_wo_svc;
end PI_pkg;
/
show errors
