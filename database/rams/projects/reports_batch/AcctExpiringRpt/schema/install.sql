
--@./install_feeder.sql

--@../../../Emails/types/emails.sql

connect / as sysdba

@./tables/table_add.sql
@./scripts/grant_add.sql
@./views/view_add.sql

connect ccreport/ccreport
@./pkgs/pkgs_install.sql

@./scripts/ae_grant.sql
