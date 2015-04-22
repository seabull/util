
  CREATE TABLE ESC.ESC_TCAI
   (	ESC_CUST_ACCT_ID INTEGER NOT NULL ENABLE,
	ESC_LN_SEQ INTEGER NOT NULL ENABLE,
	ESC_LN_STAT_TYP VARCHAR2(4) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) DEFAULT 'ESC' NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) DEFAULT 'ESC' NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) DEFAULT SYSDATE NOT NULL ENABLE,
	 CONSTRAINT ESCTCAI_PK PRIMARY KEY (ESC_CUST_ACCT_ID, ESC_LN_SEQ)
   )
;


Create INDEX  ESC.IX_ESCTCAI_1  on ESC.ESC_TCAI   (ESC_LN_SEQ);
Create INDEX  ESC.IX_ESCTCAI_2  on ESC.ESC_TCAI   (REC_UPD_TS);

