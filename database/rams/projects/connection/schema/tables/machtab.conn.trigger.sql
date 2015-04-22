-- $Id: machtab.conn.trigger.sql,v 1.1 2008/05/21 15:53:40 yangl Exp $

CREATE OR REPLACE TRIGGER HOSTDB.machtab_conn_chgd 
    AFTER INSERT OR UPDATE OF conn ON HOSTDB.MACHTAB 
    FOR EACH ROW
DECLARE
    ri ROWID;
BEGIN
    --IF (DELETING) THEN ri := :old.rowid; ELSE ri := :new.rowid; END IF;
    --
    update hoststab
       set conn = :new.conn
     where assetno = :new.assetno;
END;
/
