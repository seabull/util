
  CREATE TABLE ESC.ESC_TCAT
   (	COMN_AR_TYP VARCHAR2(4) NOT NULL ENABLE,
	COMN_AR_TYP_NM VARCHAR2(30) NOT NULL ENABLE,
	OPR_SIGN_TYP VARCHAR2(1) DEFAULT '' NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	COMN_AR_TYP_DESC VARCHAR2(256) NOT NULL ENABLE,
	 CONSTRAINT ESCTCAT_PK PRIMARY KEY (COMN_AR_TYP)
   )
;

