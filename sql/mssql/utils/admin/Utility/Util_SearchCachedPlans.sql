CREATE PROCEDURE [dbo].[Util_SearchCachedPlans] 
  	@StringToSearchFor      VARCHAR(255) 
AS 
/*---------------------------------------------------------------------- 
Purpose: Inspects cached plans for a given string. 
------------------------------------------------------------------------ 
Parameters: @StringToSearchFor - string to search for e.g. '%&lt;MissingIndexes&gt;%'. 
Revision History: 
  		 09/11/2009   Initial version 
Example Usage: 
1. exec dbo.Util_SearchCachedPlans '%&lt;MissingIndexes&gt;%' 
2. exec dbo.Util_SearchCachedPlans '%&lt;ColumnsWithNoStatistics&gt;%' 
3. exec dbo.Util_SearchCachedPlans '%&lt;TableScan%'      
4. exec dbo.Util_SearchCachedPlans '%CREATE PROC%MessageWrite%'    
-----------------------------------------------------------------------*/ 
BEGIN 
  	-- Do not lock anything, and do not get held up by any locks. 
  	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

  	SELECT TOP 20 
  		  st.text AS [SQLText] 
  		  , cp.cacheobjtype 
  		  , cp.objtype 
  		  , DB_NAME(st.dbid)AS [DatabaseName] 
  		  , cp.usecounts AS [PlanUsage] 
  		  , qp.query_plan 
  	FROM sys.dm_exec_cached_plans cp 
  	CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st 
  	CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp 
  	WHERE CAST(qp.query_plan AS NVARCHAR(MAX)) LIKE @StringToSearchFor 
  	ORDER BY  cp.usecounts DESC 
END 
