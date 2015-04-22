set heading off
set pagesize 50000

select 'PRINC'
	||','||'NAME'
	||','||'HRIS_ID'
from dual
/

-- Should I exclude those that in residual? i.e. who.dist_src='X' 
-- e.g. 'zuo'(Zuo Jingyan) is one of them.
select
	n.princ
	||','||n.name
	||','||n.emp_num
from hostdb.name n
	, hostdb.who w
where 
  	w.princ=n.princ
  and 	n.emp_num is not null
  and	n.pri=(select min(pri) from hostdb.name n2 where n2.princ=n.princ)
  and 	w.dist is not null
order by n.princ
/

select
	n.princ
	||','||n.name
	||','||n.emp_num
from hostdb.name n
	, hostdb.who w
where 
  	w.princ=n.princ
  and 	n.emp_num is null
  and	n.pri=(select min(pri) from hostdb.name n2 where n2.princ=n.princ)
  and 	w.dist is not null
order by n.princ
/

/*
-- This looks like not accurate. 
-- e.g. seth and sethg belong to the same person and only seth is a real princ.
select
	n.princ
	||','||n.name
	||','||n.emp_num
from hostdb.name n
	, hostdb.who w
	, hostdb.principal p
where 
	n.princ=p.name(+)
  and 	w.princ=p.princ
  and 	n.emp_num is not null
  and	n.pri=(select min(pri) from hostdb.name n2 where n2.princ=n.princ)
  and 	w.dist is not null
order by n.princ
/
*/
