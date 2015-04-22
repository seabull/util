-- $Id: cluster_transition.sql,v 1.1 2007/02/20 15:08:15 yangl Exp $
--

spool convert_data.log
prompt ***boston.lti
@@boston_lti.sql

prompt ***cogito
@@cogito.sql

prompt ***faccluster
@@faccluster.sql

prompt ***islr
@@islr.sql

prompt ***malbec
@@malbec.sql

prompt ***mu.lti
@@mu_lti.sql
spool off
