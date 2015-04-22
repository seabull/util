-- $Id: run_adjustments.sps.sql,v 1.2 2007/09/21 14:23:04 yangl Exp $
create or replace package hostdb.Run_Adjustments is

  -- Author  : C. RIGDON
  -- Created : 15-Feb-02 2:31:24 PM
  -- Purpose : Create adjustment only journal entry
  -- Modification History:
  --   10-DEC-2002  clr      Added JournalHoldAdjust Proc
  --   06-MAR-2003  yangl    Added TestJournalLeftover Proc

  -- Public type declarations


  PROCEDURE JournalCheckLimbo(retcode OUT VARCHAR2,errdesc OUT varchar2 );
  PROCEDURE JournalHoldAdjust(errbuf OUT varchar2,retcode OUT VARCHAR2);
  PROCEDURE JournalRecordAdjust(errbuf OUT varchar2, retcode OUT VARCHAR2);
  PROCEDURE JournalRejectAdjust(batchno IN number,errbuf OUT varchar2,retcode OUT VARCHAR2);
  PROCEDURE JournalAcceptAdjust(errbuf OUT varchar2, retcode OUT VARCHAR2);
  PROCEDURE TestJournalLeftover(errbuf OUT varchar2, retcode OUT VARCHAR2);

  -- These should be in a seperate package.
  PROCEDURE GLReportSync(pFromDate IN date, pUntilDate IN date default sysdate);
  PROCEDURE GLReportSyncForgive(pFromDate IN date, pUntilDate IN date default sysdate);

end Run_Adjustments;
/
Show Errors
