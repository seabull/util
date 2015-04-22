-- $Id: entity_charged_svcsummary_v.sql,v 1.6 2007/05/04 19:22:51 yangl Exp $

create view hostdb.entity_charged_svcsummary_v
as
select
	*
  from (
	select
		Type
		,Recorded_ID
		,Name
		,ID
		,sponsor
		,charge_src
		,case when row_number() over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag order by c.webcode)=1 then
			sum(c.charge) over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag
							order by c.webcode
						rows between unbounded preceding and unbounded following)
		end Charge
		,pct
		,case when row_number() over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag order by c.webcode)=1 then
			sum(c.amount) over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag
							order by c.webcode
						rows between unbounded preceding and unbounded following)
		end amount
		,account
		,acct_string
		,acct_type
		,journal
		,trans_date
		,account_flag
		,post_date
		,journal_type_flag
		,notes
		,case when row_number() over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag order by c.webcode)=1 then
	                                stragg_nodup(c.webcode) over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag
	                                                        order by c.webcode
	                                                rows between unbounded preceding and unbounded following)
		end services
		,case when row_number() over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag order by c.webcode)=1 then
	                                stragg(c.category) over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag
	                                                        order by c.webcode
	                                                rows between unbounded preceding and unbounded following)
		end service_categories
	  from entity_charged_v c
	) x
 where x.services is not null
/

--alter user hostdb
--  quota unlimited
--  on report01
--/
--
--create materialized view hostdb.entity_charged_svcsum_y2d_mv
--pctfree 0
--tablespace report01
----parallel
--build immediate
--refresh on demand
--disable query rewrite 
--as
--select
--        *
--  from hostdb.entity_charged_svcsummary_v
-- where post_date >= to_date('JUN-01'||to_char(add_months(sysdate,-6), 'YYYY'), 'MON-DD-YYYY')
--/
--
--grant select on hostdb.entity_charged_svcsum_y2d_mv to pireport;
