-- $Id: dist_str.views.sql,v 1.5 2006/09/13 14:37:32 yangl Exp $
--

--
-- Make sure ccreport has the following priv granted (not thru roles)
--
-- grant select on hostdb.accounts to ccreport;
-- grant execute on hostdb.account_string to ccreport;

grant select on hostdb.dist to ccreport with grant option;
grant select on hostdb.accounts_str_v to ccreport;

--	,(select hostdb.account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null) from hostdb.accounts a where a.id=account) acct_string

create or replace view ccreport.dist_string_v
as
select
	dist
	,(select acct_string from hostdb.accounts_str_v a where a.id=account) acct_string
	,pct
	,tpct
  from hostdb.dist d
/

create view ccreport.dist_string_aggr_v
as
select
	*
  from (
	select
		dist
		,case when row_number() over (partition by dist order by acct_string)=1 then
			stragg(acct_string||'@'||pct) over (partition by dist order by acct_string
	                                                rows between unbounded preceding and unbounded following)
		end dist_vec
	  from dist_string_v
	)
 where dist_vec is not null
/
