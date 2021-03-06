CREATE TABLE ESC.ESC_TSSP
(    
    SKU_PKG_GRP_ID NUMBER(*,0) NOT NULL ENABLE,
        DEPT_ID NUMBER(3,0) NOT NULL ENABLE,
        CLASS_ID NUMBER(4,0) NOT NULL ENABLE,
        SUBCLASS_ID NUMBER(4,0) NOT NULL ENABLE,
        REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
        REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
        REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
         CONSTRAINT ESCTSSP_PK PRIMARY KEY (SKU_PKG_GRP_ID, DEPT_ID, CLASS_ID, SUBCLASS_ID)
   ) 
;

