-- $Id: install.sql,v 1.1 2006/12/07 16:30:30 yangl Exp $

@ashostdb

spool install.log

set linesize 120

lock table hostdb.who_attr in exclusive mode;

-- we don't use this table but lock it to prevent others updating concurrently.
lock table hostdb.who in exclusive mode;

@@schema/scripts/schema.install.sql

prompt before changes

@@data/afs_disabled_check.sql

@@data/afs_disable_whoattr.sql

prompt after changes
@@data/afs_disabled_check.sql

spool off

set linesize 80
