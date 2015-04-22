-- $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/dist_vec_utils.sql,v 1.2 2005/11/16 22:19:43 yangl Exp $
--
-- Types and functions to split distribution vectors 
-- into distributions (like those in hostdb.dist table)
--	distribution vectors: 2345@20, 9876@80
--	distribution:
--			2345 20
--			9876 80
--

create or replace type distvec_t as object
		(
			id		number(6)
			,acct		number(6)
			,pct		number(5,2)
		)
/

create type distvec_tab_t as table of distvec_t
/

create type entity_distvec_t as object
	(
		name		varchar2(10)
		,acct		number(6)
		,pct		number(5,2)
	)
/

show errors

create type entity_distvec_tab_t is table of entity_distvec_t
/

show errors

--
-- Usage example: 
-- SQL> select * from table(distsplit(cursor(select * from dist_vector_v)));
-- SQL> desc dist_vector_v
--	dist		number(6)
--	dist_vec	varchar2(4000)
--
create or replace function distsplit(p_distvec IN sys_refcursor)
		return distvec_tab_t 
		pipelined
	is
	--
		-- l_distvec	vecstring_rec_t;
		l_pos		pls_integer := 0;
		l_pctpos	pls_integer := 0;
		l_sep		char(1) := ',';
		l_pctsep	char(1) := '@';
		-- l_pct		number(6, 2) := 100;
		-- l_acct		number(6);
		l_vecstring	varchar2(4000);
		l_distsingle	varchar2(200);
	--
		l_distid	hostdb.dist.dist%type := 0;
		l_string	varchar2(4000) := '';
		l_outrec	distvec_t := distvec_t(0, 0, 0);
	--
	begin
		loop
			-- fetch p_distvec into l_distvec;
			l_string := '';
			fetch p_distvec into l_distid, l_string;
			exit when (p_distvec%NOTFOUND);
			
			l_vecstring := l_string || l_sep;
			l_pos := 0;
			l_outrec.id := l_distid;
			loop
				l_outrec.id := l_distid;
				l_outrec.pct := 100;
				l_outrec.acct := 0;

				l_pos := instr(l_vecstring, l_sep);
				-- exit when l_pos=0;
				
				l_distsingle := substr(l_vecstring, 1, l_pos-1);
				l_pctpos := instr(l_distsingle, l_pctsep);
				if l_pctpos = 0 then
					l_outrec.pct := 100;
					l_outrec.acct := l_distsingle;
				else
					l_outrec.pct := substr(l_distsingle, l_pctpos+1);
					l_outrec.acct := substr(l_distsingle, 1, l_pctpos-1);
				end if;
				pipe row (l_outrec);

				exit when (l_pos = length(l_vecstring) or l_pos = 0);
				l_vecstring := substr(l_vecstring, l_pos+1);
			end loop;
		end loop;
		return;
	end distsplit;
/
show errors

create or replace function entity_distsplit(p_distvec IN sys_refcursor)
		return entity_distvec_tab_t 
		pipelined
	is
	--
		l_pos		pls_integer := 0;
		l_pctpos	pls_integer := 0;
		l_sep		char(1) := ',';
		l_pctsep	char(1) := '@';
		l_vecstring	varchar2(4000);
		l_distsingle	varchar2(200);
	--
		l_distid	varchar2(10) := null;
		l_string	varchar2(4000) := '';
		l_outrec	entity_distvec_t := entity_distvec_t('', 0, 0);
	--
	begin
		loop
			-- fetch p_distvec into l_distvec;
			l_string := '';
			fetch p_distvec into l_distid, l_string;
			exit when (p_distvec%NOTFOUND);
			
			l_vecstring := l_string || l_sep;
			l_pos := 0;
			l_outrec.name := l_distid;
			loop
				l_outrec.name := l_distid;
				l_outrec.pct := 100;
				l_outrec.acct := 0;

				l_pos := instr(l_vecstring, l_sep);
				-- exit when l_pos=0;
				
				l_distsingle := substr(l_vecstring, 1, l_pos-1);
				l_pctpos := instr(l_distsingle, l_pctsep);
				if l_pctpos = 0 then
					l_outrec.pct := 100;
					l_outrec.acct := l_distsingle;
				else
					l_outrec.pct := substr(l_distsingle, l_pctpos+1);
					l_outrec.acct := substr(l_distsingle, 1, l_pctpos-1);
				end if;
				pipe row (l_outrec);

				exit when (l_pos = length(l_vecstring) or l_pos = 0);
				l_vecstring := substr(l_vecstring, l_pos+1);
			end loop;
		end loop;
		return;
	end entity_distsplit;
/
show errors


-- create or replace package dist_utils
-- is
-- 	type vecstring_rec_t is record
-- 		(
-- 			id		hostdb.dist.dist%type
-- 			,vec_string	varchar2(4000)
-- 		);
-- 
-- 	type distvec_t is record
-- 		(
-- 			id		hostdb.dist.dist%type
-- 			--,vec_string	varchar2(4000)
-- 			,acct		number(6)
-- 			,pct		number(5,2)
-- 		);
-- 	type distvec_tab_t is table of distvec_t;
-- 	type dist_refcur_t is REF CURSOR return hostdb.dist%ROWTYPE;
-- 
-- 	type entity_distvec_t is record
-- 		(
-- 			name		varchar2(10)
-- 			--,vec_string	varchar2(4000)
-- 			,acct		number(6)
-- 			,pct		number(5,2)
-- 		);
-- 	type entity_distvec_tab_t is table of entity_distvec_t;
-- 
-- 	--function distsplit(p_distvec IN dist_refcur_t) return distvec_tab_t pipelined;
-- 	function distsplit(p_distvec IN sys_refcursor) return distvec_tab_t pipelined;
-- 	--function entity_distsplit(p_distvec IN sys_refcursor) return entity_distvec_tab_t pipelined;
-- end dist_utils;
-- .
-- RUN
-- show errors
-- 
-- create or replace package body dist_utils 
-- is
-- 	/*
-- 	 * split the distribution vector string into 
-- 	 * (account, pct) rows
-- 	 */
-- 	--function distsplit(p_distvec IN dist_refcur_t)
-- 	function distsplit(p_distvec IN sys_refcursor)
-- 		return distvec_tab_t 
-- 		pipelined
-- 	is
-- 	--
-- 		-- l_distvec	vecstring_rec_t;
-- 		l_pos		pls_integer := 0;
-- 		l_pctpos	pls_integer := 0;
-- 		l_sep		char(1) := ',';
-- 		l_pctsep	char(1) := '@';
-- 		-- l_pct		number(6, 2) := 100;
-- 		-- l_acct		number(6);
-- 		l_vecstring	varchar2(4000);
-- 		l_distsingle	varchar2(200);
-- 	--
-- 		l_distid	hostdb.dist.dist%type := 0;
-- 		l_string	varchar2(4000) := '';
-- 		l_outrec	distvec_t;
-- 	--
-- 	begin
-- 		loop
-- 			-- fetch p_distvec into l_distvec;
-- 			fetch p_distvec into l_distid, l_string;
-- 			exit when (p_distvec%NOTFOUND);
-- 			
-- 			l_vecstring := l_string || l_sep;
-- 			l_pos := 0;
-- 			l_outrec.id := l_distid;
-- 			loop
-- 				l_outrec.pct := 100;
-- 				l_outrec.acct := 0;
-- 
-- 				l_pos := instr(l_vecstring, l_sep);
-- 				exit when l_pos=0;
-- 				
-- 				l_distsingle := substr(l_vecstring, 1, l_pos-1);
-- 				l_pctpos := instr(l_distsingle, l_pctsep);
-- 				if l_pctpos = 0 then
-- 					l_outrec.pct := 100;
-- 					l_outrec.acct := l_distsingle;
-- 				else
-- 					l_outrec.pct := substr(l_distsingle, l_pctpos+1);
-- 					l_outrec.acct := substr(l_distsingle, 1, l_pctpos-1);
-- 				end if;
-- 				l_vecstring := substr(l_vecstring, l_pos+1);
-- 				pipe row (l_outrec);
-- 			end loop;
-- 			
-- 		end loop;
--		return;
-- 	end distsplit;
-- 
-- 	/*
-- 	 * use sys_refcursor so that both user and machine can 
-- 	 * share the same function.
-- 	 */
-- 	--function entity_distsplit(p_distvec IN sys_refcursor) 
-- 	--	return entity_distvec_tab_t 
-- 	--	pipelined
-- 	--is
-- 	--begin
-- 	--	null;
-- 	--end entity_distsplit;
-- end dist_utils;
-- /
-- show errors
