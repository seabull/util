--set termout off
set linesize 300
--set heading off
--set feedback off

truncate table charge_hist;
truncate table service_d;
truncate table time_d;
truncate table acct_d;
truncate table affiliation_d;
truncate table os_d;

drop table charge_hist;
drop table service_d;
drop table time_d;
drop table acct_d;
drop table affiliation_d;
drop table os_d;


	-- seq	number(10)
create table charge_hist
(
	name	varchar2(40)
	,id	varchar2(9)
	,journal	number(5)
	,post_date	date
	,post_month	varchar2(3)
	,post_year	varchar2(4)
	,post_fy	varchar2(4)
	,trans_date	date
	,acct_id	number(6)
	,acct		varchar2(68)
	,acct_flag	varchar2(12)
	,acct_type	varchar2(2)
	,acct_projorg	varchar2(8)
	,abbrev		varchar2(8)
	,dept_no	varchar2(5)
	,service_type	varchar2(2)
	,category	varchar2(40)
	,detailed_cat	varchar2(40)
	,service_id	number(3)
	,os_class	varchar2(10)
	,jnl_type	char(1)
	,unit_charge	number(6,2)
	,pct		number(6,2)
	,amt_charged	number(6,2)
)
tablespace costing
/

create table service_d
(
	service_id	number(3)
		constraint service_d_pk primary key using index tablespace indx
	,service_type	varchar2(2)
	,category	varchar2(40)
	,detailed_cat	varchar2(40)
)
tablespace costing
/

create table trans_d
(
	,trans_date	date
)
tablespace costing
/
create table time_d
(
	journal	number(5)
		constraint time_d_pk primary key using index tablespace indx
	,post_date	date
	,post_month	varchar2(3)
	,post_year	varchar2(4)
	,post_fy	varchar2(4)
	,jnl_type	char(1)
)
tablespace costing
/

create table acct_d
(
	id		number(6)
		constraint acct_d_pk primary key using index tablespace indx
	,acct		varchar2(68)
	,acct_flag	varchar2(12)
	,acct_type	varchar2(2)
	,acct_projorg	varchar2(8)
)
tablespace costing
/

create table affiliation_d
(
	numb		varchar2(5)
		constraint affiliation_d_pk primary key using index tablespace indx
	,abbrev		varchar2(8)
)
tablespace costing
/

create table os_d
(
	os_class	varchar2(10)
		constraint os_d_pk primary key using index tablespace indx
)
tablespace costing
/

alter table charge_hist add constraint chargehist_serviceid_fk 
	foreign key (service_id)
	references service_d (service_id)
	enable
/

alter table charge_hist add constraint chargehist_jnl_fk 
	foreign key (journal)
	references time_d (journal)
	enable
/

alter table charge_hist add constraint chargehist_acctid_fk 
	foreign key (acct_id)
	references acct_d (id)
	enable
/

alter table charge_hist add constraint chargehist_affilication_fk 
	foreign key (dept_no)
	references affiliation_d (numb)
	enable
/

alter table charge_hist add constraint chargehist_os_fk 
	foreign key (os_class)
	references affiliation_d (os_class)
	enable
/


insert into charge_hist
(
	name	
	,id
	,journal
	,post_date
	,post_month
	,post_year
	,post_fy
	,trans_date
	,acct_id
	,acct	
	,acct_flag
	,acct_type
	,acct_projorg	
	,abbrev	
	,dept_no	
	,service_type	
	,category
	,detailed_cat	
	,service_id
	,os_class
	,jnl_type	
	,unit_charge
	,pct
	,amt_charged
)
select
	hr.hostname
	,hr.assetno
	,hc.journal
	,j.post_date
	,to_char(j.post_date, 'MON')
	,to_char(j.post_date, 'YYYY')
	,to_char(add_months(j.post_date, -6), 'YYYY')
	,hc.trans_date
	,a.id
	,account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null)
	,decode(hc.account_flag, NULL, 'valid', 'i', 'Internal','I','Internal','l','Limbo','L','Limbo','Unknown')
	,decode(a.project, null, 'GL', 'GM')
	,nvl(a.project, a.org)
	,d.abbrev
	,d.numb
	,s.type
	,s.type||'-'||decode(s.attr2, null, decode(s.attr, null, s.subtype||s.other, s.attr), s.attr2) 
	,s.category
	,hc.service_id
	,s.os_class
	,j.journal_type_flag
	,hc.charge
	,hc.pct
	,hc.amount
  from hostdb.host_charged hc
	, hostdb.capequip c
	, hostdb.host_recorded hr
	, hostdb.services s
	, hostdb.journals j
	, hostdb.accounts a
	, hostdb.depts d
 where 
	hc.hr_id=hr.id
	and hc.service_id=s.id
	and hc.journal=j.id
	and hc.account=a.id
	and hr.assetno=c.assetnum
	and nvl(c.dept,'05005')=d.numb
	and j.id>222
	and j.id<228
/

insert into service_d
(
	service_id
	,service_type	
	,category
	,detailed_cat	
)
select
	unique
	s.id
	,s.type
	,s.type||'-'||decode(s.attr2, null, decode(s.attr, null, s.subtype||s.other, s.attr), s.attr2) 
	,s.category
  from hostdb.services s
/

insert into time_d
(
	journal	
	,post_date	
	,post_month
	,post_year
	,post_fy
	,jnl_type
)
select
	unique
	j.id
	,j.post_date
	,to_char(j.post_date, 'MON')
	,to_char(j.post_date, 'YYYY')
	,to_char(add_months(j.post_date, -6), 'YYYY')
	,j.journal_type_flag
  from hostdb.journals j
/

insert into trans_d
(
	trans_date
)
select 
	unqiue 
	hc.trans_date
  from host_charged hc
 where 
	j.id>222
   and j.id<228

insert into acct_d
(
	id		
	,acct	
	,acct_flag	
	,acct_type
	,acct_projorg	
)
select
	unique
	a.id
	,account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null)
	,decode(a.flag, NULL, 'valid', 'i', 'Internal','I','Internal','l','Limbo','L','Limbo','Unknown')
	,decode(a.project, null, 'GL', 'GM')
	,nvl(a.project, a.org)
  from hostdb.accounts a
/
insert into affiliation_d
(
	numb		
	,abbrev	
)
select
	d.numb
	,d.abbrev
  from hostdb.depts d
/
insert into os_d
(
	os_class
)
select 
	unique
	s.os_class
  from hostdb.services s
 where os_class is not null
/
