-- $Id: cl-master-data.sql,v 1.1 2007/02/12 17:19:55 yangl Exp $
--

@check_hostservice.sql '138263.00' before_master
-- Boston.lti master
update hostdb.machtab 
   set cputype='CL-M-DELL'
 where assetno='138263.00'
/

@check_hostservice.sql '138263.00' after_master
