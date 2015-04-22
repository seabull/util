-- $Id: cl-slave-data.sql,v 1.1 2007/02/12 17:19:55 yangl Exp $
--

@check_hostservice.sql '138765.00' before_slave_5
@check_hostservice.sql '138766.00' before_slave_6
@check_hostservice.sql '138767.00' before_slave_7
@check_hostservice.sql '138768.00' before_slave_8
@check_hostservice.sql '138769.00' before_slave_9
-- Boston.lti master
update hostdb.machtab 
   set cputype='CL-S-SUN'
        ,dist=13819
        ,dist_src='P'
 where assetno in ('138765.00', '138766.00', '138767.00', '138768.00', '138769.00')
/

@check_hostservice.sql '138765.00' after_slave_5
@check_hostservice.sql '138766.00' after_slave_6
@check_hostservice.sql '138767.00' after_slave_7
@check_hostservice.sql '138768.00' after_slave_8
@check_hostservice.sql '138769.00' after_slave_9
