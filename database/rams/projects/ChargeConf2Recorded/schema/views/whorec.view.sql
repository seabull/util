-- $Id: whorec.view.sql,v 1.1 2007/03/21 18:10:34 yangl Exp $
--
create or replace view hostdb.whorec
as
SELECT UNIQUE
        r.id wr_id
        ,w.princ
        ,w.name
        ,w.charge_src
        ,w.project
        ,w.subproject
        ,w.sponsor
        ,w.dist
  FROM whoname w
        ,who_recorded r
 WHERE (w.princ=r.princ(+))
   AND (w.name=r.name(+))
   AND (nvl(w.charge_src,'NOSRC')=nvl(r.charge_src(+),'NOSRC'))
   AND (nvl(w.project,'NOPROJECT')=nvl(r.project(+),'NOPROJECT') )
   AND (nvl(w.subproject,'NOVALUE')=nvl(r.subproject(+),'NOVALUE') )
   AND (nvl(w.sponsor,'NOVALUE')=nvl(r.sponsor(+),'NOVALUE') )
/
