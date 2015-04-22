-- $Id: views_useful.sql,v 1.3 2005/10/14 14:30:06 yangl Exp $
--
-- You may need to create synonyms first. see ../synonyms/aliases_hostdb.sql
--
-- The following object privs need to be granted to create the views.
--
-- grant create view to "YANGL@CS.CMU.EDU";
-- grant select on hostdb.who to "YANGL@CS.CMU.EDU";
-- grant select on hostdb.name to "YANGL@CS.CMU.EDU";
-- grant select on hostdb.machtab to "YANGL@CS.CMU.EDU";
-- grant select on hostdb.journals to "YANGL@CS.CMU.EDU";
-- grant select on hostdb.accounts to "YANGL@CS.CMU.EDU";
-- 
-- grant select on hostdb.who_charged to "YANGL@CS.CMU.EDU";
-- grant select on hostdb.who_charged_summary to "YANGL@CS.CMU.EDU";
-- grant select on hostdb.who_recorded to "YANGL@CS.CMU.EDU";
-- grant select on hostdb.who_service_charge to "YANGL@CS.CMU.EDU";
-- grant select on hostdb.who_service to "YANGL@CS.CMU.EDU";
-- 
-- grant select on hostdb.host_charged to "YANGL@CS.CMU.EDU";
-- grant select on hostdb.host_charged_summary to "YANGL@CS.CMU.EDU";
-- grant select on hostdb.host_recorded to "YANGL@CS.CMU.EDU";
-- grant select on hostdb.host_service_charge to "YANGL@CS.CMU.EDU";
-- grant select on hostdb.host_service to "YANGL@CS.CMU.EDU";
--

--
-- Journals related views
--
Create or Replace view journals_adjust_v
as
select /*+ first_row */
	*
  from hostdb.journals 
 where 
	journal_type_flag='A'
/

Create or Replace view journals_monthly_v
as
select /*+ first_row */
	*
  from hostdb.journals 
 where 
	journal_type_flag='M'
/

Create or Replace view journals_last_v
as
select /*+ first_row */
	*
  from hostdb.journals 
 where id=(select max(id) from hostdb.journals)
/

Create or Replace view journals_active_v
as
select /*+ first_row */
	*
  from hostdb.journals 
 where id=(
		select max(id)
		  from hostdb.journals
		 where je_in_process_flag='Y'
	)
/

Create or Replace view journals_lastm_v
as
select /*+ first_row */
	*
  from journals_monthly_v
 where id=(
		select
			max(id)
		  from journals_monthly_v
	)
/

Create or Replace view journals_lasta_v
as
select /*+ first_row */
	*
  from hostdb.journals 
 where id=(
		select
			max(id)
		  from hostdb.journals
		 where journal_type_flag='A'
	)
/

--
-- Accounts related views
--
create or replace view accounts_internal_v
as
select
	*
  from accounts
 where flag='i'
/

create or replace view accounts_external_v
as
select
	*
  from accounts
 where flag <> 'i'
/

create or replace view accounts_gm_v
as
select
	*
  from accounts
 where project is not null
/

create or replace view accounts_gl_v
as
select
	*
  from accounts
 where project is null
/

--
-- Charge related views
--
create or replace view who_charged_last_v
as
select
	wc.*
  from who_charged wc
	, journals_lastm_v j
 where wc.journal=j.id
/

create or replace view host_charged_last_v
as
select
	hc.*
  from host_charged hc
	, journals_lastm_v j
 where hc.journal=j.id
/

create or replace view who_charged_limbo_v
as
select
	wc.*
  from who_charged wc
 where 
	wc.account_flag in ('l','L')
/

create or replace view host_charged_limbo_v
as
select
	hc.*
  from host_charged hc
 where 
	hc.account_flag in ('l','L')
/

create or replace view who_charged_collected_v
as
select
	*
  from who_charged wc
 where
	wc.account_flag is null
/

create or replace view host_charged_collected_v
as
select
	*
  from host_charged hc
 where
	hc.account_flag is null
/

--
--	hr.id
--	, hr.hostname
--	, hr.assetno
--	, hr.qual
--	, hr.charge_src
--	, hr.princ
--	, hr.prjprinc
--	, hr.usrprinc
--	, hr.cpu
--	, hr.os
--	, hr.project
--	, hr.subproject
--
create or replace view hc_info_v
as
select
	hr.*
	, (select account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null)  from accounts a where a.id=hc.account) acct
	, hc.charge
	, hc.pct
	, hc.amount
	, hc.account_flag
	, hc.service_id
	, hc.trans_date
	, (select post_date from journals where id=hc.journal) post_date
	, (select journal_type_flag from journals where id=hc.journal) journal_type_flag
	, hc.notes
  from host_charged hc
	, host_recorded hr
 where hc.hr_id=hr.id
/

create or replace view wc_info_v
as
select
	wr.*
	, (select account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null)  from accounts a where a.id=wc.account) acct
	, wc.charge
	, wc.pct
	, wc.amount
	, wc.account_flag
	, wc.service_id
	, wc.trans_date
	, (select post_date from journals where id=wc.journal) post_date
	, (select journal_type_flag from journals where id=wc.journal) journal_type_flag
	, wc.notes
  from who_charged wc
	, who_recorded wr
 where wc.wr_id=wr.id
/

create or replace view hcs_info_v
as
select
	hr.*
	, (select account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null)  from accounts a where a.id=hcs.account) acct
	, hcs.charge
	, hcs.pct
	, hcs.amount
	, hcs.account_flag
	, hcs.services
	, hcs.trans_date
	, (select post_date from journals where id=hcs.journal) post_date
	, (select journal_type_flag from journals where id=hcs.journal) journal_type_flag
	, hcs.notes
  from host_charged_summary hcs
	, host_recorded hr
 where hcs.hr_id=hr.id
/

create or replace view wcs_info_v
as
select
	wr.*
	, (select account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null)  from accounts a where a.id=wcs.account) acct
	, wcs.charge
	, wcs.pct
	, wcs.amount
	, wcs.account_flag
	, wcs.services
	, wcs.trans_date
	, (select post_date from journals where id=wcs.journal) post_date
	, (select journal_type_flag from journals where id=wcs.journal) journal_type_flag
	, wcs.notes
  from who_charged_summary wcs
	, who_recorded wr
 where wcs.wr_id=wr.id
/


--
-- Entity configuration views
--

create or replace view who_labor_v
as
select
	*
  from who
 where dist is not null
   and charge_by is null
/

create or replace view who_project_v
as
select
	*
  from who
 where dist is not null
   and charge_by='P'
/

create or replace view who_nocharge_v
as
select 
	* 
  from who
 where dist is null
    or charge_by='!'
/

create or replace view machtab_user_v
as
select
	*
  from machtab
 where charge_by is null
/

create or replace view machtab_project_v
as
select
	*
  from machtab
 where charge_by='P'
/

