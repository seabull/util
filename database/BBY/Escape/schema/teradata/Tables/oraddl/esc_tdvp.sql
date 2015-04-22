
  CREATE TABLE ESC.ESC_TDVP
   (	SKU_PKG_GRP_ID INTEGER NOT NULL ENABLE,
	VNDR_ID NUMBER(9,0) NOT NULL ENABLE,
	VNDR_SUBTYP VARCHAR2(3) NOT NULL ENABLE,
	SKU_ID NUMBER(7,0) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTDVP_PK PRIMARY KEY (SKU_PKG_GRP_ID, VNDR_ID, VNDR_SUBTYP)
	 ,CONSTRAINT ESCRDVP1 FOREIGN KEY (SKU_PKG_GRP_ID)
	  REFERENCES ESC.ESC_TKPG (SKU_PKG_GRP_ID) ENABLE NOVALIDATE
   ) 
;


