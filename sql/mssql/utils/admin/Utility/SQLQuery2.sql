BEGIN TRAN

select *
  from dbo.fortvault
 where objID in (67691730,67691734, 67692992, 67692996,67697161,67697251)

SELECT * 
  FROM [LOG] 
 WHERE Log.MachineName LIKE '%USBB2UA82006MZ' 
   AND Log.ProcessName LIKE '%Fusion%' 
   --and log.Message like '%Update%'
ORDER BY Log.LogID DESC

update fortvault
set objValue = 'False'
where objid = 61708400


select * --view_definition
  from information_schema.views

select * from sys.database_principals --sys.database_permissions perm

select p.name, OBJECT_NAME(major_id), perm.*
  from sys.database_permissions perm
join sys.database_principals p
	on perm.grantee_principal_id = p.principal_id
 where p.name in ('DWPerfManagement_role','FortVaultUser', 'NA\BBY-R-DVP17DB01-PL01GEN01-D-DWPerfManagement_role-SQL-DW')
  and perm.type ='VW'

select table_name
  from information_schema.views
except
select OBJECT_NAME(major_id)--, p.name, perm.*
  from sys.database_permissions perm
join sys.database_principals p
	on perm.grantee_principal_id = p.principal_id
 where p.name in ('DWPerfManagement_role','FortVaultUser', 'NA\BBY-R-DVP17DB01-PL01GEN01-D-DWPerfManagement_role-SQL-DW')
  --and perm.type ='VW'

select *
    from sys.database_principals

select dateadd(ww, datediff(ww, 0, getdate() -1 ) - 1, -1), dateadd(ww, datediff(ww, 0, getdate()-1 ), -2)

Grant view definition on DimTimeLookupWithAlignment             to [DWPerfManagement_role]
Grant view definition on v_AlertCriteriaSets                    to [DWPerfManagement_role]
Grant view definition on v_AlertDefinitions                     to [DWPerfManagement_role]
Grant view definition on v_AlertDistributions                   to [DWPerfManagement_role]
Grant view definition on v_AlertInstances                       to [DWPerfManagement_role]
Grant view definition on v_AlertLinks                           to [DWPerfManagement_role]
Grant view definition on v_Criterias                            to [DWPerfManagement_role]
Grant view definition on v_Definitions                          to [DWPerfManagement_role]
Grant view definition on v_Distributions                        to [DWPerfManagement_role]
Grant view definition on v_FilteredCriteriaSets                 to [DWPerfManagement_role]
Grant view definition on v_NotificationCriteriaSets             to [DWPerfManagement_role]
Grant view definition on v_NotificationDefinitions              to [DWPerfManagement_role]
Grant view definition on v_NotificationDistributions            to [DWPerfManagement_role]
Grant view definition on v_NotificationInstances                to [DWPerfManagement_role]
Grant view definition on v_NotificationLinks                    to [DWPerfManagement_role]
Grant view definition on v_NotificationsReporting_SevenDay      to [DWPerfManagement_role]
Grant view definition on v_TaskCriteriaSets                     to [DWPerfManagement_role]
Grant view definition on v_TaskDefinitions                      to [DWPerfManagement_role]
Grant view definition on v_TaskDistributions                    to [DWPerfManagement_role]
Grant view definition on v_TaskInstances                        to [DWPerfManagement_role]
Grant view definition on v_TaskLinks                            to [DWPerfManagement_role]
Grant view definition on v_UserInstances                        to [DWPerfManagement_role]
Grant view definition on NotificationInstancesHistory           to [DWPerfManagement_role]

ROLLBACK

select *
  from dbo.Project65000_NewMetricLog

--293,762,834

select count(*)
  from dbo.FORTDataStore

select * 
  from dbo.t_LU_FV_DIM_Time

CREATE VIEW [dbo].[FortVault_V]
AS
select v.objID,v.objParentID,objOrder,objType,objName,objDataType,
		case when c.objValue is not null and v.objValue = '##FortVault_CLOB##' 
			then c.objValue
			else v.objValue
		end objValue,objStartDT,objEndDT,objRecModifyXML,objRecOwnerXML
  from dbo.FORTVault v
left outer join dbo.FORTVault_CLOB c
	on v.objID = c.objID
	and v.objValue = '##FortVault_CLOB##'


GRANT SELECT ON [dbo].[FortVault_V] TO [DWPerfMgmtRes_role]

select *
  from [dbo].[FortVault_V]
 where objID = 2319474

select top 10 *
  from dbo.FORTVault_CLOB


SELECT    F.ValueSetLVL 
         , F.ValueSetID 
         , F.TimeLVL 
         , F.TimeID 
         , F.GeogLVL 
         , F.GeogID 
         , F.ProdLVL 
         , F.ProdID 
         , F.CustLVL 
         , F.CustID 
         , F.OtherLVL 
         , F.OtherID 
         , F.DP01 
         , F.DP02 
         , F.DP03 
         , F.DP04 
         , F.DP05 
         , F.DP06 
         , F.DP07 
         , F.DP08 
         , F.DP09 
         , F.DP10 
         , F.DP11 
         , F.DP12 
         , F.DP13 
         , F.DP14 
         , F.DP15 
         , F.DP16 
         , CASE WHEN ( T.MediumLabel IS NULL OR LTRIM( RTRIM( T.MediumLabel)) = '' ) THEN 'Time_' + CONVERT( VARCHAR(10), F.TimeID ) + '_' + CONVERT( VARCHAR(10), F.TimeLVL ) ELSE T.MediumLabel END vwTimeMediumLabel 
         , CASE WHEN ( G.MediumLabel IS NULL OR LTRIM( RTRIM( G.MediumLabel)) = '' ) THEN 'Geog_' + CONVERT( VARCHAR(10), F.GeogID ) + '_' + CONVERT( VARCHAR(10), F.GeogLVL ) ELSE G.MediumLabel END vwGeogMediumLabel 
         , CASE WHEN ( P.MediumLabel IS NULL OR LTRIM( RTRIM( P.MediumLabel)) = '' ) THEN 'Prod_' + CONVERT( VARCHAR(10), F.ProdID ) + '_' + CONVERT( VARCHAR(10), F.ProdLVL ) ELSE P.MediumLabel END vwProdMediumLabel 
         , CASE WHEN ( C.MediumLabel IS NULL OR LTRIM( RTRIM( C.MediumLabel)) = '' ) THEN 'Cust_' + CONVERT( VARCHAR(10), F.CustID ) + '_' + CONVERT( VARCHAR(10), F.CustLVL ) ELSE C.MediumLabel END vwCustMediumLabel 
         , CASE WHEN ( O.MediumLabel IS NULL OR LTRIM( RTRIM( O.MediumLabel)) = '' ) THEN 'Other_' + CONVERT( VARCHAR(10), F.OtherID ) + '_' + CONVERT( VARCHAR(10), F.OtherLVL ) ELSE O.MediumLabel END vwOtherMediumLabel 
         , M.vw_MetricName vwMetricName 
         , M.vw_MetricID vwMetricId 
         , M.vw_MetricCalc vwMetricCalc 
         , M.vw_MetricFormat vwMetricFormat 
         , M.vw_MetricPrecision vwMetricPrecision 
 FROM      FORTDataStore F 
           INNER JOIN dbo.t_LU_FV_DIM_Metric M 
           ON F.ValueSetLVL = M.ValueSetLevel 
           AND F.ValueSetID = M.ValueSetID 
           INNER JOIN dbo.t_LU_FV_DIM_Time T 
           ON F.TimeLVL = T.vw_TimeLVL 
           AND F.TimeID = T.vw_TimeID_Data 
           INNER JOIN dbo.t_LU_FV_DIM_Geog G  
           ON F.GeogLVL = G.vw_GeogLVL 
           AND F.GeogID = G.vw_GeogID  
           LEFT OUTER JOIN dbo.t_LU_FV_DIM_Prod P  
           ON F.ProdLVL = P.vw_ProdLVL 
           AND F.ProdID = P.vw_ProdID  
           LEFT OUTER JOIN dbo.t_LU_FV_DIM_Cust C  
           ON F.CustLVL = C.vw_CustLVL 
           AND F.CustID = C.vw_CustID  
           LEFT OUTER JOIN dbo.t_LU_FV_DIM_Other O  
           ON F.OtherLVL = O.vw_OtherLVL 
           AND F.OtherID = O.vw_OtherID  
WHERE ( 
 ( M.vw_MetricID = 26 ) 
 AND ( 
 ( T.vw_TimeID_Key = 100 AND T.vw_TimeLVL = 60 ) 

 ) 

 AND ( 
 ( F.GeogId = 31 AND F.GeogLVL = 1020 ) 
 OR  ( F.GeogId = 32 AND F.GeogLVL = 1020 ) 
 OR  ( F.GeogId = 33 AND F.GeogLVL = 1020 ) 
 OR  ( F.GeogId = 34 AND F.GeogLVL = 1020 ) 
 OR  ( F.GeogId = 35 AND F.GeogLVL = 1020 ) 
 OR  ( F.GeogId = 36 AND F.GeogLVL = 1020 ) 
 OR  ( F.GeogId = 37 AND F.GeogLVL = 1020 ) 
 OR  ( F.GeogId = 38 AND F.GeogLVL = 1020 ) 
 OR  ( F.GeogId = 50 AND F.GeogLVL = 1020 ) 
 OR  ( F.GeogId = 96 AND F.GeogLVL = 1020 ) 
 OR  ( F.GeogId = 99 AND F.GeogLVL = 1020 ) 
 OR  ( F.GeogId = 4 AND F.GeogLVL = 20 ) 
 OR  ( F.GeogId = 12 AND F.GeogLVL = 20 ) 
 OR  ( F.GeogId = 13 AND F.GeogLVL = 20 ) 
 OR  ( F.GeogId = 329 AND F.GeogLVL = 20 ) 
 OR  ( F.GeogId = 337 AND F.GeogLVL = 20 ) 
 OR  ( F.GeogId = 611 AND F.GeogLVL = 20 ) 
 OR  ( F.GeogId = 1012 AND F.GeogLVL = 20 ) 
 OR  ( F.GeogId = 1063 AND F.GeogLVL = 20 ) 
 OR  ( F.GeogId = 1106 AND F.GeogLVL = 20 ) 
 OR  ( F.GeogId = 1151 AND F.GeogLVL = 20 ) 
 OR  ( F.GeogId = 1463 AND F.GeogLVL = 20 ) 
 OR  ( F.GeogId = 330 AND F.GeogLVL = 20 ) 
 OR  ( F.GeogId = 34 AND F.GeogLVL = 1020 ) 

 ) 

 AND ( F.ProdId = 0 AND F.ProdLVL = 0 ) 

 AND ( F.CustId = 0 AND F.CustLVL = 0 ) 

 AND ( F.OtherId = 0 AND F.OtherLVL = 0 ) 

)

select * --max(TimeID)
  from dbo.FORTDataStore
 where TimeLvl = 40
   and TimeID = 2011034

select * 
  from dbo.FORTDataStore
 where ValueSetLvl = 20
   and ValueSetID = 

 where TimeLvl = 20 
   and timeid = 20100222

exec dbo.Util_MissingIndexes