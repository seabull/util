set linesize 1000

spool mach_fallthru.csv
column services format a24 trunc
column account_flag heading flag format a4 trunc
column charge_by heading conf format a4 trunc
column charge_src heading actual format a6 trunc
column dist_src_type heading usr_conf format a10 trunc

set colsep ','
select
    unique
        Name
        ,ID
        ,sponsor
        ,account_flag
        ,charge_by
        ,charge_src
        ,dist_src_type
        ,'"'||services||'"' services
        ,sum(amount) amount
  from 
(
select
        a.Name
        ,a.ID
        ,a.sponsor
        ,a.account_flag
        ,m.charge_by
        ,a.charge_src
        ,a.services
        ,amount
        ,case charge_src when 'U' then
            (select unique nvl(charge_by, 'V')||'-'||decode(dist_src, 'P','P','X','X','payroll') from hostdb.who w where w.princ=a.sponsor)
        when 'X' then
            'Residual'
        when 'P' then
            'Fallthru'
        else
            'Unknown'
        end dist_src_type
  from entity_charged_svcsummary_v a
        ,hostdb.machtab m
 where m.charge_by is null
   and a.ID=m.assetno
   and a.journal=309
)
group by 
        Name
        ,ID
        ,sponsor
        ,account_flag
        ,charge_by
        ,charge_src
        ,services
        ,dist_src_type
order by 
        account_flag
        ,name
        ,charge_by
/

spool off
set linesize 80
set colsep ' '
