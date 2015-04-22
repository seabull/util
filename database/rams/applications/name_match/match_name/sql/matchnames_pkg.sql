-- $Id: matchnames_pkg.sql,v 1.10 2008/02/01 17:57:33 yangl Exp $
--

create or replace package hostdb.matchnames_pkg as
	xc_invalid_id	Exception;

	constDEBUGLEVEL_A	pls_integer	:= 2;
	constDEBUGLEVEL_B	pls_integer	:= 4;
	constDEBUGLEVEL_C	pls_integer	:= 8;
	constDEBUGLEVEL_D	pls_integer	:= 16;
	constDEBUGLEVEL_E	pls_integer	:= 32;

	xn_match_error		pls_integer	:= -20100;
	xn_id_error		pls_integer	:= -20101;

	procedure init_bids ;
	function inc_bid return number;
	function get_curbid return number;
	procedure fill_uidmatches;
	procedure match_fullname;
	procedure match_fullname(p_bid IN number);
	procedure match_lastfirst(p_bid IN number);
end matchnames_pkg;
/
show errors

create or replace package body hostdb.matchnames_pkg as

	procedure init_bids IS
	l_cnt	pls_integer := 0;
	l_bid	pls_integer := 0;
	begin
		select count(*)
		  into l_cnt
		  from name_error_bids;

		if l_cnt < 1 then
			insert into name_error_bids (id, post_date)
			select l_bid
				, sysdate
			  from dual;
		end if;
	
	end init_bids;

	procedure fill_uidmatches
	is
	begin
		traceit.log(constDEBUGLEVEL_A,'Enter hostdb.matchnames_pkg.fill_uidmatches');

		update name
		   set emp_num=(select unique emp_num from emp_tbl where lower(andrew_uid)=princ)
		 where princ in 
			(
				select
					n.princ
					--e.id
					--,e.emp_num
				  from emp_tbl e
					, name n
				 where 
					n.emp_num is null
				   and names.lastfirst(lower(n.name))=names.lastfirst(lower(e.full_name))
				   and lower(n.princ)=lower(e.andrew_uid)
			);

		traceit.log(constDEBUGLEVEL_B,'fill_uidmatches - %s rows updated in hostdb.name', SQL%ROWCOUNT);
		traceit.log(constDEBUGLEVEL_A,'Exit hostdb.matchnames_pkg.fill_uidmatches');
	end fill_uidmatches;

	procedure match_lastfirst(p_bid IN number) IS
	begin
		traceit.log(constDEBUGLEVEL_A,'Enter hostdb.matchnames_pkg.match_firstlast(p_bid=%s).', p_bid);

		fill_uidmatches;

		insert /*+ append */
		  into name_candidates (candidate_id, eid, emp_num, princ, bid)
			select
				namecand_idseq.nextval
				,x.id
				,x.emp_num
				,x.princ
				,p_bid
			  from (
				select
					distinct
					e.id
					,e.emp_num
					,n.princ
					--,p_bid
				  from emp_tbl e
					, name n
				 where 
					n.emp_num is null
                   and e.emp_num not in (select emp_num from name)
				   and names.lastfirst(lower(n.name))=names.lastfirst(lower(e.full_name))
				) x
			;

		traceit.log(constDEBUGLEVEL_A,'Exit matchnames_pkg.match_firstlast Normal');
	exception
		when others then
			traceit.log(constDEBUGLEVEL_A,'Exit matchnames_pkg.match_firstlast Exception, %s, %s', SQLCODE,substr(SQLERRM, 1, 40));
			raise_application_error(xn_match_error,'Matchname_pkg.match_firstlast - '||sqlcode||':'||substr(sqlerrm, 1, 40));
	end match_lastfirst; 

	procedure match_fullname(p_bid IN number)
	is
	begin
		traceit.log(constDEBUGLEVEL_A,'Enter hostdb.matchnames_pkg.match_fullname(p_bid=%s).', p_bid);
		insert into hostdb.name_error 
			( bid
			 ,princ
			 ,lname
			 ,emp_name
			 ,emp_num
			 ,andrew_id
			)
		 select
			p_bid
			,n1.princ
			,n1.lname
			,e1.emp_name
			,e1.emp_num
			,e1.andrew_id
		   from hostdb.emp e1
			,hostdb.name n1
		  where e1.emp_name in 
			(
				select 
					e.emp_name
					--,count(e.emp_num) 
				  from hostdb.emp e
					,hostdb.name n
				 where 
					n.emp_num is null
					and lower(n.lname)=lower(e.emp_name)
					and n.pri=0
				group by 
					e.emp_name
				having count(e.emp_num)>1
			)
			and lower(n1.lname)=lower(e1.emp_name)
			and n1.emp_num is null
		;

		traceit.log(constDEBUGLEVEL_A,'%s rows inserted into hostdb.name_error', SQL%ROWCOUNT);
		util.log(SQL%ROWCOUNT||' rows inserted into hostdb.name_error');
				
		-- we will have audit in place any way.
		-- save the first 5 letters of the user here.
		update name n
		   set (emp_num,last_update,last_updated_by)=( select e.emp_num
									,sysdate
									,substr(user, 1, 5)||'.mf'
				   from hostdb.emp e
				  where lower(n.lname)=lower(e.emp_name)
				)
		 where n.emp_num is null
		   and n.lname not in (
					select lname 
					  from name_error
					 where bid=p_bid
					)
		   and exists (	select emp_num
				  from emp e2
				 where lower(n.lname)=lower(e2.emp_name)
				)
		   and n.pri=0
			;

		traceit.log(constDEBUGLEVEL_C,'%s rows updated in hostdb.name', SQL%ROWCOUNT);
		util.log(SQL%ROWCOUNT||' rows updated in hostdb.name');
		traceit.log(constDEBUGLEVEL_A,'Exit matchnames_pkg.match_fullname Normal');
	exception
		when others then
			traceit.log(constDEBUGLEVEL_A,'Exit matchnames_pkg.match_fullname Exception, %s, %s', SQLCODE,SQLERRM);
			raise_application_error(xn_match_error,'Exception when doing match. '||SQLERRM);
			
	end match_fullname;

	function inc_bid return number
	is
		l_bid	pls_integer	:= 0;
	begin
		traceit.log(constDEBUGLEVEL_A, 'Enter hostdb.matchnames_pkg.get_bid.');
		lock table name_error_bids in exclusive mode;

		select 
			max(id)+1
			-- nm_errorbid.nextval
		  into l_bid
		  from name_error_bids;

		if l_bid is null then
			traceit.log(constDEBUGLEVEL_A,'l_bid is null. set it to 1');
			l_bid := 1;
		end if;

		if l_bid < 1 then
			traceit.log(constDEBUGLEVEL_A,'Invalid batch id=%s',l_bid);
			raise xc_invalid_id;
		end if;

		insert into name_error_bids (id, post_date)
			select nvl(l_bid, 1), sysdate
			  from dual;

		traceit.log(constDEBUGLEVEL_A,'batch id=%s',l_bid);
		traceit.log(constDEBUGLEVEL_A,'Exit hostdb.matchnames_pkg.get_bid.');
		return l_bid;
	exception
		when xc_invalid_id then
			traceit.log(constDEBUGLEVEL_A,'Exit hostdb.matchnames_pkg.inc_bid with invalid id exception.');
			raise_application_error(xn_id_error,'Invalid id is generated for name_error. bid='||l_bid);

	end inc_bid;

	function get_curbid return number
	is
		l_bid	pls_integer := 0;
	begin
		select 
			max(id)
		  into l_bid
		  from name_error_bids;
		return l_bid;
	end get_curbid;

	procedure match_fullname 
	IS
		l_bid	pls_integer	:= 0;
	begin
		traceit.log(constDEBUGLEVEL_A,'Enter hostdb.matchnames_pkg.match_fullname.');

		l_bid := inc_bid;

		match_fullname(l_bid);

		match_lastfirst(l_bid);

		traceit.log(constDEBUGLEVEL_A,'Exit matchnames_pkg.match_fullname Normal');
	exception
		when xc_invalid_id then
			raise_application_error(xn_id_error,'Invalid id is generated for name_error. bid='||l_bid);

		when others then
			traceit.log(constDEBUGLEVEL_A,'Exit matchnames_pkg.match_fullname Exception, %s, %s', SQLCODE,SQLERRM);
			raise_application_error(xn_match_error,'Exception when doing match. '||SQLERRM);
			
	end match_fullname;
--begin
	--null;
end matchnames_pkg;
/
show errors
