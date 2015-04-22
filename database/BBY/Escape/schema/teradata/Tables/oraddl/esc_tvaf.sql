
  CREATE TABLE ESC.ESC_TVAF
   (	VNDR_FILE_ID INTEGER NOT NULL ENABLE,
	VNDR_ID NUMBER(9,0),
	VNDR_SUBTYP VARCHAR2(3),
	ARCHIVE_CMPUTR_NM VARCHAR2(30) NOT NULL ENABLE,
	VNDR_FILE_STAT VARCHAR2(6) DEFAULT '' NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	ARCHIVE_FILE_NM VARCHAR2(256) NOT NULL ENABLE,
	 CONSTRAINT ESCTVAF_PK PRIMARY KEY (VNDR_FILE_ID)
   )
;

