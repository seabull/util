-- $Id: who_triggers.sql,v 1.1 2005/08/30 15:23:26 yangl Exp $

CREATE OR REPLACE TRIGGER HOSTDB.WHO_PCT_CHGD 
AFTER
	INSERT
	OR UPDATE
	OR DELETE 
OF 
	PCT
ON 
	HOSTDB.WHO 
FOR EACH ROW 
DECLARE
	ri ROWID;
BEGIN
	IF (DELETING) THEN  
		ri := null; 
	ELSE 
		ri := :new.rowid; 
	END IF;

	IF ( :new.pct != :old.pct ) THEN
		Integrity.whoPctChanged(ri, :new.princ, :old.princ);
	END IF;
END;
/
show errors

CREATE OR REPLACE TRIGGER HOSTDB.WHO_PCT_CHGS 
AFTER
	INSERT
	OR UPDATE
	OR DELETE 
OF 
	PCT
ON 
	HOSTDB.WHO 
BEGIN
	Integrity.whoPctChanges;
END;
/
show errors

--alter trigger hostdb.who_pct_chgd disable;
--alter trigger hostdb.who_pct_chgs disable;

--alter trigger hostdb.who_pct_chgd enable;
--alter trigger hostdb.who_pct_chgs enable;
