
set linesize 1000
set pagesize 50000
set wrap off
column  AUD_CHANGE_ID format 999999999
column AUD_UROWID format a20
column AUD_PRINCIPAL_LOG_ID format 99999999
column AUD_TS format a29
column os_user_name format a12 

spool foo.log
--select 
--	OS_USER_NAME
--  from aud.change_log cl
--	,aud.principal_log pl
--	,aud.session_log sl
-- where cl.PRINCIPAL_LOG_ID=pl.PRINCIPAL_LOG_ID
--   and pl.SESSION_LOG_ID=sl.SESSION_LOG_ID
--/

select
	AUD_CHANGE_ID
	,AUD_Change_flag
	,Aud_Action
	,AUD_TS
	,( select OS_USER_NAME
		  from aud.change_log cl
			,aud.principal_log pl
			,aud.session_log sl
		 where cl.PRINCIPAL_LOG_ID=pl.PRINCIPAL_LOG_ID
		   and pl.SESSION_LOG_ID=sl.SESSION_LOG_ID
		   and cl.CHANGE_ID=AUD_CHANGE_ID
	) os_user_name
	,ASSETNUM
	,SERIALNUM
	,BLDG
	,FLR
	,RM
	,SUFFIX
	,Qual
	,PONUM
	,LINENUM
	,MANUF
	,DESCRIPTION
	,LOCDATE
	,USELEVEL
	,VERIFIED
	,DEPT
	,PRINC
	,WARRANTY_Expire
	,WARRANTY_INFO
  from aud_hostdb.capequip
 where assetnum in ('UMATT1.00', '135858.00')
order by aud_ts
/
select
	AUD_CHANGE_ID
	,AUD_Change_flag
	,Aud_Action
	,AUD_TS
	,( select OS_USER_NAME
		  from aud.change_log cl
			,aud.principal_log pl
			,aud.session_log sl
		 where cl.PRINCIPAL_LOG_ID=pl.PRINCIPAL_LOG_ID
		   and pl.SESSION_LOG_ID=sl.SESSION_LOG_ID
		   and cl.CHANGE_ID=AUD_CHANGE_ID
	) os_user_name
	,ASSETNO
	,CPUTYPE
	,CPUMODEL
	,CPUMODELEXT
	,HOSTID
	,PROJECT
	,HWADDR
	,USRPRINC
	,PRJPRINC
	,Usage
	,DIST
	,Charge_by
	,Oproject
	,Ousage
	,SUBPROJECT
	,DIST
	,MR_CLASS
	,FILTER_Code
	,DESCRIPTION
  from aud_hostdb.machtab
 where assetno in ('UMATT1.00', '135858.00')
order by aud_ts
/
select
	AUD_CHANGE_ID
	,AUD_Change_flag
	,Aud_Action
	,AUD_TS
	,( select OS_USER_NAME
		  from aud.change_log cl
			,aud.principal_log pl
			,aud.session_log sl
		 where cl.PRINCIPAL_LOG_ID=pl.PRINCIPAL_LOG_ID
		   and pl.SESSION_LOG_ID=sl.SESSION_LOG_ID
		   and cl.CHANGE_ID=AUD_CHANGE_ID
	) os_user_name
	,HOSTNAME
	,OS
	,OSVERS
	,IPADDRESS
	,ASSETNO
	,PROTOCOL
	,PRI
	,TTL
	,PCT_USE
	,IROWID
	,OPRI
	,CONN
  from aud_hostdb.hoststab
 where assetno in ('UMATT1.00', '135858.00')
order by aud_ts
/
select
	AUD_CHANGE_ID
	,AUD_Change_flag
	,Aud_Action
	,AUD_TS
	,( select OS_USER_NAME
		  from aud.change_log cl
			,aud.principal_log pl
			,aud.session_log sl
		 where cl.PRINCIPAL_LOG_ID=pl.PRINCIPAL_LOG_ID
		   and pl.SESSION_LOG_ID=sl.SESSION_LOG_ID
		   and cl.CHANGE_ID=AUD_CHANGE_ID
	) os_user_name
	,ASSETNO
	,PRI
	,SERVICE_ID
	,PCT
	,SHARED
	,JOURNAL
	,TRANS_DATE
	,HR_ID
  from aud_hostdb.host_service
 where assetno in ('UMATT1.00', '135858.00')
order by aud_ts
/
select
	AUD_CHANGE_ID
	,AUD_Change_flag
	,Aud_Action
	,AUD_TS
	,( select OS_USER_NAME
		  from aud.change_log cl
			,aud.principal_log pl
			,aud.session_log sl
		 where cl.PRINCIPAL_LOG_ID=pl.PRINCIPAL_LOG_ID
		   and pl.SESSION_LOG_ID=sl.SESSION_LOG_ID
		   and cl.CHANGE_ID=AUD_CHANGE_ID
	) os_user_name
	,ASSETNO
	,PRI
	,PCT
	,CHARGE
	,AMOUNT
	,ACCOUNT
	,SERVICE_ID
	,HR_ID
	,JOURNAL
  from aud_hostdb.host_service_charge
 where assetno in ('UMATT1.00', '135858.00')
order by aud_ts
/

select
	AUD_CHANGE_ID
	,AUD_Change_flag
	,Aud_Action
	,AUD_TS
	,row_id
	,tab
	,seq
	,text1
	,text2
	,num1
	,num2
  from aud_hostdb.trigdef_q
 where text1 in ('UMATT1.00', '135858.00')
    or text2 in ('UMATT1.00', '135858.00')
order by aud_ts
/
spool off
set linesize 80
