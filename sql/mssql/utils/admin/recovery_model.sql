-- $Id: recovery_model.sql,v 1.2 2009/08/07 19:25:31 A645276 Exp $
-- $Author: A645276 $
-- $Date: 2009/08/07 19:25:31 $

USE master;
ALTER DATABASE database_name SET RECOVERY FULL;

--To set the database to the bulk-logged recovery model:
USE master;
ALTER DATABASE database_name SET RECOVERY BULK_LOGGED;

--To set the database to the simple recovery model:
USE master;
ALTER DATABASE database_name SET RECOVERY SIMPLE;

-- To view recovery model
select name, database_id, create_date, state, state_desc, recovery_model, recovery_model_desc
  from sys.databases
 where name = 'PRFDB001'
