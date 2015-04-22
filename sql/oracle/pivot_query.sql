--$Id: pivot_query.sql,v 1.2 2005/06/09 16:49:51 yangl Exp $
--
-- This is an example of pivot query in Oracle
-- Here is an example of a pivot query.  Say you have the following set of data:
-- 
-- scott@DEV816> select job, deptno, count(*)
--   2    from emp
--   3   group by job, deptno
--   4  /
-- 
-- JOB           DEPTNO   COUNT(*)
-- --------- ---------- ----------
-- ANALYST           20          2
-- CLERK             10          1
-- CLERK             20          2
-- CLERK             30          1
-- MANAGER           10          1
-- MANAGER           20          1
-- MANAGER           30          1
-- PRESIDENT         10          1
-- SALESMAN          30          4
-- 
-- 9 rows selected.
-- 
-- 
-- And you would like to make DEPTNO be a column.  We have 4 deptno's in EMP, 
-- 10,20,30,40.  We can make columns dept_10, dept_20, dept_30, dept_40 that have 
-- the values that are currently in the count column.  It would look like this:
-- 
-- 
-- scott@DEV816> 
-- scott@DEV816> select job,
-- 2         max( decode( deptno, 10, cnt, null ) ) dept_10,
-- 3         max( decode( deptno, 20, cnt, null ) ) dept_20,
-- 4         max( decode( deptno, 30, cnt, null ) ) dept_30,
-- 5         max( decode( deptno, 40, cnt, null ) ) dept_40
-- 6    from ( select job, deptno, count(*) cnt
-- 7             from emp
-- 8            group by job, deptno )
-- 9   group by job
- 10  /
-- 
-- JOB          DEPT_10    DEPT_20    DEPT_30    DEPT_40
-- --------- ---------- ---------- ---------- ----------
-- ANALYST                       2
-- CLERK              1          2          1
-- MANAGER            1          1          1
-- PRESIDENT          1
-- SALESMAN                                 4
--That has pivoted the CNT column by deptno across job.
--
--That works if you know the domain of deptno's.  What if you didn't though.  What 
--if you wanted JOB to be the column instead and leave deptno in the rows?  You 
--might not know of all of the possible jobs, or there might be 100's of them.  We 
--can use object types to pivot then:
--
--
--scott@DEV816> create or replace type myScalarType as object
  --2  ( job  varchar2(30),
  --3    cnt  number
  --4  )
  --5  /
--
--Type created.
--
--scott@DEV816> create or replace type myArrayType as table of myScalarType
  --2  /
--
--Type created.
--
--scott@DEV816> 
--scott@DEV816> column x format a40 word_wrapped
--scott@DEV816> select deptno,
  --2         cast ( multiset( select job, count(*) cnt
  --3                            from emp
  --4                           where emp.deptno = dept.deptno
  --5                           group by job ) as myArrayType ) x
  --6    from dept
  --7  /
--
--    DEPTNO X(JOB, CNT)
------------ ----------------------------------------
--        10 MYARRAYTYPE(MYSCALARTYPE('CLERK', 1),
--           MYSCALARTYPE('MANAGER', 1),
--           MYSCALARTYPE('PRESIDENT', 1))
--
--        20 MYARRAYTYPE(MYSCALARTYPE('ANALYST', 2),
--           MYSCALARTYPE('CLERK', 2),
--           MYSCALARTYPE('MANAGER', 1))
--
--        30 MYARRAYTYPE(MYSCALARTYPE('CLERK', 1),
--           MYSCALARTYPE('MANAGER', 1),
--           MYSCALARTYPE('SALESMAN', 4))
--
--        40 MYARRAYTYPE() 
--
--
create or replace package pivot
as
   type rc is ref cursor;
   -- in 9i, use SYS_REF_CURSOR
   procedure data ( p_cursor in out rc );
   -- procedure data ( p_cursor in out SYS_REF_CURSOR );
end;
/
create or replace package body pivot
as
                                                                                 
       
procedure data( p_cursor in out rc )
is
    l_stmt long;
begin
       
    l_stmt := 'select tr_date';
    for x in ( select distinct item_id from t order by 1 )
    loop
        l_stmt := l_stmt ||
        ', max(decode(item_id,' || x.item_id || 
             ', adult )) adult_' || x.item_id ||
        ', max(decode(item_id,' || x.item_id || 
             ', child )) child_' || x.item_id;
    end loop;
    l_stmt := l_stmt || ' from t group by tr_date order by tr_date';
                                                                                 
       
    open p_cursor for l_stmt;
end;
                                                                                 
       
end;
/
                                                                                 
       
                                                                                 
       
variable x refcursor
set autoprint on
exec pivot.data( :x );
