REM The objective of this function is to transpose rows to columns.
REM
REM This RowToCol function is built with invoker-rights AUTHID CURRENT_USER. The function works on tables/views of the user who invokes the function, not on the owner of this function.
REM 
REM RowToCol takes two parameters:
REM 1. SQL Statement: You can pass any valid SQL statement to this function.
REM 2. Delimiter: You can pass any character as a delimiter. Default value is `,?
REM 
REM SELECT a.deptno, a.dname, a.loc, 
REM rowtocol('SELECT DISTINCT job FROM emp WHERE deptno = ' ||a.deptno) as jobs
REM FROM dept a;
REM Example 2: Where the content in the WHERE clause is characters, put it in Sting format.
REM Notice, the main query and the passing query source is same table (EMP). So, use DISTINCT clause in the main query.
REM SELECT DISTINCT a.job
REM     ,rowtocol('SELECT ename FROM emp WHERE job = ' || '''' || a.job || '''' || ' ORDER BY ename')
REM   AS Employees
REM     FROM emp a;

CREATE OR REPLACE FUNCTION rowtocol( p_slct IN VARCHAR2,
     p_dlmtr IN VARCHAR2 DEFAULT ',' ) RETURN VARCHAR2 
     AUTHID CURRENT_USER AS
     /*
1) Column should be character type.
2) If it is non-character type, column has to be converted into character type.
3) If the returned rows should in a specified order, put that ORDER BY CLASS in the SELECT statement argument.
4) If the SQL statement happened to return duplicate values, and if you don't want that to happen, put DISTINCT in the SELECT statement argument.
*/
     TYPE c_refcur IS REF CURSOR;
     lc_str VARCHAR2(4000);
     lc_colval VARCHAR2(4000);
     c_dummy c_refcur;
     l number;

     BEGIN

     OPEN c_dummy FOR p_slct;

     LOOP
     FETCH c_dummy INTO lc_colval;
     EXIT WHEN c_dummy%NOTFOUND;
     lc_str := lc_str || p_dlmtr || lc_colval;
     END LOOP;
     CLOSE c_dummy;
     RETURN SUBSTR(lc_str,2);

     /* 

     EXCEPTION 
     WHEN OTHERS THEN

     lc_str := SQLERRM;
     IF c_dummy%ISOPEN THEN
     CLOSE c_dummy;
     END IF;
     RETURN lc_str;
     */
     END;

     /
