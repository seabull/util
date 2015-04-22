-- $Id: pt_chg_whocat_hist.sql,v 1.1 2005/05/25 14:59:42 yangl Exp $
--
create table pt_chg_whocat_hist
(
	id	NUMBER(8)
		constraint ptchgwhocathist_pk primary key
		using index tablespace INDX
	,princ	VARCHAR2(8)
		constraint ptchgwhocathist_princ_nn not null
	,odist	NUMBER(6)
	,odist_src	VARCHAR2(3)
	,opct	NUMBER(5,2)
	,npct	NUMBER(5,2)
	,acct	NUMBER(6)
	,distpct	NUMBER(6,3)
	,when	date default sysdate
	,who	VARCHAR2(20) default user
)
tablespace costing
/
create sequence hostdb.ptchgwhocathist_seq maxvalue 99999999 cycle;

/*
dist
 Name                                                  Null?    Type
 ----------------------------------------------------- -------- ------------------------------------
 DIST                                                  NOT NULL NUMBER(6)
 ACCOUNT                                               NOT NULL NUMBER(6)
 PCT                                                   NOT NULL NUMBER(6,3)
 TPCT                                                  NOT NULL NUMBER(6,3)

hostdb@FAC_03.APOGEE.FAC.CS.CMU.EDU> select * from dist where dist=2880;
      DIST    ACCOUNT        PCT       TPCT
---------- ---------- ---------- ----------
      2880      16448         50         50
      2880      16475         50         50

2 rows selected.

hostdb@FAC_03.APOGEE.FAC.CS.CMU.EDU> desc dist_names
 Name                                                  Null?    Type
 ----------------------------------------------------- -------- ------------------------------------
 DIST                                                  NOT NULL NUMBER(6)
 NAME                                                  NOT NULL VARCHAR2(30)
 SUBNAME                                               NOT NULL VARCHAR2(12)
 USER_ONLY                                                      CHAR(1)
 SRC                                                   NOT NULL VARCHAR2(3)
 PCT                                                            NUMBER(5,2)


*/

