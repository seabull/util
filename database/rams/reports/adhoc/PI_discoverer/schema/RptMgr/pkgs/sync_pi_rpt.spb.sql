-- $Id: sync_pi_rpt.spb.sql,v 1.18 2008/10/03 03:19:00 yangl Exp $
--
create or replace package body pireport.sync_pi_rpt
as
    procedure sync_all
    is
        l_cnt   pls_integer := 0;
    begin
        traceit.log(traceit.constDEBUGLEVEL_A, 'Enter sync_all');
        --null;
        l_cnt := sync_jnls;
        traceit.log(traceit.constDEBUGLEVEL_A, '%s rows sync-ed for jnls', l_cnt);
        l_cnt := sync_accts;
        traceit.log(traceit.constDEBUGLEVEL_A, '%s rows sync-ed for accts', l_cnt);
        l_cnt := sync_investigators;
        traceit.log(traceit.constDEBUGLEVEL_A, '%s rows sync-ed for investigator', l_cnt);
        l_cnt := sync_acct_role;
        traceit.log(traceit.constDEBUGLEVEL_A, '%s rows sync-ed for acct_role', l_cnt);
        l_cnt := sync_charges;
        traceit.log(traceit.constDEBUGLEVEL_A, '%s rows sync-ed for charges', l_cnt);
        update_acctflag_charges(null);
        traceit.log(traceit.constDEBUGLEVEL_A, 'update_acctflag_charges completed');

        traceit.log(traceit.constDEBUGLEVEL_A, 'Exit sync_all');
    end sync_all;

    function sync_jnls(p_jnl    IN journal_id_t default null)
        return pls_integer
    is
        l_cnt   pls_integer := 0;
        l_rtn   pls_integer := 0;
        l_max   pls_integer := 0;
    begin
            traceit.log(traceit.constDEBUGLEVEL_A, 'Enter sync_pi_rpt.jnls');

            if ( p_jnl is null) then
                begin
                        select max(jnl_id)
                          into l_max
                          from jnls
                        ;
                exception
                        when no_data_found then
                            traceit.log(traceit.constDEBUGLEVEL_A, 'sync_pi_rpt.jnls no data exception');
                            l_max := 0;
                        when others then
                            traceit.log(traceit.constDEBUGLEVEL_A, 'sync_pi_rpt.jnls exception');
                            raise_application_error(-20100, 'Error in pireport.sync_jnls');
                end;

                l_max := nvl(l_max, 0);

                traceit.log(traceit.constDEBUGLEVEL_B
                    , 'update jnls with latest journal since jnl=%s', l_max);

                insert into /*+ append */ jnls
                    (jnl_id, post_date, type)
                select
                	id
                	,trunc(post_date)
                	,nvl(journal_type_flag, 'M')
                  from hostdb.journals
                 where id > l_max
                    -- exclude the next journal.
                   and journal_type_flag is not null
                ;
            else
                select count(*)
                  into l_cnt
                  from jnls
                 where jnl_id=p_jnl
                ;
                traceit.log(traceit.constDEBUGLEVEL_B
                    , '%s rows found in jnls with id=%s', l_cnt, p_jnl);

                if(l_cnt < 1) then
                    insert into /*+ append */ jnls
                        (jnl_id, post_date, type)
                    select
                    	id
                    	,trunc(post_date)
                    	,nvl(journal_type_flag, 'M')
                      from hostdb.journals
                     where id = p_jnl
                    ;
                end if;
            end if;
    
            l_rtn := SQL%ROWCOUNT;
            traceit.log(traceit.constDEBUGLEVEL_B, '%s rows inserted into jnls', l_rtn);

            traceit.log(traceit.constDEBUGLEVEL_A, 'Exit sync_pi_rpt.jnls');
            return l_rtn;
    end sync_jnls;

    function sync_accts          
            return pls_integer
    is
        l_rtn   pls_integer := 0;
    begin
            traceit.log(traceit.constDEBUGLEVEL_A, 'Enter sync_pi_rpt.accts');

            insert into  /*+ append */ accts
                (acct_id, acct_str, type, flag, proj_name)
            select
            	id
                ,acct_string
            	,acct_type
            	,flag
                ,(select proj_name from hostdb.pta_status where pta=a.acct_string and rownum<2)
              from hostdb.accounts_str_v a
             where id not in (select acct_id from accts);
             --where id > (select max(id) from accts);

            l_rtn := SQL%ROWCOUNT;
            traceit.log(traceit.constDEBUGLEVEL_B, '%s rows inserted into accts', l_rtn);

            update accts a
               set proj_name=(select unique p.proj_name from hostdb.pta_status p
                                where acct_str=p.pta and rownum < 2) 
             where proj_name is null
               and exists (select proj_name from hostdb.pta_status where acct_str=pta)
            ;
            l_rtn := SQL%ROWCOUNT;
            traceit.log(traceit.constDEBUGLEVEL_B, '%s rows updated in accts', l_rtn);

            traceit.log(traceit.constDEBUGLEVEL_A, 'Exit sync_pi_rpt.accts');
            return l_rtn;
    end sync_accts;

    function sync_investigators  
            return pls_integer
    is
        l_rtn   pls_integer := 0;
    begin
            traceit.log(traceit.constDEBUGLEVEL_A, 'Enter sync_pi_rpt.investigators');

            --update (select i.nid, i.emp_num, i.princ, i.name
            --                ,rp.emp_num rpt_person_emp_num, rp.scs_username
            --          from hostdb.report_manager_all_info_v rp
            --                ,investigator i
            --         where i.princ is null
            --           and rp.emp_num = i.emp_num
            --           and rp.scs_username is not null
            --        ) x
            --  set x.princ=x.scs_username
            --;
            merge into investigator i2
                using ( select unique i.nid, i.emp_num, i.princ, i.name
                              ,rp.emp_num rpt_person_emp_num, rp.scs_username
                          from hostdb.report_manager_all_info_v rp
                                ,investigator i
                         where i.princ is null
                           and rp.emp_num = i.emp_num
                           and rp.scs_username is not null
                        ) x
                on (i2.nid = x.nid)
                when matched then
                    update set princ = x.scs_username
                when not matched then
                    -- this should NEVER happen
                    insert (nid,emp_num, princ, name)
                    values (rptmgr_idseq.nextval, x.rpt_person_emp_num, x.scs_username, x.name)
            ;
            l_rtn := SQL%ROWCOUNT;
            traceit.log(traceit.constDEBUGLEVEL_B, '%s rows updated with princ into investigators', l_rtn);

            --update (select i.nid, i.emp_num, i.princ, i.name
            --                ,rp.emp_num rpt_person_emp_num, rp.scs_username
            --          from hostdb.report_manager_all_info_v rp
            --                ,investigator i
            --         where i.emp_num is null
            --           and rp.scs_username = i.princ
            --           and rp.emp_num is not null
            --        ) x
            --  set x.emp_num=x.rpt_person_emp_num
            --;
            merge into investigator i2
                using (select unique i.nid, i.emp_num, i.princ, i.name
                                ,rp.emp_num rpt_person_emp_num, rp.scs_username
                         from hostdb.report_manager_all_info_v rp
                               ,investigator i
                        where i.emp_num is null
                          and rp.scs_username = i.princ
                          and rp.emp_num is not null
                       ) x
                on (i2.nid = x.nid)
                when matched then
                    update set emp_num = x.rpt_person_emp_num
                when not matched then
                    -- this should NEVER happen
                    insert (nid,emp_num, princ, name)
                    values (rptmgr_idseq.nextval, x.rpt_person_emp_num, x.scs_username, x.name)
            ;

            l_rtn := SQL%ROWCOUNT;
            traceit.log(traceit.constDEBUGLEVEL_B, '%s rows updated with emp_num into investigators', l_rtn);


            insert into /*+ append */ investigator
               (nid,emp_num, princ, name)
                select
                        rptmgr_idseq.nextval
                        --,(select emp_num from hostdb.name where princ=rp.scs_username and emp_num is not null and rownum < 2)
                        ,x.emp_num
                        ,x.scs_username
                        ,x.full_name
                  from (
                    select unique
                        rp.emp_num
                        ,rp.scs_username
                        ,rp.full_name
                  --from hostdb.report_person rp
                  from hostdb.report_manager_all_info_v rp
                 where (rp.emp_num is not null or rp.scs_username is not null)
                   and (emp_num, scs_username) not in (select emp_num, princ from investigator)
                ) x
            ;

            l_rtn := SQL%ROWCOUNT;
            traceit.log(traceit.constDEBUGLEVEL_B, '%s rows inserted into investigators', l_rtn);

            traceit.log(traceit.constDEBUGLEVEL_A, 'Exit sync_pi_rpt.investigators');
            return l_rtn;
    end sync_investigators;

    function sync_acct_role      
            return pls_integer
    is
        l_rtn   pls_integer := 0;
    begin
            traceit.log(traceit.constDEBUGLEVEL_A, 'Enter sync_pi_rpt.acct_role');

            -- TODO: need to handle cases when emp_num/princ null and later filled in.
            merge into acct_role a
            using (select unique ar.nid, ar.emp_num, ar.princ, ar.role
                        , rp.account_id, rp.emp_num rp_emp_num, rp.scs_username, rp.report_role
                     from hostdb.report_manager_all_info_v rp
                            ,acct_role ar
                    where account_id is not null
                      and rp.emp_num is not null
                      and rp.account_id = ar.acct_id
                      and ar.emp_num is null
                      and ar.princ = lower(rp.scs_username)
                      and ar.role = rp.report_role
                    ) r
            on (a.nid = r.nid)
            when matched then 
                update set a.emp_num = nvl(r.rp_emp_num, r.emp_num)
            when not matched then
                -- This should NEVER be executed
                insert (nid, acct_id, emp_num, princ, role)
                values (acctrole_idseq.nextval, r.account_id, r.emp_num, lower(r.scs_username), r.report_role)
            ;
            --on (account_id = a.acct_id and 
            --        (a.emp_num = r.emp_num
            --        or lower(a.princ) = lower(r.scs_username)
            --        )
            --    )
            l_rtn := SQL%ROWCOUNT;
            traceit.log(traceit.constDEBUGLEVEL_B, '%s rows updated with emp_num into acct_role', l_rtn);

            merge into acct_role a
            using (select unique ar.nid, ar.emp_num, ar.princ, ar.role
                        , rp.account_id, rp.emp_num rp_emp_num, rp.scs_username, rp.report_role
                     from hostdb.report_manager_all_info_v rp
                            ,acct_role ar
                    where account_id is not null
                      and rp.scs_username is not null
                      and ar.acct_id = rp.account_id
                      and ar.princ is null
                      and ar.emp_num = rp.emp_num
                      and ar.role = rp.report_role
                    ) r
            on (a.nid = r.nid)
            when matched then 
                update set a.princ = lower(r.scs_username)
            when not matched then
                -- This should NEVER be executed
                insert (nid, acct_id, emp_num, princ, role)
                values (acctrole_idseq.nextval, r.account_id, r.emp_num, lower(r.scs_username), r.report_role)
            ;
            l_rtn := SQL%ROWCOUNT;
            traceit.log(traceit.constDEBUGLEVEL_B, '%s rows updated with princ into acct_role', l_rtn);

            insert into /*+ append */ acct_role
                (nid, acct_id, emp_num, princ, role)
                select
                    acctrole_idseq.nextval
                    ,account_id
                    ,emp_num
                    ,scs_username
                    ,report_role
                    --,'Report Manager'
                  from (select 
                            unique 
                            account_id
                            ,emp_num
                            ,scs_username
                            ,report_role
                          from hostdb.report_manager_all_info_v 
                        ) rm
                 where account_id is not null
                   and (account_id, scs_username, emp_num) not in (select acct_id, princ, emp_num from acct_role)
                   and (scs_username is not null or emp_num is not null)
                   --and (account_id, emp_num) not in (select account_id, emp_num from acct_role)
            ;
                   --and (account_id, emp_num) not in (select account_id, emp_num from acct_role)

            l_rtn := SQL%ROWCOUNT;
            traceit.log(traceit.constDEBUGLEVEL_B, '%s rows inserted into acct_role', l_rtn);

            --
            -- could use merge here
            --
            update acct_role ar 
               set valid='Y'
             where valid='N'
               and exists (select 'X'
                             from hostdb.report_manager_all_info_v rm
                            where ar.acct_id=rm.account_id
                              and (ar.emp_num=rm.emp_num or ar.princ = rm.scs_username)
                              and rm.end_date_active >= sysdate
                            )
            ;
            traceit.log(traceit.constDEBUGLEVEL_B, '%s rows updated to valid in acct_role', SQL%ROWCOUNT);
            update acct_role ar 
               set valid='N'
             where valid='Y'
               and not exists (select 'X'
                                 from hostdb.report_manager_all_info_v rm
                                where ar.acct_id=rm.account_id
                                  and (ar.emp_num=rm.emp_num or ar.princ = rm.scs_username)
                                  and rm.end_date_active >= sysdate
                            )
            ;
            traceit.log(traceit.constDEBUGLEVEL_B, '%s rows updated to not valid in acct_role', SQL%ROWCOUNT);

            traceit.log(traceit.constDEBUGLEVEL_A, 'Exit sync_pi_rpt.acct_role');
            return l_rtn;
    end sync_acct_role;

    procedure update_acctflag_charges(p_jnl in journal_id_t default 0)
    is
        l_update_tbl    charges_acctflag_tbl := charges_acctflag_tbl();
        l_errors        pls_integer := 0;
        l_jnl_min       journal_id_t := p_jnl;
        l_count         pls_integer := 0;

        cursor l_charges_acctflag_csr is
            select  c.rowid
                    ,e.account_flag
              from charges c
                    ,hostdb.entity_charged_svcsummary_v e
             where
                  c.jnl_id >= l_jnl_min
              and 
                  c.entity_id=e.recorded_id
              --and e.account_flag in ('b','f', 'B')
              and c.type=e.type
              and c.acct_id=e.account
              and trunc(c.trans_date)=trunc(e.trans_date)
              and c.jnl_id=e.journal
              and rtrim(c.services)=rtrim(e.services)
              and nvl(c.account_flag, 'v')!=nvl(e.account_flag, 'v')
            ;
                    
    begin
        traceit.log(traceit.constDEBUGLEVEL_A
                        , 'Enter sync_pi_rpt.update_acctflag_charges(%s)'
                        ,p_jnl);

        if (l_jnl_min is null) then
            select journal - 21 into l_jnl_min
              from hostdb.param;
        end if;

        if (not l_charges_acctflag_csr%isopen) then
            open l_charges_acctflag_csr;
        end if;

        --for c_rec in l_charges_acctflag_csr
        --loop
        --    l_update_tbl.extend;
        --    l_update_tbl(l_update_tbl.last).rid              := c_rec.rowid;
        --    l_update_tbl(l_update_tbl.last).charged_acctflag := c_rec.account_flag;
        --end loop;

        --close l_charges_acctflag_csr;

        fetch l_charges_acctflag_csr bulk collect into l_update_tbl;
        --exit when l_charges_acctflag_csr%NOTFOUND;
        
        -- only 11g supports forall for collection of records
        --forall i in l_update_tbl.first..l_update_tbl.last  save exceptions
        --    update charges
        --       set account_flag = l_update_tbl(i).charged_acctflag
        --     where rowid = l_update_tbl(i).rid
        --       and nvl(account_flag, 'v') != nvl(l_update_tbl(i).charged_acctflag, 'v')
        --    ;
        for i in l_update_tbl.first..l_update_tbl.last
        loop
            update charges
               set account_flag = l_update_tbl(i).charged_acctflag
             where rowid = l_update_tbl(i).rid
               and nvl(account_flag, 'v') != nvl(l_update_tbl(i).charged_acctflag, 'v')
            ;
            l_count := l_count + 1;
        end loop;

        traceit.log(traceit.constDEBUGLEVEL_B
                        , 'Exit gl_report_update_pkg.acctflag_update. %s rows updated.'
                        , l_count);
                        --, SQL%ROWCOUNT);
    exception
        when others then
            --l_errors := SQL%BULK_EXCEPTIONS.count;
            --traceit.log(traceit.constDEBUGLEVEL_A
            --            , 'Number of errors in bulk updates - %s'
            --            , l_errors);
            --for i in 1..l_errors loop
            --    traceit.log(traceit.constDEBUGLEVEL_A
            --                ,'Error %s occured in iteration %s with Oracle Error %s'
            --                ,i
            --                ,SQL%BULK_EXCEPTIONS(i).error_index
            --                ,sqlerrm(-SQL%BULK_EXCEPTIONS(i).error_code)
            --                );
            --end loop;
            traceit.log(traceit.constDEBUGLEVEL_B
                        , 'Exit gl_report_update_pkg.acctflag_update with exceptions');
            traceit.log(traceit.constDEBUGLEVEL_A, 'Exit sync_pi_rpt.update_acctflag_charges');
    end update_acctflag_charges;

    procedure purge_charges(p_jnl   IN journal_id_t default 0)
    is
    begin
            traceit.log(traceit.constDEBUGLEVEL_A
                        , 'Enter sync_pi_rpt.purge_charges(%s)'
                        ,p_jnl);
            delete 
              from charges
             where jnl_id=p_jnl;

            traceit.log(traceit.constDEBUGLEVEL_B, '%s rows purge from charges with jnl_id=%s', SQL%ROWCOUNT, p_jnl);

            traceit.log(traceit.constDEBUGLEVEL_A, 'Exit sync_pi_rpt.purge_charges');
    end purge_charges;

    function sync_charges(   p_jnl_min  IN journal_id_t default null
                        ,p_jnl_max  IN  journal_id_t default null
                    )
            return pls_integer
    is
            l_jnl_min   journal_id_t := p_jnl_min;
            l_jnl_max   journal_id_t := p_jnl_max;
            l_rtn   pls_integer := 0;
    begin
            traceit.log(traceit.constDEBUGLEVEL_A
                        , 'Enter sync_pi_rpt.charges(%s, %s)'
                        ,p_jnl_min, p_jnl_max);

            if l_jnl_min is null then
                --begin
                        select max(jnl_id)
                          into l_jnl_min
                          from charges
                         ;
                        l_jnl_min := nvl(l_jnl_min, 237);
                --exception
                --        when no_data_found then
                --            -- only get FY06 and onward.
                --            l_jnl_min := 237;
                --end;
            end if;

            traceit.log(traceit.constDEBUGLEVEL_C, 'Use jnl_min = %s', l_jnl_min);

            if l_jnl_max is null then
                --begin
                        select max(id)
                          into l_jnl_max
                          from hostdb.journals
                         ;
                        l_jnl_max := nvl(l_jnl_max, 237);
                --exception
                --        when no_data_found then
                --            l_jnl_max := 1;
                --end;
            end if;

            traceit.log(traceit.constDEBUGLEVEL_C, 'Use jnl_max = %s', l_jnl_max);

            --update 
            --    (
            --        select
            --                c.nid
            --                ,c.entity_id
            --                ,c.type
            --                ,c.acct_id
            --                ,c.trans_date
            --                ,c.jnl_id
            --                ,c.account_flag
            --                ,c.services
            --                ,e.account_flag new_flag
            --          from charges c
            --                ,hostdb.entity_charged_svcsummary_v e
            --         where 
            --               c.jnl_id > l_jnl_max - 300
            --           and 
            --               c.entity_id=e.recorded_id
            --           and e.account_flag in ('b','f', 'B')
            --           and c.type=e.type
            --           and c.acct_id=e.account
            --           and trunc(c.trans_date)=trunc(e.trans_date)
            --           and c.jnl_id=e.journal
            --           and rtrim(c.services)=rtrim(e.services)
            --           and nvl(c.account_flag, 'V')!=nvl(e.account_flag, 'V')
            --        ) x
            --   set account_flag=x.new_flag 
            --;

            --traceit.log(traceit.constDEBUGLEVEL_B, '%s rows updated in charges', SQL%ROWCOUNT;);

                --,dist_vec
            insert into charges
            ( NID, ENTITY_ID, NAME, SCS_ID, TYPE, ACCT_ID, CHARGE, PCT, AMOUNT, TRANS_DATE, JNL_ID, ACCOUNT_FLAG
                ,acct_string
                ,services
            )
                select
                        charges_idseq.nextval
                        ,recorded_id
                        ,name
                        ,ID
                        ,type
                        ,account
                        ,charge
                        ,pct
                        ,amount
                        ,trans_date
                        ,journal
                        ,account_flag
                        ,acct_string
                        ,services
                        --,'unknown'
                  from hostdb.entity_charged_svcsummary_v
                 where journal > l_jnl_min
                   and journal <= l_jnl_max
            ;

            l_rtn := SQL%ROWCOUNT;
            traceit.log(traceit.constDEBUGLEVEL_B, '%s rows inserted into charges', l_rtn);

            traceit.log(traceit.constDEBUGLEVEL_A, 'Exit sync_pi_rpt.charges');
            return l_rtn;
    end sync_charges;

end sync_pi_rpt;
/
Show Errors
