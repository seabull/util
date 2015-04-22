  -- Purpose : Create adjustment journal entry file and send email notifications.
  -- follows feeder file Record layout spec ( see fmp website)

  -- Modification History:
  
whenever sqlerror exit failure rollback
whenever oserror exit failure rollback
  
set define on  
set feedback off
--set termout off
set trimspool on 
set pagesize 0 
set linesize 1000
 
    VARIABLE gl NUMBER;
    VARIABLE gm NUMBER;
    VARIABLE je NUMBER;
    VARIABLE nrows NUMBER;
    VARIABLE total NUMBER;
    VARIABLE today VARCHAR2(13);
    VARIABLE feedid CHAR(25);
    VARIABLE monyear VARCHAR2(11);
    VARIABLE nje VARCHAR2(5);
    VARIABLE source CHAR(25);
    VARIABLE mail1 CHAR(30);
    VARIABLE mail2 CHAR(30);

BEGIN

    :source := 'COMP SCI RECHARGE';
    :mail1 := 'costing+fmp@cs.cmu.edu';
    :mail2 := 'costing+fyi@cs.cmu.edu';  

     /*Obtain and format parameters from PARAM table.*/
       
    SELECT journal, TO_CHAR(journal, 'FM09999'), to_char(SYSDATE,'DD-Mon-YYYY')
      INTO :je,:nje,:monyear 
      FROM hostdb.param;
      
    SELECT count(*) 
      INTO :nrows 
      --FROM hostdb.journal 
      FROM "YANGL@CS.CMU.EDU".jnl245_journal_adj 
     WHERE journal=:je;
    
    SELECT '"'||TO_CHAR(sysdate, 'DD-Mon-YYYY')||'"', to_char(sysdate,'YYYYMMDDHH24MISS')
      INTO :today,:feedid 
      FROM dual;
      
    /* Grants total is net.  General ledger total is all debits or all credits,
     we happen to sum debits but credits would be identical.*/     
     
    SELECT nvl(sum(j.amount), 0) INTO :gm
      FROM "YANGL@CS.CMU.EDU".jnl245_journal_adj j,hostdb.accounts a
     WHERE j.journal=:je AND j.account=a.id AND a.funding IS null;
     
    SELECT nvl(sum(j.amount), 0) INTO :gl
      FROM "YANGL@CS.CMU.EDU".jnl245_journal_adj j,hostdb.accounts a
     WHERE j.journal=:je AND j.account=a.id AND a.funding IS NOT null AND j.amount>0;
    :total := :gm+:gl;

end;

    /*The next section creates the file to be transfered to oracle financials. Adjust-sumbit.sh takes filename 
    '1' and '2' as input. '1' is the combined header record and line level records. This file
    is transfered to oracle financials via scp/ssh. '2' becomes the email notification to costing 
    and gl users.*/  
/
run
   
spool &1
select '*'||
    :source||' '||
    :feedid||
    to_char(:nrows,'99999')||
    to_char(:total,'99999999999999.90')||' '||
    :mail1||' '||
    :mail2||' '||
    '.000'
 from dual;
SELECT :today||',"COMP SCI RECHARGE","'||
  to_char(j.post_date,'DD-Mon-YYYY')||'","'||
  j.objcode||'","'||
  a.funding||'","'||
  a.function||'","'||
  a.activity||'","'||
  a.org||'","'||
  a.entity||'",'||
  greatest(0,to_char(j.amount, 'FM9999999.90'))||','||
  greatest(0,to_char(-j.amount, 'FM9999999.90'))||',"'||
  'SCSCM'||:nje||'","'||
  'SCS Computer ADJUST Maintenance Batch'||'","'||
  'SCSCMJE'||:nje||'","'|| 
  'SCS Computer ADJUST Maintenance JE'||'","'||
  :nje||'",,,"'||
  j.description||'",,,,,,,,,,,0,""'
 FROM "YANGL@CS.CMU.EDU".jnl245_journal_adj j,hostdb.accounts a
 WHERE j.account=a.id AND j.journal=:je AND a.funding IS NOT NULL
 ORDER BY j.objcode,a.org,a.funding,a.function,a.activity,a.entity;
SELECT :today||',"COMP SCI RECHARGE",,,,,,,,0,0,"'||
  'SCSCM'||:nje||'",,,,,,,,,,,"'||
  to_char(j.trans_date,'DD-Mon-YYYY')||'","'||
  a.project||'","'||
  a.task||'","'||
  a.award||'","IC COMPUTING SERVICES","COMPUTER SCIENCE CHG","CSD ENGINEERING LAB COSTS",'||
  to_char(j.amount,'FM9999999.90')||',"'||
  j.description||'"'
  FROM "YANGL@CS.CMU.EDU".jnl245_journal_adj j,hostdb.accounts a
  WHERE j.account=a.id AND j.journal=:je AND a.funding IS NULL
  ORDER BY a.project,a.task,a.award;  
spool off
spool &2
  SELECT 'A SCS computer maintenance feeder ADJUST journal entry batch for'
    FROM dual;
  SELECT :monyear||' has been submitted with id '||rtrim(:feedid,' ')||'.'
    FROM dual;
  SELECT '' FROM dual;
  SELECT to_char(:gl,'999999.99')||' total general ledger charges.'
    FROM dual;
  SELECT '' FROM dual;
  SELECT to_char(:gm,'999999.99')||' total grants management charges.'
   FROM dual;
exit;
