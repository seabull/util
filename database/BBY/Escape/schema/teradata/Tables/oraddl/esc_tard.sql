  CREATE TABLE ESC.ESC_TARD
   (	AR_COMN_DTL_ID INTEGER NOT NULL ENABLE,
	APLY_COMN_DTL_ID INTEGER NOT NULL ENABLE,
	APLY_TRANS_AMT NUMBER(9,2) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTARD_PK PRIMARY KEY (AR_COMN_DTL_ID, APLY_COMN_DTL_ID)
   ) 
;