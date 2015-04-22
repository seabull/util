-- $Id: infmachd.sql,v 1.2 2008/05/14 19:52:39 yangl Exp $
-- This is to update infmachd which is a dummy user set up to
-- change costing for a group of machines. Since there are too many machines
-- Jeeves time out on the costing change.
--
-- May 13, 2008 change to
--25% to  2914-1-5001169 (  2226) (ROB-Informedia Consortium)
--20% to 17668-1-1121052 (100079) (NSF-Enhan.Dig.VideoLib-Christel), and
--20% to 18957-1-1121086 (104314) (NSF CRI Hauptmann)
--35% to 18961-1-1041072 (104315) (ROSETTEX - Wactlar)
--
--


declare
    l_did   hostdb.dist.dist%TYPE;
begin
    SELECT dist_id.nextval 
      into l_did
      FROM dual;

    dbms_output.put_line('l_did='||l_did);

    INSERT INTO dist (dist,pct,tpct,account) VALUES (l_did,'100.0','25.0',2226);
    INSERT INTO dist (dist,pct,tpct,account) VALUES (l_did,'0.0','20.0',100079);
    INSERT INTO dist (dist,pct,tpct,account) VALUES (l_did,'0.0','20.0',104314);
    INSERT INTO dist (dist,pct,tpct,account) VALUES (l_did,'0.0','35.0',104315);

    update dist
       set pct=tpct
     where dist=l_did;

    INSERT INTO dist_names 
        (name,subname,src,dist) 
    VALUES
        ('Inf-Machine-Dist','2', 'P', l_did)
    ;

end;
/

update who
   set charge_by='P'
        ,project='Inf-Machine-Dist'
        ,subproject='2'
        ,pct=4.0
 where princ='infmachd'
/
