--$Header: c:\\Repository/database/rams/applications/name_match/match_name/sql/names.sql,v 1.5 2006/07/25 21:06:44 yangl Exp $
--
--create or replace type emp_record_type as object
--(
-- 	id			number
-- 	,full_name		varchar2(50)
-- 	,emp_num		number(7)
-- 	,andrew_uid		varchar2(100)
-- 	,last_name		varchar2(50)
-- 	,first_name		varchar2(50)
-- 	,middle_name		varchar2(50)
--	,flag			char(1)
--	,last_active		date
--	,creation_date		date
--)
--/
--
--create or replace type emp_rectab_type as table of emp_record_type;

create or replace package names
is
	-- Type/subtype definition
	subtype match_t is pls_integer;

	type emp_xt_refcur_t is REF CURSOR return employee_xt%ROWTYPE;

	--
	-- constants
	constMatch		pls_integer := 0;
	constACTIVEFLAG		char(1) := 'A';
	constINACTIVEFLAG	char(1) := 'N';
	constTRUE		number  := 1;
	constFALSE		number  := 0;

	-- public methods
	procedure parse(pFull IN VARCHAR2, pLast OUT varchar2, pMiddle OUT varchar2, pFirst OUT varchar2);
	procedure emp_load;
	procedure emp_load(p_flag IN number);
	-- function equals(pName1 IN varchar2, pName2 IN varchar2) return number;
	function equals(pName1 IN varchar2, pName2 IN varchar2, pNoMiddle IN number default 0) return number;
	procedure emp_flag_update(p_date IN date default sysdate-1);
	function lname(pName IN varchar2) return varchar2;
	function firstname(pName IN varchar2) return varchar2;
	function lastname(pName IN varchar2) return varchar2;
	function lastfirst(pName IN varchar2) return varchar2;
end names;
/
show errors

-- /*
--  * usage of parse_pipe
--  * 	select * from table(names.parse_pipe(cursor(select * from employee_xt)));
--  */
create or replace package body names
is
	/*
	 *
	 * Split the full name passed in into
	 * last middle first
	 *
	**/
	procedure parse(
			pFull    IN	varchar2
			,pLast   OUT	varchar2
			,pMiddle OUT	varchar2
			,pFirst  OUT	varchar2
			)
	is
		l_tname		emp_tbl.full_name%TYPE;
		l_lastmode	boolean := false;
		lc		pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'enter name parse, pFull=%s', pFull);
		IF (pFull is null)
		THEN
			pLast := NULL;
			pFirst := NULL;
			pMiddle := NULL;
		ELSE
			lc := INSTR (pFull, ',');
			
			IF (lc > 0)
			THEN
				l_lastmode := true;

				pLast := LTRIM (RTRIM (SUBSTR (pFull, 1, lc - 1)));
				l_tname := LTRIM (RTRIM (SUBSTR (pFull, lc + 1)));
				traceit.log(traceit.constDEBUGLEVEL_B, 'Last name=%s', pLast);
			ELSE
				lc := INSTR (pFull, ' ', -1);

				pLast := LTRIM (RTRIM (SUBSTR (pFull, lc+1)));
				l_tname := LTRIM(RTRIM(SUBSTR(pFull, 1, lc - 1)));
				traceit.log(traceit.constDEBUGLEVEL_B, 'Deduce Last name as %s', pLast);
			END IF;

			lc := INSTR (l_tname, ' ', -1, 1);
			
			--firstname := lc;
			--middlename := NULL;
			traceit.log(traceit.constDEBUGLEVEL_E, 'Deduce First and Middle names by format from %s', l_tname);

			IF (lc < 1)
			THEN
				pFirst := l_tname;
				pMiddle := NULL;
			ELSE
				pFirst := RTRIM (SUBSTR (l_tname, 1, lc - 1));
				pMiddle := RTRIM (LTRIM (SUBSTR (l_tname, lc + 1)));
			END IF;

		END IF;

		traceit.log(traceit.constDEBUGLEVEL_B, 'Exit name parse, pFirst=%s, pMiddle=%s, pLast=%s', pFirst, pMiddle, pLast);

	end parse;

	function equals(pName1 IN varchar2, pName2 IN varchar2, pNoMiddle IN number default 0)
	return number
	is
		l_rtn		number	:= constFALSE;

		l_last1		emp_tbl.full_name%TYPE := '';
		l_first1	emp_tbl.full_name%TYPE := '';
		l_middle1	emp_tbl.full_name%TYPE := '';

		l_last2		emp_tbl.full_name%TYPE := '';
		l_first2	emp_tbl.full_name%TYPE := '';
		l_middle2	emp_tbl.full_name%TYPE := '';
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'enter names.equals, Name1=%s, Name2=%s, pNoMiddle=%s', pName1, pName2, pNoMiddle);
		if (lower(pName1) = lower(pName2)) then
			l_rtn := constTRUE;
		else
			parse(lower(pName1), l_last1, l_middle1, l_first1);
			traceit.log(traceit.constDEBUGLEVEL_B, 'l_last1=%s, l_middle1=%s, l_first1=%s', l_last1, l_middle1, l_first1);
			parse(lower(pName2), l_last2, l_middle2, l_first2);
			traceit.log(traceit.constDEBUGLEVEL_B, 'l_last2=%s, l_middle2=%s, l_first2=%s', l_last2, l_middle2, l_first2);
			if (l_last1 = l_last2 and l_first1 = l_first2) then
				if (pNoMiddle > 0 or l_middle1 = l_middle2) then
					l_rtn := constTRUE;
				else
					l_rtn := constFALSE;
				end if;
			else
				l_rtn := constFALSE;
			end if;
		end if;
		traceit.log(traceit.constDEBUGLEVEL_B, 'exit names.equals=%s', l_rtn);
		return l_rtn;
	end equals;

	function lname(pName IN varchar2)
	return varchar2
	is
		l_last		emp_tbl.full_name%TYPE;
		l_first		emp_tbl.full_name%TYPE;
		l_middle	emp_tbl.full_name%TYPE;
		l_lname		emp_tbl.full_name%TYPE;
		lc		pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'enter names.lname, pName=%s', pName);
		lc := INSTR (pName, ',');
		if (lc > 0) then
			l_lname := pName;
		else
			parse(pName, l_last, l_middle, l_first);
			l_lname := l_last || ', ' || l_first || ' ' ||l_middle;
		end if;
		traceit.log(traceit.constDEBUGLEVEL_B, 'exit names.lname=%s', l_lname);
		return l_lname;
	end lname;

	function lastname(pName IN varchar2)
	return varchar2
	is
		l_last		emp_tbl.full_name%TYPE;
		l_first		emp_tbl.full_name%TYPE;
		l_middle	emp_tbl.full_name%TYPE;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'enter names.lastname, pName=%s', pName);
		parse(pName, l_last, l_middle, l_first);
		traceit.log(traceit.constDEBUGLEVEL_B, 'exit names.lastname=%s', l_last);
		return l_last;
	end lastname;

	function firstname(pName IN varchar2)
	return varchar2
	is
		l_last		emp_tbl.full_name%TYPE;
		l_first		emp_tbl.full_name%TYPE;
		l_middle	emp_tbl.full_name%TYPE;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'enter names.firstname, pName=%s', pName);
		parse(pName, l_last, l_middle, l_first);
		traceit.log(traceit.constDEBUGLEVEL_B, 'exit names.firstname=%s', l_first);
		return l_first;
	end firstname;

	function lastfirst(pName IN varchar2)
	return varchar2
	is
		l_last		emp_tbl.full_name%TYPE;
		l_first		emp_tbl.full_name%TYPE;
		l_middle	emp_tbl.full_name%TYPE;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'enter names.lastfirst, pName=%s', pName);
		parse(pName, l_last, l_middle, l_first);
		traceit.log(traceit.constDEBUGLEVEL_B, 'exit names.lastfirst=%s', l_last||', '||l_first);
		return l_last||', '||l_first;
	end lastfirst;


	procedure emp_load is
	begin
		emp_load(0);
	end emp_load;

	/*
	 * load employee table with feeder.
	 * p_flag > 1 : force to load
	 */
	procedure emp_load(p_flag IN number)
	is
		l_cnt	pls_integer := 0;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'enter names.emp_load');

		if (p_flag > 0) then
			l_cnt := 0;
		else
			select count(*)
			  into l_cnt
			  from emp_tbl
			 where last_active > trunc(sysdate-1);
		end if;

		-- Do nothing if the data for today has been loaded.
		if l_cnt < 1 then
			emp_flag_update(sysdate);

			merge into emp_tbl e
				using (select	distinct
						emp_num
						,full_name
						,andrew_uid
					 from employee_xt
				) x
			on (e.emp_num = x.emp_num and e.full_name = x.full_name)
			when matched then
				update set e.flag=constACTIVEFLAG, e.last_active=trunc(sysdate)
			when not matched then
				insert (e.id, e.full_name, e.emp_num, e.andrew_uid, e.flag, e.last_active,e.creation_date)
				values (empid_seq.nextval, x.full_name, x.emp_num, x.andrew_uid, constACTIVEFLAG, sysdate, sysdate)
			;
		end if;

		traceit.log(traceit.constDEBUGLEVEL_B, 'exit names.emp_load');
	end emp_load;

	procedure emp_flag_update(p_date IN date default sysdate-1)
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'enter names.emp_flag_update');
		update emp_tbl
		   set flag=constINACTIVEFLAG
		 where last_active < p_date
		   and flag=constACTIVEFLAG;
		traceit.log(traceit.constDEBUGLEVEL_B, 'exit names.emp_flag_update. updated %s entries.', SQL%ROWCOUNT);
	end emp_flag_update;

end names;
/
show errors
grant execute on hostdb.names to names_change;
