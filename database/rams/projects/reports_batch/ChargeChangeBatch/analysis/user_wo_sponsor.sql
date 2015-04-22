set linesize 600
set pagesize 50000
spool user_wo_sponsor.lst

select
	princ
	,'"'||(select name from hostdb.name n where n.princ=w.princ and n.pri=0)||'"' name
	,decode(w.charge_by, 'P', 'Project', 'Labor') charge_src
	,nvl(sponsor, 'unknown') sponsor
	,pct
	,'"'||project||'"' project
	,id
  from hostdb.who w
 where w.sponsor is null
   and w.dist is not null
order by princ
/

spool off
