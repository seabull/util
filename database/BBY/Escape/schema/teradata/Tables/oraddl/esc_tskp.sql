
  CREATE TABLE ESC.ESC_TSKP
   (	SKU_PKG_GRP_ID INTEGER NOT NULL ENABLE,
	SKU_ID NUMBER(7,0) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTSKP_PK PRIMARY KEY (SKU_PKG_GRP_ID, SKU_ID)
   )
;


--Create INDEX  ESC.IX_ESCTSKP_1  on ESC.ESC_TSKP   (SKU_ID,SKU_PKG_GRP_ID);
