
  CREATE TABLE ESC.ESC_TBMD
   (	COMN_MODL_ID INTEGER NOT NULL ENABLE,
	CHGBK_PRD_TYP VARCHAR2(4) NOT NULL ENABLE,
	CHGBK_PRD_NBR INTEGER NOT NULL ENABLE,
	BNTY_CALC_TYP VARCHAR2(4) NOT NULL ENABLE,
	BNTY_DLR_AMT NUMBER(9,2) NOT NULL ENABLE,
	BNTY_RESRV_FLG VARCHAR2(1) NOT NULL ENABLE,
	CHGBK_PCT NUMBER(5,2) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTBMD_PK PRIMARY KEY (COMN_MODL_ID)
	 ,CONSTRAINT ESCRBMD1 FOREIGN KEY (COMN_MODL_ID)
	  REFERENCES ESC.ESC_TCMD (COMN_MODL_ID) ENABLE NOVALIDATE
   ) 
;

