
  CREATE TABLE ESC.ESC_TVPT
   (	ATRIB_PRFL_ID INTEGER NOT NULL ENABLE,
	VNDR_ATRIB_TYP VARCHAR2(10) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTVPT_PK PRIMARY KEY (ATRIB_PRFL_ID, VNDR_ATRIB_TYP)
	 ,CONSTRAINT ESCRVPT1 FOREIGN KEY (ATRIB_PRFL_ID)
	  REFERENCES ESC.ESC_TVAP (ATRIB_PRFL_ID) ENABLE NOVALIDATE,
	 CONSTRAINT ESCRVPT2 FOREIGN KEY (VNDR_ATRIB_TYP)
	  REFERENCES ESC.ESC_TVAT (VNDR_ATRIB_TYP) ENABLE NOVALIDATE
   ) 
;


Create INDEX  ESC.IX_ESCTVPT_1  on ESC.ESC_TVPT   (VNDR_ATRIB_TYP);

