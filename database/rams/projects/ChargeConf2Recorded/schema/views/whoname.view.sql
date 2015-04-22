-- $Id: whoname.view.sql,v 1.1 2007/03/21 18:10:34 yangl Exp $
--

create or replace view hostdb.whoname
as
SELECT 
        w.princ
        ,n.name
        ,w.dist_src charge_src
        ,w.project
        ,w.subproject
        ,w.sponsor
        ,w.dist
  FROM who w
        , name n
 WHERE w.princ=n.princ
   AND n.pri = (SELECT min(name.pri) FROM name WHERE name.princ=w.princ)
/
