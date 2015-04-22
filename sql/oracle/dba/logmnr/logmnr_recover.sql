REM exec dbms_logmnr_d.build('dictionary_export.ora','/usr/oracle/debug');

REM exec dbms_logmnr.add_logfile('/usr12/oralogs/arch/facbeta/facbeta_1_26.log',DBMS_LOGMNR.ADDFILE);
exec dbms_logmnr.add_logfile('/usr12/oralogs/arch/facbeta/facbeta_1_27.log',DBMS_LOGMNR.ADDFILE);
exec dbms_logmnr.add_logfile('/usr12/oralogs/arch/facbeta/facbeta_1_28.log',DBMS_LOGMNR.ADDFILE);
REM exec dbms_logmnr.add_logfile('/usr12/oralogs/arch/facbeta/facbeta_1_29.log',DBMS_LOGMNR.ADDFILE);

exec  dbms_logmnr.start_logmnr(0,0,to_date('01/18/05 10:00','MM/DD/YY hh24:mi'), to_date('01/18/05 17:00','mm/dd/yy hh24:mi'),'/usr/oracle/debug/dictionary_export.ora', DBMS_LOGMNR.DDL_DICT_TRACKING);

REM spool deleteme.log
REM select TIMESTAMP,COMMIT_TIMESTAMP,SQL_UNDO,ROLLBACK,UNDO_VALUE,SQL_COLUMN_NAME,SQL_COLUMN_TYPE
REM from v$logmnr_contents 
REM where timestamp > to_date('01-24-05','mm-dd-yy')
REM and timestamp < to_date('01-26-05','mm-dd-yy');

REM spool off
REM exec dbms_logmnr.end_logmnr;
REM quit

