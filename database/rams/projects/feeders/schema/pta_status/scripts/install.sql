-- $Header: c:\\Repository/database/rams/projects/feeders/schema/pta_status/scripts/install.sql,v 1.1 2006/04/26 19:48:20 yangl Exp $

prompt Creating external table pta_status_xt
@@../tables/pta_status_tables.xt.add.sql

prompt Creating tables pta_recorded etc.
@@../tables/pta_status_tables.add.sql
