-- $Id: charge_sources.add.sql,v 1.1 2007/01/15 15:02:16 yangl Exp $

insert into hostdb.charge_sources
    (kind, description, attr, pri, org)
values
    (
        'Z'
        ,'charge from Other Organizations payroll effort in Carnegie Mellon'
        ,'P'
        ,8
        ,'EOTHER'
    )
/

insert into hostdb.charge_sources
    (kind, description, attr, pri, org)
values
    (
        'z'
        ,'charge from Other Organizations part-time effort in Carnegie Mellon'
        ,'P'
        ,6
        ,'EOTHER'
    )
/

