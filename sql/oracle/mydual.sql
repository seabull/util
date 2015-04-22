-- $Id: mydual.sql,v 1.1 2006/11/16 20:23:41 yangl Exp $
--
create table mydual
(
    dummy varchar2(1) primary key 
        constraint one_row check(dummy='X')
)
    organization index
/ 
