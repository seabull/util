
  CREATE TABLE ESC.ESC_TLNI
   (	ESC_LN_SEQ INTEGER NOT NULL ENABLE,
	ESC_LN_SKU_ID NUMBER(7,0) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	ORIG_SLS_TRANS_NBR NUMBER(5,0) NOT NULL ENABLE,
	ORIG_LOC_ID NUMBER(5,0) NOT NULL ENABLE,
	ORIG_REGSTR_NBR NUMBER(3,0) NOT NULL ENABLE,
	ORIG_SLS_TRANS_TS TIMESTAMP (6) NOT NULL ENABLE,
	SLS_TRANS_LN_AMT NUMBER(9,2) DEFAULT 0 NOT NULL ENABLE,
	 CONSTRAINT ESCTLNI_PK PRIMARY KEY (ESC_LN_SEQ)
   )
;


Create INDEX  ESC.IX_ESCTLNI_1  on ESC.ESC_TLNI   (ORIG_LOC_ID ,ORIG_SLS_TRANS_NBR ,ORIG_REGSTR_NBR ,ORIG_SLS_TRANS_TS);
Create INDEX  ESC.IX_ESCTLNI_2  on ESC.ESC_TLNI   (ESC_LN_SKU_ID);
