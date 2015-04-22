#!/bin/sh

# This script descibes how to extract DDL from database.
# You can not just simple run this script.
echo "Check the script for usage."
exit

#1. use imp/exp
exp userid=/ owner=hostdb
imp userid=/ indexfile=hostdb_.sql

#2. For Oracle 9i 
#select dbms_metadata.get_ddl( 'TABLE', 'EMP', 'SCOTT' ) from dual;

#DBMS_METADATA.GET_DDL('TABLE','EMP','SCOTT')
#--------------------------------------------------------------------------------
#
  #CREATE TABLE "SCOTT"."EMP"
   #(    "EMPNO" NUMBER(4,0),
        #"ENAME" VARCHAR2(10),
        #"JOB" VARCHAR2(9),
        #"MGR" NUMBER(4,0),
        #"HIREDATE" DATE,
        #"SAL" NUMBER(7,2),
        #"COMM" NUMBER(7,2),
        #"DEPTNO" NUMBER(2,0),
         #CONSTRAINT "PK_EMP" PRIMARY KEY ("EMPNO")
  #USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255
  #STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  #PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  #TABLESPACE "SYSTEM"  ENABLE,
         #CONSTRAINT "EMP_FK_EMP" FOREIGN KEY ("MGR")
          #REFERENCES "SCOTT"."EMP" ("EMPNO") ENABLE,
         #CONSTRAINT "FK_DEPTNO" FOREIGN KEY ("DEPTNO")
          #REFERENCES "SCOTT"."DEPT" ("DEPTNO") ENABLE
   #) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  #STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  #PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  #TABLESPACE "SYSTEM"
