create or replace view asset_charged_svcsum_v
-- merge by assetno to have one entry per asset 
-- instead of per host (for dual boot machines)
as
select
    *
  from (
    select
        Type
        --,Recorded_ID
        ,Name
        ,ID
        ,sponsor
        ,charge_src
        ,case when row_number() over (partition by c.type, id, c.journal, c.account, c.trans_date, c.pct order by c.webcode)=1 then
            sum(c.charge) over (partition by c.type, c.journal,id,  c.account, c.trans_date, c.pct
                            order by c.webcode
                        rows between unbounded preceding and unbounded following)
        end Charge
        ,pct
        ,case when row_number() over (partition by c.type, c.journal,id,  c.account, c.trans_date, c.pct order by c.webcode)=1 then
            sum(c.amount) over (partition by c.type, c.journal,id,  c.account, c.trans_date, c.pct
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
        ,case when row_number() over (partition by c.type, c.journal,id,  c.account, c.trans_date, c.pct order by c.webcode)=1 then
                                    stragg_nodup(c.webcode) over (partition by c.type, c.journal,id,  c.account, c.trans_date, c.pct
                                                            order by c.webcode
                                                    rows between unbounded preceding and unbounded following)
        end services
        ,case when row_number() over (partition by c.type, c.journal,id,  c.account, c.trans_date, c.pct order by c.webcode)=1 then
                                    stragg(c.category) over (partition by c.type, c.journal,id,  c.account, c.trans_date, c.pct
                                                            order by c.webcode
                                                    rows between unbounded preceding and unbounded following)
        end service_categories
      from entity_charged_v c
     where type='M'
    ) x
 where x.services is not null
/
