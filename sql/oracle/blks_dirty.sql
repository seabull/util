-- $Id: blks_dirty.sql,v 1.1 2005/03/29 03:50:30 yangl Exp $
--
REM Check how many blocks are dirty
REM
select 
	dirty
	, count(*) 
  from v$bh 
group by dirty
/
