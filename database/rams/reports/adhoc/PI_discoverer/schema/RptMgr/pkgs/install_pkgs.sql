-- $Id: install_pkgs.sql,v 1.3 2007/03/27 16:05:24 yangl Exp $
--

@@sync_pi_rpt.sps.sql
@@sync_pi_rpt.spb.sql

grant execute on pireport.sync_pi_rpt   to pireport_change;

@@month_aggr.func.sql
