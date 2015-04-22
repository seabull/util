--
-- $Author: yangl $
-- $RCSfile: views.sql,v $
-- $Revision: 1.3 $
-- $Date: 2007/09/24 18:59:54 $
--

-- create views
create view entity_charged_v
as
select
	'M' Type
	,hc.hr_id Recorded_ID
	,hr.hostname Name
	,hr.assetno ID
	,hr.usrprinc sponsor
	,hr.charge_src
	,hc.charge
	,hc.pct
	,hc.amount
	,hc.account
	,a.acct_string
	,a.acct_type
	,hc.journal
	,hc.trans_date
	,s.category
	,hc.service_id
	,s.webcode
	,hc.account_flag
	,j.post_date
	,j.journal_type_flag
	,hc.notes
  from hostdb.host_charged hc
	,hostdb.host_recorded hr
	,accounts_str_v a
	,hostdb.journals j
	,hostdb.services s
 where hc.hr_id=hr.id
   and hc.account=a.id
   and s.id=hc.service_id
   and j.id=hc.journal
union
select
	'U' Type
	,wc.wr_id Recorded_ID
	,wr.name Name
	,wr.princ ID
	,wr.sponsor
	,wr.charge_src
	,wc.charge
	,wc.pct
	,wc.amount
	,wc.account
	,a.acct_string
	,a.acct_type
	,wc.journal
	,wc.trans_date
	,s.category
	,wc.service_id
	,s.webcode
	,wc.account_flag
	,j.post_date
	,j.journal_type_flag
	,wc.notes
  from hostdb.who_charged wc
	,hostdb.who_recorded wr
	,accounts_str_v a
	,hostdb.journals j
	,hostdb.services s
 where wc.wr_id=wr.id
   and wc.account=a.id
   and s.id=wc.service_id
   and j.id=wc.journal
/

create view nameprinc_v
as
select
    p.princ
    ,n.name
    ,n.pri
    ,n.lname
    ,n.princ nprinc
    ,n.emp_num
  from
    hostdb.name n
    ,hostdb.principal p
 where n.princ=p.name
/

create view whonameprinc_v
as
select
    w.*
    ,n.name
    ,n.pri
    ,n.lname
    ,n.emp_num
  from hostdb.who w
    ,nameprinc_v n
 where w.princ=n.princ
/

Create view journals_monthly_v
as
select /*+ first_row */
	*
  from hostdb.journals 
 where 
	journal_type_flag='M'
/
Create view journals_last_v
as
select /*+ first_row */
	*
  from hostdb.journals 
 where id=(select max(id) from hostdb.journals)
/

Create view journals_lastm_v
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


create view who_distsrc_v
as
select
        unique
        princ ID
        ,name
        ,0 pri
        ,emp_num
        ,sponsor
        ,project
        ,subproject
        ,decode(dist_src, 'P','Default','X','Residual','Payroll') dist_src_type
        ,dist_src
        ,decode(charge_by, null,'Payroll','P','Project','Unknown') charge_by_type
        ,charge_by
        ,dist
        ,pct
        ,(select dist from hostdb.dist_names where name=nvl(project,'NULLPROJ') and subname=nvl(subproject,'NULLSUBPROJ')) default_dist
  from whonameprinc_v
 where dist is not null
   and pri=0
/

        --,decode(dist_src, 'U','PrimaryUser','X','Residual','P','Project',null,'null', 'unknown') dist_src_type
        --,dist_src
create view host_distsrc_v
as
select
        m.assetno ID
        ,h.hostname name
        ,h.pri
        ,null emp_num
        ,m.usrprinc
        ,project
        ,subproject
        ,case dist_src when 'U' then
            (select unique dist_src_type from who_distsrc_v w where w.ID=usrprinc and rownum<2)
        when 'X' then
            'Residual'
        when 'P' then
            'Project'
        else
            'unknown'
        end dist_src_type
        ,case dist_src when 'U' then
            (select unique dist_src from who_distsrc_v w where w.ID=usrprinc)
        else
            dist_src
        end dist_src
        ,decode(charge_by, null,'PrimaryUser','P','Project','Unknown') charge_by_type
        ,charge_by
        ,dist
        ,100 pct
        ,case charge_by when null then
            (select unique dist from who_distsrc_v w where usrprinc=w.ID)
        else
            (select unique dist from hostdb.dist_names where name=nvl(project,'NULLPROJ') and subname=nvl(subproject,'NULLSUBPROJ') and rownum < 2) 
        end default_dist
  from hostdb.machtab m
        ,hostdb.capequip c
        ,hostdb.hoststab h
 where m.dist is not null
   and m.assetno=h.assetno(+)
   and c.assetnum=m.assetno
   and c.qual in (select code from hostdb.qualifiers where no_charge is null)
/

create view entity_distsrc_v
as
select
        'U' type
        ,w.*
  from who_distsrc_v w
union
select
        'M'
        ,h.*
  from host_distsrc_v h
/

grant select on who_distsrc_v       to costing_change;
grant select on host_distsrc_v      to costing_change;
grant select on entity_distsrc_v    to costing_change;
grant select on entity_charged_v    to costing_change;
grant select on nameprinc_v         to costing_change;
grant select on whonameprinc_v      to costing_change;
grant select on journals_monthly_v  to costing_change;
grant select on journals_last_v     to costing_change;
grant select on journals_lastm_v    to costing_change;
