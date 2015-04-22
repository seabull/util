PROMPT Creating user ramsreport
CREATE USER ramsreport  PROFILE DEFAULT
        IDENTIFIED BY "uiohjk"
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP2
        QUOTA unlimited ON TEMP2
        QUOTA 256M ON USERS
        QUOTA UNLIMITED ON costing_lg
        QUOTA UNLIMITED ON indx
        ACCOUNT UNLOCK;

GRANT CREATE PROCEDURE TO ramsreport;
GRANT CREATE SEQUENCE TO ramsreport;
GRANT CREATE SESSION TO ramsreport;
GRANT CREATE TABLE TO ramsreport;
GRANT CREATE TRIGGER TO ramsreport;
GRANT CREATE synonym TO ramsreport;
GRANT CREATE type TO ramsreport;

GRANT "CONNECT" TO ramsreport;

create role ramsreport_view not identified;
create role jnl_view not identified;

grant select on hostdb.who_charged to jnl_view;
grant select on hostdb.host_charged to jnl_view;
grant select on hostdb.who_recorded to jnl_view;
grant select on hostdb.host_recorded to jnl_view;
grant select on hostdb.accounts to jnl_view;
grant select on hostdb.name to jnl_view;
grant execute on hostdb.account_string to jnl_view;

grant jnl_view to ramsreport;

grant execute on hostdb.account_string to ramsreport;
grant select on hostdb.accounts to ramsreport;
grant select on hostdb.who_charged to ramsreport;
grant select on hostdb.host_charged to ramsreport;
grant select on hostdb.journals to ramsreport;
grant select on hostdb.who to ramsreport;
grant select on hostdb.machtab to ramsreport;

create synonym ramsreport.X for hostdb.X;
create synonym ramsreport.account_string for hostdb.account_string;
