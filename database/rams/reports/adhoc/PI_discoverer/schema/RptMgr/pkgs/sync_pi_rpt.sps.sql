-- $Id: sync_pi_rpt.sps.sql,v 1.4 2007/12/24 17:38:45 yangl Exp $
--
create or replace package pireport.sync_pi_rpt
    authid definer
as
    constERROR              pls_integer := -1;

    subtype journal_id_t    is charges.jnl_id%TYPE;

    g_jnl_max               journal_id_t := 99999;

    type charges_acctflag_rec is record
        (
            rid                 rowid
            ,charged_acctflag   char(1)
        );
            --,charged_notes      varchar2(50)

    type charges_acctflag_tbl is table of charges_acctflag_rec ;
            --index by binary_integer;

    procedure sync_all;

    procedure update_acctflag_charges(p_jnl in journal_id_t default 0);

    function sync_jnls(p_jnl    IN journal_id_t default null)
                                 return pls_integer;
    function sync_accts          return pls_integer;
    function sync_investigators  return pls_integer;
    function sync_acct_role      return pls_integer;

    function sync_charges(   p_jnl_min IN journal_id_t default null
                        ,p_jnl_max IN journal_id_t default null
                    )
            return pls_integer;

end sync_pi_rpt;
/
Show Errors

-- @./jnls.sql
-- @./acct.sql
-- @./investigator.sql
-- @./acct_role.sql
-- @./charges_byacct.sql
