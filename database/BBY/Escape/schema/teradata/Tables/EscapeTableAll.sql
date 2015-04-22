--------------------------------------------------------------------
-- $Id: EscapeTableAll.sql,v 1.6 2008/12/19 17:24:20 A645276 Exp $
-- $Author: A645276 $
-- $Date: 2008/12/19 17:24:20 $
-- $Revision: 1.6 $
--------------------------------------------------------------------
--  Revision History:
--  2008/12/09      LJ Yang     Teradata DDLs based on ESCAPE Oracle DB Physical Design Document
--
--------------------------------------------------------------------

DROP TABLE DEVBBYMEADHOCDB.ESC_TACS 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TARD 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TARS 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TASC 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TATA 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TBMD 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TCAC 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TCAI 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TCAT 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TCMD 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TCPT 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TCSC 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TCSI 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TCTP 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TDVP 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TEGT 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TFAT 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TKPG 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TLIA 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TLNI 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TPAD 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TPAK 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TPKG 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TPKP 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TPKT 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TPLC 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TPLN 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TRMD 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TSKP 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TSLT 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TVAF 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TVNI 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TVPF 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TVPR 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TVPT 
;DROP TABLE DEVBBYMEADHOCDB.ESC_CUSTCST 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TCMH 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TSTD 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TDPT 
;DROP TABLE DEVBBYMEADHOCDB.ESC_TDPM 
;
-----------------------------------------------

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TACS   ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL,
    CHECKSUM = DEFAULT
(
         AR_COMN_DTL_ID      INTEGER         NOT NULL   --Primary Key X		X
        ,COMN_SLS_BATCH_ID   INTEGER                    --           		X
        ,COMN_AR_TYP         VARCHAR(4)                 --           		X
        ,ESC_CUST_ACCT_ID    INTEGER                    --           		X
        ,COMN_MODL_ID        INTEGER                    --           		X
        ,COMN_TRANS_POST_TS  TIMESTAMP                  --           		X
        ,COMN_TRANS_AMT      NUMERIC(9,2)               --           		X
        ,REC_CREATE_PGM_ID   VARCHAR(8)                 --           		X
        ,REC_CREATE_TS       TIMESTAMP                  --           		X
        ,REC_CREATE_USR_ID   VARCHAR(8)                 --           		X
        ,REC_UPD_PGM_ID      VARCHAR(8)                 --           		X
        ,REC_UPD_TS          TIMESTAMP                  --           		X
        ,REC_UPD_USR_ID      VARCHAR(8)                 --           		X
        ,AR_COMN_BAL_AMT     NUMERIC(9,2)               --           		X
        ,AR_STAT_TYP         VARCHAR(6)                 --           	X	X
        ,ESC_PLAN_ID         INTEGER                    --           		
        ,TRANS_AUDIT_ID      INTEGER                    --           	X	
)
UNIQUE PRIMARY INDEX ESC_TACS_PI (AR_COMN_DTL_ID)
INDEX (ESC_CUST_ACCT_ID)
INDEX (AR_COMN_BAL_AMT)
INDEX (COMN_AR_TYP, COMN_SLS_BATCH_ID)
INDEX (COMN_TRANS_POST_TS, COMN_AR_TYP)
INDEX (TRANS_AUDIT_ID)
;

COMMENT ON DEVBBYMEADHOCDB.ESC_TACS  IS 'The account receivable detail table contains all detailed account receivable information associated with specific account-commission id combinations' 
;
--AR_COMN_DTL_ID	The account receivable detail number is a surrogate key used to uniquely identify an AR detail.
--COMN_SLS_BATCH_ID	The sales batch number is a surrogate key used to uniquely identify a sales batch process.
--COMN_AR_TYP	The account receivable type code identifies the type of an account receivable.  Available AR types are represented by the rows in the ESCTCAT table.
--ESC_CUST_ACCT_ID	The customer account identifier is a surrogate key used to uniquely identify an ESC customer account.
--COMN_MODL_ID	The commission model identifier is a surrogate key used to uniquely identify a commission model.
--COMN_TRANS_POST_TS	The detail posting date is the date that the A/R detail was posted.
--COMN_TRANS_AMT	The detail dollar amount is the dollar amount of the account receivable detail.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--AR_COMN_BAL_AMT	Account Receivable Detail Balance
--AR_STAT_TYP	Account Receivable Detail Status Type
--ESC_PLAN_ID	The subscription plan identifier is a surrogate key representing a unique subscription plan.  An example of a rate plan would be 'AT&T Digital PCS One Rate 600 Minutes'.
--TRANS_AUDIT_ID	

--indexes
--(ESC_CUST_ACCT_ID)
--(AR_COMN_BAL_AMT)
--(COMN_AR_TYP, COMN_SLS_BATCH_ID)
--(COMN_TRANS_POST_TS, COMN_AR_TYP)
--(TRANS_AUDIT_ID)

----------------------------------------------
CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TARD ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
         AR_COMN_DTL_ID      INTEGER	    --X	X	X
        ,APLY_COMN_DTL_ID    INTEGER	    --X		X
        ,APLY_TRANS_AMT      NUMERIC(9,2)	--		X
        ,REC_CREATE_PGM_ID   VARCHAR(8)	--		X
        ,REC_CREATE_TS       TIMESTAMP		--	X
        ,REC_CREATE_USR_ID   VARCHAR(8)	--		X
        ,REC_UPD_PGM_ID      VARCHAR(8)	--		X
        ,REC_UPD_TS          TIMESTAMP		--	X
        ,REC_UPD_USR_ID      VARCHAR(8)	--		X
)
UNIQUE PRIMARY INDEX ESC_TARD_PI (AR_COMN_DTL_ID,APLY_COMN_DTL_ID)
;

COMMENT ON DEVBBYMEADHOCDB.ESC_TARD   IS 'Adjustment Account Receivable Detail' 
;
--AR_COMN_DTL_ID	The account receivable detail number is a surrogate key used to uniquely identify an AR detail.
--APLY_COMN_DTL_ID	Applied Account Receivable Detail Identifier
--APLY_TRANS_AMT	Applied Transaction Amount
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.

----------------------------------------------
CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TARS ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
         AR_STAT_TYP         VARCHAR(6)	--    X		X
        ,AR_STAT_NM          VARCHAR(30)	--		X
        ,REC_CREATE_PGM_ID   VARCHAR(8)	--		    X
        ,REC_UPD_PGM_ID      VARCHAR(8)	--		    X
        ,REC_UPD_USR_ID      VARCHAR(8)	--		    X
        ,REC_CREATE_USR_ID   VARCHAR(8)	--		    X
        ,REC_UPD_TS          TIMESTAMP		--	    X
        ,REC_CREATE_TS       TIMESTAMP		--	    X
        ,AR_STAT_DESC        VARCHAR(256)	--		X
)
UNIQUE PRIMARY INDEX ESC_TARS_PI (AR_STAT_TYP)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TARS   IS 'Account Receivable Status Type table' 
;
--AR_STAT_TYP	Account Receivable Detail Status Type
--AR_STAT_NM	Account Receivable Detail Status Name
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--AR_STAT_DESC	Account Receivable Detail Status Description

----------------------------------------------
--Account Commission
--The account commission table acts as a transition table solving the many-to-many relationship between customer accounts and commission models.  The specific combination of these two entities is used to schedule the posting of account receivable information.
--
CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TASC ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
         ESC_CUST_ACCT_ID    INTEGER	    --X	X	X	
        ,COMN_MODL_ID        INTEGER	    --X	X	X	
        ,SCHD_STAT_TYP       VARCHAR(4)	--	X	X	
        ,LAST_COMN_PROC_TS   TIMESTAMP		--		
        ,REC_CREATE_PGM_ID   VARCHAR(8)	--		X	
        ,REC_CREATE_TS       TIMESTAMP		--	X	
        ,REC_CREATE_USR_ID   VARCHAR(8)	--		X	
        ,REC_UPD_PGM_ID      VARCHAR(8)	--		X	
        ,REC_UPD_TS          TIMESTAMP		--	X	
        ,REC_UPD_USR_ID      VARCHAR(8)	--		X	
)
UNIQUE PRIMARY INDEX ESC_TASC_PI (ESC_CUST_ACCT_ID, COMN_MODL_ID)
INDEX (COMN_MODL_ID)
INDEX (SCHD_STAT_TYP)
;

COMMENT ON DEVBBYMEADHOCDB.ESC_TASC   IS 'account commission table acts as a transition table solving the many-to-many relationship between customer accounts and commission models. The specific combination of these two entities is used to schedule the posting of account receivable information.' 
;

--ESC_CUST_ACCT_ID	The customer account identifier is a surrogate key used to uniquely identify an ESC customer account.	INTEGER	X	X	X
--COMN_MODL_ID	The commission model identifier is a surrogate key used to uniquely identify a commission model.	INTEGER	X	X	X
--SCHD_STAT_TYP	The account commission status code is a four-character code that identifies the status of a specific account-commission combination.  Available codes include (followed by their description): SCHD (Scheduled), NSCH (Not Scheduled), DONE (Completed revenue	VARCHAR(4)		X	X
--LAST_COMN_PROC_TS	The last processed date is the last date that the specific account-commission combination was processed for posting receivable revenue.	TIMESTAMP			
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.	VARCHAR(8)			X
--REC_CREATE_TS	The date and time upon which the physical record is created.	TIMESTAMP			X
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.	VARCHAR(8)			X
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.	VARCHAR(8)			X
--REC_UPD_TS	Timestamp of the last time the record was modified.	TIMESTAMP			X
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.	VARCHAR(8)			X


----------------------------------------------
--Name	ESCTATA
--Stereotype	Account Receivable Adjustment
--Comment	AR Adjustment type table

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TATA ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
         COMN_AR_TYP         VARCHAR(4)	                --X	X	X	    
        ,APLY_TO_AR_TYP      VARCHAR(4)	                --X		X	
        ,REC_CREATE_PGM_ID   VARCHAR(8)	                --		X	
        ,REC_UPD_PGM_ID      VARCHAR(8)	                --		X	
        ,REC_CREATE_USR_ID   VARCHAR(8)	                --		X	
        ,REC_UPD_USR_ID      VARCHAR(8)	                --		X	
        ,REC_CREATE_TS       TIMESTAMP		                --	X	
        ,REC_UPD_TS          TIMESTAMP		                --	X	
        ,MANL_ADJ_FLG        VARCHAR(1)	DEFAULT 'N'     --		X	N
        ,OPR_SIGN_TYP        VARCHAR(1)	DEFAULT 'N'     --	X	X	N
)
UNIQUE PRIMARY INDEX ESC_TATA_PI (COMN_AR_TYP, APLY_TO_AR_TYP)
;

COMMENT ON DEVBBYMEADHOCDB.ESC_TATA   IS 'Account Receivable Adjustment Type' 
;

--The account receivable type code is a four-character code that identifies the type of an account receivable.  Available codes include (followed by their description): RECV (Receivable), PYMT (Payment), CHBK (Chargeback), RETN (Return), TADJ (Tier Adjustment)
--Applied Account Receivable Type
--The unique identifier of the management information systems program that was used to create the physical record.
--The identifier of the information systems program that was used to update the record most recently.
--The identifier of the user that was responsible for initially creating & populating the record.
--The identifier of the user who was responsible for updating the record most recently.
--The date and time upon which the physical record is created.
--Timestamp of the last time the record was modified.
--MANL_ADJ_FLG
--Sign Operator Type



----------------------------------------------
--Name	ESCTBMD
--Stereotype	Bounty Model
--Comment	The bounty model table defines the commission models that can be used to calculate bounty account receivables for selling a provider's subscription service at Best Buy.  Individual bounty models can be used by several plans.
--
CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TBMD ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
         COMN_MODL_ID        INTEGER	    --X	X	X
        ,CHGBK_PRD_TYP       VARCHAR(4)	--	X	X
        ,CHGBK_PRD_NBR       INTEGER		--	    X
        ,BNTY_CALC_TYP       VARCHAR(4)	--	X	X
        ,BNTY_DLR_AMT        NUMERIC(9,2)	--		X
        ,BNTY_RESRV_FLG      VARCHAR(1)	--		X
        ,CHGBK_PCT           NUMERIC(5,2)	--		X
        ,REC_CREATE_PGM_ID   VARCHAR(8)	--		X
        ,REC_CREATE_TS       TIMESTAMP		--	X
        ,REC_CREATE_USR_ID   VARCHAR(8)	--		X
        ,REC_UPD_PGM_ID      VARCHAR(8)	--		X
        ,REC_UPD_TS          TIMESTAMP		--	X
        ,REC_UPD_USR_ID      VARCHAR(8)	--		X
)
UNIQUE PRIMARY INDEX ESC_TBMD_PI (COMN_MODL_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TBMD   IS 'bounty model table defines the commission models that can be used to calculate bounty account receivables for selling a providers subscription service at BBY. Individual bounty models can be used by several plans.' 
;


--The bounty calculation type code is a character code that identifies the type of a bounty calculation.  Available codes include (followed by their description): ACTV (on activation), SALE (on sale).
--The bounty dollar amount is the dollar amount of the bounty payment.
--The reserve indicator is an indicator of whether or not Accounting has created a reserve for this bounty payment.  If there is a reserve, bounty payments with chargebacks occurring within a specified period (i.e. 90 days) can be realized immediately.
--The chargeback percentage is the percentage of the bounty payment that a provider can charge back to Best Buy.
--The unique identifier of the management information systems program that was used to create the physical record.
--The date and time upon which the physical record is created.
--The identifier of the user that was responsible for initially creating & populating the record.
--The identifier of the information systems program that was used to update the record most recently.
--Timestamp of the last time the record was modified.
--The identifier of the user who was responsible for updating the record most recently.



----------------------------------------------
--Name	ESCTCAC
--Stereotype	Customer Account
--Comment	The customer account table holds all customer accounts setup in the ESC system.  Data specific to a customer account record include:

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TCAC ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 ESC_CUST_ACCT_ID    INTEGER	    --X	X	X
		,ESC_PLAN_ID         INTEGER		--    X	X
		,ESC_ACCT_STAT_TYP   VARCHAR(4)	--	X	X
		,CUST_ID             NUMERIC(18)		--	X
		,ESC_ACCT_ACTV_DT    DATE			--
		,ALL_ITEM_RTN_FLG    VARCHAR(1)	--		X
		,REC_CREATE_PGM_ID   VARCHAR(8)	--		X
		,REC_CREATE_TS       TIMESTAMP		--	X
		,REC_CREATE_USR_ID   VARCHAR(8)	--		X
		,REC_UPD_PGM_ID      VARCHAR(8)	--		X
		,REC_UPD_TS          TIMESTAMP		--	X
		,REC_UPD_USR_ID      VARCHAR(8)	--		X
		,ACCT_BAL_AMT        NUMERIC(9,2)	--		X
		,CUST_SIGNTR_ID      NUMERIC(9)		--	
		,ESC_CA_OFFLINE      VARCHAR(1)	--		X
		,AGGR_VNDR_ID        NUMERIC(9)		--	
		,AGGR_VNDR_SUBTYP    VARCHAR(3)	--		 
)
UNIQUE PRIMARY INDEX ESC_TCAC_PI (ESC_CUST_ACCT_ID)
INDEX (ESC_PLAN_ID ,ESC_ACCT_STAT_TYP ,REC_CREATE_TS ,AGGR_VNDR_ID)
INDEX (CUST_ID)
INDEX (AGGR_VNDR_ID ,AGGR_VNDR_SUBTYP)
INDEX (REC_UPD_TS)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCAC   IS 'customer account table holds all customer accounts setup in the ESC system.' 
;


--The customer account identifier is a surrogate key used to uniquely identify an ESC customer account.
--The subscription plan identifier is a surrogate key representing a unique subscription plan.  An example of a rate plan would be 'AT&T Digital PCS One Rate 600 Minutes'.
--The customer account status provides a workflow for the account.  Each code represents a step in the workflow of an account.  The account has two workflows, activation of an account and the cancellation of an account. The activation has the following cod
--The customer identifier is a surrogate key for the customer.  This identifier is used to uniquely identify a Best Buy customer.; Unique identifier of a customer.
--Account Activation Date
--All Items Returned Indicator
--The unique identifier of the management information systems program that was used to create the physical record.
--The date and time upon which the physical record is created.
--The identifier of the user that was responsible for initially creating & populating the record.
--The identifier of the information systems program that was used to update the record most recently.
--Timestamp of the last time the record was modified.
--The identifier of the user who was responsible for updating the record most recently.
--Customer Account Balance
--This is a foreign key and unique identifier for customer signature information.; The unique identifier of signature captured for a customer.
--A flag that tells if this was an offline transaction.
--Identifier of the vendor that is acting as an aggregator for a group of accounts.
--Subtype of the Aggregate Vendor.


----------------------------------------------
--Name	ESCTCAI
--Stereotype	Customer Account Transaction Item
--Comment	The account line item table acts as a transition table solving the many-to-many relationship between customer accounts and transaction line items. Data specific to an account line item record include:

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TCAI ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 ESC_CUST_ACCT_ID    INTEGER	    --X	X	X	
		,ESC_LN_SEQ          INTEGER	    --X	X	X	
		,ESC_LN_STAT_TYP     VARCHAR(4)	--	X	X	
		,REC_CREATE_TS       TIMESTAMP		--	X
		,REC_CREATE_PGM_ID   VARCHAR(8)	--		X
		,REC_CREATE_USR_ID   VARCHAR(8)	--		X
		,REC_UPD_PGM_ID      VARCHAR(8)	--		X
		,REC_UPD_USR_ID      VARCHAR(8)	--		X
		,REC_UPD_TS          TIMESTAMP		--	X
)
UNIQUE PRIMARY INDEX ESC_TCAI_PI (ESC_CUST_ACCT_ID ,ESC_LN_SEQ)
INDEX (ESC_LN_SEQ)
INDEX (REC_UPD_TS)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCAI   IS 'account line item table acts as a transition table solving the many-to-many relationship between customer accounts and transaction line items.' 
;

--The customer account identifier is a surrogate key used to uniquely identify an ESC customer account.
--The line item sequence number is a surrogate key used to uniquely identify a transaction line item.
--The line item status code is a four-character code that identifies the status of a specific transaction line item.  Available codes include (followed by their description): ACTV (Active) and INAC (Inactive).  When all line items for an account are inactive
--The date and time upon which the physical record is created.
--The unique identifier of the management information systems program that was used to create the physical record.
--The identifier of the user that was responsible for initially creating & populating the record.
--The identifier of the information systems program that was used to update the record most recently.
--The identifier of the user who was responsible for updating the record most recently.
--Timestamp of the last time the record was modified.


----------------------------------------------
--Name	ESCTCAT
--Stereotype	Commision Account Receivable Type
--Comment	The account receivable type table contains information pertaining to the type of information that an AR detail represents. Data specific to an account receivable type record include:

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TCAT ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 COMN_AR_TYP         VARCHAR(4)	    --X		X	
		,COMN_AR_TYP_NM      VARCHAR(30)		--	X	
		,OPR_SIGN_TYP        VARCHAR(1)		DEFAULT ' ' --	    X	' '
		,REC_CREATE_PGM_ID   VARCHAR(8)		--	    X	
		,REC_CREATE_TS       TIMESTAMP			--    X	
		,REC_CREATE_USR_ID   VARCHAR(8)		--	    X	
		,REC_UPD_PGM_ID      VARCHAR(8)		--	    X	
		,REC_UPD_USR_ID      VARCHAR(8)		--	    X	
		,REC_UPD_TS          TIMESTAMP			--    X	
		,COMN_AR_TYP_DESC    VARCHAR(256)		--	X	    
)
UNIQUE PRIMARY INDEX ESC_TCAT_PI (COMN_AR_TYP)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCAT   IS 'account receivable type table contains information pertaining to the type of information that an AR detail represents.' 
;


----------------------------------------------
--Name	ESCTCMD
--Stereotype	Commission Model
--Comment	The commission model table defines the commission models that can be used to calculate the appropriate account receivables for selling a provider's subscription service at Best Buy.  Individual commission models can be used by several plans. Data specific

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TCMD ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 COMN_MODL_ID            INTEGER	        --X		X	
		,COMN_MODL_TYP           VARCHAR(4)		--    X	X	
		,COMN_MODL_NM            VARCHAR(30)		--	X	
		,TIER_CNDR_TYP           VARCHAR(4)		--        X	  
		,TIER_PRD_TYP            VARCHAR(4)		--        X	  
		,TIER_CNDR_PRD_NBR       INTEGER			--        	
		,TIER_VAL_TYP            VARCHAR(4)		--        X	  
		,PYMT_TLRNC_AMT          NUMERIC(9,2)		DEFAULT 0   --	    X	0
		,REC_CREATE_PGM_ID       VARCHAR(8)		--	    X	
		,REC_CREATE_TS           TIMESTAMP			--    X	
		,REC_CREATE_USR_ID       VARCHAR(8)		--	    X	
		,REC_UPD_PGM_ID          VARCHAR(8)		--	    X	
		,REC_UPD_TS              TIMESTAMP			--    X	
		,REC_UPD_USR_ID          VARCHAR(8)		--	    X	
		,COMN_MODL_DESC          VARCHAR(256)		--	X	
		,COMN_POST_FLG           VARCHAR(1)		DEFAULT 'Y' --	    X	Y
)
UNIQUE PRIMARY INDEX ESC_TCMD_PI (COMN_MODL_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCMD   IS 'commission model table defines the commission models that can be used to calculate the appropriate account receivables for selling a providers subscription service at Best Buy. Individual commission models can be used by several plans.' 
;



----------------------------------------------
--Name	ESCTCPT
--Stereotype	Chargeback Period Type
--Comment	The chargeback period type table is a lookup table for describing each of the chargeback period types.  Examples of period types are Days, Weeks, Months, Quarters and Years.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TCPT ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 CHGBK_PRD_TYP       VARCHAR(4)	    --X		X	
		,CHGBK_PRD_TYP_NM    VARCHAR(30)		--	X	
		,REC_CREATE_PGM_ID   VARCHAR(8)		--	    X	
		,REC_CREATE_TS       TIMESTAMP			--    X	
		,REC_CREATE_USR_ID   VARCHAR(8)		--	    X	
		,REC_UPD_PGM_ID      VARCHAR(8)		--	    X	
		,REC_UPD_TS          TIMESTAMP			--    X	
		,REC_UPD_USR_ID      VARCHAR(8)		--	    X	
		,CHGBK_PRD_TYP_DESC  VARCHAR(256)		--	X	
)
UNIQUE PRIMARY INDEX ESC_TCPT_PI (CHGBK_PRD_TYP)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCPT   IS 'chargeback period type table is a lookup table for describing each of the chargeback period types. Examples of period types are Days, Weeks, Months, Quarters and Years.' 
;

----------------------------------------------
--Name	ESCTCSC
--Stereotype	Account Receivable Schedule
--Comment	The Schedule table is used for assigning a future date for processing customer accounts to determine account receivable revenue.  The table is used by both the scheduling batch process (schedules items for future posting) and the posting batch process (p

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TCSC ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 ESC_CUST_ACCT_ID        INTEGER	    --X	X	X	
		,COMN_MODL_ID            INTEGER	    --X	X	X	
		,PROC_STAT_TYP           VARCHAR(4)	--	X	X	
		,SCHD_TS                 TIMESTAMP		--		
		,REC_CREATE_PGM_ID       VARCHAR(8)	--		X	
		,REC_CREATE_TS           TIMESTAMP		--	X	
		,REC_CREATE_USR_ID       VARCHAR(8)	--		X	
		,REC_UPD_PGM_ID          VARCHAR(8)	--		X	
		,REC_UPD_TS              TIMESTAMP		--	X	
		,REC_UPD_USR_ID          VARCHAR(8)	--		X	
)
UNIQUE PRIMARY INDEX ESC_TCSC_PI (ESC_CUST_ACCT_ID ,COMN_MODL_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCSC   IS 'Schedule table is used for assigning a future date for processing customer accounts to determine account receivable revenue. The table is used by both the scheduling batch process (schedules items for future posting) and the posting batch process' 
;


----------------------------------------------
--Name	ESCTCSI
--Stereotype	Account Secondary Information
--Comment	Account Secondary information

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TCSI ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 ESC_CUST_ACCT_ID        NUMERIC	        --X		X	
		,INST_1ST_NM             VARCHAR(25)	--			
		,INST_MDL_INTL           VARCHAR(1)	--			
		,INST_LAST_NM            VARCHAR(25)	--			
		,INST_NM_PREFIX_TYP      VARCHAR(7)	--			
		,INST_NM_SUFFIX_TYP      VARCHAR(3)	--			
		,INST_ADDR_ST_NBR        VARCHAR(10)	--			
		,INST_ADDR_ST_NM         VARCHAR(30)	--			
		,INST_ADDR_UNIT_ID       VARCHAR(10)	--			
		,INST_ADDR_CITY_NM       VARCHAR(30)	--			
		,INST_STATE_ABBR         VARCHAR(5)	--			
		,INST_ADDR_ZIP           VARCHAR(7)	--			
		,INST_ADDR_ZIP4          VARCHAR(4)	--			
		,INST_CNTRY_ID           VARCHAR(2)	--			
		,INST_HOME_PH_AREA       VARCHAR(3)	--			
		,INST_HOME_PH_NBR        VARCHAR(7)	--			
		,CRCARD_ACCT_ID          RAW(32)		--		
		,CRCARD_EXP_YEAR         RAW(32)		--		
		,CRCARD_EXP_MNTH         RAW(32)		--		
		,CRCARD_1ST_NM           RAW(32)		--		
		,CRCARD_MDL_INTL         RAW(32)		--		
		,CRCARD_LAST_NM          RAW(32)		--		
		,REC_CREATE_PGM_ID       VARCHAR(8)	--		    X	
		,REC_CREATE_TS           TIMESTAMP (6)	--		X	
		,REC_CREATE_USR_ID       VARCHAR(8)	--		    X	
		,REC_UPD_PGM_ID          VARCHAR(8)	--		    X	
		,REC_UPD_TS              TIMESTAMP (6)	--		X	
		,REC_UPD_USR_ID          VARCHAR(8)	--		    X	
		,CRCARD_TYPE             RAW(16)		--        X		
		,EMAIL_ADDR_ID           VARCHAR(55)	--			
		,WORK_PH_AREA_NBR        VARCHAR(3)	--			
		,WORK_PH_NBR             VARCHAR(7)	--			
		,WORK_PH_EXT             VARCHAR(5)	--			
		,COMN_DEPT_TYP           VARCHAR(4)	DEFAULT 'DFLT'  --		    X	DFLT
		,CRCD_AUTH_ID            VARCHAR(16)	--			
		,CUST_RAC_USR_ID         VARCHAR(30)	--			
		,CUST_RAC_PSWD_TXT       VARCHAR(8)	--			
		,LANG_LCLE_ID            NUMERIC(10,0)	--	    X		
		,CVRD_SKU_ID             NUMERIC(7)		--		        
)
UNIQUE PRIMARY INDEX ESC_TCSI_PI (ESC_CUST_ACCT_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCSI   IS 'Account Secondary information' 
;


--ESC_CUST_ACCT_ID	The customer account identifier is a surrogate key used to uniquely identify an ESC customer account.
--INST_1ST_NM	The first name of the recipient at the physical installation location.
--INST_MDL_INTL	The middle initial of the recipient at the physical installation location.
--INST_LAST_NM	The last name of the recipient at the physical installation location.
--INST_NM_PREFIX_TYP	This is classification of the prefix used in the proper name of a customer.; A classification of prefix used in the name of a person.  Prefixes often indicate gender. Values are: Mr. Mrs. Ms
--INST_NM_SUFFIX_TYP	This is classification of the suffix used in the proper name of a customer.; A classification of suffixes used in the proper name of a person. Values are: JR SR 2nd 3rd
--INST_ADDR_ST_NBR	The street number where the physical installation will occur or reside.
--INST_ADDR_ST_NM	The street name where the physical installation will occur or reside.
--INST_ADDR_UNIT_ID	The unit id (apartment number, suite number, etc.)  where the physical installation will occur or reside.
--INST_ADDR_CITY_NM	The name of the city where the physical installation will occur or reside.
--INST_STATE_ABBR	The five character state abbreviation where the physical installation will occur or reside.
--INST_ADDR_ZIP	The zip code for the location where physical installation will occur or reside.
--INST_ADDR_ZIP4	The zip code suffix for the location where physical installation will occur or reside.
--INST_CNTRY_ID	The two character identifier for the country where the physical installation will occur or reside.
--INST_HOME_PH_AREA	The area code for the phone number where the physical installation will occur or reside.
--INST_HOME_PH_NBR	The phone number where the physical installation will occur or reside.
--CRCARD_ACCT_ID	The credit card account number.; The unique externally defined identifier of a credit card account.  The identifier is assigned by the bank and is unique within card type (such as Visa or Discover).  Most credit cards are only 16 digits long.  However, s
--CRCARD_EXP_YEAR	The year portion of the expiration date on the credit card.
--CRCARD_EXP_MNTH	The month portion of the expiration date on the credit card.
--CRCARD_1ST_NM	The first name of the name on the credit card.
--CRCARD_MDL_INTL	The middle initial of the name on the credit card.
--CRCARD_LAST_NM	The surname of the name on the credit card.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--CRCARD_TYPE	A one character code that tells what type of card (Visa, Mastercard, etc.) it is.  Sample values are:  A (American Express);  D (Discover);  M (Master Card);  V (Visa).
--EMAIL_ADDR_ID	The unique identifier of an electronic mail address.
--WORK_PH_AREA_NBR	The North American area code portion of a telephone number.
--WORK_PH_NBR	Phone number.
--WORK_PH_EXT	Phone extension number.
--COMN_DEPT_TYP	Unique identifier of a 'commission department' to which NPV revenue can be credited for the sale of a subscription.  The value of 'DFLT' indicates that the default department should be used.
--CRCD_AUTH_ID	The credit card provider authorization of this transaction
--CUST_RAC_USR_ID	The user identifier assigned via Remote Access Creation for the customer to an external partner's system.
--CUST_RAC_PSWD_TXT	The password text assigned via Remote Access Creation for the customer to an external partner's system.
--LANG_LCLE_ID	The identifier of a language spoken by a locale. The values are:
--   1033 - English
--   1036 - French 
-- 20490 - Spanish
--CVRD_SKU_ID	The identifier of the SKU that is being covered.

----------------------------------------------
--Name	ESCTCTP
--Stereotype	Commission Model Type
--Comment	The commission model type table is a lookup table for describing each of the commission model types.  Currently, the only two commission model types are bounties and residuals.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TCTP ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 COMN_MODL_TYP       VARCHAR(4)	    --X		X	
		,COMN_MODL_TYP_NM    VARCHAR(30)		--	X	
		,REC_CREATE_PGM_ID   VARCHAR(8)		--	    X	
		,REC_CREATE_TS       TIMESTAMP			--    X	
		,REC_CREATE_USR_ID   VARCHAR(8)		--	    X	
		,REC_UPD_PGM_ID      VARCHAR(8)		--	    X	
		,REC_UPD_TS          TIMESTAMP			--    X	
		,REC_UPD_USR_ID      VARCHAR(8)		--	    X	
		,COMN_MODL_TYP_DESC  VARCHAR(256)		--	X	
)
UNIQUE PRIMARY INDEX ESC_TCTP_PI (COMN_MODL_TYP)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCTP   IS 'commission model type table is a lookup table for describing each of the commission model types.  Currently, the only two commission model types are bounties and residuals.' 
;


--COMN_MODL_TYP	The commission model type code is a character code that identifies the type of a commission model.  Available codes include (followed by their description): BNTY (Bounty), RSDL (Residual).
--COMN_MODL_TYP_NM	The commission model type name is the name of a commission model type for purposes of displaying the commission model type on a GUI.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--COMN_MODL_TYP_DESC	The commission model type description is the textual description of the character commission model type code.


----------------------------------------------
--Name	ESCTDVP
--Stereotype	Default Vendor Plan
--Comment	Default Vendor Plan table

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TDVP ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 SKU_PKG_GRP_ID      INTEGER	    --X	X	X	
		,VNDR_ID             NUMERIC(9)	    --X		X	
		,VNDR_SUBTYP         VARCHAR(3)	--X		X	
		,SKU_ID              NUMERIC(7)		--	X	
		,REC_CREATE_TS       TIMESTAMP		--	X	
		,REC_UPD_TS          TIMESTAMP		--	X	
		,REC_CREATE_PGM_ID   VARCHAR(8)	--		X	
		,REC_CREATE_USR_ID   VARCHAR(8)	--		X	
		,REC_UPD_USR_ID      VARCHAR(8)	--		X	
		,REC_UPD_PGM_ID      VARCHAR(8)	--		X	
)
UNIQUE PRIMARY INDEX ESC_TDVP_PI ( SKU_PKG_GRP_ID ,VNDR_ID      ,VNDR_SUBTYP )
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TDVP   IS 'Default Vendor Plan table' 
;

--SKU_PKG_GRP_ID	The SKU package group identifier uniquely identifies a group of SKU packages.; Number assigned to uniquely identify a sku package group within a package.  Sku package groups are groups of skus created for sku value packages and sku bundles.
--VNDR_ID	The unique identifier of a vendor.  The vendor ID is derived from the following: (VNDR_NBR+DEPT_ID+CHK_DIGIT_NBR). The check digit number is calculated from the following formula:  1. (N1 + 2N2 + N3 + 2N4 + N5 + 2N6 + N7 + 2N8)/ 10 2. 10 - mod = check digit
--VNDR_SUBTYP	Vendor Subtype; A classification of vendors by the nature of the service or product the vendor provides to Best Buy. Values are:    100 - AP Music    100 - AP Merchandise    200 - AP Expense, Employee    300 - AP Expense, E-Commerce (future)    500 - AP Expense
--SKU_ID	Unique Stock Keeping Unit assigned by Best Buy. The SKU identifier is a foreign key from the SKU table.; The unique identifier of a stock keeping unit of Best Buy Co.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.


----------------------------------------------
--Name	ESCTEGT
--Stereotype	Sales Integration
--Comment	Sales Integration table

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TEGT ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 TRANS_AUDIT_ID              INTEGER	    --X		X	
		,SLS_TRANS_NBR               NUMERIC(5)		--	X	
		,REGSTR_NBR                  NUMERIC(3)		--	X	
		,SLS_TRANS_TS                TIMESTAMP		--	X	
		,LOC_ID                      NUMERIC(5)		--	X	
		,AUDIT_TYP                   VARCHAR(4)	--		X	
		,REC_CREATE_PGM_ID           VARCHAR(8)	--		X	
		,REC_CREATE_TS               TIMESTAMP		--	X	
		,REC_CREATE_USR_ID           VARCHAR(8)	--		X	
		,REC_UPD_PGM_ID              VARCHAR(8)	--		X	
		,REC_UPD_TS                  TIMESTAMP		--	X	
		,REC_UPD_USR_ID              VARCHAR(8)	--		X	
		,COMN_AR_TYP                 VARCHAR(4)	--			
		,POST_SKU_ID                 NUMERIC(7)		--		
		,SALE_AMT                    NUMERIC(9,2)	--			
		,GL_CD                       VARCHAR(6)	--	    X		
		,SALE_POST_TS                TIMESTAMP		--		
		,SLS_ADT_PCSD_STAT_TYP       VARCHAR(4)	DEFAULT 'LDED'  --		X	'LDED'
		,SLS_ADT_PRCS_MC_NM          VARCHAR(10)	--			    
)
UNIQUE PRIMARY INDEX ESC_TEGT_PI (TRANS_AUDIT_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TEGT   IS 'Sales Integration table' 
;

--TRANS_AUDIT_ID	
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.SLS_TRANS_NBR	        is 'The unique number of a sales transaction.  This number is unique within a particular date, register, and location.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.REGSTR_NBR	        is 'The unique identifier of a point-of-sale register within a Best Buy location.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.SLS_TRANS_TS	        is 'The transaction timestamp is the date and time that a Best Buy transaction occurred.; The date and time of the sales transaction.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.LOC_ID	            is 'The internally assigned unique identifier of a location within Best Buy Retail.  A location can either be a store, warehouse, service center, distribution center or defective center.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.AUDIT_TYP	            is ''
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.REC_CREATE_PGM_ID	    is 'The unique identifier of the management information systems program that was used to create the physical record.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.REC_CREATE_TS	        is 'The date and time upon which the physical record is created.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.REC_CREATE_USR_ID	    is 'The identifier of the user that was responsible for initially creating & populating the record.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.REC_UPD_PGM_ID	    is 'The identifier of the information systems program that was used to update the record most recently.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.REC_UPD_TS	        is 'Timestamp of the last time the record was modified.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.REC_UPD_USR_ID	    is 'The identifier of the user who was responsible for updating the record most recently.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.COMN_AR_TYP	        is 'The account receivable type code is a four-character code that identifies the type of an account receivable.  Available codes include: RECV (Receivable), PYMT (Payment), CHBK (Chargeback), RETN (Return), TADJ (Tier Adjustment)'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.POST_SKU_ID	        is 'Identifier of the SKU to which the revenue is posted.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.SALE_AMT	            is 'Total amount of the sale to be posted.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.GL_CD	GL_CD is        is 'the General Ledger account code against which the ESC revenue is posted.  e.g, for wireless plans, it is 'CELL', for DirecTV it is DBS etc.  This code is a foreign key to the ESC_TGLC table.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.SALE_POST_TS	        is 'Date and time that the message / transaction is posted.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.SLS_ADT_PCSD_STAT_TYP	It will be PCSD if  the Record is sent to STH else it will be LDED. Once the record is Picked for processing, it would be PSNG until it is processed.'
--Comment on DEVBBYMEADHOCDB.ESC_TEGT.SLS_ADT_PRCS_MC_NM	is 'This holds the Hostname of the machine which will process the record.'


----------------------------------------------
--Name	ESCTFAT
--Stereotype	File Activity Type
--Comment	Activity type describing the type of communications being submitted to vendors.  These are communications related to subscription services plans.  Activity types include Cancellation, Activation, Activation Intent, Cancellation Intent, Payment, and Charge

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TFAT ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 FILE_ACTVTY_TYP         VARCHAR(4)	    --X		X	
		,FILE_ACTVTY_TYP_NM      VARCHAR(30)		--	X	
		,REC_CREATE_PGM_ID       VARCHAR(8)		--	    X	
		,REC_CREATE_TS           TIMESTAMP			--    X	
		,REC_CREATE_USR_ID       VARCHAR(8)		--	    X	
		,REC_UPD_PGM_ID          VARCHAR(8)		--	    X	
		,REC_UPD_TS              TIMESTAMP			--    X	
		,REC_UPD_USR_ID          VARCHAR(8)		--	    X	
		,FILE_ACTVTY_DESC        VARCHAR(256)		--	X	
		,JAVA_CLASS_NM           VARCHAR(256)		--		
		,FILE_TYP_HOLD_FLG       VARCHAR(1)		DEFAULT 'N' --	    X	N
)
UNIQUE PRIMARY INDEX ESC_TFAT_PI (FILE_ACTVTY_TYP)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TFAT   IS 'File Activity type describing the type of communications being submitted to vendors. These are communications related to subscription service plans. Activity types include Cancellation,Activation,Activation Intent,Cancellation Intent, Payment, and Charge' 
;



--FILE_ACTVTY_TYP	Code that identifies Subscription Services file Activity Type.
--FILE_ACTVTY_TYP_NM	Name of the Subscriptions Services file Activity Type.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--FILE_ACTVTY_DESC	Description of the Subscription Services Activity Type.
--JAVA_CLASS_NM	Contains the processor implementation java class name for a file type.
--FILE_TYP_HOLD_FLG	Flag to indicate whether a file type is enabled for holding.




----------------------------------------------
--Name	ESCTKPG
--Stereotype	SKU Package Group
--Comment	The package group table identifies a group of SKU packages.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TKPG ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 SKU_PKG_GRP_ID          INTEGER	        --X		X	
		,SKU_PKG_GRP_NM          VARCHAR(30)		--	X	
		,PROVDR_REQD_FLG         VARCHAR(1)		--	    X	
		,SKU_PKG_ID              INTEGER		    --    X	X	
		,REC_CREATE_TS           TIMESTAMP			--    X	
		,REC_UPD_TS              TIMESTAMP			--    X	
		,REC_UPD_USR_ID          VARCHAR(8)		--	    X	
		,REC_UPD_PGM_ID          VARCHAR(8)		--	    X	
		,REC_CREATE_USR_ID       VARCHAR(8)		--	    X	
		,REC_CREATE_PGM_ID       VARCHAR(8)		--	    X	
		,SKU_PKG_GRP_DESC        VARCHAR(256)		--	X	
		,SNGL_INSTL_REQ_FLG      VARCHAR(1)		DEFAULT 'N' --	    X	N
)
UNIQUE PRIMARY INDEX ESC_TKPG_PI (SKU_PKG_GRP_ID)
INDEX (SKU_PKG_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TKPG   IS 'SKU package group table identifies a group of SKU packages.' 
;


--SKU_PKG_GRP_ID	The SKU package group identifier uniquely identifies a group of SKU packages.; Number assigned to uniquely identify a sku package group within a package.  Sku package groups are groups of skus created for sku value packages and sku bundles.
--SKU_PKG_GRP_NM	The SKU package group name is the name of a SKU package group for purposes of displaying the SKU package group on a GUI.
--PROVDR_REQD_FLG	Provider Required Indicator; Indicates whether the provider must be chosen as part of the plan setup.  If the provider is not required, then the 'no plan' option must be available from the interface.   Values:  'N' = provider not required            
--SKU_PKG_ID	The SKU package identifier uniquely identifies a package of SKUs.; Identifier assigned to uniquely identify a Sku package
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--SKU_PKG_GRP_DESC	The SKU package group description is a brief description of the package group.  It helps to identify the package group from a maintenance application.
--SNGL_INSTL_REQ_FLG	A flag that indicates whether this package group requires the single installation option.


----------------------------------------------
--Name	ESCTLIA
--Stereotype	Line Item Attribute
--Comment	The line item attribute table acts as a transition table solving the many-to-many relationship between transaction line items and line item attributes.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TLIA ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 ESC_LN_SEQ          INTEGER	        --X	X	X
		,ATRIB_NM            VARCHAR(10)	    --X		X
		,ESC_ATRIB_VAL       VARCHAR(100)	    --		X
		,REC_CREATE_TS       TIMESTAMP		    --	    X
		,REC_UPD_TS          TIMESTAMP		    --	    X
		,REC_UPD_USR_ID      VARCHAR(8)		--	    X
		,REC_UPD_PGM_ID      VARCHAR(8)		--	    X
		,REC_CREATE_USR_ID   VARCHAR(8)		--	    X
		,REC_CREATE_PGM_ID   VARCHAR(8)		--	    X
)
UNIQUE PRIMARY INDEX ESC_TLIA_PI (ESC_LN_SEQ,ATRIB_NM)
INDEX (ESC_ATRIB_VAL)
INDEX (ATRIB_NM)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TLIA   IS 'line item attribute table acts as a transition table solving the many-to-many relationship between transaction line items and line item attributes.' 
;

--ESC_LN_SEQ	The line item sequence number is a surrogate key used to uniquely identify a transaction line item.
--ATRIB_NM	The attribute name is the unique name used to identify an attribute.
--ESC_ATRIB_VAL	The attribute value text is the value of the unique attribute associated with subscription service sale.  Examples include the ESN number on cell phones and the serial numbers and access card numbers on DirecTV receivers.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.


----------------------------------------------
--Name	ESCTLNI
--Stereotype	Line Item
--Comment	The line item table represents specific line items on a transaction that are associated with subscription service sales (SKUs).   This is a surrogate definition of a line item, not necessarily the physical line item on a transaction.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TLNI ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 ESC_LN_SEQ              INTEGER	    --X		X	
		,ESC_LN_SKU_ID           NUMERIC(7)		--	    X	
		,REC_CREATE_PGM_ID       VARCHAR(8)	--		X	
		,REC_CREATE_TS           TIMESTAMP		--	    X	
		,REC_CREATE_USR_ID       VARCHAR(8)	--		X	
		,REC_UPD_PGM_ID          VARCHAR(8)	--		X	
		,REC_UPD_TS              TIMESTAMP		--	    X	
		,REC_UPD_USR_ID          VARCHAR(8)	--		X	
		,ORIG_SLS_TRANS_NBR      NUMERIC(5)		--	    X	
		,ORIG_LOC_ID             NUMERIC(5)		--	    X	
		,ORIG_REGSTR_NBR         NUMERIC(3)		--	    X	
		,ORIG_SLS_TRANS_TS       TIMESTAMP		--	    X	
		,SLS_TRANS_LN_AMT        NUMERIC(9,2)	DEFAULT 0   --		X	0
)
UNIQUE PRIMARY INDEX ESC_TLNI_PI (ESC_LN_SEQ)
INDEX (ORIG_LOC_ID ,ORIG_SLS_TRANS_NBR ,ORIG_REGSTR_NBR ,ORIG_SLS_TRANS_TS)
INDEX (ESC_LN_SKU_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TLNI   IS 'line item table represents specific line items on a transaction that are associated with subscription service sales (SKUs). This is a surrogate definition of a line item, not necessarily the physical line item on a transaction.' 
;


--ESC_LN_SEQ	The line item sequence number is a surrogate key used to uniquely identify a transaction line item.
--ESC_LN_SKU_ID	The line item SKU identifier is a foreign key from the SKU table (SKUTSKU).
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--ORIG_SLS_TRANS_NBR	The original transaction identifier is the original Best Buy transaction ID at the time of sale.
--ORIG_LOC_ID	For Return transactions, it is the location at which the initial sale transaction occurred.; The internally assigned unique identifier of a location within Best Buy Retail.  A location can either be a store, warehouse, service center, distribution center
--ORIG_REGSTR_NBR	The original register number is the Best Buy register number at the time of sale.
--ORIG_SLS_TRANS_TS	For Return transactions, it is the timestamp (date and time) of the initial sales transaction.; The date and time of the sales transaction.
--SLS_TRANS_LN_AMT	Dollar amount associated with the sales transaction line.  For ESC transactions, the quantity / line is always = 1.  Hence, it will also equal the price per unit. Note:  When adding this column to the table (10/02), it was decided to not populate the his



----------------------------------------------
--Name	ESCTPAD
--Stereotype	Inbound CSV File Setup
--Comment	Inbound CSV File setup table

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TPAD ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 VNDR_PRFL_ID            INTEGER	    --X	X	X	
		,XML_DOC_ID              INTEGER	    --X		X	
		,FILE_ACTVTY_TYP         VARCHAR(4)	--X	X	X	
		,REC_CREATE_PGM_ID       VARCHAR(8)	--		X	
		,REC_CREATE_TS           TIMESTAMP		--	X	
		,REC_CREATE_USR_ID       VARCHAR(8)	--		X	
)
UNIQUE PRIMARY INDEX ESC_TPAD_PI ( VNDR_PRFL_ID ,XML_DOC_ID ,FILE_ACTVTY_TYP)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPAD   IS 'Inbound CSV File setup table' 
;

--VNDR_PRFL_ID	The unique identifier for one profile for a vendor.
--XML_DOC_ID	ID to uniquely identify the XML Document.
--FILE_ACTVTY_TYP	Code that identifies Subscription Services file Activity Type.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.

----------------------------------------------
--Name	ESCTPAK
--Stereotype	Plan SKU
--Comment	The Plan SKU table acts as a transition table solving the many-to-many relationship between subscription plans and activation SKUs.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TPAK ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 SKU_ID                  NUMERIC(7)	    --X		X	
		,ESC_PLAN_ID             INTEGER	    --X	X	X	
		,REC_CREATE_TS           TIMESTAMP		--	    X	
		,REC_CREATE_USR_ID       VARCHAR(8)	--		X	
		,REC_CREATE_PGM_ID       VARCHAR(8)	--		X	
)
UNIQUE PRIMARY INDEX ESC_TPAK_PI (SKU_ID ,ESC_PLAN_ID)
INDEX (ESC_PLAN_ID ,SKU_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPAK   IS 'Plan SKU table acts as a transition table solving the many-to-many relationship between subscription plans and activation SKUs.' 
;

--SKU_ID	Unique Stock Keeping Unit assigned by Best Buy. The SKU identifier is a foreign key from the SKU table.; The unique identifier of a stock keeping unit of Best Buy Co.
--ESC_PLAN_ID	The subscription plan identifier is a surrogate key representing a unique subscription plan.  An example of a rate plan would be 'AT&T Digital PCS One Rate 600 Minutes'.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.



----------------------------------------------
--Name	ESCTPKG
--Stereotype	SKU Package
--Comment	The SKU package table identifies an assembly of  SKUs for related items that can be sold together as a package.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TPKG ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 SKU_PKG_ID          INTEGER	        --X		X	
		,SKU_PKG_NM          VARCHAR(30)		--	X	
		,PKG_OWNR_TYP        VARCHAR(4)		--    X	X	
		,SKU_PKG_BEG_DT      TIMESTAMP			--    X	
		,SKU_PKG_END_DT      TIMESTAMP			--    X	
		,ESC_GRP_TYP         VARCHAR(4)		--	    X	
		,REC_CREATE_TS       TIMESTAMP			--    X	
		,REC_UPD_TS          TIMESTAMP			--    X	
		,REC_UPD_USR_ID      VARCHAR(8)		--	    X	
		,REC_UPD_PGM_ID      VARCHAR(8)		--	    X	
		,REC_CREATE_USR_ID   VARCHAR(8)		--	    X	
		,REC_CREATE_PGM_ID   VARCHAR(8)		--	    X	
		,SKU_PKG_DESC        VARCHAR(256)		--	X	
		,SKU_PKG_TYP         VARCHAR(4)		DEFAULT 'STND'  --    X	X	STND
)
UNIQUE PRIMARY INDEX ESC_TPKG_PI (SKU_PKG_ID)
INDEX (SKU_PKG_TYP)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPKG   IS 'SKU package table identifies an assembly of  SKUs for related items that can be sold together as a package.' 
;

--SKU_PKG_ID	The SKU package identifier uniquely identifies a package of SKUs.; Identifier assigned to uniquely identify a Sku package
--SKU_PKG_NM	The SKU package name is the name of a SKU package for purposes of displaying the SKU package on a GUI.; Sku Package name.
--PKG_OWNR_TYP	The package owner type code is a character code that identifies the type of a package owner. Packages can be owned by the ESC system or by other systems. The package owner determines what can be changed in the package.  Available codes include (followedb
--SKU_PKG_BEG_DT	The SKU package start date is the beginning date for the SKU package.
--SKU_PKG_END_DT	The SKU package end date is the ending date for the SKU package.
--ESC_GRP_TYP	The ESC group type code is a character code specifying the ESC group type.  Available codes include (with their associated description): CELL (Cellular), DSS (DBS Systems), ISP (ISP).
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--SKU_PKG_DESC	The SKU package description is a brief description of the package.  It helps to identify the package from a maintenance application.; Description of Sku package.
--SKU_PKG_TYP	The indication if the SKU package is a sku bundle or a SKU package.  Values: STND = Standard Package (Default) BNDL = Bundle Package


----------------------------------------------
--Name	ESCTPKP
--Stereotype	Primary SKU
--Comment	The primary SKU table identifies primary SKUs.  For the ESC system, these are hardware SKUs (cell phone, DBS receiver, set top box).

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TPKP ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 SKU_PKG_ID          INTEGER	    --X	X	X	
		,SKU_ID              NUMERIC(7)	    --X		X	
		,REC_CREATE_TS       TIMESTAMP		--    	X	
		,REC_CREATE_USR_ID   VARCHAR(8)	--		X	
		,REC_CREATE_PGM_ID   VARCHAR(8)	--		X	
)
UNIQUE PRIMARY INDEX ESC_TPKP_PI (SKU_PKG_ID, SKU_ID)
INDEX (SKU_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPKP   IS 'primary SKU table identifies primary SKUs. For the ESC system, these are hardware SKUs (cell phone, DBS receiver, set top box).' 
;

--SKU_PKG_ID	The SKU package identifier uniquely identifies a package of SKUs.; Identifier assigned to uniquely identify a Sku package
--SKU_ID	Unique Stock Keeping Unit assigned by Best Buy. The SKU identifier is a foreign key from the SKU table.; The unique identifier of a stock keeping unit of Best Buy Co.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.


----------------------------------------------
--Name	ESCTPKT
--Stereotype	Package Type
--Comment	Package type table

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TPKT ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 SKU_PKG_TYP         VARCHAR(4)	    --X		X	
		,SKU_PKG_TYP_NM      VARCHAR(30)		--	    X	
		,SKU_PKG_TYP_DESC    VARCHAR(256)		--	    X	
		,REC_CREATE_TS       TIMESTAMP			DEFAULT CURRENT_TIMESTAMP   --        X	SYSDATE
		,REC_CREATE_USR_ID   VARCHAR(8)		--	    X	
		,REC_CREATE_PGM_ID   VARCHAR(8)		--	    X	        
)
UNIQUE PRIMARY INDEX ESC_TPKT_PI (SKU_PKG_TYP)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPKT   IS '' 
;

--SKU_PKG_TYP	The indication if the SKU package is a sku bundle or a SKU package.  Values: STND = Standard Package (Default) BNDL = Bundle Package
--SKU_PKG_TYP_NM	
--SKU_PKG_TYP_DESC	The character representation used to name a SKU package type.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.


----------------------------------------------
--Name	ESCTPLC
--Stereotype	Plan Commission
--Comment	The plan commission table acts as a transition table solving the many-to-many relationship between subscription plans and commission models.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TPLC ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 ESC_PLAN_ID             INTEGER	    --X	X	X
		,COMN_MODL_ID            INTEGER	    --X	X	X
		,PLAN_COMN_BEG_TS        TIMESTAMP		--	    X
		,PLAN_COMN_END_TS        TIMESTAMP		--	    X
		,REC_CREATE_TS           TIMESTAMP		--	    X
		,REC_UPD_TS              TIMESTAMP		--	    X
		,REC_CREATE_PGM_ID       VARCHAR(8)	--		X
		,REC_CREATE_USR_ID       VARCHAR(8)	--		X
		,REC_UPD_PGM_ID          VARCHAR(8)	--		X
		,REC_UPD_USR_ID          VARCHAR(8)	--		X
		,SKU_ID                  NUMERIC(7)		--	
)
UNIQUE PRIMARY INDEX ESC_TPLC_PI (ESC_PLAN_ID, COMN_MODL_ID)
INDEX (COMN_MODL_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPLC   IS 'plan commission table acts as a transition table solving the many-to-many relationship between subscription plans and commission models.' 
;

--ESC_PLAN_ID	The subscription plan identifier is a surrogate key representing a unique subscription plan.  An example of a rate plan would be 'AT&T Digital PCS One Rate 600 Minutes'.
--COMN_MODL_ID	The commission model identifier is a surrogate key used to uniquely identify a commission model.
--PLAN_COMN_BEG_TS	The plan commission start date is the first date that a specific subscription plan will have a specific commission model.
--PLAN_COMN_END_TS	The plan commission end date is the last date that a specific subscription plan will have a specific commission model.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--SKU_ID	SKU Identifier; The unique identifier of a stock keeping unit of Best Buy Co.


----------------------------------------------
--Name	ESCTPLN
--Stereotype	Subscription Plan
--Comment	The subscription plan table defines the different plans that service providers offer. Plans are specific to a particular vendor such that AT&T's 600 minute cellular plan is different from Sprint's 600 minute cellular plan.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TPLN ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 ESC_PLAN_ID             INTEGER	        --X		X	
		,VNDR_ID                 NUMERIC(9)			--    X	
		,VNDR_SUBTYP             VARCHAR(3)		--	    X	
		,ESC_PLAN_NM             VARCHAR(30)		--	X	
		,PLAN_ACTV_FLG           VARCHAR(1)		DEFAULT 'N' --	    X	N
		,MULT_PRIM_SKU_FLG       VARCHAR(1)		--	    X	
		,ESC_GRP_TYP             VARCHAR(4)		--	    X	
		,VNDR_PLAN_ID            VARCHAR(30)		--	X	
		,REC_CREATE_TS           TIMESTAMP			--    X	
		,REC_UPD_TS              TIMESTAMP			--    X	
		,REC_UPD_USR_ID          VARCHAR(8)		--	    X	
		,REC_UPD_PGM_ID          VARCHAR(8)		--	    X	
		,REC_CREATE_USR_ID       VARCHAR(8)		--	    X	
		,REC_CREATE_PGM_ID       VARCHAR(8)		--	    X	
		,ESC_PLAN_DESC           VARCHAR(256)		--		
		,ESC_PLAN_XPTN_TYP       VARCHAR(4)		DEFAULT 'EXCL'  --    X	X	EXCL
		,CUST_PLAN_XPTN_TYP      VARCHAR(4)		DEFAULT 'ALL'   --	    X	ALL
		,ESC_PLAN_NRTC_FLG       VARCHAR(1)		DEFAULT 'N'     --	    X	N
		,AVAIL_OFFLN_FLG         VARCHAR(1)		DEFAULT 'Y'     --	    X	Y
		,SEC_VNDR_PLAN_ID        VARCHAR(50)		--		    
)
UNIQUE PRIMARY INDEX ESC_TPLN_PI (ESC_PLAN_ID)
INDEX (VNDR_ID,VNDR_SUBTYP)
INDEX (ESC_GRP_TYP)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPLN   IS 'subscription plan table defines the different plans that service providers offer. Plans are specific to a particular vendor such that AT&Ts 600 minute cellular plan is different from Sprints 600 minute cellular plan.' 
;

--ESC_PLAN_ID	The subscription plan identifier is a surrogate key representing a unique subscription plan.  An example of a rate plan would be 'AT&T Digital PCS One Rate 600 Minutes'.
--VNDR_ID	The unique identifier of a vendor.  The vendor ID is derived from the following: (VNDR_NBR+DEPT_ID+CHK_DIGIT_NBR). The check digit number is calculated from the following formula:  1. (N1 + 2N2 + N3 + 2N4 + N5 + 2N6 + N7 + 2N8)/ 10 2. 10 - mod = check digit
--VNDR_SUBTYP	Vendor Subtype; A classification of vendors by the nature of the service or product the vendor provides to Best Buy. Values are:    100 - AP Music    100 - AP Merchandise    200 - AP Expense, Employee    300 - AP Expense, E-Commerce (future)    500 - AP Expense
--ESC_PLAN_NM	The subscription plan name is the name of a subscription plan for purposes of displaying the subscription plan on a GUI.; Short description of Electronic Subscription Capture plan.
--PLAN_ACTV_FLG	Plan Active Flag
--MULT_PRIM_SKU_FLG	The multiple primary SKU indicator indicates whether a plan has multiple primary SKUs.
--ESC_GRP_TYP	The ESC group type code is a character code specifying the ESC group type.  Available codes include (with their associated description): CELL (Cellular), DSS (DBS Systems), ISP (ISP).
--VNDR_PLAN_ID	The unique identifier for one profile for a vendor.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--ESC_PLAN_DESC	The subscription plan description used for clarifying the subscription plan.  The description should be detailed enough to differentiate plans.; Text description of Electronic Subscription Capture plan.
--ESC_PLAN_XPTN_TYP	The indication if the SKU plan exception is an exclusion of locations or an inclusion.  Values: EXCL = Exclusion (Default) INCL = Inclusion
--CUST_PLAN_XPTN_TYP	
--ESC_PLAN_NRTC_FLG	
--AVAIL_OFFLN_FLG	A flag that indicates whether this plan is available to offline processing.
--SEC_VNDR_PLAN_ID	The unique identifier for a secondary profile for a vendor or secondary component that uniquely identifies this plan for use by the external vendor.



----------------------------------------------
--Name	ESCTRMD
--Stereotype	Residual Model
--Comment	The residual model table defines the commission models that can be used to calculate residual account receivables for selling a provider's subscription service at Best Buy.  Individual residual models can be used by several plans.
--
CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TRMD ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 COMN_MODL_ID        INTEGER	    --X	X	X	
		,RESID_OFFSET_TYP    VARCHAR(4)	--	X	X	
		,RESID_PRD_TYP       VARCHAR(4)	--	X	X	
		,RESID_CALC_TYP      VARCHAR(4)	--	X	X	
		,LIFE_TM_RESID_FLG   VARCHAR(1)	--		X	
		,MAX_RESID_PMNT_NBR  INTEGER		--	    X	
		,RESID_PRD_NBR       INTEGER		--	    X	
		,RESID_OFFSET_NBR    INTEGER		--	    X	
		,RESID_PYMT_DLR_AMT  NUMERIC(9,2)	--		X	
		,RESID_PYMT_PCT      NUMERIC(5,2)	--		X	
		,DFLT_PYMT_DLR_AMT   NUMERIC(9,2)	--		X	
		,REC_CREATE_PGM_ID   VARCHAR(8)	--		X	
		,REC_CREATE_TS       TIMESTAMP		--	X	
		,REC_CREATE_USR_ID   VARCHAR(8)	--		X	
		,REC_UPD_PGM_ID      VARCHAR(8)	--		X	
		,REC_UPD_TS          TIMESTAMP		--	X	
		,REC_UPD_USR_ID      VARCHAR(8)	--		X	
)
UNIQUE PRIMARY INDEX ESC_TRMD_PI (COMN_MODL_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TRMD   IS 'residual model table defines the commission models that can be used to calculate residual account receivables for selling a providers subscription service at Best Buy.  Individual residual models can be used by several plans.' 
;

--COMN_MODL_ID	The commission model identifier is a surrogate key used to uniquely identify a commission model.
--RESID_OFFSET_TYP	The residual offset period type code is a character code that identifies the type of an offset period for residuals.  Available codes include (followed by their description): DY (Day), WK (Week), MO (Month), QR (Quarter), and YR (Year).
--RESID_PRD_TYP	The residual period type code is a character code that identifies the type of a period for residuals.  Available codes include (followed by their description): DY (Day), WK (Week), MO (Month), QR (Quarter), and YR (Year).
--RESID_CALC_TYP	The residual calculation type code is a character code that identifies the type of a residual recognition.  Available codes include (followed by their description): UNSD (Unit sold), UNAC (Unit activated), PBILL (Percent of bill), PLN (Percent of plan am
--LIFE_TM_RESID_FLG	The activation lifetime residual indicator indicates whether or not a residual model is paid forever (until the customer cancels their subscription account).
--MAX_RESID_PMNT_NBR	The maximum payment number is the maximum number of payments that can be received for a residual.  For example Best Buy may receive monthly payments for only one year (12 payments).
--RESID_PRD_NBR	The residual period number is the number of 'period types' in a period for the periodic residual payment.  For example if Best Buy receives a monthly payment, the number of period types (months) in the period would be 1.
--RESID_OFFSET_NBR	The residual offset period number is the number of 'offset period types' from the sale date that we can start recognizing the first residual.
--RESID_PYMT_DLR_AMT	The residual dollar amount is the dollar amount of the residual payment (for per unit sold and per unit activated flat payment residuals).
--RESID_PYMT_PCT	The residual percentage is the percentage used in calculating account receivable dollars when the residual recognition type uses a percentage.
--DFLT_PYMT_DLR_AMT	The default percentage dollar amount is the default dollar amount used to calculate percentage account receivables when the actual dollar amount has not yet been indicated by the provider.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--



----------------------------------------------
--Name	ESCTSKP
--Stereotype	Secondary SKU
--Comment	The secondary SKU table identifies Secondary SKUs.  For the ESC system, these are subscription activation SKUs.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TSKP ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 SKU_PKG_GRP_ID      INTEGER	    --X	X	X	
		,SKU_ID              NUMERIC(7)	    --X		X	
		,REC_CREATE_TS       TIMESTAMP		--	X	
		,REC_CREATE_USR_ID   VARCHAR(8)	--		X	
		,REC_CREATE_PGM_ID   VARCHAR(8)	--		X	
)
UNIQUE PRIMARY INDEX ESC_TSKP_PI (SKU_PKG_GRP_ID, SKU_ID)
INDEX (SKU_ID,SKU_PKG_GRP_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TSKP   IS 'secondary SKU table identifies Secondary SKUs. For the ESC system, these are subscription activation SKUs.' 
;

--SKU_PKG_GRP_ID	The SKU package group identifier uniquely identifies a group of SKU packages.; Number assigned to uniquely identify a sku package group within a package.  Sku package groups are groups of skus created for sku value packages and sku bundles.
--SKU_ID	Unique Stock Keeping Unit assigned by Best Buy. The SKU identifier is a foreign key from the SKU table.; The unique identifier of a stock keeping unit of Best Buy Co.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.



----------------------------------------------
--Name	ESCTSLT
--Stereotype	Sale Transaction
--Comment	The Transaction Header table identifies transactions that contain subscription service items. Data specific to a line item attribute record include:

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TSLT ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 SLS_TRANS_NBR       NUMERIC(5)	    --X		X	
		,REGSTR_NBR          NUMERIC(3)	    --X		X	
		,SLS_TRANS_TS        TIMESTAMP	    --X		X	
		,LOC_ID              NUMERIC(5)	    --X		X	
		,ESC_TRANS_SRC_TYP   VARCHAR(4)	--	X	X	
		,ESC_TRANS_VOID_FLG  VARCHAR(1)	--		X	
		,REC_CREATE_TS       TIMESTAMP		--    	X	
		,REC_UPD_TS          TIMESTAMP		--    	X	
		,REC_UPD_USR_ID      VARCHAR(8)	--		X	
		,REC_UPD_PGM_ID      VARCHAR(8)	--		X	
		,REC_CREATE_USR_ID   VARCHAR(8)	--		X	
		,REC_CREATE_PGM_ID   VARCHAR(8)	--		X	
)
UNIQUE PRIMARY INDEX ESC_TSLT_PI ( SLS_TRANS_NBR ,REGSTR_NBR  ,SLS_TRANS_TS ,LOC_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TSLT   IS 'Transaction Header table identifies transactions that contain subscription service items.' 
;


--SLS_TRANS_NBR	The transaction identifier is the Best Buy transaction ID at the time of sale.; The unique number of a sales transaction.  This number is unique within a particular date, register, and location.
--REGSTR_NBR	The unique identifier of a point-of-sale register within a Best Buy location.
--SLS_TRANS_TS	The transaction timestamp is the date and time that a Best Buy transaction occurred.; The date and time of the sales transaction.
--LOC_ID	The location identifier is a unique identifier of a Best Buy location.  Locations include stores, warehouses, etc. The location identifier is a foreign key from the Best Buy location table.; The internally assigned unique identifier of a location within 
--ESC_TRANS_SRC_TYP	The transaction source code is a character code that identifies the source of a transaction.  Available codes include (followed by their description): SCOR (Sales Correction), POS (Point of Sale).
--ESC_TRANS_VOID_FLG	The post void indicator is an indicator of whether or not the specific transaction has been voided.  If it has been, there will be an entry in the Transaction Void table indicating which transaction voided it.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.


----------------------------------------------
--Name	ESCTVAF
--Stereotype	Vendor Activity
--Comment	The vendor activity file table defines each of the vendor feeds received from various vendors.  Vendor feeds can be either payments or notifications of cancellation and/or activation.  Data specific to a vendor activity file record include:

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TVAF ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 VNDR_FILE_ID            INTEGER	        --X		X	
		,VNDR_ID                 NUMERIC(9)			--	
		,VNDR_SUBTYP             VARCHAR(3)		--		
		,ARCHIVE_CMPUTR_NM       VARCHAR(30)		--    	X	
		,VNDR_FILE_STAT          VARCHAR(6)		DEFAULT ' ' --    X	X	' '
		,REC_CREATE_PGM_ID       VARCHAR(8)		--	    X	
		,REC_CREATE_TS           TIMESTAMP			--        X	
		,REC_CREATE_USR_ID       VARCHAR(8)		--	    X	
		,REC_UPD_PGM_ID          VARCHAR(8)		--	    X	
		,REC_UPD_TS              TIMESTAMP			--        X	
		,REC_UPD_USR_ID          VARCHAR(8)		--	    X	
		,ARCHIVE_FILE_NM         VARCHAR(256)		--	    X	    
)
UNIQUE PRIMARY INDEX ESC_TVAF_PI (VNDR_FILE_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TVAF   IS 'vendor activity file table defines each of the vendor feeds received from various vendors.  Vendor feeds can be either payments or notifications of cancellation and/or activation.' 
;

--VNDR_FILE_ID	The vendor activity file identifier is a surrogate key that uniquely identifies a vendor activity file.
--VNDR_ID	The unique identifier of a vendor.  The vendor ID is derived from the following: (VNDR_NBR+DEPT_ID+CHK_DIGIT_NBR). The check digit number is calculated from the following formula:  1. (N1 + 2N2 + N3 + 2N4 + N5 + 2N6 + N7 + 2N8)/ 10 2. 10 - mod = check digit
--VNDR_SUBTYP	Vendor Subtype; A classification of vendors by the nature of the service or product the vendor provides to Best Buy. Values are:    100 - AP Music    100 - AP Merchandise    200 - AP Expense, Employee    300 - AP Expense, E-Commerce (future)    500 - AP Expense
--ARCHIVE_CMPUTR_NM	The archive host name is the name of the machine where the vendor activity file was archived.
--VNDR_FILE_STAT	Vendor File Status Type
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--ARCHIVE_FILE_NM	The archive full path file name is the full path name of the archived version of the vendor activity file on the machine with name (archive host name).



----------------------------------------------
--Name	ESCTVNI
--Stereotype	Vendor Information
--Comment	The vendor information table provides additional vendor information that is not located within the main Best Buy vendor table.  Data specific to a vendor information record include:

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TVNI ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 VNDR_ID             NUMERIC(9)	        --X		X	
		,VNDR_SUBTYP         VARCHAR(3)	    --X		X	
		,FISC_TYP_ID         INTEGER		    --    X	X	
		,VNDR_PRFL_ID        INTEGER		    --    X	X	
		,ACTV_PH_AREA_NBR    VARCHAR(3)		--	    X	
		,ACTV_PH_NBR         VARCHAR(7)		--	    X	
		,ACTV_PH_EXT         VARCHAR(5)		--	    	
		,REC_CREATE_PGM_ID   VARCHAR(8)		--	    X	
		,REC_CREATE_TS       TIMESTAMP			--    X	
		,REC_CREATE_USR_ID   VARCHAR(8)		--	    X	
		,REC_UPD_PGM_ID      VARCHAR(8)		--	    X	
		,REC_UPD_TS          TIMESTAMP			--    X	
		,REC_UPD_USR_ID      VARCHAR(8)		--	    X	
		,ESC_VNDR_POS_TXT    VARCHAR(256)		--	X	
)
UNIQUE PRIMARY INDEX ESC_TVNI_PI (VNDR_ID, VNDR_SUBTYP)
INDEX (FISC_TYP_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TVNI   IS 'vendor information table provides additional vendor information that is not located within the main Best Buy vendor table.' 
;

--VNDR_ID	The unique identifier of a vendor.  The vendor ID is derived from the following: (VNDR_NBR+DEPT_ID+CHK_DIGIT_NBR). The check digit number is calculated from the following formula:  1. (N1 + 2N2 + N3 + 2N4 + N5 + 2N6 + N7 + 2N8)/ 10 2. 10 - mod = check digit
--VNDR_SUBTYP	Vendor Subtype; A classification of vendors by the nature of the service or product the vendor provides to Best Buy. Values are:    100 - AP Music    100 - AP Merchandise    200 - AP Expense, Employee    300 - AP Expense, E-Commerce (future)    500 - AP Expense
--FISC_TYP_ID	The fiscal calendar type identifier uniquely identifies a type of fiscal calendar.
--VNDR_PRFL_ID	The unique identifier for one profile for a vendor.
--ACTV_PH_AREA_NBR	The activation phone area code is the area code of the phone number that the customer can call to activate their subscription service.
--ACTV_PH_NBR	The activation phone number is the phone number (less the area code) that the customer can call to activate their subscription service.
--ACTV_PH_EXT	The activation phone extension is the extension of the phone number that the customer can call to activate their subscription service.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--ESC_VNDR_POS_TXT	Vendor POS Receipt Text



----------------------------------------------
--Name	ESCTVPF
--Stereotype	Vendor Payment
--Comment	The vendor payment table defines those vendor activity files that are of the payment variety.  Payment files indicate the check or wire transfer number of the transaction as well as header information pertaining to the vendor payment.  Data specific to a

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TVPF ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 VNDR_FILE_ID            INTEGER	        --X	X	X	
		,VNDR_PYMT_XFER_TYP      VARCHAR(5)		--        X	 
		,VNDR_PYMT_ID            VARCHAR(30)		--	X	
		,VNDR_PYMT_DRAW_DT       DATE				--
		,VNDR_NET_PYMT_AMT       NUMERIC(9,2)		--	    X	
		,REC_CREATE_PGM_ID       VARCHAR(8)		--	    X	
		,REC_CREATE_TS           TIMESTAMP			--    X	
		,REC_CREATE_USR_ID       VARCHAR(8)		--	    X	
		,REC_UPD_PGM_ID          VARCHAR(8)		--	    X	
		,REC_UPD_USR_ID          VARCHAR(8)		--	    X	
		,REC_UPD_TS              TIMESTAMP			--    X	
)
UNIQUE PRIMARY INDEX ESC_TVPF_PI (VNDR_FILE_ID)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TVPF   IS 'vendor payment table defines those vendor activity files that are of the payment variety.  Payment files indicate the check or wire transfer number of the transaction as well as header information pertaining to the vendor payment.' 
;

--VNDR_FILE_ID	The vendor activity file identifier is a surrogate key that uniquely identifies a vendor activity file.
--VNDR_PYMT_XFER_TYP	The payment transfer type is a character code that represents a specific type of payment transfer type.  Examples (with their associated descriptions) include: CHECK (Check) and WIRE (Wire Transfer).
--VNDR_PYMT_ID	The payment identifier is the number associated with the specific vendor payment (i.e. the check number, wire transfer number).
--VNDR_PYMT_DRAW_DT	The payment drawn date is the date that the amount of the payment can be withdrawn from the vendor's bank.  This would be synonymous with the date on the check (for example: post-dating a check), or the actual date of a wire transfer of funds.
--VNDR_NET_PYMT_AMT	The payment amount is the net amount of the payment deposited by Best Buy.  This is equal the total dollars for payments less the total dollars for chargebacks.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--REC_UPD_TS	Timestamp of the last time the record was modified.


----------------------------------------------
--Name	ESCTVPR
--Stereotype	Vendor Profile
--Comment	Each vendor has more than one conversion possibilities.  For each file profile type, and activity, a different conversion will occur.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TVPR ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 VNDR_PRFL_ID            INTEGER	        --X		X	
		,VNDR_ID                 NUMERIC(9)			--    X	
		,VNDR_SUBTYP             VARCHAR(3)		--	    X	
		,FILE_PRFL_TYP           VARCHAR(4)		--    X	X	
		,FILE_LAYOT_TYP          VARCHAR(4)		--    X	X	
		,TRANSPT_PROTCL_TYP      VARCHAR(5)		--    X	X	
		,DELMT_TXT               VARCHAR(1)		--		
		,REC_CREATE_PGM_ID       VARCHAR(8)		--	    X	
		,REC_CREATE_TS           TIMESTAMP			--    X	
		,REC_CREATE_USR_ID       VARCHAR(8)		--	    X	
		,REC_UPD_PGM_ID          VARCHAR(8)		--	    X	
		,REC_UPD_TS              TIMESTAMP			--    X	
		,REC_UPD_USR_ID          VARCHAR(8)		--	    X	
		,XFER_USR_ID             VARCHAR(20)		--		
		,XFER_PSWD_TXT           VARCHAR(20)		--		
		,GRFX_EC_TYPE            VARCHAR(3)		--        X		
		,EC_RAW_DATA_FLG         VARCHAR(1)		--	    X	
		,EC_GRFX_FILE_FLG        VARCHAR(1)		--	    X	
		,EC_ECNTR_FLG            VARCHAR(1)		DEFAULT 'N' --	    X	N
		,EC_SSN_FLG              VARCHAR(1)		DEFAULT 'N' --	    X	N
		,EC_SEC_ADDR_FLG         VARCHAR(1)		DEFAULT 'N' --	    X	N
		,EC_SIGNTR_FLG           VARCHAR(1)		DEFAULT 'N' --	    X	N
		,EC_CRDT_INFO_FLG        VARCHAR(1)		DEFAULT 'N' --	    X	N
		,VNDR_ECNTR_FILE         VARCHAR(12)		--		
		,XFER_XSL_FILE_NM        VARCHAR(100)		--		
		,TRNSPT_URL_TXT          VARCHAR(256)		--		
		,TRNSPT_DIR_TXT          VARCHAR(256)		--		
		,VNDR_HDR_SIZE           INTEGER			--	
		,VNDR_DT_FORMAT          VARCHAR(25)		--		
		,EC_EMAIL_REQ_FLG        VARCHAR(1)		DEFAULT 'N' --	    X	N
		,EC_SSN_REQ_FLG          VARCHAR(1)		DEFAULT 'Y' --	    X	Y
		,PLAN_SEL_REQD_FLG       VARCHAR(1)		DEFAULT 'Y' --	    X	Y
		,ATTRB_REQD_FLG          VARCHAR(1)		DEFAULT 'Y' --	    X	Y
		,EC_SEC_INFO_FLG         VARCHAR(1)		DEFAULT 'N' --	    X	N
		,INCL_ALL_HDWR_FLG       VARCHAR(1)		DEFAULT 'N' --	    X	N
		,DUP_ACCT_INCL_FLG       VARCHAR(1)		DEFAULT 'N' --	    X	N
		,AGGR_VNDR_FLG           VARCHAR(1)		DEFAULT 'N' --	    X	N
		,CUST_SEL_REQ_FLG        VARCHAR(1)		DEFAULT 'Y' --	    X	Y
		,EC_WORK_PH_REQ_FLG      VARCHAR(1)		DEFAULT 'N' --	    X	N
		,EC_WORK_PH_DIS_FLG      VARCHAR(1)		DEFAULT 'N' --	    X	N
		,EC_EMAIL_DIS_FLG        VARCHAR(1)		DEFAULT 'N' --	    X	N
		,COMN_DEPT_DIS_FLG       VARCHAR(1)		DEFAULT 'N' --	    X	N
		,SYS_EXCP_RSLN_FLG       VARCHAR(1)		DEFAULT 'N' --	    X	N
		,ESC_RAC_ENBL_FLG        VARCHAR(1)		DEFAULT 'N' --	    X	N
		,ESC_RAC_OFFLN_CDE       VARCHAR(1)		DEFAULT '0' --	    X	0
		,EXCH_ENBL_FLG           VARCHAR(1)		DEFAULT 'Y' --	    	Y
		,B2B_SFWR_VER_ID         VARCHAR(10)		DEFAULT 'WM6' --	    X	WM6
		,INVL_ACCT_AUTO_CMPLT_FLGVARCHAR(1)		DEFAULT 'N' --	    X	'N'
)
UNIQUE PRIMARY INDEX ESC_TVPR_PI (VNDR_PRFL_ID)
INDEX (VNDR_ID,VNDR_SUBTYP)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TVPR   IS 'Each vendor has more than one conversion possibilities.  For each file profile type, and activity, a different conversion will occur.' 
;




----------------------------------------------
--Name	ESCTVPT
--Stereotype	Vendor Profile Type
--Comment	This is middle table to create a many to many relationship for Vendor Attribute Types and Vendor Attribute Profiles.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TVPT ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 ATRIB_PRFL_ID       INTEGER	        --X	X	X	
		,VNDR_ATRIB_TYP      VARCHAR(10)	    --X	X	X	
		,REC_CREATE_PGM_ID   VARCHAR(8)		--	    X	
		,REC_CREATE_TS       TIMESTAMP			--    X	
		,REC_CREATE_USR_ID   VARCHAR(8)		--	    X	
)
UNIQUE PRIMARY INDEX ESC_TVPT_PI (ATRIB_PRFL_ID ,VNDR_ATRIB_TYP)
INDEX (VNDR_ATRIB_TYP)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TVPT   IS 'This is middle table to create a many to many relationship for Vendor Attribute Types and Vendor Attribute Profiles.' 
;


--ATRIB_PRFL_ID	Primary key for the Attribute Profile table.
--VNDR_ATRIB_TYP	Vendor Attribute Type
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.




----------------------------------------------
--Name	ESC_CUSTCST
--Stereotype	Customer
--Comment	This table contains the unique identifier of a customer along with customer name,address and telephone information.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_CUSTCST ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 CUST_ID                 NUMERIC(18)	    --X		X	
		,CUST_1ST_NM             VARCHAR(25)	--		X	
		,CUST_MDL_INTL           VARCHAR(1)	--			
		,CUST_LAST_NM            VARCHAR(25)	--		X	
		,CUST_NM_PREFIX_TYP      VARCHAR(7)	--			
		,CUST_NM_SUFFIX_TYP      VARCHAR(3)	--			
		,CUST_ADDR_ST_NBR        VARCHAR(10)	--			
		,CUST_ADDR_ST_NM         VARCHAR(30)	--		X	
		,CUST_ADDR_UNIT_ID       VARCHAR(10)	--			
		,CUST_ADDR_CITY_NM       VARCHAR(30)	--		X	
		,STATE_ABBR              VARCHAR(5)	--		    X	
		,CUST_ADDR_ZIP           VARCHAR(7)	--		    X	
		,CUST_ADDR_ZIP4          VARCHAR(4)	--		    	
		,CNTRY_ID                VARCHAR(2)	--		    X	
		,EMAIL_ADDR_ID           VARCHAR(55)	--	    	 
		,HOME_PH_AREA_NBR        VARCHAR(3)	--		    	
		,HOME_PH_NBR             VARCHAR(7)	--		    X	
		,WORK_PH_AREA_NBR        VARCHAR(3)	--			
		,WORK_PH_NBR             VARCHAR(7)	--			
		,WORK_PH_EXT             VARCHAR(5)	--			
		,EC_SENT_FLG             CHAR(1)		DEFAULT 'N' --	        X	N
		,REC_CREATE_TS           TIMESTAMP		--	    X	
		,REC_CREATE_USR_ID       VARCHAR(8)	--		    X	
		,REC_CREATE_PGM_ID       VARCHAR(8)	--		    X	
		,REC_UPD_TS              TIMESTAMP		--	    X	
		,REC_UPD_USR_ID          VARCHAR(8)	--		    X	
		,REC_UPD_PGM_ID          VARCHAR(8)	--		    X	
)
UNIQUE PRIMARY INDEX ESC_CUSTCST_PI (CUST_ID)
INDEX ( CUST_LAST_NM ,CUST_1ST_NM ,CUST_ID)
INDEX ( HOME_PH_NBR ,CUST_LAST_NM ,CUST_1ST_NM ,HOME_PH_AREA_NBR)
INDEX (EC_SENT_FLG)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_CUSTCST   IS 'This table contains the unique identifier of a customer along with customer name,address and telephone information.' 
;


--CUST_ID	Unique identifier of a customer.
--CUST_1ST_NM	The first name of a customer.
--CUST_MDL_INTL	The middle initial of a customer.
--CUST_LAST_NM	The last name of a customer.
--CUST_NM_PREFIX_TYP	This is classification of the prefix used in the proper name of a customer.; A classification of prefix used in the name of a person.  Prefixes often indicate gender. Values are: Mr. Mrs. Ms
--CUST_NM_SUFFIX_TYP	This is classification of the suffix used in the proper name of a customer.; A classification of suffixes used in the proper name of a person. Values are: JR SR 2nd 3rd
--CUST_ADDR_ST_NBR	The house number that uniquely identifies a customer address within a street.
--CUST_ADDR_ST_NM	The name of the street associated with a customer address.
--CUST_ADDR_UNIT_ID	The identifier of a particular address unit, such as apartment, within the customer address.  The unit reflects a further breakdown of a single mail stop.
--CUST_ADDR_CITY_NM	The city name for a particular customer's address.
--STATE_ABBR	The abbreviated name of one state of the United States of America.
--CUST_ADDR_ZIP	The zip code of a particular customer's address.  This field is large enough to contain Canada's 6 characters delimited with one space in the middle.
--CUST_ADDR_ZIP4	The last four digits of the postal zip code associated with the customer address.
--CNTRY_ID	The unique identifier of land of a person's birth, residence, or citizenship; a political state or nation or its territory.
--EMAIL_ADDR_ID	The unique identifier of an electronic mail address.
--HOME_PH_AREA_NBR	The number associated with the telephone area code for the customers home phone number.; The North American area code portion of a telephone number.
--HOME_PH_NBR	The home phone number of a customer of Best Buy.; Phone number.
--WORK_PH_AREA_NBR	The number associated with the telephone area code for the customers WORK phone number.; The North American area code portion of a telephone number.
--WORK_PH_NBR	The WORK phone number of a customer of Best Buy.; Phone number.
--WORK_PH_EXT	The extension number appended to a customer's work phone number.
--EC_SENT_FLG	This field represents a flag which indicates whether this Customer Record has been sent to the Enterprise Customer application.
--
--Values are: Y or N
--'N' is default value.
--
--Data Architect - Rick Buelow 5/10/2005
--
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.


----------------------------------------------
--Name	ESCTCMH
--Stereotype	Communication History
--Comment	Communication history table

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TCMH ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 ESC_CUST_ACCT_ID        INTEGER	    --X	X	X
		,ESC_COMM_HIST_NBR       INTEGER	    --X		X
		,FILE_ACTVTY_TYP         VARCHAR(4)	--X		X
		,ESC_COMM_TS             TIMESTAMP		--	 
		,REC_CREATE_PGM_ID       VARCHAR(8)	--		X
		,REC_CREATE_TS           TIMESTAMP		--	X
		,REC_CREATE_USR_ID       VARCHAR(8)	--		X
		,REC_UPD_PGM_ID          VARCHAR(8)	--		X
		,REC_UPD_TS              TIMESTAMP		--	X
		,REC_UPD_USR_ID          VARCHAR(8)	--		X
		,VNDR_ID                 NUMERIC(9)		--	 
		,VNDR_SUBTYP             VARCHAR(3)	--		 
		,ESC_LN_SEQ              INTEGER		--		
)
UNIQUE PRIMARY INDEX ESC_TCMH_PI (ESC_CUST_ACCT_ID ,ESC_COMM_HIST_NBR ,FILE_ACTVTY_TYP) 
INDEX (ESC_COMM_TS)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCMH   IS 'Communication history table' 
;

--ESC_CUST_ACCT_ID	The customer account identifier is a surrogate key used to uniquely identify an ESC customer account.
--ESC_COMM_HIST_NBR	
--FILE_ACTVTY_TYP	Code that identifies Subscription Services file Activity Type.
--ESC_COMM_TS	
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--VNDR_ID	The unique identifier of a vendor.  The vendor ID is derived from the following: (VNDR_NBR+DEPT_ID+CHK_DIGIT_NBR). The check digit number is calculated from the following formula:  1. (N1 + 2N2 + N3 + 2N4 + N5 + 2N6 + N7 + 2N8)/ 10 2. 10 - mod = check digit
--VNDR_SUBTYP	A classification of vendors by the nature of the service or product the vendor provides to Best Buy. Values are:    100 - AP Music    100 - AP Merchandise    200 - AP Expense, Employee    300 - AP Expense, E-Commerce (future)    500 - AP Expense, Non Employee
--ESC_LN_SEQ	The line item sequence number is a surrogate key used to uniquely identify a transaction line item.


----------------------------------------------
--Name	ESCTSTD
--Stereotype	Sale Transaction Detail
--Comment	The transaction detail table represents specific line items on a transaction that are associated with subscription service sales.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TSTD ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 SLS_TRANS_LN_NBR        NUMERIC(4)	        --X		X	
		,SLS_TRANS_NBR           NUMERIC(5)	        --X	X	X	
		,REGSTR_NBR              NUMERIC(3)	        --X	X	X	
		,SLS_TRANS_TS            TIMESTAMP	        --X	X	X	
		,LOC_ID                  NUMERIC(5)	        --X	X	X	
		,ESC_LN_SEQ              INTEGER	        --		    X	
		,ESC_LN_ACTVTY_TYP       VARCHAR(4)        --		X	X	
		,ESC_LN_VOID_FLG         VARCHAR(1)        --			X	
		,REC_CREATE_TS           TIMESTAMP	        --		X	
		,REC_UPD_TS              TIMESTAMP	        --		X	
		,REC_UPD_USR_ID          VARCHAR(8)        --			X	
		,REC_UPD_PGM_ID          VARCHAR(8)        --			X	
		,REC_CREATE_USR_ID       VARCHAR(8)        --			X	
		,REC_CREATE_PGM_ID       VARCHAR(8)        --			X	
)
UNIQUE PRIMARY INDEX ESC_TSTD_PI (SLS_TRANS_LN_NBR ,SLS_TRANS_NBR  ,REGSTR_NBR    ,SLS_TRANS_TS ,LOC_ID) 
INDEX (ESC_LN_SEQ)
INDEX (REGSTR_NBR)
INDEX (SLS_TRANS_TS,LOC_ID)
INDEX (SLS_TRANS_NBR)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TSTD   IS 'The transaction detail table represents specific line items on a transaction that are associated with subscription service sales.' 
;

--SLS_TRANS_LN_NBR	The transaction line number is the physical line number on a transaction that a specific line item detail appears.; The internally assigned unique identifier of a line within a sales transaction.  The line number is unique within a sales transaction and 
--SLS_TRANS_NBR	The transaction identifier is the Best Buy transaction ID at the time of sale.; The unique number of a sales transaction.  This number is unique within a particular date, register, and location.
--REGSTR_NBR	The unique identifier of a point-of-sale register within a Best Buy location.
--SLS_TRANS_TS	The transaction timestamp is the date and time that a Best Buy transaction occurred.; The date and time of the sales transaction.
--LOC_ID	The location identifier is a unique identifier of a Best Buy location.  Locations include stores, warehouses, etc. The location identifier is a foreign key from the Best Buy location table.; The internally assigned unique identifier of a location within 
--ESC_LN_SEQ	The line item sequence number is a surrogate key used to uniquely identify a transaction line item.
--ESC_LN_ACTVTY_TYP	The line item action code is a four-character code that identifies the line item action of a transaction line item.  Available codes include (followed by their description): SALE (Sale of an item), RETN (Return of item), VOID (Line item was voided).
--ESC_LN_VOID_FLG	A flag that indicates whether a transaction-time void or post-void has been used on this sales transaction line.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.




----------------------------------------------
--Name	ESCTDPT
--Stereotype	Commission Department Type
--Comment	This table holds the Commission Department information such as department type, department name, department description and department active flag.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TDPT ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 COMN_DEPT_TYP           VARCHAR(4)	    --X		X	
		,COMN_DEPT_NM            VARCHAR(30)		--	X	
		,COMN_DEPT_DESC          VARCHAR(255)		--	X	
		,COMN_DEPT_ACTV_FLG      VARCHAR(1)		--	    X	
		,REC_CREATE_PGM_ID       VARCHAR(8)		--	    X	
		,REC_CREATE_USR_ID       VARCHAR(8)		--	    X	
		,REC_CREATE_TS           TIMESTAMP			--    X	
		,REC_UPD_PGM_ID          VARCHAR(8)		--	    X	
		,REC_UPD_USR_ID          VARCHAR(8)		--	    X	
		,REC_UPD_TS              TIMESTAMP			--    X	
)
UNIQUE PRIMARY INDEX ESC_TDPT_PI (COMN_DEPT_TYP)
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TDPT   IS 'This table holds the Commission Department information such as department type, department name, department description and department active flag.' 
;



--COMN_DEPT_TYP	Unique identifier of a 'commission department' to which NPV revenue can be credited for the sale of a subscription.  The value of 'DFLT' indicates that the default department should be used.
--COMN_DEPT_NM	Name of a commission department to which NPV revenue can be credited.
--COMN_DEPT_DESC	Narrative description of the Commission Department.
--COMN_DEPT_ACTV_FLG	Flag indicating whether the Commission Department is active or not. Will have values as either Y or N.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--REC_UPD_TS	Timestamp of the last time the record was modified.


----------------------------------------------
--Name	ESCTDPM
--Stereotype	Commision Department Model
--Comment	This table defines a mapping between a plan, the plan's commission model, and the commission departments in which it can be sold, to get the posting SKU.

CREATE SET TABLE DEVBBYMEADHOCDB.ESC_TDPM ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL, CHECKSUM = DEFAULT
(
		 COMN_MODL_ID            INTEGER	    --X	X	X	
		,ESC_PLAN_ID             INTEGER	    --X		X	
		,COMN_DEPT_TYP           VARCHAR(4)	--X	X	X	
		,POST_SKU_ID             NUMERIC(7)		--	X	
		,REC_CREATE_PGM_ID       VARCHAR(8)	--		X	
		,REC_CREATE_USR_ID       VARCHAR(8)	--		X	
		,REC_CREATE_TS           TIMESTAMP		--	X	
		,REC_UPD_PGM_ID          VARCHAR(8)	--		X	
		,REC_UPD_USR_ID          VARCHAR(8)	--		X	
		,REC_UPD_TS              TIMESTAMP		--	X	
		,ACTV_FLG                VARCHAR(1)	--		X	Y
)
UNIQUE PRIMARY INDEX ESC_TDPM_PI (COMN_MODL_ID ,ESC_PLAN_ID ,COMN_DEPT_TYP) 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TDPM   IS 'This table defines a mapping between a plan, the plans commission model, and the commission departments in which it can be sold, to get the posting SKU.' 
;

--COMN_MODL_ID	The commission model identifier is a surrogate key used to uniquely identify a commission model.
--ESC_PLAN_ID	The subscription plan identifier is a surrogate key representing a unique subscription plan.  An example of a rate plan would be 'AT&T Digital PCS One Rate 600 Minutes'.
--COMN_DEPT_TYP	Unique identifier of a 'commission department' to which NPV revenue can be credited for the sale of a subscription.  The value of 'DFLT' indicates that the default department should be used.
--POST_SKU_ID	Identifier of the SKU to which the revenue is posted.
--REC_CREATE_PGM_ID	The unique identifier of the management information systems program that was used to create the physical record.
--REC_CREATE_USR_ID	The identifier of the user that was responsible for initially creating & populating the record.
--REC_CREATE_TS	The date and time upon which the physical record is created.
--REC_UPD_PGM_ID	The identifier of the information systems program that was used to update the record most recently.
--REC_UPD_USR_ID	The identifier of the user who was responsible for updating the record most recently.
--REC_UPD_TS	Timestamp of the last time the record was modified.
--ACTV_FLG	Flag indications whether the mapping between a commission model, plan and commission department is currently active. Values are: 'Y'= Yes, the mapping is currently active; 'N'= No, the mapping is not active.


--CUSTCST
--ESCTACS
--ESCTARD
--ESCTARS
--ESCTASC
--ESCTATA
--ESCTBMD
--ESCTCAC
--ESCTCAI
--ESCTCAT
--ESCTCMD
--ESCTCMH
--ESCTCPT
--ESCTCSC
--ESCTCSI
--ESCTCTP
--ESCTDPM
--ESCTDPT
--ESCTDVP
--ESCTEGT
--ESCTFAT
--ESCTKPG
--ESCTLIA
--ESCTLNI
--ESCTPAD
--ESCTPAK
--ESCTPKG
--ESCTPKP
--ESCTPKT
--ESCTPLC
--ESCTPLN
--ESCTRMD
--ESCTSKP
--ESCTSLT
--ESCTSTD
--ESCTVAF
--ESCTVNI
--ESCTVPF
--ESCTVPR
--ESCTVPT

--CREATE SET TABLE ProdBBYDB.TBEND_SA_SALE ,NO FALLBACK , NO BEFORE JOURNAL, NO AFTER JOURNAL,
--     CHECKSUM = DEFAULT
--     (
--      SLS_KEY VARCHAR(200) CHARACTER SET LATIN NOT CASESPECIFIC NOT NULL,
--      RVSN_NBR INTEGER NOT NULL COMPRESS (1 ,2 ,3 ),
--      RVSN_CDE CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC NOT NULL COMPRESS ('R','T'),
--      SLS_BSNS_DT DATE FORMAT 'yyyy-mm-dd' NOT NULL,
--      CHN_ID SMALLINT NOT NULL COMPRESS (110 ,160 ),
--      LOC_ID INTEGER NOT NULL,
--      SLS_TRANS_TS TIMESTAMP(6) NOT NULL,
--      SLS_TRANS_SEQ_NBR DECIMAL(18,0),
--      SLS_REAS_TYP_CDE VARCHAR(6) CHARACTER SET LATIN NOT CASESPECIFIC,
--      SLS_POS_TRANS_FLG CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC COMPRESS ('N','Y'),
--      SLS_ORD_NBR VARCHAR(20) CHARACTER SET LATIN NOT CASESPECIFIC,
--      SLS_LGCY_TRANS_TYP_CDE CHAR(2) CHARACTER SET LATIN NOT CASESPECIFIC COMPRESS ('  ','01','02','03','04','05','06'),
--      CMRCL_SALE_CR_LOC_ID INTEGER,
--      ORIG_SLS_KEY VARCHAR(200) CHARACTER SET LATIN NOT CASESPECIFIC,
--      SLS_RWRD_ZONE_FLG CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC COMPRESS ('N','Y'),
--      SLS_RWRD_ZONE_CR_AMT DECIMAL(9,2) COMPRESS 0.00 ,
--      ORIG_SLS_BSNS_DT DATE FORMAT 'yyyy-mm-dd',
--      ALL_CHNL_RPT_LOC_ID INTEGER NOT NULL,
--      RPT_TRANS_CNT_VAL SMALLINT NOT NULL,
--      GROS_SLS_QTY INTEGER COMPRESS (1 ,2 ,3 ,4 ,5 ,6 ,7 ),
--      GROS_SLS_AMT DECIMAL(9,2) COMPRESS 0.00 ,
--      GROS_RTN_QTY INTEGER COMPRESS (0 ,1 ,2 ),
--      GROS_RTN_AMT DECIMAL(9,2) COMPRESS 0.00 ,
--      NON_MDSE_SLS_AMT DECIMAL(9,2) COMPRESS 0.00 ,
--      EMP_DCNT_AMT DECIMAL(9,2) COMPRESS 0.00 ,
--      OFF_RTL_DCNT_AMT DECIMAL(9,2) COMPRESS 0.00 ,
--      OTHR_DCNT_AMT DECIMAL(9,2) COMPRESS 0.00 ,
--      RWZ_DCNT_AMT DECIMAL(9,2) COMPRESS 0.00 ,
--      INSTANT_SVCD_RBT_DCNT_AMT DECIMAL(9,2) COMPRESS 0.00 ,
--      XTND_COST_AMT DECIMAL(9,2) COMPRESS 0.00 ,
--      XTND_REG_PRC_AMT DECIMAL(9,2) COMPRESS 0.00 ,
--      XTND_ORIG_PRC_AMT DECIMAL(9,2) COMPRESS 0.00 ,
--      ALL_CHNL_SLS_ALOC_REAS_CDE CHAR(4) CHARACTER SET LATIN NOT CASESPECIFIC,
--      ORIG_TRANS_BSNS_DT DATE FORMAT 'YYYY-MM-DD',
--      REC_CRT_TS TIMESTAMP(6) NOT NULL,
--      REC_UPD_TS TIMESTAMP(6))
--PRIMARY INDEX ITEND_SA_SALE_PI ( SLS_KEY )
--PARTITION BY RANGE_N(SLS_BSNS_DT  BETWEEN '2002-03-01' AND '2009-12-31' EACH INTERVAL '1' DAY )
--INDEX ( SLS_BSNS_DT ,LOC_ID )
--INDEX ITEND_SA_SALE_SI2 ( SLS_BSNS_DT ,CHN_ID ,LOC_ID ,SLS_RGST_NBR , SLS_TRANS_NBR );
--
