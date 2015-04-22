-- $Id: install.sql,v 1.4 2007/04/30 19:04:48 yangl Exp $

spool install.log
@@ users/users.install.sql

@@ tables/tables.install.sql

@@ views/views.install.sql

@@ roles/roles.install.sql

@@ pkgs/install_pkgs.sql

grant pireport_view to "YANGL@CS.CMU.EDU";
grant pireport_view to "ED0U@CS.CMU.EDU";
grant pireport_view to "KZM@CS.CMU.EDU";
grant pireport_view to "NIKITHSE@CS.CMU.EDU";

grant pireport_change to "YANGL@CS.CMU.EDU";
grant pireport_change to "COSTING@CS.CMU.EDU";
spool off

--
-- grant select on hostdb.pta_status to pireport;
--
-- alter table pireport.accts add (proj_name varchar2(30));
-- sync_pi_rpt.spb.sql
--
