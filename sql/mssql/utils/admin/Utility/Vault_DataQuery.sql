--CREATE NONCLUSTERED INDEX [DataStore_ValueSetIdx] ON [dbo].[FORTDataStore] 
--(
--	[ValueSetLVL] ASC
--    , [ValueSetID] ASC
--    ,TimeLvl ASC
--    ,TimeID  DESC
--)
--INCLUDE ( 
--        [GeogLVL],
--        [GeogID],
--        [ProdLVL],
--        [ProdID],
--        [CustLVL],
--        [CustID],
--        [OtherLVL],
--        [OtherID]
--) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF
--, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Group00]
----)WITH (STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Group00]
--GO
--
--drop index [DataStore_ValueSetTimeLvlIdx] ON [dbo].[FORTDataStore] 
-- 
--CREATE NONCLUSTERED INDEX [DataStore_ValueSetTimeLvlIdx] ON [dbo].[FORTDataStore] 
--(
--	[ValueSetLVL] ASC,
--	[ValueSetID] ASC,
--	[TimeLVL] ASC
--)
--INCLUDE ( [TimeID],
--        [GeogLVL],
--        [GeogID],
--        [ProdLVL],
--        [ProdID],
--        [CustLVL],
--        [CustID],
--        [OtherLVL],
--        [OtherID]
--) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF
--, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Group00]

CREATE NONCLUSTERED INDEX [DataStore_ValueSetIdx] ON [dbo].[FORTDataStore] 
(
	[ValueSetLVL] ASC,
	[ValueSetID] ASC
)
INCLUDE ( 
        [TimeLvl],
        [TimeID],
        [GeogLVL],
        [GeogID],
        [ProdLVL],
        [ProdID],
        [CustLVL],
        [CustID],
        [OtherLVL],
        [OtherID]
) 
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF
, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Group00]

CREATE NONCLUSTERED INDEX [DataStore_TimeIdx] ON [dbo].[FORTDataStore] 
(
        [TimeLvl] ASC,
        [TimeID] ASC
)
--INCLUDE ( 
--	    [ValueSetLVL] ,
--	    [ValueSetID] ,
--        [GeogLVL],
--        [GeogID],
--        [ProdLVL],
--        [ProdID],
--        [CustLVL],
--        [CustID],
--        [OtherLVL],
--        [OtherID]
--) 
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF
, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Group00]

SET STATISTICS TIME ON
SET STATISTICS IO ON
SET STATISTICS PROFILE ON
SET STATISTICS XML ON
SET SHOWPLAN_ALL ON 
SET SHOWPLAN_TEXT ON
SET SHOWPLAN_XML ON

SET STATISTICS PROFILE OFF
GO

SET SHOWPLAN_ALL OFF 
GO

select *
  from sys.dm_db_missing_index_group_stats

select *
  from sys.dm_db_missing_index_groups

select *
  from sys.dm_db_missing_index_details

select *
  from sys.dm_db_missing_index_columns

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
 FROM      dbo.FORTDataStore F 
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
        ( M.vw_MetricID = 28 ) 
    AND ( 
            ( T.vw_TimeLVL = 60 AND T.vw_TimeID_Key = 100 ) 
        ) 
    AND ( 
            ( F.GeogId = 1 AND F.GeogLVL = 120 ) 
        OR  ( F.GeogId = 5 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 6 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 8 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 10 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 14 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 15 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 17 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 245 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 281 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 330 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 604 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 861 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 982 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 983 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 984 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 987 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 1000 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 1055 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 1195 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 1450 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 11 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 1443 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 43 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 522 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 540 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 7 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 9 AND F.GeogLVL = 20 ) 
        ) 
    AND ( 
            ( F.ProdId = 0 AND F.ProdLVL = 0 ) 
        ) 
    AND ( 
            ( F.CustId = 0 AND F.CustLVL = 0 ) 
        ) 
    AND ( 
            ( F.OtherId = 0 AND F.OtherLVL = 0 ) 
        ) 
    )
 OR ( 
        ( M.vw_MetricID = 29 ) 
    AND ( 
            ( T.vw_TimeID_Key = 100 AND T.vw_TimeLVL = 60 ) 
        ) 
    AND ( 
            ( F.GeogId = 1 AND F.GeogLVL = 120 ) 
        OR  ( F.GeogId = 5 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 6 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 8 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 10 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 14 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 15 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 17 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 245 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 281 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 330 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 604 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 861 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 982 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 983 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 984 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 987 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 1000 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 1055 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 1195 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 1450 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 11 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 1443 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 43 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 522 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 540 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 7 AND F.GeogLVL = 20 ) 
        OR  ( F.GeogId = 9 AND F.GeogLVL = 20 ) 
        ) 
    AND ( 
            ( F.ProdId = 0 AND F.ProdLVL = 0 ) 
        ) 
    AND ( 
            ( F.CustId = 0 AND F.CustLVL = 0 ) 
        ) 
    AND ( F.OtherId = 0 AND F.OtherLVL = 0 ) 
        )
    OR ( 
            ( M.vw_MetricID = 42 ) 
        AND ( 
                ( T.vw_TimeID_Key = 100 AND T.vw_TimeLVL = 60 ) 
            ) 
        AND ( 
                ( F.GeogId = 1 AND F.GeogLVL = 120 ) 
            OR  ( F.GeogId = 5 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 6 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 8 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 10 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 14 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 15 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 17 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 245 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 281 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 330 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 604 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 861 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 982 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 983 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 984 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 987 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 1000 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 1055 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 1195 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 1450 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 11 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 1443 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 43 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 522 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 540 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 7 AND F.GeogLVL = 20 ) 
            OR  ( F.GeogId = 9 AND F.GeogLVL = 20 ) 
            ) 
        AND ( 
                ( F.ProdId = 0 AND F.ProdLVL = 0 ) 
            ) 
        AND ( 
                ( F.CustId = 0 AND F.CustLVL = 0 ) 
            ) 
        AND ( F.OtherId = 0 AND F.OtherLVL = 0 ) 
            )
        OR ( 
                ( M.vw_MetricID = 1 ) 
            AND ( 
                    ( T.vw_TimeID_Key = 100 AND T.vw_TimeLVL = 60 ) 
                ) 
            AND ( 
                    ( F.GeogId = 1 AND F.GeogLVL = 120 ) 
                OR  ( F.GeogId = 5 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 6 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 8 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 10 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 14 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 15 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 17 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 245 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 281 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 330 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 604 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 861 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 982 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 983 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 984 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 987 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 1000 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 1055 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 1195 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 1450 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 11 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 1443 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 43 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 522 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 540 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 7 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 9 AND F.GeogLVL = 20 ) 
                ) 
            AND ( 
                    ( F.ProdId = 0 AND F.ProdLVL = 0 ) 
                ) 
            AND ( 
                    ( F.CustId = 0 AND F.CustLVL = 0 ) 
                ) 
            AND ( 
                    ( F.OtherId = 0 AND F.OtherLVL = 0 ) 
                ) 
            )
        OR ( 
                ( M.vw_MetricID = 54 ) 
            AND ( 
                    ( T.vw_TimeID_Key = 100 AND T.vw_TimeLVL = 60 ) 
                ) 
            AND ( 
                    ( F.GeogId = 1 AND F.GeogLVL = 120 ) 
                OR  ( F.GeogId = 5 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 6 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 8 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 10 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 14 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 15 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 17 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 245 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 281 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 330 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 604 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 861 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 982 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 983 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 984 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 987 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 1000 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 1055 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 1195 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 1450 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 11 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 1443 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 43 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 522 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 540 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 7 AND F.GeogLVL = 20 ) 
                OR  ( F.GeogId = 9 AND F.GeogLVL = 20 ) 
                ) 
            AND ( 
                    ( F.ProdId = 0 AND F.ProdLVL = 0 ) 
                ) 
            AND ( 
                    ( F.CustId = 0 AND F.CustLVL = 0 ) 
                ) 
            AND ( 
                    ( F.OtherId = 0 AND F.OtherLVL = 0 ) 
                ) 
            )
