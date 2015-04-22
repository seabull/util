CREATE TABLE ESC.ESC_CUSTCST
(	
    CUST_ID NUMBER(18,0) NOT NULL ENABLE,
	CUST_1ST_NM VARCHAR2(25) NOT NULL ENABLE,
	CUST_MDL_INTL VARCHAR2(1),
	CUST_LAST_NM VARCHAR2(25) NOT NULL ENABLE,
	CUST_NM_PREFIX_TYP VARCHAR2(7),
	CUST_ADDR_ST_NBR VARCHAR2(10),
	CUST_ADDR_ST_NM VARCHAR2(30) NOT NULL ENABLE,
	CUST_ADDR_UNIT_ID VARCHAR2(10),
	CUST_ADDR_CITY_NM VARCHAR2(30) NOT NULL ENABLE,
	STATE_ABBR VARCHAR2(5) NOT NULL ENABLE,
	CUST_ADDR_ZIP VARCHAR2(7) NOT NULL ENABLE,
	CUST_ADDR_ZIP4 VARCHAR2(4),
	CNTRY_ID VARCHAR2(2) NOT NULL ENABLE,
	EMAIL_ADDR_ID VARCHAR2(55),
	HOME_PH_AREA_NBR VARCHAR2(3),
	HOME_PH_NBR VARCHAR2(7) NOT NULL ENABLE,
	WORK_PH_AREA_NBR VARCHAR2(3),
	WORK_PH_NBR VARCHAR2(7),
	WORK_PH_EXT VARCHAR2(5),
	EC_SENT_FLG CHAR(1) DEFAULT 'N' NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	CUST_NM_SUFFIX_TYP VARCHAR2(3),
	 CONSTRAINT CUSTCST_PK PRIMARY KEY (CUST_ID)
) 
;

  CREATE TABLE ESC.ESC_TACS
   (
	AR_COMN_DTL_ID INTEGER NOT NULL ENABLE,
	COMN_SLS_BATCH_ID INTEGER NOT NULL ENABLE,
	COMN_AR_TYP VARCHAR2(4) NOT NULL ENABLE,
	ESC_CUST_ACCT_ID INTEGER NOT NULL ENABLE,
	COMN_MODL_ID INTEGER NOT NULL ENABLE,
	COMN_TRANS_POST_TS TIMESTAMP (6) NOT NULL ENABLE,
	COMN_TRANS_AMT NUMBER(9,2) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	AR_COMN_BAL_AMT NUMBER(9,2) NOT NULL ENABLE,
	AR_STAT_TYP VARCHAR2(6) NOT NULL ENABLE,
	ESC_PLAN_ID INTEGER,
	TRANS_AUDIT_ID INTEGER,
	 CONSTRAINT ESCTACS_PK PRIMARY KEY (AR_COMN_DTL_ID)
   ) 
;


  CREATE TABLE ESC.ESC_TARD
   (	AR_COMN_DTL_ID INTEGER NOT NULL ENABLE,
	APLY_COMN_DTL_ID INTEGER NOT NULL ENABLE,
	APLY_TRANS_AMT NUMBER(9,2) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTARD_PK PRIMARY KEY (AR_COMN_DTL_ID, APLY_COMN_DTL_ID)
   ) 
;


  CREATE TABLE ESC.ESC_TARS
   (	AR_STAT_TYP VARCHAR2(6) NOT NULL ENABLE,
	AR_STAT_NM VARCHAR2(30) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	AR_STAT_DESC VARCHAR2(256) NOT NULL ENABLE,
	 CONSTRAINT ESCTARS_PK PRIMARY KEY (AR_STAT_TYP)
   )
;


  CREATE TABLE ESC.ESC_TASC
   (	ESC_CUST_ACCT_ID INTEGER NOT NULL ENABLE,
	COMN_MODL_ID INTEGER NOT NULL ENABLE,
	SCHD_STAT_TYP VARCHAR2(4) NOT NULL ENABLE,
	LAST_COMN_PROC_TS TIMESTAMP (6),
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTASC_PK PRIMARY KEY (ESC_CUST_ACCT_ID, COMN_MODL_ID)
	 ,CONSTRAINT ESCRASC2 FOREIGN KEY (COMN_MODL_ID)
	  REFERENCES ESC.ESC_TCMD (COMN_MODL_ID) ENABLE NOVALIDATE,
	 CONSTRAINT ESCRASC3 FOREIGN KEY (SCHD_STAT_TYP)
	  REFERENCES ESC.ESC_TSCS (SCHD_STAT_TYP) ENABLE NOVALIDATE
   ) 
;


  CREATE TABLE ESC.ESC_TATA
   (	COMN_AR_TYP VARCHAR2(4) NOT NULL ENABLE,
	APLY_TO_AR_TYP VARCHAR2(4) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	MANL_ADJ_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	OPR_SIGN_TYP VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	 CONSTRAINT ESCTATA_PK PRIMARY KEY (COMN_AR_TYP, APLY_TO_AR_TYP)
	 ,CONSTRAINT ESCRATA1 FOREIGN KEY (COMN_AR_TYP)
	  REFERENCES ESC.ESC_TCAT (COMN_AR_TYP) ENABLE NOVALIDATE
   ) 
;


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


  CREATE TABLE ESC.ESC_TCAC
   (	ESC_CUST_ACCT_ID INTEGER NOT NULL ENABLE,
	ESC_PLAN_ID INTEGER NOT NULL ENABLE,
	ESC_ACCT_STAT_TYP VARCHAR2(4) NOT NULL ENABLE,
	CUST_ID NUMBER(18,0) NOT NULL ENABLE,
	ESC_ACCT_ACTV_DT DATE,
	ALL_ITEM_RTN_FLG VARCHAR2(1) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	ACCT_BAL_AMT NUMBER(9,2) NOT NULL ENABLE,
	CUST_SIGNTR_ID NUMBER(9,0),
	ESC_CA_OFFLINE VARCHAR2(1) NOT NULL ENABLE,
	AGGR_VNDR_ID NUMBER(9,0),
	AGGR_VNDR_SUBTYP VARCHAR2(3),
	 CONSTRAINT ESCTCAC_PK PRIMARY KEY (ESC_CUST_ACCT_ID)
   )
;


  CREATE TABLE ESC.ESC_TCAI
   (	ESC_CUST_ACCT_ID INTEGER NOT NULL ENABLE,
	ESC_LN_SEQ INTEGER NOT NULL ENABLE,
	ESC_LN_STAT_TYP VARCHAR2(4) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) DEFAULT 'ESC' NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) DEFAULT 'ESC' NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) DEFAULT SYSDATE NOT NULL ENABLE,
	 CONSTRAINT ESCTCAI_PK PRIMARY KEY (ESC_CUST_ACCT_ID, ESC_LN_SEQ)
   )
;


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


  CREATE TABLE ESC.ESC_TCMD
   (	COMN_MODL_ID INTEGER NOT NULL ENABLE,
	COMN_MODL_TYP VARCHAR2(4) NOT NULL ENABLE,
	COMN_MODL_NM VARCHAR2(30) NOT NULL ENABLE,
	TIER_CNDR_TYP VARCHAR2(4),
	TIER_PRD_TYP VARCHAR2(4),
	TIER_CNDR_PRD_NBR INTEGER,
	TIER_VAL_TYP VARCHAR2(4),
	PYMT_TLRNC_AMT NUMBER(9,2) DEFAULT 0 NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	COMN_MODL_DESC VARCHAR2(256) NOT NULL ENABLE,
	COMN_POST_FLG VARCHAR2(1) DEFAULT 'Y' NOT NULL ENABLE,
	 CONSTRAINT ESCTCMD_PK PRIMARY KEY (COMN_MODL_ID)
   )
;


  CREATE TABLE ESC.ESC_TCMH
   (	ESC_CUST_ACCT_ID INTEGER NOT NULL ENABLE,
	ESC_COMM_HIST_NBR INTEGER NOT NULL ENABLE,
	FILE_ACTVTY_TYP VARCHAR2(4) NOT NULL ENABLE,
	ESC_COMM_TS TIMESTAMP (6),
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	VNDR_ID NUMBER(9,0),
	VNDR_SUBTYP VARCHAR2(3),
	ESC_LN_SEQ INTEGER,
	 CONSTRAINT ESCTCMH_PK PRIMARY KEY (ESC_CUST_ACCT_ID, ESC_COMM_HIST_NBR, FILE_ACTVTY_TYP)
   )
;


  CREATE TABLE ESC.ESC_TCPT
   (	CHGBK_PRD_TYP VARCHAR2(4) NOT NULL ENABLE,
	CHGBK_PRD_TYP_NM VARCHAR2(30) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	CHGBK_PRD_TYP_DESC VARCHAR2(256) NOT NULL ENABLE,
	 CONSTRAINT ESCTCPT_PK PRIMARY KEY (CHGBK_PRD_TYP)
   )
;


  CREATE TABLE ESC.ESC_TCSC
   (	ESC_CUST_ACCT_ID INTEGER NOT NULL ENABLE,
	COMN_MODL_ID INTEGER NOT NULL ENABLE,
	PROC_STAT_TYP VARCHAR2(4) NOT NULL ENABLE,
	SCHD_TS TIMESTAMP (6),
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTCSC_PK PRIMARY KEY (ESC_CUST_ACCT_ID, COMN_MODL_ID)
	 ,CONSTRAINT ESCRCSC1 FOREIGN KEY (ESC_CUST_ACCT_ID, COMN_MODL_ID)
	  REFERENCES ESC.ESC_TASC (ESC_CUST_ACCT_ID, COMN_MODL_ID) ENABLE NOVALIDATE
   ) 
;


  CREATE TABLE ESC.ESC_TCSI
   (	ESC_CUST_ACCT_ID INTEGER NOT NULL ENABLE,
	INST_1ST_NM VARCHAR2(25),
	INST_MDL_INTL VARCHAR2(1),
	INST_LAST_NM VARCHAR2(25),
	INST_NM_PREFIX_TYP VARCHAR2(7),
	INST_NM_SUFFIX_TYP VARCHAR2(3),
	INST_ADDR_ST_NBR VARCHAR2(10),
	INST_ADDR_ST_NM VARCHAR2(30),
	INST_ADDR_UNIT_ID VARCHAR2(10),
	INST_ADDR_CITY_NM VARCHAR2(30),
	INST_STATE_ABBR VARCHAR2(5),
	INST_ADDR_ZIP VARCHAR2(7),
	INST_ADDR_ZIP4 VARCHAR2(4),
	INST_CNTRY_ID VARCHAR2(2),
	INST_HOME_PH_AREA VARCHAR2(3),
	INST_HOME_PH_NBR VARCHAR2(7),
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	PCI_CRCARD_TYPE VARCHAR2(1),
	EMAIL_ADDR_ID VARCHAR2(55),
	WORK_PH_AREA_NBR VARCHAR2(3),
	WORK_PH_NBR VARCHAR2(7),
	WORK_PH_EXT VARCHAR2(5),
	COMN_DEPT_TYP VARCHAR2(4) DEFAULT 'DFLT' NOT NULL ENABLE,
	CRCD_AUTH_ID VARCHAR2(16),
	CUST_RAC_USR_ID VARCHAR2(30),
	CUST_RAC_PSWD_TXT VARCHAR2(8),
	LANG_LCLE_ID NUMBER(10,0),
	CRCARD_ACCT_ID RAW(32),
	CRCARD_EXP_YEAR RAW(32),
	CRCARD_EXP_MNTH RAW(32),
	CRCARD_1ST_NM RAW(32),
	CRCARD_LAST_NM RAW(32),
	CRCARD_MDL_INTL RAW(16),
	CRCARD_TYPE RAW(16),
	CVRD_SKU_ID NUMBER(7,0),
	 CONSTRAINT ESCTCSI_PK PRIMARY KEY (ESC_CUST_ACCT_ID)
   ) 
;


  CREATE TABLE ESC.ESC_TCTP
   (	COMN_MODL_TYP VARCHAR2(4) NOT NULL ENABLE,
	COMN_MODL_TYP_NM VARCHAR2(30) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	COMN_MODL_TYP_DESC VARCHAR2(256) NOT NULL ENABLE,
	 CONSTRAINT ESCTCTP_PK PRIMARY KEY (COMN_MODL_TYP)
   )
;


  CREATE TABLE ESC.ESC_TDPM
   (	COMN_MODL_ID INTEGER NOT NULL ENABLE,
	ESC_PLAN_ID INTEGER NOT NULL ENABLE,
	COMN_DEPT_TYP VARCHAR2(4) NOT NULL ENABLE,
	POST_SKU_ID NUMBER(7,0) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	ACTV_FLG VARCHAR2(1) DEFAULT 'Y' NOT NULL ENABLE,
	 CONSTRAINT ESCTDPM_PK PRIMARY KEY (COMN_MODL_ID, ESC_PLAN_ID, COMN_DEPT_TYP)
   )
;


  CREATE TABLE ESC.ESC_TDPT
   (	COMN_DEPT_TYP VARCHAR2(4) NOT NULL ENABLE,
	COMN_DEPT_NM VARCHAR2(30) NOT NULL ENABLE,
	COMN_DEPT_DESC VARCHAR2(255) NOT NULL ENABLE,
	COMN_DEPT_ACTV_FLG VARCHAR2(1) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	 CONSTRAINT ESCTDPT_PK PRIMARY KEY (COMN_DEPT_TYP)
   ) 
;


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


	 --,CONSTRAINT CHK_SLS_ADT_PCSD_STAT_TYP CHECK (SLS_ADT_PCSD_STAT_TYP in ('PCSD', 'LDED', 'PSNG', 'FAIL')) ENABLE NOVALIDATE
  CREATE TABLE ESC.ESC_TEGT
   (	TRANS_AUDIT_ID INTEGER NOT NULL ENABLE,
	SLS_TRANS_NBR NUMBER(5,0) NOT NULL ENABLE,
	REGSTR_NBR NUMBER(3,0) NOT NULL ENABLE,
	SLS_TRANS_TS TIMESTAMP (6) NOT NULL ENABLE,
	LOC_ID NUMBER(5,0) NOT NULL ENABLE,
	AUDIT_TYP VARCHAR2(4) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	COMN_AR_TYP VARCHAR2(4),
	POST_SKU_ID NUMBER(7,0),
	SALE_AMT NUMBER(9,2),
	GL_CD VARCHAR2(6),
	SALE_POST_TS TIMESTAMP (6),
	SLS_ADT_PCSD_STAT_TYP VARCHAR2(4) DEFAULT 'LDED' NOT NULL ENABLE,
	SLS_ADT_PRCS_MC_NM VARCHAR2(10),
	CC_FEED_PCSD_STAT_TYP VARCHAR2(4) NOT NULL ENABLE,
	 CONSTRAINT ESCTEGT_PK PRIMARY KEY (TRANS_AUDIT_ID)
   ) 
;

  CREATE TABLE ESC.ESC_TFAT
   (	FILE_ACTVTY_TYP VARCHAR2(4) NOT NULL ENABLE,
	FILE_ACTVTY_TYP_NM VARCHAR2(30) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	FILE_ACTVTY_DESC VARCHAR2(256) NOT NULL ENABLE,
	JAVA_CLASS_NM VARCHAR2(256),
	FILE_TYP_HOLD_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	 CONSTRAINT ESCTFAT_PK PRIMARY KEY (FILE_ACTVTY_TYP)
   )
;


  CREATE TABLE ESC.ESC_TKPG
   (	SKU_PKG_GRP_ID INTEGER NOT NULL ENABLE,
	SKU_PKG_GRP_NM VARCHAR2(30) NOT NULL ENABLE,
	PROVDR_REQD_FLG VARCHAR2(1) NOT NULL ENABLE,
	SKU_PKG_ID INTEGER NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	SKU_PKG_GRP_DESC VARCHAR2(256) NOT NULL ENABLE,
	SNGL_INSTL_REQ_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	 CONSTRAINT ESCTKPG_PK PRIMARY KEY (SKU_PKG_GRP_ID)
	 ,CONSTRAINT ESCRKPG1 FOREIGN KEY (SKU_PKG_ID)
	  REFERENCES ESC.ESC_TPKG (SKU_PKG_ID) ENABLE NOVALIDATE
   ) 
;


  CREATE TABLE ESC.ESC_TLIA
   (	ESC_LN_SEQ INTEGER NOT NULL ENABLE,
	ATRIB_NM VARCHAR2(10) NOT NULL ENABLE,
	ESC_ATRIB_VAL VARCHAR2(100) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTLIA_PK PRIMARY KEY (ESC_LN_SEQ, ATRIB_NM)
   )
;


  CREATE TABLE ESC.ESC_TLNI
   (	ESC_LN_SEQ INTEGER NOT NULL ENABLE,
	ESC_LN_SKU_ID NUMBER(7,0) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	ORIG_SLS_TRANS_NBR NUMBER(5,0) NOT NULL ENABLE,
	ORIG_LOC_ID NUMBER(5,0) NOT NULL ENABLE,
	ORIG_REGSTR_NBR NUMBER(3,0) NOT NULL ENABLE,
	ORIG_SLS_TRANS_TS TIMESTAMP (6) NOT NULL ENABLE,
	SLS_TRANS_LN_AMT NUMBER(9,2) DEFAULT 0 NOT NULL ENABLE,
	 CONSTRAINT ESCTLNI_PK PRIMARY KEY (ESC_LN_SEQ)
   )
;


  CREATE TABLE ESC.ESC_TPAD
   (	VNDR_PRFL_ID INTEGER NOT NULL ENABLE,
	XML_DOC_ID INTEGER NOT NULL ENABLE,
	FILE_ACTVTY_TYP VARCHAR2(4) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTPAD_PK PRIMARY KEY (VNDR_PRFL_ID, XML_DOC_ID, FILE_ACTVTY_TYP)
   )
;


  CREATE TABLE ESC.ESC_TPAK
   (	SKU_ID NUMBER(7,0) NOT NULL ENABLE,
	ESC_PLAN_ID INTEGER NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTPAK_PK PRIMARY KEY (SKU_ID, ESC_PLAN_ID)
   )
;


  CREATE TABLE ESC.ESC_TPKG
   (	SKU_PKG_ID INTEGER NOT NULL ENABLE,
	SKU_PKG_NM VARCHAR2(30) NOT NULL ENABLE,
	PKG_OWNR_TYP VARCHAR2(4) NOT NULL ENABLE,
	SKU_PKG_BEG_DT TIMESTAMP (6) NOT NULL ENABLE,
	SKU_PKG_END_DT TIMESTAMP (6) NOT NULL ENABLE,
	ESC_GRP_TYP VARCHAR2(4) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	SKU_PKG_DESC VARCHAR2(256) NOT NULL ENABLE,
	SKU_PKG_TYP VARCHAR2(4) DEFAULT 'STND' NOT NULL ENABLE,
	 CONSTRAINT ESCTPKG_PK PRIMARY KEY (SKU_PKG_ID)
	 ,CONSTRAINT ESCRPKT1 FOREIGN KEY (SKU_PKG_TYP)
	  REFERENCES ESC.ESC_TPKT (SKU_PKG_TYP) ENABLE NOVALIDATE
   ) 
;


  CREATE TABLE ESC.ESC_TPKP
   (	SKU_PKG_ID INTEGER NOT NULL ENABLE,
	SKU_ID NUMBER(7,0) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTPKP_PK PRIMARY KEY (SKU_PKG_ID, SKU_ID)
   )
;


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


  CREATE TABLE ESC.ESC_TPLC
   (	ESC_PLAN_ID INTEGER NOT NULL ENABLE,
	COMN_MODL_ID INTEGER NOT NULL ENABLE,
	PLAN_COMN_BEG_TS TIMESTAMP (6) NOT NULL ENABLE,
	PLAN_COMN_END_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	SKU_ID NUMBER(7,0),
	 CONSTRAINT ESCTPLC_PK PRIMARY KEY (ESC_PLAN_ID, COMN_MODL_ID)
	 ,CONSTRAINT ESCRPLC1 FOREIGN KEY (COMN_MODL_ID)
	  REFERENCES ESC.ESC_TCMD (COMN_MODL_ID) ENABLE NOVALIDATE,
	 CONSTRAINT ESCRPLC2 FOREIGN KEY (ESC_PLAN_ID)
	  REFERENCES ESC.ESC_TPLN (ESC_PLAN_ID) ENABLE NOVALIDATE
   ) 
;


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
   )
;


  CREATE TABLE ESC.ESC_TRMD
   (	COMN_MODL_ID INTEGER NOT NULL ENABLE,
	RESID_OFFSET_TYP VARCHAR2(4) NOT NULL ENABLE,
	RESID_PRD_TYP VARCHAR2(4) NOT NULL ENABLE,
	RESID_CALC_TYP VARCHAR2(4) NOT NULL ENABLE,
	LIFE_TM_RESID_FLG VARCHAR2(1) NOT NULL ENABLE,
	MAX_RESID_PMNT_NBR INTEGER NOT NULL ENABLE,
	RESID_PRD_NBR INTEGER NOT NULL ENABLE,
	RESID_OFFSET_NBR INTEGER NOT NULL ENABLE,
	RESID_PYMT_DLR_AMT NUMBER(9,2) NOT NULL ENABLE,
	RESID_PYMT_PCT NUMBER(5,2) NOT NULL ENABLE,
	DFLT_PYMT_DLR_AMT NUMBER(9,2) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTRMD_PK PRIMARY KEY (COMN_MODL_ID)
	 ,CONSTRAINT ESCRRMD4 FOREIGN KEY (COMN_MODL_ID)
	  REFERENCES ESC.ESC_TCMD (COMN_MODL_ID) ENABLE NOVALIDATE
   )
;


  CREATE TABLE ESC.ESC_TSKP
   (	SKU_PKG_GRP_ID INTEGER NOT NULL ENABLE,
	SKU_ID NUMBER(7,0) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTSKP_PK PRIMARY KEY (SKU_PKG_GRP_ID, SKU_ID)
   )
;


  CREATE TABLE ESC.ESC_TSLT
   (	SLS_TRANS_NBR NUMBER(5,0) NOT NULL ENABLE,
	REGSTR_NBR NUMBER(3,0) NOT NULL ENABLE,
	SLS_TRANS_TS TIMESTAMP (6) NOT NULL ENABLE,
	LOC_ID NUMBER(5,0) NOT NULL ENABLE,
	ESC_TRANS_SRC_TYP VARCHAR2(4) NOT NULL ENABLE,
	ESC_TRANS_VOID_FLG VARCHAR2(1) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTSLT_PK PRIMARY KEY (LOC_ID, SLS_TRANS_NBR, REGSTR_NBR, SLS_TRANS_TS)
   )
;


  CREATE TABLE ESC.ESC_TSTD
   (	SLS_TRANS_LN_NBR NUMBER(4,0) NOT NULL ENABLE,
	SLS_TRANS_NBR NUMBER(5,0) NOT NULL ENABLE,
	REGSTR_NBR NUMBER(3,0) NOT NULL ENABLE,
	SLS_TRANS_TS TIMESTAMP (6) NOT NULL ENABLE,
	LOC_ID NUMBER(5,0) NOT NULL ENABLE,
	ESC_LN_SEQ INTEGER NOT NULL ENABLE,
	ESC_LN_ACTVTY_TYP VARCHAR2(4) NOT NULL ENABLE,
	ESC_LN_VOID_FLG VARCHAR2(1) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTSTD_PK PRIMARY KEY (LOC_ID, SLS_TRANS_NBR, REGSTR_NBR, SLS_TRANS_TS, SLS_TRANS_LN_NBR)
	 ,CONSTRAINT ESCRSTD1 FOREIGN KEY (LOC_ID, SLS_TRANS_NBR, REGSTR_NBR, SLS_TRANS_TS)
	  REFERENCES ESC.ESC_TSLT (LOC_ID, SLS_TRANS_NBR, REGSTR_NBR, SLS_TRANS_TS) ENABLE NOVALIDATE
   ) 
;


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
   ) 
;


  CREATE TABLE ESC.ESC_TVPF
   (	VNDR_FILE_ID INTEGER NOT NULL ENABLE,
	VNDR_PYMT_XFER_TYP VARCHAR2(5),
	VNDR_PYMT_ID VARCHAR2(30) NOT NULL ENABLE,
	VNDR_PYMT_DRAW_DT DATE,
	VNDR_NET_PYMT_AMT NUMBER(9,2) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	 CONSTRAINT ESCTVPF_PK PRIMARY KEY (VNDR_FILE_ID)
	 ,CONSTRAINT ESCRVPF1 FOREIGN KEY (VNDR_FILE_ID)
	  REFERENCES ESC.ESC_TVAF (VNDR_FILE_ID) ENABLE NOVALIDATE
   ) 
;


  CREATE TABLE ESC.ESC_TVPR
   (	VNDR_PRFL_ID INTEGER NOT NULL ENABLE,
	VNDR_ID NUMBER(9,0) NOT NULL ENABLE,
	VNDR_SUBTYP VARCHAR2(3) NOT NULL ENABLE,
	FILE_PRFL_TYP VARCHAR2(4) NOT NULL ENABLE,
	FILE_LAYOT_TYP VARCHAR2(4) NOT NULL ENABLE,
	TRANSPT_PROTCL_TYP VARCHAR2(5) NOT NULL ENABLE,
	DELMT_TXT VARCHAR2(1),
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_UPD_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	XFER_USR_ID VARCHAR2(20),
	XFER_PSWD_TXT VARCHAR2(20),
	GRFX_EC_TYPE VARCHAR2(3),
	EC_RAW_DATA_FLG VARCHAR2(1) NOT NULL ENABLE,
	EC_GRFX_FILE_FLG VARCHAR2(1) NOT NULL ENABLE,
	EC_ECNTR_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	EC_SSN_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	EC_SEC_ADDR_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	EC_SIGNTR_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	EC_CRDT_INFO_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	VNDR_ECNTR_FILE VARCHAR2(12),
	XFER_XSL_FILE_NM VARCHAR2(100),
	TRNSPT_URL_TXT VARCHAR2(256),
	TRNSPT_DIR_TXT VARCHAR2(256),
	VNDR_HDR_SIZE INTEGER,
	VNDR_DT_FORMAT VARCHAR2(25),
	EC_EMAIL_REQ_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	EC_SSN_REQ_FLG VARCHAR2(1) DEFAULT 'Y' NOT NULL ENABLE,
	PLAN_SEL_REQD_FLG VARCHAR2(1) DEFAULT 'Y' NOT NULL ENABLE,
	ATTRB_REQD_FLG VARCHAR2(1) DEFAULT 'Y' NOT NULL ENABLE,
	EC_SEC_INFO_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	INCL_ALL_HDWR_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	DUP_ACCT_INCL_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	AGGR_VNDR_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	CUST_SEL_REQ_FLG VARCHAR2(1) DEFAULT 'Y' NOT NULL ENABLE,
	EC_WORK_PH_REQ_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	EC_WORK_PH_DIS_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	EC_EMAIL_DIS_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	COMN_DEPT_DIS_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	SYS_EXCP_RSLN_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	ESC_RAC_ENBL_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	ESC_RAC_OFFLN_CDE VARCHAR2(1) DEFAULT '0' NOT NULL ENABLE,
	EXCH_ENBL_FLG VARCHAR2(1) DEFAULT 'Y' NOT NULL ENABLE,
	B2B_SFWR_VER_ID VARCHAR2(10) DEFAULT 'WM6' NOT NULL ENABLE,
	INVL_ACCT_AUTO_CMPLT_FLG VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
	 CONSTRAINT ESCTVPR_PK PRIMARY KEY (VNDR_PRFL_ID)
   )
;


  CREATE TABLE ESC.ESC_TVPT
   (	ATRIB_PRFL_ID INTEGER NOT NULL ENABLE,
	VNDR_ATRIB_TYP VARCHAR2(10) NOT NULL ENABLE,
	REC_CREATE_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
	REC_CREATE_TS TIMESTAMP (6) NOT NULL ENABLE,
	REC_CREATE_USR_ID VARCHAR2(8) NOT NULL ENABLE,
	 CONSTRAINT ESCTVPT_PK PRIMARY KEY (ATRIB_PRFL_ID, VNDR_ATRIB_TYP)
   ) 
;

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

--PCTFREE 10 PCTUSED 40 INITRANS 4 MAXTRANS 255 NOCOMPRESS LOGGING
--  STORAGE(INITIAL 2097152 NEXT 2097152 MINEXTENTS 1 MAXEXTENTS 2147483645
--  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
--  TABLESPACE ESCDAT01

CREATE TABLE ESC.ESC_SKUTSKU
   (    SKU_ID NUMBER(7,0) NOT NULL ENABLE,
        SKU_DESC VARCHAR2(30) NOT NULL ENABLE,
        SKU_MFG_MODEL_ID VARCHAR2(10) NOT NULL ENABLE,
        SUBCLASS_ID NUMBER(4,0) NOT NULL ENABLE,
        CLASS_ID NUMBER(4,0) NOT NULL ENABLE,
        DEPT_ID NUMBER(3,0) NOT NULL ENABLE,
        SKU_ACTV_FLG VARCHAR2(1) NOT NULL ENABLE,
        PRIM_VNDR_ID NUMBER(9,0) NOT NULL ENABLE,
        REC_CREATE_DT DATE NOT NULL ENABLE,
        REC_UPD_PGM_TS TIMESTAMP (6) NOT NULL ENABLE,
        REC_UPD_USR_ID VARCHAR2(8) NOT NULL ENABLE,
        REC_UPD_PGM_ID VARCHAR2(8) NOT NULL ENABLE,
         CONSTRAINT SKUTSKU_PK PRIMARY KEY (SKU_ID)
   ) 
;


Create INDEX  ESC.IX_ESCTACS_1  on ESC.ESC_TACS (ESC_CUST_ACCT_ID);
Create INDEX  ESC.IX_ESCTACS_2  on ESC.ESC_TACS (AR_COMN_BAL_AMT);
Create INDEX  ESC.IX_ESCTACS_3  on ESC.ESC_TACS (COMN_AR_TYP, COMN_SLS_BATCH_ID);
Create INDEX  ESC.IX_ESCTACS_4  on ESC.ESC_TACS (COMN_TRANS_POST_TS, COMN_AR_TYP);
Create INDEX  ESC.IX_ESCTACS_5  on ESC.ESC_TACS (TRANS_AUDIT_ID);
Create INDEX  ESC.IX_ESCTASC_1  on ESC.ESC_TASC (COMN_MODL_ID);
Create INDEX  ESC.IX_ESCTASC_2  on ESC.ESC_TASC (SCHD_STAT_TYP);
Create INDEX  ESC.IX_ESCTCAC_1  on ESC.ESC_TCAC (ESC_PLAN_ID ,ESC_ACCT_STAT_TYP ,REC_CREATE_TS ,AGGR_VNDR_ID);
Create INDEX  ESC.IX_ESCTCAC_2  on ESC.ESC_TCAC (CUST_ID);
Create INDEX  ESC.IX_ESCTCAC_3  on ESC.ESC_TCAC (AGGR_VNDR_ID ,AGGR_VNDR_SUBTYP);
Create INDEX  ESC.IX_ESCTCAC_4  on ESC.ESC_TCAC (REC_UPD_TS);
Create INDEX  ESC.IX_ESCTCAI_1  on ESC.ESC_TCAI   (ESC_LN_SEQ);
Create INDEX  ESC.IX_ESCTCAI_2  on ESC.ESC_TCAI   (REC_UPD_TS);
Create INDEX  ESC.IX_ESCTKPG_1  on ESC.ESC_TKPG   (SKU_PKG_ID);
Create INDEX  ESC.IX_ESCTLIA_1  on ESC.ESC_TLIA   (ESC_ATRIB_VAL);
Create INDEX  ESC.IX_ESCTLIA_2  on ESC.ESC_TLIA   (ATRIB_NM);
Create INDEX  ESC.IX_ESCTLNI_1  on ESC.ESC_TLNI   (ORIG_LOC_ID ,ORIG_SLS_TRANS_NBR ,ORIG_REGSTR_NBR ,ORIG_SLS_TRANS_TS);
Create INDEX  ESC.IX_ESCTLNI_2  on ESC.ESC_TLNI   (ESC_LN_SKU_ID);
Create INDEX  ESC.IX_ESCTPKG_1  on ESC.ESC_TPKG   (SKU_PKG_TYP);
Create INDEX  ESC.IX_ESCTPKP_1  on ESC.ESC_TPKP   (SKU_ID);
Create INDEX  ESC.IX_ESCTPLC_1  on ESC.ESC_TPLC   (COMN_MODL_ID);
Create INDEX  ESC.IX_ESCTPLN_1  on ESC.ESC_TPLN   (VNDR_ID,VNDR_SUBTYP);
Create INDEX  ESC.IX_ESCTPLN_2  on ESC.ESC_TPLN   (ESC_GRP_TYP);
Create INDEX  ESC.IX_ESCTVNI_1  on ESC.ESC_TVNI   (FISC_TYP_ID);
Create INDEX  ESC.IX_ESCTVPR_1  on ESC.ESC_TVPR   (VNDR_ID,VNDR_SUBTYP);
Create INDEX  ESC.IX_ESCTVPT_1  on ESC.ESC_TVPT   (VNDR_ATRIB_TYP);
Create INDEX  ESC.IX_ESCCUSTCST_1  on ESC.ESC_CUSTCST   ( CUST_LAST_NM ,CUST_1ST_NM ,CUST_ID);
Create INDEX  ESC.IX_ESCCUSTCST_2  on ESC.ESC_CUSTCST   ( HOME_PH_NBR ,CUST_LAST_NM ,CUST_1ST_NM ,HOME_PH_AREA_NBR);
Create INDEX  ESC.IX_ESCCUSTCST_3  on ESC.ESC_CUSTCST   (EC_SENT_FLG);
Create INDEX  ESC.IX_ESCTCMH_1  on ESC.ESC_TCMH   (ESC_COMM_TS);
Create INDEX  ESC.IX_ESCTSTD_1  on ESC.ESC_TSTD   (ESC_LN_SEQ);
Create INDEX  ESC.IX_ESCTSTD_2  on ESC.ESC_TSTD   (REGSTR_NBR);
Create INDEX  ESC.IX_ESCTSTD_3  on ESC.ESC_TSTD   (SLS_TRANS_TS,LOC_ID);
Create INDEX  ESC.IX_ESCTSTD_4  on ESC.ESC_TSTD   (SLS_TRANS_NBR);

--Create INDEX  ESC.IX_ESCTPAK_1  on ESC.ESC_TPAK   (ESC_PLAN_ID ,SKU_ID);
