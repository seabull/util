
  CREATE TABLE ESC.ESC_TPKT
   (	SKU_PKG_TYP VARCHAR2(4) NOT NULL ENABLE,
	SKU_PKG_TYP_NM VARCHAR2(30) NOT NULL ENABLE,
	SKU_PKG_TYP_DESC VARCHAR2(256) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) DEFAULT SYSDATE NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTPKT_PK PRIMARY KEY (SKU_PKG_TYP)
   )
;


