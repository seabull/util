
create or replace type chargeline as object
(
	entity_number	number(6)
	,entity_type	char(1)
	,journal	number(5)
	,account_id	number(6)
	-- 
	,entity_id	varchar2(9)
	,entity_name	varchar2(50)
	,services	number(3)
	,charge		number(6,2)
	,pct		number(5,2)
	,amount		number(6,2)
	,account_flag	char(1)
	,charge_src	char(1)
	,dist_src	char(1)
	,trans_date	date
	,post_date	date
)
/

create or replace type chargeline_t as table of chargeline
/

create or replace package charges_pkg as
	TYPE charge_rec_t IS RECORD (
		entity_id	varchar2(9)
		,entity_type	char(1)
		,journal	number(5)
		,service_id	number(3)
		,charge		number(6,2)
		,pct		number(5,2)
		,amount		number(6,2)
		,account_id	number(6)
		,account_flag	char(1)
		,trans_date	date
		,notes		varchar2(50)
	);
	TYPE charge_rec_tab is table of charge_rec_t;
	TYPE charge_rec_refcur is REF CURSOR return charge_rec_t;

	function get_charges(p_cursor IN sys_refcursor) 
		return chargeline_t pipelined;
end charges_pkg;
/
show error;

create or replace package body charges_pkg as
	--
	--
	-- function get_charges(p_cursor IN sys_refcursor)
	function get_charges(p_cursor IN charge_rec_refcur)
		return chargeline_t
		pipelined
		parallel_enable (partition p_cursor by id)
	is
		charge_rec_t	chg_rec;

	begin
		LOOP
			-- look up
			fetch p_cursor into chg_rec;
			exit when p_cursor%NOTFOUND;

			select
			  into
			  from accounts
			 where id=chg_rec.account_id;

			
			pipe row (chargeline() );
		END LOOP;
	end get_charges;
end charges_pkg;
/
show error
