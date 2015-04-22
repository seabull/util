-- Padding 0s for timestamp 
-- Month/Date/Year Hour:Minute:Second AM/PM string.
-- 6/12/2010 5:20:6 am
-- 06/12/2010 05:20:06 am

select top 100 interview_start
, substr ( interview_start , 1, index( interview_start,'/') -1) as m
, case when CHARACTER_LENGTH(m) = 1 then '0'||m else m end as mvalue
, substr ( interview_start , index( interview_start,'/')+1) as mnext
, substr ( mnext , 1, index( mnext,'/') -1) as d
, case when CHARACTER_LENGTH(d) = 1 then '0'||d else d end as dvalue
, substr ( mnext , index(mnext,'/')+1 ) as dnext
, substr ( dnext , 1, index( dnext,' ') -1) as yvalue
, substr ( interview_start , index( interview_start,' ')+1, index( interview_start,':') -1) as hnext
, substr ( hnext , 1,index(hnext,':') -1) as h
, case when CHARACTER_LENGTH(h) = 1 then '0'||h else h end as hvalue
, substr ( interview_start , index( interview_start,':')) as remvalue
, trim(mvalue||'/'||dvalue||'/'||yvalue||' '||hvalue||remvalue) as datevalue
, datevalue (timestamp(0), format 'MM/DD/YYYYBHH:MI:SSBT') as thetime
, cast(thetime as varchar(50))
from prodbbymeadhocwrk.skynet_csidata


