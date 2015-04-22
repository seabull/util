REM
REM see explainplan_setup.sql
REM
REM create user UTILS or TOOLS
REM grant create session, create table to UTILS
REM create global temporary table plan_table (
REM	statement_id	varchar2(30)
REM	, timestamp	Date
REM	, remarks	varchar2(80)
REM	, operation	varchar2(30) 
REM	,OPTIONS        VARCHAR2(30)
REM	,OBJECT_NODE    VARCHAR2(128)
REM	,OBJECT_OWNER   VARCHAR2(30)
REM	,OBJECT_NAME    VARCHAR2(30)
REM	,OBJECT_INSTANCE        NUMBER
REM	,OBJECT_TYPE    VARCHAR2(30)
REM	,OPTIMIZER      VARCHAR2(255)
REM	,SEARCH_COLUMNS NUMBER
REM	,ID             NUMBER
REM	,PARENT_ID      NUMBER
REM	,POSITION       NUMBER
REM	,COST           NUMBER
REM	,CARDINALITY    NUMBER
REM	,BYTES          NUMBER
REM	,OTHER_TAG      VARCHAR2(255)
REM	,PARTITION_START	VARCHAR2(255)
REM	,PARTITION_STOP VARCHAR2(255)
REM	,PARTITION_ID   NUMBER
REM	,OTHER          LONG
REM	, access_predicates	varchar2(4000)
REM	, filter_predicates	varchar2(4000)
REM	)
REM	ON COMMIT PRESERVE ROWS

REM grant all to public
REM create public synonym plan_table
