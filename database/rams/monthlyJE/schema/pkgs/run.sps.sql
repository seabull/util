create or replace PACKAGE hostdb.Run IS

  SUBTYPE dist_t IS dist.dist%TYPE;
  SUBTYPE pct_t IS dist_names.pct%TYPE;
  SUBTYPE princ_t IS who.princ%TYPE;
  SUBTYPE journal_t IS journals.id%TYPE;

  FUNCTION busiday(asof DATE) RETURN DATE;
  PRAGMA RESTRICT_REFERENCES (busiday, WNDS, WNPS, RNDS, RNPS);

  PROCEDURE journalAccepted;
  PROCEDURE journalRecord;
  PROCEDURE journalRecord(recapture BOOLEAN);
  PROCEDURE journalRecord(recapture BOOLEAN, qjournal journal_t);

  PROCEDURE ICESRecord;
  PROCEDURE timecardRecord;
  PROCEDURE laborRecord;

  PROCEDURE peopleDistNames(xprinc princ_t);
  PROCEDURE peopleDistNamesApply;
  PROCEDURE unLimbo;
  PROCEDURE unlimbo_all_sc;
  FUNCTION  get_open_je RETURN journal_t;
END;
/
Show Errors
