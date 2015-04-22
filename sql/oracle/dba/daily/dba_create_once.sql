REM connect / as sysdba

CREATE TABLE yangl.utl_vol_facts
 (
  table_name                 VARCHAR2(30),
  num_rows                   NUMBER,
  meas_dt                    DATE
 )
TABLESPACE tools
 STORAGE   (
      INITIAL     128k
      NEXT        128k
      PCTINCREASE 0
      MINEXTENTS  1
      MAXEXTENTS  unlimited
   )
/

-- Public Synonym

REM CREATE PUBLIC SYNONYM utl_vol_facts FOR &OWNER..utl_vol_facts
CREATE PUBLIC SYNONYM utl_vol_facts FOR yangl.utl_vol_facts
/

-- Grants for UTL_VOL_FACTS

GRANT SELECT ON utl_vol_facts TO public
/


REM -- analyze_comp.sql
REM -- 
REM BEGIN
   REM sys.dbms_utility.analyze_schema ( '&OWNER','COMPUTE');
REM END ;
REM /

