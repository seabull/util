
  CREATE TABLE ESC.ESC_TVNI
   (	VNDR_ID NUMBER(9,0) NOT NULL ENABLE,
	VNDR_SUBTYP VARCHAR2(3) NOT NULL ENABLE,
	FISC_TYP_ID INTEGER NOT NULL ENABLE,
	VNDR_PRFL_ID INTEGER NOT NULL ENABLE,
	ACTV_PH_AREA_NBR VARCHAR2(3) NOT NULL ENABLE,
	ACTV_PH_NBR VARCHAR2(7) NOT NULL ENABLE,
	ACTV_PH_EXT VARCHAR2(5),
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	ESC_VNDR_POS_TXT VARCHAR2(256) NOT NULL ENABLE,
	 CONSTRAINT ESCTVNI_PK PRIMARY KEY (VNDR_ID, VNDR_SUBTYP)
	 ,CONSTRAINT ESCRVNI2 FOREIGN KEY (FISC_TYP_ID)
	  REFERENCES ESC.ESC_TFST (FISC_TYP_ID) ENABLE NOVALIDATE
   ) 
;


Create INDEX  ESC.IX_ESCTVNI_1  on ESC.ESC_TVNI   (FISC_TYP_ID);

