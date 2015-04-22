
spool uninstall.log
-- grant select on charges to pireport_view;
-- grant select on accts to pireport_view;
-- grant select on jnls to pireport_view;
-- grant select on investigator to pireport_view;
-- grant select on acct_role to pireport_view;
-- 
-- grant insert, update, delete on charges to pireport_change;
-- grant insert, update, delete on accts to pireport_change;
-- grant insert, update, delete on jnls to pireport_change;
-- grant insert, update, delete on investigator to pireport_change;
-- grant insert, update, delete on acct_role to pireport_change;
-- 
-- @connect '/ as sysdba'
-- grant pireport_view to pireport_change;

--drop table ACCT_ROLE ;
--drop table INVESTIGATOR;
--drop table charges;
--drop table jnls;
--drop table accts ;
--drop sequence pi_idseq;
--drop sequence acctrole_idseq;
--drop sequence charges_idseq;

@@tables/tables.uninstall.sql

--drop role pireport_view;
--drop role pireport_change;

@@roles/roles.uninstall.sql

--drop user pireport cascade;

@@users/users.uninstall.sql

spool off
