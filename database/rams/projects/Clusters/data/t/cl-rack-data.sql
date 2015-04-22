-- $Id: cl-rack-data.sql,v 1.1 2007/02/12 17:19:55 yangl Exp $
--

@check_hostservice.sql '137455.00' before_rack
-- Boston.lti rack
insert into hostdb.machtab 
    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist)
values
    ('137455.00', 'CL-R-RACK'   ,'LOGICAL'    ,'callan'   ,'callan', 13819)
/

@check_hostservice.sql '137455.00' after_rack
