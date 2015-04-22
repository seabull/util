-- vim: sw=4 ts=4 et ft=sql: 

--Replace view PRODBBYMEADHOCVWS.RASC_DBPerf_Header_Wk as
--	locking row for access
--Select 
--	 case when UserName = 'RASC_FORT_BCH' then 'Batch' 
--	 when r.Calndr_DT < 1080618 and UserName = 'a035767' then 'Batch' 
--		else 'Adhoc' end as UserType
--	,Fisc_Wk_of_Mth_ID as Fisc_Wk_ID
--	,Fisc_Mth_Abbr_NM ||' '|| Fisc_Wk_Of_Mth_NM AS Fisc_wk_Nm
--	,Fisc_Mth_ID as  Fisc_Mth_ID
--	,Fisc_Mth_Abbr_NM as  Fisc_Mth_Nm
--	,case 
--		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 60000 and 100000 then 2
--		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 100000 and 190000 then 3
--		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM > 190000 then 6
--		else 4 end as ETL_Period
--	,case 
--	 	when ETL_Period = 1 then 3.92
--	 	when ETL_Period = 1 then 2.96
--	 	when ETL_Period = 1 then 0.73
--	 	else 0.22 end as TPH_Cost
--	,SQLType
--	,Sum(Total_CPU) as Total_CPU
--	,Sum(Total_IO) as Total_IO
--	,Count(*) as SQL_Count
--	,Sum(Total_CPU)*0.002702 as Total_TPH
--	,Total_TPH * TPH_Cost as Run_Cost
--  From PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
--   join prodbbyrptvws.bby_fiscal_calendar d
--	on r.Calndr_DT=d.Calndr_DT
--Group by 1,2,3,4,5,6
--Select 
--	 case when UserName in('RASC_FORT_BCH','a035767') then 'Batch' 
--		else 'Adhoc' end as UserType
--	,Fisc_Wk_of_Mth_ID as Fisc_Wk_ID
--	,Fisc_Mth_Abbr_NM ||' '|| Fisc_Wk_Of_Mth_NM AS Fisc_wk_Nm
--	,case 
--	 	when Calndr_TM < 60000 then 1
--	 	when Calndr_TM between 60000 and 100000 then 2
--	 	when Calndr_TM between 100000 and 190000 then 3
--	 	else 6 end as ETL_Period
--	,case 
--	 	when ETL_Period = 1 then 3.92
--	 	when ETL_Period = 1 then 2.96
--	 	when ETL_Period = 1 then 0.73
--	 	else 0.22 end as TPH_Cost
--	,SQLType
--	,Sum(Total_CPU) as Total_CPU
--	,Sum(Total_IO) as Total_IO
--	,Count(*) as SQL_Count
--	,Sum(Total_CPU)*0.002702 as Total_TPH
--	,Total_TPH * TPH_Cost as Run_Cost
--  From PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
--   join prodbbyrptvws.bby_fiscal_calendar d
--	on r.Calndr_DT=d.Calndr_DT
--Group by 1,2,3,4,5,6


--Submitted by RASC SqlExplorer a035767 - SqlExplorer Application
--Select 
--	case when UserName ='RASC_FORT_BCH' 
--		then 'ETL BATCH'
--		else 'Adhoc' 
--	end as UserType
--	,Fisc_Wk_of_Mth_ID
--	,case when Calndr_TM < 60000 then 1
--		when Calndr_TM between 60000 and 100000 then 2
--		when Calndr_TM between 100000 and 190000 then 3
--		else 6 
--	end as ETL_Period
--	,case 
--		when ETL_Period = 1 then 3.92
--		when ETL_Period = 1 then 2.96
--		when ETL_Period = 1 then 0.73
--		else 0.22
--	end as TPH_Cost
--	,SQLType
--	,Sum(Total_CPU) as Total_CPU
--	,Sum(Total_IO) as Total_IO
--	,Count(*) as SQL_Count
--	,Sum(Total_CPU)*0.002702 as Total_TPH
--	,Total_TPH * TPH_Cost as Run_Cost
--  From PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
--	join prodbbyrptvws.bby_fiscal_calendar d
--		on r.Calndr_DT=d.Calndr_DT
-- where d.Fisc_Mth_ID in (200904,200905,200906)
--Group by 1,2,3,4,5
--;

	Create View PRODBBYMEADHOCVWS.RASC_DBPerf_Detail_v
	    As Locking Row For Access
	Select r.Calndr_Dt                     
	     , Calndr_Tm                   
	        ,case when Calndr_TM < 60000 then 1
	            when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 60000 and 100000 then 2
	            when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 100000 and 190000 then 3
	            when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM > 190000 then 4
	            else 6 
	        end as ETL_Period    
	        ,Fisc_Day_of_Wk_Nbr
	        ,Fisc_Wk_of_Mth_ID as Fisc_Wk_ID
	        ,(d.Fisc_Yr_ID*100) + d.Fisc_Wk_of_Yr_Nbr as Fisc_Wk_Yr_ID
	        ,Fisc_Mth_Abbr_NM ||' '|| Fisc_Wk_Of_Mth_NM AS Fisc_wk_Nm
	        ,Fisc_Mth_ID as  Fisc_Mth_ID
	        ,Fisc_Mth_Abbr_NM as  Fisc_Mth_Nm       
	        ,Fisc_Yr_ID
	        ,SQLType                       
	        ,SQLIdText                     
	        ,ActionId                      
	        ,AlertId                       
	        ,JobId                         
	        ,WaveId                        
	        ,SQLId                         
	        ,UserName                     
	        ,case when UserName = 'RASC_FORT_BCH' then 'Batch' 
	            when r.Calndr_DT < 1080618 and UserName = 'a035767' then 'Batch'   
                when r.Calndr_DT < 1081201 and r.Calndr_DT > 1081119 and UserName = 'CN3649' then 'Batch' 
	            else 'Adhoc' end as UserType            
	        ,SessionId                     
	        ,RequestNum                    
	        ,Total_CPU                     
	        ,Total_IO      
	        --,Total_CPU*0.0027 as TPH
	        ,Total_CPU*0.0019874 as TPH
	        ,case 
	            when ETL_Period = 1 then 3.92
	            when ETL_Period = 2 then 2.96
	            when ETL_Period = 3 then 0.73
	            when ETL_Period = 4 then 0.73
	            else 0.22 
	        end as TPH_ETL_Period_Cost    
	        ,cast(TPH * TPH_ETL_Period_Cost as decimal(16,2)) as TPH_Cost
	From PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
	join prodbbyrptvws.bby_fiscal_calendar d
	    on r.Calndr_DT=d.Calndr_DT
	;

select Calndr_dt
        ,userType
        ,ETL_Period
        ,Fisc_Day_of_Wk_Nbr
        ,Fisc_wk_Nm
        ,jobID
        ,sum(TPH) TPH
        ,sum(TPH_Cost) TPH_Cost
  from PRODBBYMEADHOCVWS.RASC_DBPerf_Detail_v
 where userType = 'Batch'
group by 1,2,3,4,5,6

replace view prodbbymeadhocvws.utilization_reporting
	as 
	locking row for access
Select
	fisc_mth_id
	,cubelvl
	,cubeid
	,reporttype
	,category
	,projectname
	,reportname
	,url
	,clicks
	,rtl_clicks
	,rtl_clicks_pct
	,days
	,clicks_per_day
	,substr(cast(rundt as date format 'MM/DD/YYYY' ),1,10 ) as rundt
	,sum(clicks) over (partition by reportname, projectname, reporttype, cubeid, cubelvl 
				order by reportname, projectname, reporttype, cubeid, cubelvl, fisc_mth_id ASC 
				ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
	as clicks1
	,sum(clicks) over (partition by reportname, projectname, reporttype, cubeid, cubelvl order by reportname, projectname, reporttype, cubeid, cubelvl, fisc_mth_id ASC  ROWS BETWEEN 2 PRECEDING AND 2 PRECEDING) as clicks2
	,case when CubeLVL = 1000020 then 'Company'
		when CubeLVL = 1020 then 'Territory'
		when CubeLVL = 120 then 'District'
		when CubeLVL = 20 then 'Store' 
	end as Geog1
 from prodbbymeadhocdb.vert00200_utilization u
where cubelvl = 1000020;


--
select 
	sum(cputime) CPUTime
	,sum(DiskIO) DiskIO
	,sum(CPUTime) * 0.002702 TPH
  from DBC.AmpUsage
 where Username = User;

select
	case when UserName in('RASC_FORT_BCH','a035767') then 'Batch' 
		else 'Adhoc' 
	end UserType
	,Calndr_dt
	,case when Calndr_TM < 60000 then 1
		when Calndr_TM between 60000 and 100000 then 2
		when Calndr_TM between 100000 and 190000 then 3
		else 6 
	end ETL_Period
	,case 
		when ETL_Period = 1 then 3.92
		when ETL_Period = 1 then 2.96
		when ETL_Period = 1 then 0.73
		else 0.22
	end as TPH_Cost
	,SQLType
	,Sum(Total_CPU) Total_CPU
	,Sum(Total_IO)  Total_IO
	,Count(*) 	SQL_Count
	,Sum(Total_CPU)*0.002702 Total_TPH
	,Total_TPH * TPH_Cost 	Run_Cost
  from PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
 where Calndr_dt > current_date - 5
group by UserType
	,Calndr_dt
	,ETL_Period
	,TPH_Cost
	,SQLType
order by etl_period
	,6 desc
	,7 desc
	,8 desc
	,UserType
;

--
-- Aggregate by period 2
--
select
	Calndr_dt
	,etl_period
	,sum(Total_CPU) CPU_Total
	,sum(Total_TPH) TPH_Total
  from
(
select
	case when UserName in('RASC_FORT_BCH','a035767') then 'Batch' 
		else 'Adhoc' 
	end UserType
	,Calndr_dt
	,case when Calndr_TM < 60000 then 1
		when Calndr_TM between 60000 and 100000 then 2
		when Calndr_TM between 100000 and 190000 then 3
		else 6 
	end ETL_Period
	,case 
		when ETL_Period = 1 then 3.92
		when ETL_Period = 1 then 2.96
		when ETL_Period = 1 then 0.73
		else 0.22
	end as TPH_Cost
	,SQLType
	,Sum(Total_CPU) Total_CPU
	,Sum(Total_IO)  Total_IO
	,Count(*) 	SQL_Count
	,Sum(Total_CPU)*0.002702 Total_TPH
	,Total_TPH * TPH_Cost 	Run_Cost
  from PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
 where Calndr_dt > current_date - 5
group by UserType
	,Calndr_dt
	,ETL_Period
	,TPH_Cost
	,SQLType
) v
 where v.etl_period = 2
group by 
	Calndr_dt
	,etl_period;

replace view prodbbymeadhocvws.rasc_dbperf_fort_job_wave_sql
as
(
select
	f.JobId
	,f.WaveId
	,f.SqlId
	,f.SqlName
	,r.Calndr_Dt
	,r.Calndr_Tm
	,f.startDT
	,f.endDT
	,r.SQLType
	,r.SQLIdText
	,r.Total_CPU
	,r.Total_IO
	,r.UserName
	,r.SessionId
  from prodbbymeadhocdb.rasc_dbperf_Detail r
	,prodbbymeadhocdb.fort_job_wave_SQL f
 where r.JobId = f.JobId
   and r.WaveId = f.WaveId
   and r.SqlId  = f.SqlId
);

select
	JobId
	,WaveId
	,SqlId
	,SqlName
	,count(unique Calndr_Dt) Dt_Cnt
	,Sum(Total_CPU) Total_CPU
	,Sum(Total_IO)  Total_IO
	--,Count(*) 	SQL_Count
	,Sum(Total_CPU)*0.002702 Total_TPH
	,Sum(Total_CPU)*0.002702/count(unique Calndr_Dt) Avg_TPH
  from prodbbymeadhocvws.rasc_dbperf_fort_job_wave_sql
 where Calndr_Dt > Current_Date - 15
group by 
	JobId
	,WaveId
	,SqlId
	,SqlName
order by Total_TPH desc;
--(
--select
--	f.JobId
--	,f.WaveId
--	,f.SqlId
--	,f.SqlName
--	,r.Calndr_Dt
--	,r.Calndr_Tm
--	,r.SQLType
--	,r.SQLIdText
--	,r.Total_CPU
--	,r.Total_IO
--	,r.UserName
--	,r.SessionId
--  from prodbbymeadhocdb.rasc_dbperf_Detail r
--	,prodbbymeadhocdb.fort_job_wave_SQL f
-- where r.JobId = f.JobId
--   and r.WaveId = f.WaveId
--   and r.SqlId  = f.SqlId
--) s

replace view prodbbymeadhocvws.rasc_DBPerf_Header_Dt14
	as
	locking row for access
select
	--case when UserName in('RASC_FORT_BCH','a035767') then 'Batch' 
	case when UserName = 'RASC_FORT_BCH' then 'Batch' 
	when r.Calndr_DT < 1080618 and UserName = 'a035767' then 'Batch' 
		else 'Adhoc' 
	end UserType
	,JobId
	,WaveId
	,SqlID
	--,Calndr_dt
	,SQLType
	,(sum(case when Current_date - Calndr_dt < 15 then Total_CPU else 0 end)*0.002702)  TPH_14Day_Total
	,(sum(case when Current_date - Calndr_dt < 8  then Total_CPU else 0 end)*0.002702)  TPH_7Day_Total
	,(sum(case when Current_date - Calndr_dt < 4  then Total_CPU else 0 end)*0.002702)  TPH_3Day_Total
	,sum(case when Current_date - Calndr_dt < 2  then Total_CPU else 0 end)*0.002702    TPH_1Day_Total
	--,Sum(Total_CPU)*0.002702 Total_TPH
  from PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
 where WaveId is not null
   and JobId is not null
   and Calndr_dt > Current_date - 16
group by 
	JobId
	,WaveId
	,SqlID
	--,Calndr_dt
	,UserType
	,SQLType

update prodbbymeadhocdb.fort_job_wave_sql
  from prodbbymeadhocvws.rasc_DBPerf_Header_Dt14 r
   set TPH_14Day_Avg  = r.TPH_14Day_Avg
	,TPH_7Day_Avg = r.TPH_7Day_Avg
	,TPH_3Day_Avg = r.TPH_3Day_Avg
	,TPH_1Day_Avg = r.TPH_1Day_Avg
 where r.JobId = prodbbymeadhocdb.fort_job_wave_sql.JobId
   and r.WaveId = prodbbymeadhocdb.fort_job_wave_sql.WaveId
   and r.SqlId  = prodbbymeadhocdb.fort_job_wave_sql.SqlId
   and r.userType = 'Batch'
   and endDt > current_date - 15;


--create view prodbbymeadhocvws.rasc_DBPerf_Header_Period_Dt14
replace view prodbbymeadhocvws.rasc_DBPerf_Header_Period_Dt14
	as
	locking row for access
select
	case when UserName = 'RASC_FORT_BCH' then 'Batch' 
	when r.Calndr_DT < 1080618 and UserName = 'a035767' then 'Batch' 
		else 'Adhoc' 
	end UserType
	,case 
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM < 60000 then 1
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 60000 and 100000 then 2
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 100000 and 190000 then 3
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM > 190000 then 6
		else 4 
	end as ETL_Period
	,JobId
	,WaveId
	,SqlID
	,SQLType
	,(sum(case when Current_date - 2 - 15 < r.Calndr_dt and r.Calndr_dt < Current_date - 2 then Total_CPU else 0 end)*0.002702)  TPH_14Day_Total
	,(sum(case when Current_date - 2 - 8  < r.Calndr_dt and r.Calndr_dt < Current_date - 2 then Total_CPU else 0 end)*0.002702)  TPH_7Day_Total
	,(sum(case when Current_date - 2 - 4  < r.Calndr_dt and r.Calndr_dt < Current_date - 2 then Total_CPU else 0 end)*0.002702)  TPH_3Day_Total
	,sum(case when  Current_date - 2 - 2  < r.Calndr_dt and r.Calndr_dt < Current_date - 2 then Total_CPU else 0 end)*0.002702   TPH_1Day_Total
    ,case 
        when ETL_Period = 1 then 3.92
        when ETL_Period = 2 then 2.96
        when ETL_Period = 3 then 0.73
        when ETL_Period = 4 then 0.73
        else 0.22 
    end TPH_ETL_Period_Cost 
    ,cast(Total_CPU * 0.0027 * TPH_ETL_Period_Cost as decimal(16,2)) as TPH_Cost
	--,Sum(Total_CPU)*0.002702 Total_TPH
  from PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
join prodbbyrptvws.bby_fiscal_calendar c
	on r.Calndr_DT=c.Calndr_DT
 where WaveId is not null
   and JobId is not null
   and r.Calndr_dt > Current_date - 16
group by 
	JobId
	,WaveId
	,SqlID
	,ETL_Period
    ,TPH_Cost
	--,Calndr_dt
	,UserType
	,SQLType;


replace macro prodbbymeadhocdb.fort_job_wave_sql_tph14day_ins 
	(untilDt (Date, Format 'yyyy-mm-dd'))
	as
(
	-- This macro updates TPH avg for the past 14, 7, 3 and 1 day(s)
	-- The view prodbbymeadhocvws.rasc_DBPerf_Header_Dt14 is similar
	-- to the derivative table used in the following update stmt only
	-- with current_date as untilDt
	update prodbbymeadhocdb.fort_job_wave_sql
	--  from prodbbymeadhocvws.rasc_DBPerf_Header_Dt14 r
	from
		(select
			--case when UserName in('RASC_FORT_BCH','a035767') then 'Batch' 
			case when UserName in('RASC_FORT_BCH') then 'Batch' 
				else 'Adhoc' 
			end UserType
			,JobId
			,WaveId
			,SqlID
			,SQLType
			,(sum(case when :untilDt - 15 < Calndr_dt and Calndr_dt < :untilDt then Total_CPU else 0 end)*0.002702)/14 TPH_14Day_Avg
			,(sum(case when :untilDt - 8  < Calndr_dt and Calndr_dt < :untilDt then Total_CPU else 0 end)*0.002702)/7  TPH_7Day_Avg
			,(sum(case when :untilDt - 4  < Calndr_dt and Calndr_dt < :untilDt then Total_CPU else 0 end)*0.002702)/3  TPH_3Day_Avg
			,sum(case when  :untilDt - 2  < Calndr_dt and Calndr_dt < :untilDt then Total_CPU else 0 end)*0.002702     TPH_1Day_Avg
		  from PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
		 where WaveId is not null
		   and JobId is not null
		   and Calndr_dt > :untilDt - 15
		group by 
			JobId
			,WaveId
			,SqlID
			,UserType
			,SQLType
		) r
	   set TPH_14Day_Avg  = r.TPH_14Day_Avg
		,TPH_7Day_Avg = r.TPH_7Day_Avg
		,TPH_3Day_Avg = r.TPH_3Day_Avg
		,TPH_1Day_Avg = r.TPH_1Day_Avg
	 where r.JobId = prodbbymeadhocdb.fort_job_wave_sql.JobId
	   and r.WaveId = prodbbymeadhocdb.fort_job_wave_sql.WaveId
	   and r.SqlId  = prodbbymeadhocdb.fort_job_wave_sql.SqlId
	   and r.userType = 'Batch'
	   and endDt > :untilDt - 15;
);

replace macro prodbbymeadhocdb.fort_job_tph14day_ins 
	(untilDt (Date, Format 'yyyy-mm-dd'))
	as
(
	-- This macro updates TPH avg for the past 14, 7, 3 and 1 day(s)
	-- in fort_job table
	update prodbbymeadhocdb.fort_job
	  from
		(select
			--case when UserName in('RASC_FORT_BCH','a035767') then 'Batch' 
			case when UserName in('RASC_FORT_BCH') then 'Batch' 
				else 'Adhoc' 
			end UserType
			,JobId
			,(sum(case when :untilDt - 15 < Calndr_dt and Calndr_dt < :untilDt then Total_CPU else 0 end)*0.002702)/14 TPH_14Day_Avg
			,(sum(case when :untilDt - 8  < Calndr_dt and Calndr_dt < :untilDt then Total_CPU else 0 end)*0.002702)/7  TPH_7Day_Avg
			,(sum(case when :untilDt - 4  < Calndr_dt and Calndr_dt < :untilDt then Total_CPU else 0 end)*0.002702)/3  TPH_3Day_Avg
			,sum(case when  :untilDt - 2  < Calndr_dt and Calndr_dt < :untilDt then Total_CPU else 0 end)*0.002702     TPH_1Day_Avg
		  from PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
		 where JobId is not null
		   and Calndr_dt > :untilDt - 15
		group by 
			JobId
			,UserType
		) r
	   set TPH_14Day_Avg  = r.TPH_14Day_Avg
		,TPH_7Day_Avg = r.TPH_7Day_Avg
		,TPH_3Day_Avg = r.TPH_3Day_Avg
		,TPH_1Day_Avg = r.TPH_1Day_Avg
	 where r.JobId = prodbbymeadhocdb.fort_job.JobId
	   and r.userType = 'Batch'
	   and endDt > :untilDt - 15;
);

--
-- Query to generate report by fort job TPerfHour
--
select
	x.jobID
	,x.ETL_Period
	,100*TPH14D_Job_Total/TPH14D_Total 	(Format 'ZZ9.9999%%')	TPH14D_Job_Pct
	,100*TPH7D_Job_Total/TPH7D_Total	(Format 'ZZ9.9999%%')	TPH7D_Job_Pct
	,100*TPH3D_Job_Total/TPH3D_Total	(Format 'ZZ9.9999%%')	TPH3D_Job_Pct
	,rank() over (partition by x.ETL_Period order by TPH7D_Job_Total desc) rankInPeriod
	,TPH14D_Total/14 TPH14D_AVG
	,TPH7D_Total/7 TPH7D_AVG
	,TPH3D_Total/3 TPH3D_AVG
	,jobName
	--,jobDesc
  from
(
	select
		--UserType
		--,
		unique
		jobID
		,ETL_Period
		,sum(TPH_14Day_Total) over (partition by jobID) TPH14D_Job_Total
		,sum(TPH_7Day_Total)  over (partition by jobID) TPH7D_Job_Total
		,sum(TPH_3Day_Total)  over (partition by jobID) TPH3D_Job_Total
		,sum(TPH_14Day_Total) over (partition by ETL_Period) TPH14D_Period_Total
		,sum(TPH_7Day_Total)  over (partition by ETL_Period) TPH7D_Period_Total
		,sum(TPH_3Day_Total)  over (partition by ETL_Period) TPH3D_Period_Total
		,sum(TPH_14Day_Total) over () TPH14D_Total
		,sum(TPH_7Day_Total)  over () TPH7D_Total
		,sum(TPH_3Day_Total)  over () TPH3D_Total
	  from prodbbymeadhocvws.rasc_DBPerf_Header_Period_Dt14
	 where UserType='Batch'
) x
left join PRODBBYMEADHOCDB.Fort_Job j
	on x.jobID = j.jobID
order by 4 desc, 3 desc, 5 desc, 2

-- Another version
--create view prodbbymeadhocvws.rasc_DBPerf_JobAvg_14Day
replace view prodbbymeadhocvws.rasc_DBPerf_JobAvg_14Day
	as
	locking row for access
select
	x.jobID
	,ETL_1 || ETL_2 || ETL_3 || ETL_4 || ETL_6 ETL_Periods
	,TPH14D_Job_Pct
	,TPH7D_Job_Pct
	,TPH3D_Job_Pct
	--,rankInPeriod
    ,TPH14D_Job_CostTotal
    ,TPH7D_Job_CostTotal
    ,TPH3D_Job_CostTotal
	,TPH14D_AVG
	,TPH7D_AVG
	,TPH3D_AVG
	,jobName
	--,jobDesc
  from
  (
      select
    	jobID
    	,max(ETL_01) ETL_1
    	,max(ETL_02) ETL_2
    	,max(ETL_03) ETL_3
    	,max(ETL_04) ETL_4
    	,max(ETL_06) ETL_6
    	,TPH14D_Job_CostTotal 		TPH14D_Job_CostTotal
    	,TPH7D_Job_CostTotal    	TPH7D_Job_CostTotal
    	,TPH3D_Job_CostTotal    	TPH3D_Job_CostTotal
    	,100*TPH14D_Job_CostTotal/TPH14D_Total 	(Format 'ZZ9.9999%%')	TPH14D_Job_Pct
    	,100*TPH7D_Job_CostTotal/TPH7D_Total	(Format 'ZZ9.9999%%')	TPH7D_Job_Pct
    	,100*TPH3D_Job_CostTotal/TPH3D_Total	(Format 'ZZ9.9999%%')	TPH3D_Job_Pct
    	--,rank() over (partition by xx.ETL_Period order by TPH7D_Job_Total desc) rankInPeriod
    	,TPH14D_Total/14 TPH14D_AVG
    	,TPH7D_Total/7 TPH7D_AVG
    	,TPH3D_Total/3 TPH3D_AVG
         from
            (
            	select
            		--UserType
            		--,
            		unique
            		jobID
            		,ETL_Period
            		,case when ETL_Period = 1 then '1' else '' end ETL_01
            		,case when ETL_Period = 2 then '2' else '' end ETL_02
            		,case when ETL_Period = 3 then '3' else '' end ETL_03
            		,case when ETL_Period = 4 then '4' else '' end ETL_04
            		,case when ETL_Period = 6 then '6' else '' end ETL_06
            		,sum(TPH_14Day_Total * TPH_ETL_Period_Cost) over (partition by jobID) TPH14D_Job_CostTotal
            		,sum(TPH_7Day_Total * TPH_ETL_Period_Cost)  over (partition by jobID) TPH7D_Job_CostTotal
            		,sum(TPH_3Day_Total * TPH_ETL_Period_Cost)  over (partition by jobID) TPH3D_Job_CostTotal
            		,sum(TPH_14Day_Total * TPH_ETL_Period_Cost) over (partition by ETL_Period) TPH14D_Period_CostTotal
            		,sum(TPH_7Day_Total * TPH_ETL_Period_Cost)  over (partition by ETL_Period) TPH7D_Period_CostTotal
            		,sum(TPH_3Day_Total * TPH_ETL_Period_Cost)  over (partition by ETL_Period) TPH3D_Period_CostTotal
            		,sum(TPH_14Day_Total) over (partition by jobID) TPH14D_Job_Total
            		,sum(TPH_7Day_Total)  over (partition by jobID) TPH7D_Job_Total
            		,sum(TPH_3Day_Total)  over (partition by jobID) TPH3D_Job_Total
            		,sum(TPH_14Day_Total) over (partition by ETL_Period) TPH14D_Period_Total
            		,sum(TPH_7Day_Total)  over (partition by ETL_Period) TPH7D_Period_Total
            		,sum(TPH_3Day_Total)  over (partition by ETL_Period) TPH3D_Period_Total
            		,sum(TPH_14Day_Total) over () TPH14D_Total
            		,sum(TPH_7Day_Total)  over () TPH7D_Total
            		,sum(TPH_3Day_Total)  over () TPH3D_Total
            	  from prodbbymeadhocvws.rasc_DBPerf_Header_Period_Dt14
            	 where UserType='Batch'
            ) xx
    group by 1, 7,8,9,10,11,12,13,14,15
) x
left join PRODBBYMEADHOCDB.Fort_Job j
	on x.jobID = j.jobID
order by 4 desc, 3 desc, 5 desc, 2

replace view prodbbymeadhocvws.rasc_DBPerf_SqlAvg_14Day
	as
	locking row for access
select
	x.jobID
	,ETL_1 || ETL_2 || ETL_3 || ETL_4 || ETL_6 ETL_Periods
	,TPH14D_Sql_Pct
	,TPH7D_Sql_Pct
	,TPH3D_Sql_Pct
	--,rankInPeriod
    ,TPH14D_Sql_CostTotal
    ,TPH7D_Sql_CostTotal
    ,TPH3D_Sql_CostTotal
	,TPH14D_AVG
	,TPH7D_AVG
	,TPH3D_AVG
	,jobName
    ,sqlName
    ,x.waveID
    ,x.sqlID
	--,jobDesc
  from
  (
      select
    	jobID
        ,waveID
        ,sqlID
    	,max(ETL_01) ETL_1
    	,max(ETL_02) ETL_2
    	,max(ETL_03) ETL_3
    	,max(ETL_04) ETL_4
    	,max(ETL_06) ETL_6
    	,TPH14D_Sql_CostTotal 		TPH14D_Sql_CostTotal
    	,TPH7D_Sql_CostTotal    	TPH7D_Sql_CostTotal
    	,TPH3D_Sql_CostTotal    	TPH3D_Sql_CostTotal
    	,100*TPH14D_Sql_CostTotal/TPH14D_Total 	(Format 'ZZ9.9999%%')	TPH14D_Sql_Pct
    	,100*TPH7D_Sql_CostTotal/TPH7D_Total	(Format 'ZZ9.9999%%')	TPH7D_Sql_Pct
    	,100*TPH3D_Sql_CostTotal/TPH3D_Total	(Format 'ZZ9.9999%%')	TPH3D_Sql_Pct
    	--,rank() over (partition by xx.ETL_Period order by TPH7D_Job_Total desc) rankInPeriod
    	,TPH14D_Total/14 TPH14D_AVG
    	,TPH7D_Total/7 TPH7D_AVG
    	,TPH3D_Total/3 TPH3D_AVG
         from
            (
            	select
            		--UserType
            		--,
            		unique
            		jobID
                    ,waveID
                    ,sqlID
            		,ETL_Period
            		,case when ETL_Period = 1 then '1' else '' end ETL_01
            		,case when ETL_Period = 2 then '2' else '' end ETL_02
            		,case when ETL_Period = 3 then '3' else '' end ETL_03
            		,case when ETL_Period = 4 then '4' else '' end ETL_04
            		,case when ETL_Period = 6 then '6' else '' end ETL_06
            		,sum(TPH_14Day_Total * TPH_ETL_Period_Cost) over (partition by jobID, waveID, sqlID) TPH14D_sql_CostTotal
            		,sum(TPH_7Day_Total * TPH_ETL_Period_Cost)  over (partition by jobID, waveID, sqlID) TPH7D_sql_CostTotal
            		,sum(TPH_3Day_Total * TPH_ETL_Period_Cost)  over (partition by jobID, waveID, sqlID) TPH3D_sql_CostTotal
            		,sum(TPH_14Day_Total * TPH_ETL_Period_Cost) over (partition by ETL_Period) TPH14D_Period_CostTotal
            		,sum(TPH_7Day_Total * TPH_ETL_Period_Cost)  over (partition by ETL_Period) TPH7D_Period_CostTotal
            		,sum(TPH_3Day_Total * TPH_ETL_Period_Cost)  over (partition by ETL_Period) TPH3D_Period_CostTotal
            		,sum(TPH_14Day_Total) over (partition by jobID, waveID, sqlID) TPH14D_Sql_Total
            		,sum(TPH_7Day_Total)  over (partition by jobID, waveID, sqlID) TPH7D_Sql_Total
            		,sum(TPH_3Day_Total)  over (partition by jobID, waveID, sqlID) TPH3D_Sql_Total
            		,sum(TPH_14Day_Total) over (partition by ETL_Period) TPH14D_Period_Total
            		,sum(TPH_7Day_Total)  over (partition by ETL_Period) TPH7D_Period_Total
            		,sum(TPH_3Day_Total)  over (partition by ETL_Period) TPH3D_Period_Total
            		,sum(TPH_14Day_Total) over () TPH14D_Total
            		,sum(TPH_7Day_Total)  over () TPH7D_Total
            		,sum(TPH_3Day_Total)  over () TPH3D_Total
            	  from prodbbymeadhocvws.rasc_DBPerf_Header_Period_Dt14
            	 where UserType='Batch'
            ) xx
    group by 1, 2,3, 9,10,11,12,13,14,15,16,17
) x
left join PRODBBYMEADHOCDB.Fort_Job_Wave_Sql s
	on x.jobID  = s.jobID
    and x.waveID = s.waveID
    and x.sqlID = s.sqlID
left join PRODBBYMEADHOCDB.Fort_Job j
    on j.jobID = s.jobID

order by 4 desc, 3 desc, 5 desc, 2
-- 
--
--
Create view PRODBBYMEADHOCVWS.RASC_DBPerf_AllPeriods_13Wk 
    as locking row for access
Select 
     JobTypeName
    ,Fisc_Wk_NM
    ,etl_period
    ,Sum(TPH) as TPH
    ,sum(TPH_Cost) as TPH_Cost
From
(
    Select Fisc_Wk_Yr_ID,Fisc_wk_Nm
        ,case when SQLType <> 'Job' then SQLType 
            when j.TPH_14Day_Avg<5 then 'Small Jobs' 
            else j.JobName 
          end as JobTypeName
        ,r.etl_period
        ,Sum(Total_CPU) as Total_CPU
        ,Sum(Total_IO) as Total_IO
        ,Count(*) as SQL_Count
        ,Sum(TPH) as TPH
        ,avg(TPH) as Avg_TPH
        ,sum(TPH_Cost) as TPH_Cost
     From PRODBBYMEADHOCvws.RASC_DBPerf_Detail_v r
    left outer join prodbbymeadhocdb.fort_job j
            on j.Jobid=r.jobid
    where UserType='Batch'
      --and r.ETL_Period=2
      and r.Fisc_Wk_Id in
            ( Select Fisc_Wk_of_Mth_ID 
                from prodbbyrptvws.bby_fiscal_calendar 
               where Calndr_DT between DATE-91 and DATE-7 
            group by Fisc_Wk_of_Mth_ID
            )
    Group by Fisc_Wk_Yr_ID
            ,Fisc_wk_Nm
            ,r.etl_period
            ,j.JobName
            ,SQLType
            ,j.TPH_14Day_Avg
) a
Group by JobTypeName,Fisc_Wk_NM, etl_period
order by Fisc_Wk_nm, etl_period, 4 Desc, JobTypeName

create view prodbbymeadhocvws.rasc_dbperf_sql_TPH_delta
    as locking row for access
select
        xx.*
  from
(
    select
            jobID
            ,waveID
            ,sqlID
            ,calndr_dt
            ,fisc_wk_Nm
            ,fisc_day_of_wk_nbr
            ,max(calndr_dt) over (partition by jobID, waveID, sqlID, userType) last_run_dt
            ,avg(TPH) over (partition by jobID, waveID, sqlID, userType order by calndr_dt ASC rows between 5 preceding and 1 preceding) avg_TPH
            ,TPH
            ,case when avg_TPH > 0 then TPH/avg_TPH end curr_TPH_pct
            ,TPH - avg_TPH curr_TPH_inc
      from 
    (
        select 
                userType
                ,jobID
                ,waveID
                ,sqlID
                ,calndr_dt
                ,fisc_wk_Nm
                ,fisc_day_of_wk_nbr
                ,etl_period
                ,sum(TPH) TPH
          from (select userType, jobID, waveID, sqlID, calndr_dt, etl_period, fisc_wk_Nm, fisc_day_of_Wk_nbr, max(TPH) TPH
                  from PRODBBYMEADHOCvws.RASC_DBPerf_Detail_v group by 1,2,3,4,5,6,7,8
                ) r
         where userType = 'Batch'
        group by 1,2,3,4,5,6,7,8
    ) x
) xx
 where calndr_dt = last_run_dt


create view prodbbymeadhocvws.rasc_dbperf_job_TPH_delta
    as locking row for access
select
        xx.*
  from
(
    select
            jobID
            ,calndr_dt
            ,fisc_wk_Nm
            ,fisc_day_of_wk_nbr
            ,max(calndr_dt) over (partition by jobID, userType) last_run_dt
            ,avg(TPH) over (partition by jobID, userType order by calndr_dt ASC rows between 5 preceding and 1 preceding) avg_TPH
            ,TPH
            ,case when avg_TPH > 0 then TPH/avg_TPH end curr_TPH_pct
            ,TPH - avg_TPH curr_TPH_inc
      from 
    (
        select 
                userType
                ,jobID
                ,calndr_dt
                ,fisc_wk_Nm
                ,fisc_day_of_wk_nbr
                ,etl_period
                ,sum(TPH) TPH
          from (select userType, jobID, waveID, sqlID, calndr_dt, etl_period, fisc_wk_Nm, fisc_day_of_Wk_nbr, max(TPH) TPH
                  from PRODBBYMEADHOCvws.RASC_DBPerf_Detail_v group by 1,2,3,4,5,6,7,8
                ) r
         where userType = 'Batch'
        group by 1,2,3,4,5,6
    ) x
) xx
 where calndr_dt = last_run_dt

Create View PRODBBYMEADHOCVWS.RASC_DBPerf_Period_Dt_Sum_v
    As Locking Row For Access
Select 
        Calndr_Dt
        --,Calndr_Tm
        ,ETL_Period
        ,Fisc_Day_of_Wk_Nbr
        ,Fisc_Wk_ID
        ,Fisc_Wk_Yr_ID
        ,Fisc_wk_Nm
        ,Fisc_Mth_ID
        ,Fisc_Mth_Nm       
        ,Fisc_Yr_ID
        --,SQLType
        --,SQLIdText
        --,ActionId
        --,AlertId
        --,JobId
        --,WaveId
        --,SQLId
        --,UserName                     
        ,TPH_ETL_Period_Cost
        ,UserType            
        --,SessionId                     
        --,RequestNum                    
        ,sum(Total_CPU) Total_CPU
        ,sum(TPH)       Total_TPH
        ,sum(TPH_Cost)  Total_TPH_Cost
From PRODBBYMEADHOCVWS.RASC_DBPerf_Detail_v r
group by 1,2,3,4,5,6,7,8,9,10,11
; 

Create View PRODBBYMEADHOCVWS.RASC_DBPerf_Period_wk_psum_v
    As Locking Row For Access
--select *
--  from (
Select 
        Calndr_Dt (format 'YYYY/MM/DD')
        ,ETL_Period
        ,Fisc_Day_of_Wk_Nbr
        ,Fisc_Wk_ID
        ,Fisc_Wk_Yr_ID
        ,Fisc_wk_Nm
        ,Fisc_Mth_ID
        ,Fisc_Mth_Nm
        ,Fisc_Yr_ID
        ,UserType
        --,Total_CPU 
        ,Total_TPH TPH
        ,Total_TPH_Cost TPH_Cost
        ,sum(Total_TPH) over (partition by UserType, ETL_Period, Fisc_Day_of_Wk_nbr order by Fisc_Wk_id ASC rows between 3 preceding and 1 preceding)  Total_last_3DayOfWk_TPH
        ,sum(Total_TPH) over (partition by UserType, ETL_Period order by Calndr_dt ASC rows between 3 preceding and 1 preceding)  Total_last_3dt_TPH
        ,sum(Total_TPH) over (partition by UserType, ETL_Period order by Calndr_dt ASC rows between 7 preceding and 1 preceding)  Total_last_7dt_TPH
        --,sum(Total_TPH) over (partition by UserType, ETL_Period, Fisc_Wk_id)  Total_fullwk_TPH
        --,sum(Total_fullwk_TPH) over (order by Fisc_Wk_id ASC rows between 1 preceding and 1 preceding)  Total_last_fullwk_TPH
        ,sum(Total_TPH) over (partition by UserType, calndr_dt) Total_TPH_Dt_Type
        ,sum(Total_TPH) over (partition by calndr_dt)           Total_TPH_Dt
        ,sum(Total_TPH_Cost) over (partition by UserType, ETL_Period, Fisc_Day_of_Wk_nbr order by Fisc_Wk_id ASC rows between 3 preceding and 1 preceding)  Total_last_3DayOfWk_TPH_Cost
        ,sum(Total_TPH_Cost) over (partition by UserType, ETL_Period order by Calndr_dt ASC rows between 3 preceding and 1 preceding)  Total_last_3dt_TPH_Cost
        ,sum(Total_TPH_Cost) over (partition by UserType, ETL_Period order by Calndr_dt ASC rows between 7 preceding and 1 preceding)  Total_last_7dt_TPH_Cost
        ,sum(Total_TPH_Cost) over (partition by UserType, calndr_dt) Total_TPH_Cost_Dt_Type
        ,sum(Total_TPH_Cost) over (partition by calndr_dt)           Total_TPH_Cost_Dt
  From PRODBBYMEADHOCVWS.RASC_DBPerf_Period_Dt_Sum_v r
--) x
-- where Calndr_dt <= date

select
		--calndr_dt
		cast((calndr_dt (format 'YYYY-MM-DD')) as varchar(10)) Calndr_dt
		--,etl_period
		--,UserType
		--,Total_TPH TPH
		--,Total_last_3DayOfWk_TPH/3
		--,Total_last_3Dt_TPH/3
		--,Total_last_7Dt_TPH/7
		--,Total_TPH_Dt_Type
		--,Total_TPH_Dt
		,max(case when etl_period = 1 and UserType = 'Batch' then cast(TPH_Cost as decimal(20,2)) end)                          TPH_P1_Batch
		,max(case when etl_period = 2 and UserType = 'Batch' then cast(TPH_Cost as decimal(20,2)) end)                          TPH_P2_Batch
		,max(case when etl_period = 3 and UserType = 'Batch' then cast(TPH_Cost as decimal(20,2)) end)                          TPH_P3_Batch
		,max(case when etl_period = 4 and UserType = 'Batch' then cast(TPH_Cost as decimal(20,2)) end)                          TPH_P4_Batch
		,max(case when etl_period = 6 and UserType = 'Batch' then cast(TPH_Cost as decimal(20,2)) end)                          TPH_P6_Batch
		,max(case when etl_period = 1 and UserType = 'Adhoc' then cast(TPH_Cost as decimal(20,2)) end)                          TPH_P1_Adhoc
		,max(case when etl_period = 2 and UserType = 'Adhoc' then cast(TPH_Cost as decimal(20,2)) end)                          TPH_P2_Adhoc
		,max(case when etl_period = 3 and UserType = 'Adhoc' then cast(TPH_Cost as decimal(20,2)) end)                          TPH_P3_Adhoc
		,max(case when etl_period = 4 and UserType = 'Adhoc' then cast(TPH_Cost as decimal(20,2)) end)                          TPH_P4_Adhoc
		,max(case when etl_period = 6 and UserType = 'Adhoc' then cast(TPH_Cost as decimal(20,2)) end)                          TPH_P6_Adhoc
        ,max(case when UserType='Adhoc' then cast(Total_TPH_Cost_Dt_Type as decimal(20,2)) end)                                 TPH_Adhoc_Dt
        ,max(case when UserType='Batch' then cast(Total_TPH_Cost_Dt_Type as decimal(20,2)) end)                                 TPH_Batch_Dt
        ,max(cast(Total_TPH_Cost_Dt as decimal(20,2)))                                                                          TPH_Total_Dt
		,max(case when etl_period = 1 and UserType = 'Batch' then cast(Total_Last_3DayOfWk_TPH_Cost/3 as decimal(20,2)) end)    TPH_P1_Batch_3Day_Avg
		,max(case when etl_period = 2 and UserType = 'Batch' then cast(Total_Last_3DayOfWk_TPH_Cost/3 as decimal(20,2)) end)    TPH_P2_Batch_3Day_Avg
		,max(case when etl_period = 3 and UserType = 'Batch' then cast(Total_Last_3DayOfWk_TPH_Cost/3 as decimal(20,2)) end)    TPH_P3_Batch_3Day_Avg
		,max(case when etl_period = 4 and UserType = 'Batch' then cast(Total_Last_3DayOfWk_TPH_Cost/3 as decimal(20,2)) end)    TPH_P4_Batch_3Day_Avg
		,max(case when etl_period = 6 and UserType = 'Batch' then cast(Total_Last_3DayOfWk_TPH_Cost/3 as decimal(20,2)) end)    TPH_P6_Batch_3Day_Avg
		,max(case when etl_period = 1 and UserType = 'Adhoc' then cast(Total_Last_3DayOfWk_TPH_Cost/3 as decimal(20,2)) end)    TPH_P1_Adhoc_3Day_Avg
		,max(case when etl_period = 2 and UserType = 'Adhoc' then cast(Total_Last_3DayOfWk_TPH_Cost/3 as decimal(20,2)) end)    TPH_P2_Adhoc_3Day_Avg
		,max(case when etl_period = 3 and UserType = 'Adhoc' then cast(Total_Last_3DayOfWk_TPH_Cost/3 as decimal(20,2)) end)    TPH_P3_Adhoc_3Day_Avg
		,max(case when etl_period = 4 and UserType = 'Adhoc' then cast(Total_Last_3DayOfWk_TPH_Cost/3 as decimal(20,2)) end)    TPH_P4_Adhoc_3Day_Avg
		,max(case when etl_period = 6 and UserType = 'Adhoc' then cast(Total_Last_3DayOfWk_TPH_Cost/3 as decimal(20,2)) end)    TPH_P6_Adhoc_3Day_Avg
		,max(case when etl_period = 1 and UserType = 'Batch' then cast(Total_Last_3Dt_TPH_Cost/3 as decimal(20,2)) end)         TPH_P1_Batch_3Dt_Avg
		,max(case when etl_period = 2 and UserType = 'Batch' then cast(Total_Last_3Dt_TPH_Cost/3 as decimal(20,2)) end)         TPH_P2_Batch_3Dt_Avg
		,max(case when etl_period = 3 and UserType = 'Batch' then cast(Total_Last_3Dt_TPH_Cost/3 as decimal(20,2)) end)         TPH_P3_Batch_3Dt_Avg
		,max(case when etl_period = 4 and UserType = 'Batch' then cast(Total_Last_3Dt_TPH_Cost/3 as decimal(20,2)) end)         TPH_P4_Batch_3Dt_Avg
		,max(case when etl_period = 6 and UserType = 'Batch' then cast(Total_Last_3Dt_TPH_Cost/3 as decimal(20,2)) end)         TPH_P6_Batch_3Dt_Avg
		,max(case when etl_period = 1 and UserType = 'Adhoc' then cast(Total_Last_3Dt_TPH_Cost/3 as decimal(20,2)) end)         TPH_P1_Adhoc_3Dt_Avg
		,max(case when etl_period = 2 and UserType = 'Adhoc' then cast(Total_Last_3Dt_TPH_Cost/3 as decimal(20,2)) end)         TPH_P2_Adhoc_3Dt_Avg
		,max(case when etl_period = 3 and UserType = 'Adhoc' then cast(Total_Last_3Dt_TPH_Cost/3 as decimal(20,2)) end)         TPH_P3_Adhoc_3Dt_Avg
		,max(case when etl_period = 4 and UserType = 'Adhoc' then cast(Total_Last_3Dt_TPH_Cost/3 as decimal(20,2)) end)         TPH_P4_Adhoc_3Dt_Avg
		,max(case when etl_period = 6 and UserType = 'Adhoc' then cast(Total_Last_3Dt_TPH_Cost/3 as decimal(20,2)) end)         TPH_P6_Adhoc_3Dt_Avg
		,max(case when etl_period = 1 and UserType = 'Batch' then cast(Total_Last_7Dt_TPH_Cost/7 as decimal(20,2)) end)         TPH_P1_Batch_7Dt_Avg
		,max(case when etl_period = 2 and UserType = 'Batch' then cast(Total_Last_7Dt_TPH_Cost/7 as decimal(20,2)) end)         TPH_P2_Batch_7Dt_Avg
		,max(case when etl_period = 3 and UserType = 'Batch' then cast(Total_Last_7Dt_TPH_Cost/7 as decimal(20,2)) end)         TPH_P3_Batch_7Dt_Avg
		,max(case when etl_period = 4 and UserType = 'Batch' then cast(Total_Last_7Dt_TPH_Cost/7 as decimal(20,2)) end)         TPH_P4_Batch_7Dt_Avg
		,max(case when etl_period = 6 and UserType = 'Batch' then cast(Total_Last_7Dt_TPH_Cost/7 as decimal(20,2)) end)         TPH_P6_Batch_7Dt_Avg
		,max(case when etl_period = 1 and UserType = 'Adhoc' then cast(Total_Last_7Dt_TPH_Cost/7 as decimal(20,2)) end)         TPH_P1_Adhoc_7Dt_Avg
		,max(case when etl_period = 2 and UserType = 'Adhoc' then cast(Total_Last_7Dt_TPH_Cost/7 as decimal(20,2)) end)         TPH_P2_Adhoc_7Dt_Avg
		,max(case when etl_period = 3 and UserType = 'Adhoc' then cast(Total_Last_7Dt_TPH_Cost/7 as decimal(20,2)) end)         TPH_P3_Adhoc_7Dt_Avg
		,max(case when etl_period = 4 and UserType = 'Adhoc' then cast(Total_Last_7Dt_TPH_Cost/7 as decimal(20,2)) end)         TPH_P4_Adhoc_7Dt_Avg
		,max(case when etl_period = 6 and UserType = 'Adhoc' then cast(Total_Last_7Dt_TPH_Cost/7 as decimal(20,2)) end)         TPH_P6_Adhoc_7Dt_Avg
  from PRODBBYMEADHOCVWS.RASC_DBPerf_Period_wk_psum_v
 where Calndr_dt = date - 2
group by 1

   and curr_TPH_pct > 1.5

select
        j.jobName
        ,p.*
        ,j.lastStartTS
  from prodbbymeadhocdb.fort_job j
        ,prodbbymeadhocvws.rasc_dbperf_job_TPH_delta p
 where j.jobID = p.jobID
   and (curr_TPH_pct > 1.1 or curr_TPH_pct is null)
   and curr_TPH_inc > 0
   and last_run_dt > date - 36
order by curr_TPH_inc DESC

select
    x.jobTypeName
    ,case when day_count > 1 then (x.TPH - r.TPH)/(day_count - 1) 
        else r.TPH end avg_TPH
    ,r.TPH last_run_TPH
    ,case when avg_TPH = 0 then 0 else last_run_TPH/avg_TPH end last_run_pct
    ,x.last_run_dt
  from
(
    Select 
         JobTypeName
        --,calndr_dt
        --,Fisc_Wk_NM
        ,etl_period
        ,max(calndr_dt) last_run_dt
        ,Sum(TPH) as TPH
        ,count(calndr_dt) day_count
        --,avg(TPH) as Avg_TPH
        ,sum(TPH_Cost) as TPH_Cost
    From
    (
        Select Fisc_Wk_Yr_ID,Fisc_wk_Nm
            ,calndr_dt
            ,case when SQLType <> 'Job' then SQLType 
                when j.TPH_14Day_Avg<2 then 'Small Jobs' 
                else r.jobID || ':' ||j.JobName 
              end as JobTypeName
            ,r.etl_period
            ,Sum(Total_CPU) as Total_CPU
            ,Sum(Total_IO) as Total_IO
            ,Count(*) as SQL_Count
            ,Sum(TPH) as TPH
            --,avg(TPH) as Avg_TPH
            ,sum(TPH_Cost) as TPH_Cost
         From PRODBBYMEADHOCvws.RASC_DBPerf_Detail_v r
        left outer join prodbbymeadhocvws.fort_job j
                on j.Jobid=r.jobid
        where UserType='Batch'
          --and r.ETL_Period=2
          and r.Fisc_Wk_Id in
                ( Select Fisc_Wk_of_Mth_ID 
                    from prodbbyrptvws.bby_fiscal_calendar 
                   where Calndr_DT between DATE-91 and DATE-7 
                group by Fisc_Wk_of_Mth_ID
                )
        Group by 1,2,3,4,5
    ) a
    Group by 1,2
) x
    ,(select UserType
            ,calndr_dt
            ,etl_period
            ,jobID
            ,sum(TPH) TPH
        from PRODBBYMEADHOCvws.RASC_DBPerf_Detail_v 
        group by 1,2,3,4
    ) r
 where substring(x.jobTypeName from 1 for position(':' in x.jobTypeName) ) = r.jobID || ':'
   and x.last_run_dt = r.calndr_dt
   and x.etl_period = r.etl_period
   and r.userType = 'Batch'
   and x.last_run_dt > date - 35

---------------------------------------------------------------------------

select
	case when UserName = 'RASC_FORT_BCH' then 'Batch' 
	     when r.Calndr_DT < 1080618 and UserName = 'a035767' then 'Batch' 
		 else 'Adhoc' 
	    end UserType
	,case 
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM < 60000 then 1
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 60000 and 100000 then 2
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 100000 and 190000 then 3
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM > 190000 then 6
		else 4 
	end as ETL_Period
	,JobId
	,WaveId
	,SqlID
	,SQLType
	,(sum(case when Current_date - 2 - 15 < r.Calndr_dt and r.Calndr_dt < Current_date - 2 then Total_CPU else 0 end)*0.002702)  TPH_14Day_Total
	,(sum(case when Current_date - 2 - 8  < r.Calndr_dt and r.Calndr_dt < Current_date - 2 then Total_CPU else 0 end)*0.002702)  TPH_7Day_Total
	,(sum(case when Current_date - 2 - 4  < r.Calndr_dt and r.Calndr_dt < Current_date - 2 then Total_CPU else 0 end)*0.002702)  TPH_3Day_Total
	,sum(case when  Current_date - 2 - 2  < r.Calndr_dt and r.Calndr_dt < Current_date - 2 then Total_CPU else 0 end)*0.002702   TPH_1Day_Total
    ,case 
        when ETL_Period = 1 then 3.92
        when ETL_Period = 2 then 2.96
        when ETL_Period = 3 then 0.73
        when ETL_Period = 4 then 0.73
        else 0.22 
    end TPH_ETL_Period_Cost 
    ,cast(Total_CPU * 0.0027 * TPH_ETL_Period_Cost as decimal(16,2)) as TPH_Cost
	--,Sum(Total_CPU)*0.002702 Total_TPH
  from PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
join prodbbyrptvws.bby_fiscal_calendar c
	on r.Calndr_DT=c.Calndr_DT
 where WaveId is not null
   and JobId is not null
   and r.Calndr_dt > Current_date - 16
group by 
	JobId
	,WaveId
	,SqlID
	,ETL_Period
    ,TPH_Cost
	--,Calndr_dt
	,UserType
	,SQLType;

select jobID, waveID, sqlID
		,SQLType, UserType
		,sum(TPH_14Day_Total)
		,sum(TPH_7Day_Total)
		,sum(TPH_3Day_Total)
		,sum(TPH_1Day_Total)
  from prodbbymeadhocvws.rasc_DBPerf_Header_Period_Dt14
 where UserType = 'Batch'
 group by 1,2,3,4,5
order by 7 Desc, 6 Desc


SELECT
        d.DatabaseName
        ,t.TableName
        ,t.CreatorName as Analyst
        ,SUM(CurrentPerm)/1024 as Used_KB
        ,SUM(CurrentPerm)/1024/1024 as Used_MB
        ,SUM(CurrentPerm)/1024/1024/1024 as Used_GB 
        ,cast(Used_KB as decimal(18,6)) / cast(Max_KB as decimal(18,6))  as Use_Pct 
        ,PermSpace /1024 as Max_KB 
        ,PermSpace /1024/1024 as Max_MB 
        ,PermSpace /1024/1024/1024 as Max_GB 
  FROM dbc.TableSize s
        , dbc.databases d
        , dbc.Tables t 
 where d.databasename = s.databasename 
   and t.databasename = s.databasename 
   and t.databasename = d.databasename 
   and s.TableName = t.TableName 
   and d.databasename like 'PRODBBYMEADHOC%'
---  and t.tablename in('vwbb_mcube_dt','vwbb_ocube_dt')
group by d.DatabaseName,t.TableName,d.PermSpace,t.CreatorName
order by 1,2,3

insert into prodbbymeadhocdb.Fort_Job_xRef (jobID, ReportID)
select j.jobID, rc.reportID
 from prodbbymeadhocvws.fort_prj_report_column rc
 		,prodbbymeadhocvws.fort_job j
		,prodbbymeadhocvws.fort_dim_metric m
 where rc.metricID = m.metricID
   and lower(m.metricDest) = lower(j.metricDataTable)
group by 1,2

insert into prodbbymeadhocdb.Fort_Job_xRef 
(jobID, ReportID, comments)
select r.reportID, j.jobID, r.reportName || ' ---- ' || j.jobName 
  from prodbbymeadhocvws.fort_prj_report r
  		,prodbbymeadhocvws.fort_job j
		,prodbbymeadhocvws.fort_job_wave_sql s
 where j.jobID = s.jobID
   and position(lower(r.tableName) in lower(s.shellSQL)) > 0
   and (r.reportID, j.jobID) not in (select reportID, jobID from prodbbymeadhocdb.Fort_Job_xRef )

Replace View PRODBBYMEADHOCVWS.RASC_DBPerf_Detail 
    As Locking Row For Access
Select r.Calndr_Dt                     
     , Calndr_Tm                   
        ,case when Calndr_TM < 60000 then 1
            when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 60000 and 100000 then 2
            when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 100000 and 190000 then 3
            when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM > 190000 then 4
            else 6 
        end as ETL_Period    
        ,Fisc_Day_of_Wk_Nbr
        ,Fisc_Wk_of_Mth_ID as Fisc_Wk_ID
        ,(d.Fisc_Yr_ID*100) + d.Fisc_Wk_of_Yr_Nbr as Fisc_Wk_Yr_ID
        ,Fisc_Mth_Abbr_NM ||' '|| Fisc_Wk_Of_Mth_NM AS Fisc_wk_Nm
        ,Fisc_Mth_ID as  Fisc_Mth_ID
        ,Fisc_Mth_Abbr_NM as  Fisc_Mth_Nm       
        ,Fisc_Yr_ID
        ,SQLType                       
        ,SQLIdText                     
        ,ActionId                      
        ,AlertId                       
        ,JobId                         
        ,WaveId                        
        ,SQLId                         
        ,UserName                     
        ,case when UserName = 'RASC_FORT_BCH' then 'Batch' 
            when r.Calndr_DT < 1080618 and UserName = 'a035767' then 'Batch'   
            else 'Adhoc' end as UserType            
        ,SessionId                     
        ,RequestNum                    
        ,Total_CPU                     
        ,Total_IO      
        ,Total_CPU*0.0027 as TPH
        ,case 
            when ETL_Period = 1 then 3.92
            when ETL_Period = 2 then 2.96
            when ETL_Period = 3 then 0.73
            when ETL_Period = 4 then 0.73
            else 0.22 
        end as TPH_ETL_Period_Cost    
        ,cast(TPH * TPH_ETL_Period_Cost as decimal(16,2)) as TPH_Cost
From PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
join prodbbyrptvws.bby_fiscal_calendar d
    on r.Calndr_DT=d.Calndr_DT

Replace view PRODBBYMEADHOCVWS.RASC_DBPerf_P2Batch_13Wk 
    as locking row for access
Select 
     JobTypeName
    ,Fisc_Wk_NM
    ,Sum(TPH) as TPH
    ,sum(TPH_Cost) as TPH_Cost
From
(
    Select Fisc_Wk_Yr_ID,Fisc_wk_Nm
        ,case when SQLType <> 'Job' then SQLType 
            when j.TPH_14Day_Avg<5 then 'Small Jobs' 
            else j.JobName 
          end as JobTypeName
        ,Sum(Total_CPU) as Total_CPU
        ,Sum(Total_IO) as Total_IO
        ,Count(*) as SQL_Count
        ,Sum(TPH) as TPH
        ,avg(TPH) as Avg_TPH
        ,sum(TPH_Cost) as TPH_Cost
     From PRODBBYMEADHOCvws.RASC_DBPerf_Detail r
    left outer join prodbbymeadhocvws.fort_job j
            on j.Jobid=r.jobid
    where UserType='Batch' and r.ETL_Period=2
        and r.Fisc_Wk_Id in
            ( Select Fisc_Wk_of_Mth_ID 
                from prodbbyrptvws.bby_fiscal_calendar 
               where Calndr_DT between DATE-91 and DATE-7 
            group by Fisc_Wk_of_Mth_ID
            )
    Group by Fisc_Wk_Yr_ID
            ,Fisc_wk_Nm
            ,j.JobName,SQLType
            ,j.TPH_14Day_Avg
) a
Group by JobTypeName,Fisc_Wk_NM


--
sel
    c.databasenamei as DatabaseName
    , b.tvmnamei as TableName
    , a.fieldname as ColumnName
    , cast(
        ( case
            when substr(fieldstatistics,1,1) = 'D8'XB then '2008-'
            when substr(fieldstatistics,1,1) = 'D7'XB then '2007-'
            when substr(fieldstatistics,1,1) = 'D6'XB then '2006-'
            when substr(fieldstatistics,1,1) = 'D5'XB then '2005-'
            when substr(fieldstatistics,1,1) = 'D4'XB then '2004-'
            when substr(fieldstatistics,1,1) = 'D3'XB then '2003-'
            when substr(fieldstatistics,1,1) = 'D2'XB then '2002-'
            when substr(fieldstatistics,1,1) = 'D1'XB then '2001-'
            when substr(fieldstatistics,1,1) = 'D0'XB then '2000-'
            when substr(fieldstatistics,1,1) = 'CF'XB then '1999-'
            when substr(fieldstatistics,1,1) = 'CE'XB then '1998-'
            else NULL
        end)||
        (case when substr(fieldstatistics,3,1) = '01'XB then '01-'
            when substr(fieldstatistics,3,1) = '02'XB then '02-'
            when substr(fieldstatistics,3,1) = '03'XB then '03-'
            when substr(fieldstatistics,3,1) = '04'XB then '04-'
            when substr(fieldstatistics,3,1) = '05'XB then '05-'
            when substr(fieldstatistics,3,1) = '06'XB then '06-'
            when substr(fieldstatistics,3,1) = '07'XB then '07-'
            when substr(fieldstatistics,3,1) = '08'XB then '08-'
            when substr(fieldstatistics,3,1) = '09'XB then '09-'
            when substr(fieldstatistics,3,1) = '0A'XB then '10-'
            when substr(fieldstatistics,3,1) = '0B'XB then '11-'
            when substr(fieldstatistics,3,1) = '0C'XB then '12-'
            else 'xx-'
            end)||
        (case when substr(fieldstatistics,4,1) = '01'XB then '01'
            when substr(fieldstatistics,4,1) = '02'XB then '02'
            when substr(fieldstatistics,4,1) = '03'XB then '03'
            when substr(fieldstatistics,4,1) = '04'XB then '04'
            when substr(fieldstatistics,4,1) = '05'XB then '05'
            when substr(fieldstatistics,4,1) = '06'XB then '06'
            when substr(fieldstatistics,4,1) = '07'XB then '07'
            when substr(fieldstatistics,4,1) = '08'XB then '08'
            when substr(fieldstatistics,4,1) = '09'XB then '09'
            when substr(fieldstatistics,4,1) = '0A'XB then '10'
            when substr(fieldstatistics,4,1) = '0B'XB then '11'
            when substr(fieldstatistics,4,1) = '0C'XB then '12'
            when substr(fieldstatistics,4,1) = '0D'XB then '13'
            when substr(fieldstatistics,4,1) = '0E'XB then '14'
            when substr(fieldstatistics,4,1) = '0F'XB then '15'
            when substr(fieldstatistics,4,1) = '10'XB then '16'
            when substr(fieldstatistics,4,1) = '11'XB then '17'
            when substr(fieldstatistics,4,1) = '12'XB then '18'
            when substr(fieldstatistics,4,1) = '13'XB then '19'
            when substr(fieldstatistics,4,1) = '14'XB then '20'
            when substr(fieldstatistics,4,1) = '15'XB then '21'
            when substr(fieldstatistics,4,1) = '16'XB then '22'
            when substr(fieldstatistics,4,1) = '17'XB then '23'
            when substr(fieldstatistics,4,1) = '18'XB then '24'
            when substr(fieldstatistics,4,1) = '19'XB then '25'
            when substr(fieldstatistics,4,1) = '1A'XB then '26'
            when substr(fieldstatistics,4,1) = '1B'XB then '27'
            when substr(fieldstatistics,4,1) = '1C'XB then '28'
            when substr(fieldstatistics,4,1) = '1D'XB then '29'
            when substr(fieldstatistics,4,1) = '1E'XB then '30'
            when substr(fieldstatistics,4,1) = '1F'XB then '31'
            else 'xx-'
            end) as char(10)
        )
  from dbc.
 where 




SELECT 
        ST.UserName (FORMAT 'X(10)', TITLE 'UserName')
        ,ST.AccountName (FORMAT 'X(10)', TITLE 'AccountName')
        ,ST.SessionNo (FORMAT '9(10)', TITLE 'Session')
        ,SUM(AC.CPU) (FORMAT 'ZZ,ZZZ,ZZZ,ZZ9.99', TITLE 'CPU//Seconds') as cput
        ,SUM(AC.IO) (FORMAT 'ZZZ,ZZZ,ZZZ,ZZ9', TITLE 'Disk IO//Accesses') as dio
        ,dio/(nullifzero(cput)) (FORMAT 'ZZZ.99999',TITLE 'Disk to//CPU ratio', NAMED d2c)
  from DBC.SessionTbl ST
        ,DBC.Acctg AC
 WHERE ST.UserName = AC.UserName
   and ST.AccountName = AC.AccountName
GROUP BY 1,2,3
HAVING d2c < 100
    and cput > 10
ORDER BY 6 asc


select * from dbc.columns where columnName in ( 'FieldStatistics', 'ColumnStatistics');

select
        j.jobName
        ,j.jobID
        ,s.waveID
        ,s.sqlID
        ,w.WaveName
        ,s.sqlName
        ,s.shellSQL 
        ,s.TPH_14Day_Avg
        ,s.TPH_7Day_Avg
        ,s.TPH_3Day_Avg
  from prodbbymeadhocdb.FORT_JOB_WAVE_SQL s
        ,prodbbymeadhocdb.FORT_JOB_WAVE w
        ,prodbbymeadhocdb.FORT_JOB j
 where s.jobId=j.jobId
   and w.jobID=j.jobId
   and w.waveID = s.WaveID
   and j.jobId in (375, 140, 1000)
order by s.TPH_7Day_Avg   DESC
        ,s.TPH_14Day_Avg  DESC
        ,s.TPH_3Day_Avg   DESC

select shellSQL
  from prodbbymeadhocdb.FORT_JOB_WAVE_SQL 
 where jobID  = 
   and waveID =
   and sqlID  = 

select
        w.WaveName
        ,s.sqlName
        ,s.shellSQL 
        ,s.TPH_14Day_Avg
        ,s.TPH_7Day_Avg
        ,s.TPH_3Day_Avg
        ,rank(s.TPH_7Day_Avg DESC) as TPH_7DayRank
  from prodbbymeadhocdb.FORT_JOB_WAVE_SQL s
        ,prodbbymeadhocdb.FORT_JOB_WAVE w
        --,prodbbymeadhocdb.FORT_JOB j
 where w.jobID=s.jobId
   --and s.jobId=j.jobId
   and w.waveID = s.WaveID
   and w.jobId=375
order by w.waveID
        ,s.sqlID
--order by s.TPH_7Day_Avg   DESC
--        ,s.TPH_14Day_Avg  DESC
--        ,s.TPH_3Day_Avg   DESC
;

--
-- Get list of tables and views
--
select
        DatabaseName                  
        ,TableName                     
        ,Version                       
        ,TableKind                     
        ,CreatorName                   
        ,CommentString                 
  from dbc.tables
 where databasename in ('prodbbymeadhocdb','prodbbymeadhocvws')
    and (tablename like 'FORT_%' 
    		or tablename like 'TBE%'
    		or tablename like 'REC%'
    		)
    and TableKind in ('T' ,'V')  -- M: Macro
 order by Databasename
 			,tableName;

select
        DatabaseName||'.'||TableName                     
        ,ColumnName                    
        ,ColumnType                    
        ,ColumnFormat                  
        ,ColumnTitle                   
        ,DefaultValue                  
        ,Nullable                      
  from dbc.columns
 where databasename in ('prodbbymeadhocdb','prodbbymeadhocvws')
    and (tablename like 'FORT_%' 
    		or tablename like 'TBE%'
    		or tablename like 'REC%'
    		)
    and TableKind in ('T' ,'V')  -- M: Macro
 order by Databasename
 			,tableName


--
-- Query to generate report by fort job TPerfHour
--
select
	x.jobID
	,x.ETL_Period
	,100*TPH14D_Job_Total/TPH14D_Total 	(Format 'ZZ9.9999%%')	TPH14D_Job_Pct
	,100*TPH7D_Job_Total/TPH7D_Total	(Format 'ZZ9.9999%%')	TPH7D_Job_Pct
	,100*TPH3D_Job_Total/TPH3D_Total	(Format 'ZZ9.9999%%')	TPH3D_Job_Pct
	,rank() over (partition by x.ETL_Period order by TPH7D_Job_Total desc) rankInPeriod
	,TPH14D_Total/14 TPH14D_AVG
	,TPH7D_Total/7 TPH7D_AVG
	,TPH3D_Total/3 TPH3D_AVG
	,jobName
	--,jobDesc
  from
(
	select
		--UserType
		--,
		unique
		jobID
		,ETL_Period
		,sum(TPH_14Day_Total) over (partition by jobID) TPH14D_Job_Total
		,sum(TPH_7Day_Total)  over (partition by jobID) TPH7D_Job_Total
		,sum(TPH_3Day_Total)  over (partition by jobID) TPH3D_Job_Total
		,sum(TPH_14Day_Total) over (partition by ETL_Period) TPH14D_Period_Total
		,sum(TPH_7Day_Total)  over (partition by ETL_Period) TPH7D_Period_Total
		,sum(TPH_3Day_Total)  over (partition by ETL_Period) TPH3D_Period_Total
		,sum(TPH_14Day_Total) over () TPH14D_Total
		,sum(TPH_7Day_Total)  over () TPH7D_Total
		,sum(TPH_3Day_Total)  over () TPH3D_Total
	  from prodbbymeadhocvws.rasc_DBPerf_Header_Period_Dt14
	 where UserType='Batch'
) x
left join PRODBBYMEADHOCDB.Fort_Job j
	on x.jobID = j.jobID
order by 4 desc, 3 desc, 5 desc, 2

select
	case when UserName = 'RASC_FORT_BCH' then 'Batch' 
	when r.Calndr_DT < 1080618 and UserName = 'a035767' then 'Batch' 
		else 'Adhoc' 
	end UserType
	,case 
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 60000 and 100000 then 2
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 100000 and 190000 then 3
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM > 190000 then 6
		else 4 
	end as ETL_Period
	,JobId
	,WaveId
	,SqlID
	,SQLType
	,(sum(case when Current_date - Calndr_dt < 15 then Total_CPU else 0 end)*0.002702)  TPH_14Day_Total
	,(sum(case when Current_date - Calndr_dt < 8  then Total_CPU else 0 end)*0.002702)  TPH_7Day_Total
	,(sum(case when Current_date - Calndr_dt < 4  then Total_CPU else 0 end)*0.002702)  TPH_3Day_Total
	,sum(case when Current_date - Calndr_dt < 2  then Total_CPU else 0 end)*0.002702    TPH_1Day_Total
	--,Sum(Total_CPU)*0.002702 Total_TPH
  from PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
join prodbbyrptvws.bby_fiscal_calendar c
 where WaveId is not null
   and JobId is not null
   and Calndr_dt > Current_date - 16
group by 
	JobId
	,WaveId
	,SqlID
	,ETL_Period
	--,Calndr_dt
	,UserType
	,SQLType

select
	unique
	OwnerID
	,FirstName||' '||LastName OwnerName
	,ProjectID
	,ReportID
	,ReportName
  from prodbbymeadhocdb.fort_prj_report r
left join prodbbymeadhocvws.RASC_LU_LDAP_Employee l
on r.ownerID=l.ldap_id
order by OwnerID
	,ProjectID
	,ReportID

select
	unique
	OwnerID
	,FirstName||' '||LastName OwnerName
	,ProjectID
	,r.ReportID
	,ReportName
	,s.JobID
	,s.jobName
	,s.jobRequestedBy
  from prodbbymeadhocdb.fort_prj_report r
left join prodbbymeadhocvws.RASC_LU_LDAP_Employee l
on r.ownerID=l.ldap_id
left join (
		select x.jobID, x.ReportID, j.jobName, jobRequestedBy
		  from prodbbymeadhocvws.fort_job_xRef x
		 left join prodbbymeadhocvws.fort_job j
			on x.JobID = j.JobID
	) s
on r.ReportID=s.ReportID
order by OwnerID
	,ProjectID
	,r.ReportID
--
-- Click per TPH and Job/Report
--
Select r.ReportID,r.ReportName,r.OwnerID,j.JobID,j.JobName,j.LastEndTS
,j.TPH_14Day_Avg,u.Clicks,u.Rtl_Clicks,Clicks_Per_Day
from 
 prodbbymeadhocvws.FORT_Job_xRef x
,prodbbymeadhocvws.utilization_reporting u
,prodbbymeadhocvws.fort_job j
,prodbbymeadhocdb.fort_prj_report r
where x.JobID=j.JobID
and x.ReportID=r.ReportID
and trim(u.ReportType)=trim(cast(r.ReportID as varchar(100)))
and u.Fisc_Mth_ID=200905


select
	UserType
	,sum(TPH_14Day_Avg)
	,sum(TPH_7Day_Avg)
	,sum(TPH_1Day_Avg)
  from
(
select
	--case when UserName in('RASC_FORT_BCH','a035767') then 'Batch' 
	case when UserName in('RASC_FORT_BCH') then 'Batch' 
		else 'Adhoc' 
	end UserType
	,JobId
	--,WaveId
	--,SqlID
	--,SQLType
	,(sum(case when current_date - 1 - 15 < Calndr_dt and Calndr_dt < current_date - 1 then Total_CPU else 0 end)*0.002702)/14 TPH_14Day_Avg
	,(sum(case when current_date - 1 - 8  < Calndr_dt and Calndr_dt < current_date - 1 then Total_CPU else 0 end)*0.002702)/7  TPH_7Day_Avg
	,(sum(case when current_date - 1 - 4  < Calndr_dt and Calndr_dt < current_date - 1 then Total_CPU else 0 end)*0.002702)/3  TPH_3Day_Avg
	,sum(case when  current_date - 1 - 2  < Calndr_dt and Calndr_dt < current_date - 1 then Total_CPU else 0 end)*0.002702     TPH_1Day_Avg
  from PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
 where WaveId is not null
   and JobId is not null
   and Calndr_dt > current_date - 1 - 15
group by 
	JobId
	,UserType
	--,WaveId
	--,SqlID
	--,SQLType
) x
group by UserType

Select 
	 trim(Fisc_Wk_ID) ||' '|| Fisc_Wk_NM as Fisc_WK
	,SQLType
	,ETL_Period
	,sum(total_TPH) as TPH
  from prodbbymeadhocvws.rasc_dbperf_Header_wk
 --where UserType='Batch'
Group by 1,2,3

select
	j.JobID
	,j.jobName
	,j.jobDesc
	,j.jobRequestedBy
	,j.LastStartTS
	,j.LastEndTS
	,j.TPH_14Day_Avg 
	,j.TPH_7Day_Avg 
	,j.TPH_3Day_Avg 
	,j.TPH_1Day_Avg 
  from prodbbymeadhocdb.fort_job j
order by 
	j.TPH_14Day_Avg desc
	,j.TPH_7Day_Avg desc
	,j.TPH_3Day_Avg desc
	,j.TPH_1Day_Avg desc
select
	s.JobID
	,s.WaveID
	,s.SqlID
	--,j.etl_period
	,s.sqlName
	,s.ShellSql
	,s.TPH_14Day_Avg 
	,s.TPH_7Day_Avg 
	,s.TPH_3Day_Avg 
	,s.TPH_1Day_Avg 
  from prodbbymeadhocdb.fort_job_wave_sql s
--left join prodbbymeadhocdb.fort_job j
--	on s.jobID = j.jobID
order by 
	s.TPH_14Day_Avg desc
	,s.TPH_7Day_Avg desc
	,s.TPH_3Day_Avg desc
	,s.TPH_1Day_Avg desc

--Replace view PRODBBYMEADHOCVWS.RASC_DBPerf_Header_Wk as
--	locking row for access
Select 
	 case when UserName = 'RASC_FORT_BCH' then 'Batch' 
	 when r.Calndr_DT < 1080618 and UserName = 'a035767' then 'Batch' 
		else 'Adhoc' end as UserType
	,Fisc_Wk_of_Mth_ID as Fisc_Wk_ID
	,Fisc_Mth_Abbr_NM ||' '|| Fisc_Wk_Of_Mth_NM AS Fisc_wk_Nm
	,Fisc_Mth_ID as  Fisc_Mth_ID
	,Fisc_Mth_Abbr_NM as  Fisc_Mth_Nm
	,case 
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 60000 and 100000 then 2
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM between 100000 and 190000 then 3
		when fisc_day_of_wk_nbr between 2 and 6 and Calndr_TM > 190000 then 6
		else 4 
	end as ETL_Period
	,case 
	 	when ETL_Period = 1 then 3.92
	 	when ETL_Period = 1 then 2.96
	 	when ETL_Period = 1 then 0.73
	 	else 0.22 
	end as TPH_Cost
	,SQLType
	,Sum(Total_CPU) as Total_CPU
	,Sum(Total_IO) as Total_IO
	,Count(*) as SQL_Count
	,Sum(Total_CPU)*0.002702 as Total_TPH
	,Total_TPH * TPH_Cost as Run_Cost
  From PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
   join prodbbyrptvws.bby_fiscal_calendar d
	on r.Calndr_DT=d.Calndr_DT
Group by 1,2,3,4,5,6,7,8

update prodbbymeadhocdb.fort_job_wave_sql
--  from prodbbymeadhocvws.rasc_DBPerf_Header_Dt14 r
from
(select
	--case when UserName in('RASC_FORT_BCH','a035767') then 'Batch' 
	case when UserName in('RASC_FORT_BCH') then 'Batch' 
		else 'Adhoc' 
	end UserType
	,JobId
	,WaveId
	,SqlID
	--,Calndr_dt
	,SQLType
	,(sum(case when Current_date - Calndr_dt < 15 then Total_CPU else 0 end)*0.002702)/14 TPH_14Day_Avg
	,(sum(case when Current_date - Calndr_dt < 8  then Total_CPU else 0 end)*0.002702)/7  TPH_7Day_Avg
	,(sum(case when Current_date - Calndr_dt < 4  then Total_CPU else 0 end)*0.002702)/3  TPH_3Day_Avg
	,sum(case when Current_date - Calndr_dt < 2  then Total_CPU else 0 end)*0.002702      TPH_1Day_Avg
	--,Sum(Total_CPU)*0.002702 Total_TPH
  from PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
 where WaveId is not null
   and JobId is not null
   and Calndr_dt > Current_date - 16
group by 
	JobId
	,WaveId
	,SqlID
	--,Calndr_dt
	,UserType
	,SQLType
) r
   set TPH_14Day_Avg  = r.TPH_14Day_Avg
	,TPH_7Day_Avg = r.TPH_7Day_Avg
	,TPH_3Day_Avg = r.TPH_3Day_Avg
	,TPH_1Day_Avg = r.TPH_1Day_Avg
 where r.JobId = prodbbymeadhocdb.fort_job_wave_sql.JobId
   and r.WaveId = prodbbymeadhocdb.fort_job_wave_sql.WaveId
   and r.SqlId  = prodbbymeadhocdb.fort_job_wave_sql.SqlId
   and r.userType = 'Batch'
   and endDt > current_date - 15;

   --and Calndr_dt > current_date - 5
--group by UserType
--	,JobId
--	,WaveId
--	,SqlId
--	,Calndr_dt
--	,SQLType

select
		jobId
		,WaveId
		,SqlId
		,count(unique UserType)
  from (
select
	case when UserName in('RASC_FORT_BCH','a035767') then 'Batch' 
		else 'Adhoc' 
	end UserType
	,JobId
	,WaveId
	,SqlID
	,Calndr_dt
	,SQLType
	,(sum(case when Current_date - Calndr_dt < 15 then Total_CPU else 0 end)*0.002702)/14 Avg_Total_TPH14
	,(sum(case when Current_date - Calndr_dt < 8  then Total_CPU else 0 end)*0.002702)/7  Avg_Total_TPH7
	,(sum(case when Current_date - Calndr_dt < 4  then Total_CPU else 0 end)*0.002702)/3  Avg_Total_TPH3
	,sum(case when Current_date - Calndr_dt < 2  then Total_CPU else 0 end)*0.002702    Avg_Total_TPH1
	--,Sum(Total_CPU)*0.002702 Total_TPH
  from PRODBBYMEADHOCDB.RASC_DBPerf_Detail r
 where WaveId is not null
   and JobId is not null
   and Calndr_dt > Current_date - 15
   and JobId = 12025
   and 
group by UserType
	,JobId
	,WaveId
	,SqlID
	,Calndr_dt
	,SQLType
	) x
group by
		jobId
		,WaveId
		,SqlId
having count(unique UserType) > 1;


Select 
	* 
  From PRODBBYMEADHOCVWS.RASC_DBPerf_Header_Wk
;


Select top 10 JobID,WaveID,SQLID,TPH_14Day_Avg,TPH_7Day_Avg,TPH_3Day_Avg,TPH_1Day_Avg 
from prodbbymeadhocdb.fort_job_wave_SQL;

 
Select top 10 *
from prodbbymeadhocdb.rasc_dbperf_Detail
where SQLType='Job'
and UserName='RASC_FORT_BCH'
and WaveID is not null;

select
	count(*)
  from prodbbymeadhocdb.fort_job_wave_SQL;

select 
	jobId
	,WaveId
	,SqlID
	,count(StartDT)
   from prodbbymeadhocdb.fort_job_wave_SQL
   group by jobId
   			,WaveId
   			,SqlID
  having count(startDT) > 1;

select
	f.JobId
	,f.WaveId
	,f.SqlId
	,f.SqlName
	,r.Calndr_Dt
	,r.Calndr_Tm
	,r.SQLType
	,r.SQLIdText
	,r.Total_CPU
	,r.Total_IO
	,r.UserName
	,r.SessionId
  from prodbbymeadhocdb.rasc_dbperf_Detail as r
  	,prodbbymeadhocdb.fort_job_wave_SQL as f
 where r.JobId = f.JobId
   and r.WaveId = f.WaveId
   and r.SqlId  = f.SqlId
   and r.Calndr_Dt > Current_Date - 15;

select
	s.JobId
	,s.WaveId
	,s.SqlId
	,s.sqlName
	,count(unique s.Calndr_Dt) Dt_Cnt
	,Sum(Total_CPU) Total_CPU
	,Sum(Total_IO)  Total_IO
	--,Count(*) 	SQL_Count
	,Sum(Total_CPU)*0.002702 Total_TPH
	,Sum(Total_CPU)*0.002702/count(unique s.Calndr_Dt) Avg_TPH
  from 
(
select
	f.JobId
	,f.WaveId
	,f.SqlId
	,f.SqlName
	,r.Calndr_Dt
	,r.Calndr_Tm
	,r.SQLType
	,r.SQLIdText
	,r.Total_CPU
	,r.Total_IO
	,r.UserName
	,r.SessionId
  from prodbbymeadhocdb.rasc_dbperf_Detail r
	,prodbbymeadhocdb.fort_job_wave_SQL f
 where r.JobId = f.JobId
   and r.WaveId = f.WaveId
   and r.SqlId  = f.SqlId
) s
 where s.Calndr_Dt > Current_Date - 15
group by 
	s.JobId
	,s.WaveId
	,s.SqlId
	,s.sqlName
order by Total_TPH desc;


select min(calndr_dt)
  from prodbbymeadhocdb.rasc_dbperf_detail;

select
	c.calendar_date
	,count(d.sessionId)
  from prodbbymeadhocdb.rasc_dbperf_detail d
right join sys_calendar.calendar c
	on d.calndr_dt = c.calendar_date
 where c.calendar_date < current_date
   and c.calendar_date > (select min(calndr_dt) from prodbbymeadhocdb.rasc_dbperf_detail)
group by c.calendar_date
having count(d.sessionId) < 20;

--Column Name                    Type Comment
-------------------------------- ---- ----------------
--Calndr_Dt                      DA   ?
--Calndr_Tm                      D    ?
--SQLType                        CF   ?
--SQLIdText                      CV   ?
--ActionId                       I    ?
--AlertId                        I    ?
--JobId                          I    ?
--WaveId                         I    ?
--SQLId                          I    ?
--UserName                       CV   ?
--SessionId                      I    ?
--RequestNum                     I    ?
--Total_CPU                      D    ?
--Total_IO                       D    ?

-- Fort_Job_Wave_Sql
--Column Name                    Type Comment
-------------------------------- ---- ---------------
--JobID                          I    ?
--WaveID                         I    ?
--SQLID                          I    ?
--SQLName                        CV   ?
--ShellSQL                       CV   ?
--TestFlag                       CF   ?
--TestValueExpected              I    ?
--TestRetrySeconds               I    ?
--TestRetryAttempts              I    ?
--AbortWaveFlag                  CF   ?
--AbortJobFlag                   CF   ?
--LastStartTS                    TS   ?
--LastEndTS                      TS   ?
--LastRunStatus                  CV   ?
--StartDT                        DA   ?
--EndDT                          DA   ?
--RecModTS                       TS   ?
--FollowUp                       CV   ?
--UpdateKey                      D    ?
--FailJobID                      I    ?
--KeyWords                       CV   ?
--WriteFileFlag                  CF   ?
--WriteFileName                  CV   ?
--ExecFileFlag                   CF   ?
--EmailOnFailFlag                CF   ?
--AllowReRun                     CF   ?
--RecAffected                    I    ?
--ExportToFileFlag               CF   ?
--ExportXmlFlag                  CF   ?
--ExportHeaderRowFlag            CF   ?
--ExportDelimiter                CV   ?
--ExportFileName                 CV   ?
--EmailOnSuccessFlag             CF   ?
--EmailAddress                   CV   ?
--EmailSubject                   CV   ?
--EmailBody                      CV   ?
--EmailLastSentTS                TS   ?
--TPH_14Day_Avg                  D    ?
--TPH_7Day_Avg                   D    ?
--TPH_3Day_Avg                   D    ?
--TPH_1Day_Avg                   D    ?
CREATE SET TABLE prodbbymeadhocdb.fort_job_wave_SQL ,NO FALLBACK ,
     NO BEFORE JOURNAL,
     NO AFTER JOURNAL,
     CHECKSUM = DEFAULT
     (
      JobID INTEGER NOT NULL,
      WaveID INTEGER NOT NULL,
      SQLID INTEGER NOT NULL,
      SQLName VARCHAR(100) CHARACTER SET LATIN NOT CASESPECIFIC,
      ShellSQL VARCHAR(30000) CHARACTER SET LATIN NOT CASESPECIFIC FORMAT 'X(9000)',
      TestFlag CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'N',
      TestValueExpected INTEGER,
      TestRetrySeconds INTEGER,
      TestRetryAttempts INTEGER,
      AbortWaveFlag CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'N',
      AbortJobFlag CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'N',
      LastStartTS TIMESTAMP(0),
      LastEndTS TIMESTAMP(0),
      LastRunStatus VARCHAR(200) CHARACTER SET LATIN NOT CASESPECIFIC FORMAT 'X(50)',
      StartDT DATE FORMAT 'yyyy-mm-dd' NOT NULL DEFAULT DATE '1899-01-01',
      EndDT DATE FORMAT 'yyyy-mm-dd' NOT NULL DEFAULT DATE '9999-01-01',
      RecModTS TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(0),
      FollowUp VARCHAR(100) CHARACTER SET LATIN NOT CASESPECIFIC,
      UpdateKey DECIMAL(18,0) GENERATED ALWAYS AS IDENTITY
           (START WITH 1 
            INCREMENT BY 1 
            MINVALUE -999999999999999999 
            MAXVALUE 999999999999999999 
            NO CYCLE),
      FailJobID INTEGER,
      KeyWords VARCHAR(500) CHARACTER SET LATIN NOT CASESPECIFIC,
      WriteFileFlag CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC NOT NULL DEFAULT 'N',
      WriteFileName VARCHAR(100) CHARACTER SET LATIN NOT CASESPECIFIC,
      ExecFileFlag CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC NOT NULL DEFAULT 'N',
      EmailOnFailFlag CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'Y',
      AllowReRun CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'N',
      RecAffected INTEGER,
      ExportToFileFlag CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'N',
      ExportXmlFlag CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'N',
      ExportHeaderRowFlag CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'N',
      ExportDelimiter VARCHAR(5) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'tab',
      ExportFileName VARCHAR(250) CHARACTER SET LATIN NOT CASESPECIFIC FORMAT 'X(100)',
      EmailOnSuccessFlag CHAR(1) CHARACTER SET LATIN NOT CASESPECIFIC DEFAULT 'N',
      EmailAddress VARCHAR(1000) CHARACTER SET LATIN NOT CASESPECIFIC,
      EmailSubject VARCHAR(100) CHARACTER SET LATIN NOT CASESPECIFIC,
      EmailBody VARCHAR(10000) CHARACTER SET LATIN NOT CASESPECIFIC,
      EmailLastSentTS TIMESTAMP(0),
      TPH_14Day_Avg DECIMAL(16,6),
      TPH_7Day_Avg DECIMAL(16,6),
      TPH_3Day_Avg DECIMAL(16,6),
      TPH_1Day_Avg DECIMAL(16,6),
      CONSTRAINT chkEmailOnSuccessFlag CHECK ( EmailOnSuccessFlag  IN ('Y','N') ),
      CONSTRAINT chk_Tflg CHECK ( TestFlag  IN ('Y','N') ),
      CONSTRAINT chk_AbJ CHECK ( AbortJobFlag  IN ('Y','N') ),
      CONSTRAINT chk_AbW CHECK ( AbortWaveFlag  IN ('Y','N') ),
      CONSTRAINT EmailOnFailFlag CHECK ( EmailOnFailFlag  IN ('Y','N') ),
      CONSTRAINT chkAllowRerun CHECK ( AllowReRun  IN ('Y','N') ),
      CONSTRAINT chkExportToFileFlag CHECK ( ExportToFileFlag  IN ('Y','N') ),
      CONSTRAINT chkExportxmlFlag CHECK ( ExportXmlFlag  IN ('Y','N') ),
      CONSTRAINT chkExportHeaderRowFlag CHECK ( ExportHeaderRowFlag  IN ('Y','N') ), 
CONSTRAINT fk_wave FOREIGN KEY ( JobID ,WaveID ) REFERENCES PRODBBYMEADHOCDB.FORT_JOB_WAVE ( JobID ,
WaveID ))
UNIQUE PRIMARY INDEX ( JobID ,WaveID ,SQLID );

------------------------------------------------------------------------------------------------
CREATE SET TABLE prodbbymeadhocdb.rasc_dbperf_Detail ,NO FALLBACK ,
     NO BEFORE JOURNAL,
     NO AFTER JOURNAL,
     CHECKSUM = DEFAULT
     (
      Calndr_Dt DATE FORMAT 'YYYY-MM-DD' NOT NULL,
      Calndr_Tm DECIMAL(8,2) FORMAT '99:99:99.99' NOT NULL,
      SQLType CHAR(30) CHARACTER SET LATIN NOT CASESPECIFIC COMPRESS ('Action                        ','Alert          
               ','Internal                      ','Job                           '),
      SQLIdText VARCHAR(50) CHARACTER SET LATIN NOT CASESPECIFIC,
      ActionId INTEGER COMPRESS ,
      AlertId INTEGER COMPRESS ,
      JobId INTEGER COMPRESS ,
      WaveId INTEGER COMPRESS ,
      SQLId INTEGER COMPRESS ,
      UserName VARCHAR(30) CHARACTER SET LATIN NOT CASESPECIFIC,
      SessionId INTEGER NOT NULL,
      RequestNum INTEGER NOT NULL,
      Total_CPU DECIMAL(18,2) COMPRESS (0.00 ,3.00 ,1.00 ,4.00 ,2.00 ),
      Total_IO DECIMAL(18,0) COMPRESS (0. ,1. ,2. ,3. ,4. ,5. ,6. ,7. ,8. ,9. ,10. ,11. ,12. ,13. ,14. ,15. ,16. ,17. ,
18. ,19. ,20. ))
UNIQUE PRIMARY INDEX UPI_RASC_DBPerf_Detail ( Calndr_Dt ,SessionId ,
RequestNum )
PARTITION BY RANGE_N(Calndr_Dt  BETWEEN DATE '2006-09-14' AND '2008-12-31' EACH INTERVAL '1' DAY ,
 NO RANGE, UNKNOWN);

create hash index rasc_dbperf

select
	x.jobID
	,ETL1||ETL_2 || ETL_3 || ETL_4 || ETL_6 ETL_Periods
	,TPH14D_Job_Pct
	,TPH7D_Job_Pct
	,TPH3D_Job_Pct
	,rankInPeriod
	,TPH14D_AVG
	,TPH7D_AVG
	,TPH3D_AVG
	,jobName
	--,jobDesc
  from
  (
      select
    	jobID
    	,max(ETL_01) ETL_1
    	,max(ETL_02) ETL_2
    	,max(ETL_03) ETL_3
    	,max(ETL_04) ETL_4
    	,max(ETL_06) ETL_6
    	,100*TPH14D_Job_Total/TPH14D_Total 	(Format 'ZZ9.9999%%')	TPH14D_Job_Pct
    	,100*TPH7D_Job_Total/TPH7D_Total	(Format 'ZZ9.9999%%')	TPH7D_Job_Pct
    	,100*TPH3D_Job_Total/TPH3D_Total	(Format 'ZZ9.9999%%')	TPH3D_Job_Pct
    	--,rank() over (partition by xx.ETL_Period order by TPH7D_Job_Total desc) rankInPeriod
    	,TPH14D_Total/14 TPH14D_AVG
    	,TPH7D_Total/7 TPH7D_AVG
    	,TPH3D_Total/3 TPH3D_AVG
         from
            (
            	select
            		--UserType
            		--,
            		unique
            		jobID
            		,ETL_Period
            		,case when ETL_Period = 1 then '1' else '' end ETL_01
            		,case when ETL_Period = 2 then '2' else '' end ETL_02
            		,case when ETL_Period = 3 then '3' else '' end ETL_03
            		,case when ETL_Period = 4 then '4' else '' end ETL_04
            		,case when ETL_Period = 6 then '6' else '' end ETL_06
            		,sum(TPH_14Day_Total) over (partition by jobID) TPH14D_Job_Total
            		,sum(TPH_7Day_Total)  over (partition by jobID) TPH7D_Job_Total
            		,sum(TPH_3Day_Total)  over (partition by jobID) TPH3D_Job_Total
            		,sum(TPH_14Day_Total) over (partition by ETL_Period) TPH14D_Period_Total
            		,sum(TPH_7Day_Total)  over (partition by ETL_Period) TPH7D_Period_Total
            		,sum(TPH_3Day_Total)  over (partition by ETL_Period) TPH3D_Period_Total
            		,sum(TPH_14Day_Total) over () TPH14D_Total
            		,sum(TPH_7Day_Total)  over () TPH7D_Total
            		,sum(TPH_3Day_Total)  over () TPH3D_Total
            	  from prodbbymeadhocvws.rasc_DBPerf_Header_Period_Dt14
            	 where UserType='Batch'
            ) xx
    group by 1, 7,8,9,10,11,12
) x
left join PRODBBYMEADHOCDB.Fort_Job j
	on x.jobID = j.jobID
order by 4 desc, 3 desc, 5 desc, 2
--order by 9 desc, 8 desc, 10 desc, 7;

select
        toi.offr_key
        ,typ.subclass_type
  from ProdBBYvws.TBEND_OF_ITEM toi
join    ProdBBYvws.TBEND_SA_ITEM itm
        on  itm.OFFR_KEY = toi.OFFR_KEY
    AND toi.REC_STAT_CDE = 'C'
left join prodbbymeadhocdb.bbym_sti_subclasses sc
        on toi.scls_id=sc.scls_id
        and toi.class_id=sc.class_id
 LEFT JOIN  PRODBBYMEADHOCDB.BBYM_STI_SUBCLASS_TYPE typ
    ON  sc.CLASS_ID = typ.CLASS_ID
    AND sc.SCLS_ID = typ.SCLS_ID
    AND itm.SLS_BSNS_DT BETWEEN typ.REC_BEG_DT AND typ.REC_END_DT
left join prodbbymeadhocdb.bbym_sti_sku_type sku
        on sku.sku_id = itm.sku_id
 where sku.sku_type='PRP';


Enclosed are two scripts written by NCR consultants.
Hope it helps
Dan

1) Simple, you can select databases, which will be reported:
////////////////////////////////////////////////// ////////////////
////////////////////////////////////////////////// ////////////////
--Here is an SQL that was written by Frank Slovac from NCR to help me
answer the same question that you have:
sel
    c.databasenamei as DatabaseName
    , b.tvmnamei as TableName
    , a.fieldname as ColumnName
    , cast((case when substr(fieldstatistics,1,1) = 'D2'XB then '2002-'
        when substr(fieldstatistics,1,1) = 'D1'XB then '2001-'
        when substr(fieldstatistics,1,1) = 'D0'XB then '2000-'
        when substr(fieldstatistics,1,1) = 'CF'XB then '1999-'
        when substr(fieldstatistics,1,1) = 'CE'XB then '1998-'
        else NULL
        end)||
        (case when substr(fieldstatistics,3,1) = '01'XB then '01-'
            when substr(fieldstatistics,3,1) = '02'XB then '02-'
            when substr(fieldstatistics,3,1) = '03'XB then '03-'
            when substr(fieldstatistics,3,1) = '04'XB then '04-'
            when substr(fieldstatistics,3,1) = '05'XB then '05-'
            when substr(fieldstatistics,3,1) = '06'XB then '06-'
            when substr(fieldstatistics,3,1) = '07'XB then '07-'
            when substr(fieldstatistics,3,1) = '08'XB then '08-'
            when substr(fieldstatistics,3,1) = '09'XB then '09-'
            when substr(fieldstatistics,3,1) = '0A'XB then '10-'
            when substr(fieldstatistics,3,1) = '0B'XB then '11-'
            when substr(fieldstatistics,3,1) = '0C'XB then '12-'
            else 'xx-'
            end)||
(case when substr(fieldstatistics,4,1) = '01'XB then '01'
when substr(fieldstatistics,4,1) = '02'XB then '02'
when substr(fieldstatistics,4,1) = '03'XB then '03'
when substr(fieldstatistics,4,1) = '04'XB then '04'
when substr(fieldstatistics,4,1) = '05'XB then '05'
when substr(fieldstatistics,4,1) = '06'XB then '06'
when substr(fieldstatistics,4,1) = '07'XB then '07'
when substr(fieldstatistics,4,1) = '08'XB then '08'
when substr(fieldstatistics,4,1) = '09'XB then '09'
when substr(fieldstatistics,4,1) = '0A'XB then '10'
when substr(fieldstatistics,4,1) = '0B'XB then '11'
when substr(fieldstatistics,4,1) = '0C'XB then '12'
when substr(fieldstatistics,4,1) = '0D'XB then '13'
when substr(fieldstatistics,4,1) = '0E'XB then '14'
when substr(fieldstatistics,4,1) = '0F'XB then '15'
when substr(fieldstatistics,4,1) = '10'XB then '16'
when substr(fieldstatistics,4,1) = '11'XB then '17'
when substr(fieldstatistics,4,1) = '12'XB then '18'
when substr(fieldstatistics,4,1) = '13'XB then '19'
when substr(fieldstatistics,4,1) = '14'XB then '20'
when substr(fieldstatistics,4,1) = '15'XB then '21'
when substr(fieldstatistics,4,1) = '16'XB 

Insert into  prodbbymeadhocdb.FORT_JOB_WAVE_SQL  
    (JobID, WaveID,SQLID,SQLNAME,ShellSQL,EmailOnFailFlag)
Select 3,3,Rank() over(Order by NewTableName desc, CurrTableName asc) as SQLID
    ,case when CurLetter='e' then 'Drop ' || trim(CurrTableName)
         else 'Rename ' || trim(CurrTableName) end as SQLName
    ,case when CurLetter='e' then 'Drop Table prodbbymeadhocwrk.' || trim(CurrTableName)
         else 'Rename Table prodbbymeadhocwrk.' || trim(CurrTableName)
                || ' to prodbbymeadhocwrk.' || NewTableName end 
        || ';' as RenameStatement
    ,'Y' as EmailonError
From 
(
    Select TableName as CurrTableName
        ,substr(TableName,4,1) as CurLetter
        ,case 
         when CurLetter='a' then 'b'
         when CurLetter='b' then 'c'
         when CurLetter='c' then 'd'
         when CurLetter='d' then 'e' end as NextLetter
        ,substr(TableName,1,3) || NextLetter || substr(TableName,5) as NewTableName
      from dbc.Tables t
     where t.databasename = 'prodbbymeadhocwrk'
       and t.TableName like 'bu0%'
       and t.TableKind='T'
) a

rasc_dbperf_detail

	Calndr_Dt                     	DA	?	N	YYYY-MM-DD                    	?	4	?	?	?	?	N	T	?	?	?	?
	Calndr_Tm                     	D 	?	N	99:99:99.99                   	?	4	8	2	?	?	N	T	?	?	?	?
	SQLType                       	CF	?	Y	X(30)                         	?	30	?	?	?	?	N	T	?	1	?	?
	SQLIdText                     	CV	?	Y	X(50)                         	?	50	?	?	?	?	N	T	?	1	?	?
	ActionId                      	I 	?	Y	-(10)9                        	?	4	?	?	?	?	N	T	?	?	?	?
	AlertId                       	I 	?	Y	-(10)9                        	?	4	?	?	?	?	N	T	?	?	?	?
	JobId                         	I 	?	Y	-(10)9                        	?	4	?	?	?	?	N	T	?	?	?	?
	WaveId                        	I 	?	Y	-(10)9                        	?	4	?	?	?	?	N	T	?	?	?	?
	SQLId                         	I 	?	Y	-(10)9                        	?	4	?	?	?	?	N	T	?	?	?	?
	UserName                      	CV	?	Y	X(30)                         	?	30	?	?	?	?	N	T	?	1	?	?
	SessionId                     	I 	?	N	-(10)9                        	?	4	?	?	?	?	N	T	?	?	?	?
	RequestNum                    	I 	?	N	-(10)9                        	?	4	?	?	?	?	N	T	?	?	?	?
	Total_CPU                     	D 	?	Y	-----------------.99          	?	8	18	2	?	?	N	T	?	?	?	?
	Total_IO                      	D 	?	Y	------------------9.          	?	8	18	0	?	?	N	T	?	?	?	?

