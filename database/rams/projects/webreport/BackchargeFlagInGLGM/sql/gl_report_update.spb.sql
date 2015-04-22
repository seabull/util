-- $Id: gl_report_update.spb.sql,v 1.4 2008/07/14 18:52:19 yangl Exp $
create or replace package body hostdb.gl_report_update_pkg
is
    procedure acctflag_update
    is
        --l_notes_new     hostdb.who_charged.notes%TYPE;
        --l_account_flag  hostdb.who_charged.account_flag%TYPE;

        l_update_tbl    rpt_flag_update_tbl ;
        l_errors        pls_integer := 0;

        cursor l_report_csr(p_jnl hostdb.journals.id%TYPE) is
            select   
                    g.rowid
                    ,c.account_flag
                    ,c.notes
              from hostdb.entity_charged_svcsummary_v c
                    ,hostdb.gl_report g
             where c.account_flag in ('b', 'f')
               and g.limbo_flag='l'
               and c.journal=g.jid
               and c.journal >= p_jnl
               and c.notes is not null
               and g.type=c.type
               and g.name=c.name
               and decode(proj, null, fund||'-'||func||'-'||act||'-'||org||'-'||ent
                            , proj||'-'||task||'-'||award
                            )=c.acct_string
               and trunc(g.trans_date)=trunc(c.trans_date)
               --and rtrim(g.services)=rtrim(c.services)
            ;
        -- services are different in gl_report for MR1 (M1), in the view MR1 is M.
    begin
        traceit.log(traceit.constDEBUGLEVEL_B, 'Enter gl_report_update_pkg.acctflag_update');
        if (not l_report_csr%isopen) then
            open l_report_csr(276);
        end if;
        fetch l_report_csr bulk collect into l_update_tbl;
        --exit when l_report_csr%notfound;
        
        --forall i in l_update_tbl.first..l_update_tbl.last  --save exceptions
        for i in l_update_tbl.first..l_update_tbl.last  --save exceptions
        loop
            --dbms_output.put_line('update i='||i||':'||l_update_tbl(i).charged_notes);
            update hostdb.gl_report
               set notes      = l_update_tbl(i).charged_notes
                  ,limbo_flag = l_update_tbl(i).charged_acctflag
             where rowid = l_update_tbl(i).rid
               and limbo_flag != l_update_tbl(i).charged_acctflag
            ;
        end loop;

        traceit.log(traceit.constDEBUGLEVEL_B
                        , 'Exit gl_report_update_pkg.acctflag_update. %s rows updated.'
                        , SQL%ROWCOUNT);
    exception
        when no_data_found then
            l_errors := SQL%BULK_EXCEPTIONS.count;
            traceit.log(traceit.constDEBUGLEVEL_A
                        , 'Number of errors in bulk updates - %s'
                        , l_errors);
            dbms_output.put_line('no data found to update');
        when others then
            l_errors := SQL%BULK_EXCEPTIONS.count;
            traceit.log(traceit.constDEBUGLEVEL_A
                        , 'Number of errors in bulk updates - %s'
                        , l_errors);
            for i in 1..l_errors loop
                traceit.log(traceit.constDEBUGLEVEL_A
                            ,'Error %s occured in iteration %s with Oracle Error %s'
                            ,i
                            ,SQL%BULK_EXCEPTIONS(i).error_index
                            ,sqlerrm(-SQL%BULK_EXCEPTIONS(i).error_code)
                            );
            end loop;
            traceit.log(traceit.constDEBUGLEVEL_B
                        , 'Exit gl_report_update_pkg.acctflag_update with exceptions');
    end acctflag_update;

end gl_report_update_pkg;
/
show errors
