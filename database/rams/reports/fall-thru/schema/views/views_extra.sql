-- $Id: views_extra.sql,v 1.1 2007/09/24 18:59:54 yangl Exp $

create or replace view dist_string_v as
select
    dist
    ,(select acct_string||'-'||upper(a.flag) from accounts_str_v a where a.id=account) acct_string
    ,(select flag from hostdb.accounts a where a.id=account) flag
    ,pct
    ,tpct
  from hostdb.dist d
/

create or replace view dist_vector_string_v
as
select
    *
  from (
    select
        dist
        ,case when row_number() over (partition by dist order by acct_string,pct)=1 then
            stragg(acct_string||'@'||pct) over (partition by dist order by acct_string, pct
                        rows between unbounded preceding and unbounded following)
            end dist_vec
        ,case when row_number() over (partition by dist order by acct_string)=1 then
            stragg_nodup(nvl(flag,'v')) over (partition by dist order by flag, acct_string, pct
                        rows between unbounded preceding and unbounded following)
            end flags
      from dist_string_v
    )
 where dist_vec is not null
/

