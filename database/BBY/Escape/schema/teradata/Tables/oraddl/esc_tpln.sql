
  CREATE TABLE ESC.ESC_TPLN
   (	ESC_PLAN_ID INTEGER NOT NULL ENABLE,
	VNDR_ID NUMBER(9,0) NOT NULL ENABLE,
	VNDR_SUBTYP VARCHAR2(3) NOT NULL ENABLE,
	ESC_PLAN_NM VARCHAR2(30) NOT NULL ENABLE,
	PLAN_ACTV_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	MULT_PRIM_SKU_FLG VARCHAR2(1) NOT NULL ENABLE,
	ESC_GRP_TYP VARCHAR2(4) NOT NULL ENABLE,
	VNDR_PLAN_ID VARCHAR2(30) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	ESC_PLAN_DESC VARCHAR2(256),
	ESC_PLAN_XPTN_TYP VARCHAR2(4) DEFAULT 'EXCL' NOT NULL ENABLE,
	CUST_PLAN_XPTN_TYP VARCHAR2(4) DEFAULT 'ALL' NOT NULL ENABLE,
	ESC_PLAN_NRTC_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	AVAIL_OFFLN_FLG VARCHAR2(1) DEFAULT 'Y' NOT NULL ENABLE,
	SEC_VNDR_PLAN_ID VARCHAR2(50),
	 CONSTRAINT ESCTPLN_PK PRIMARY KEY (ESC_PLAN_ID)
	 ,CONSTRAINT ESCRPLN1 FOREIGN KEY (ESC_PLAN_XPTN_TYP)
	  REFERENCES ESC.ESC_TPLX (ESC_PLAN_XPTN_TYP) ENABLE NOVALIDATE
   )
;


Create INDEX  ESC.IX_ESCTPLN_1  on ESC.ESC_TPLN   (VNDR_ID,VNDR_SUBTYP);
Create INDEX  ESC.IX_ESCTPLN_2  on ESC.ESC_TPLN   (ESC_GRP_TYP);

