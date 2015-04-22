-- $Id: install.pkg.sql,v 1.1 2007/07/24 15:45:32 yangl Exp $

prompt install integrity body
@@integrity.spb.sql

prompt install costing body
@@costing.spb.sql

prompt install run body
@@ run.spb.sql
