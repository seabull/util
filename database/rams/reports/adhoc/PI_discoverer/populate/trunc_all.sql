alter table ACCT_ROLE drop constraint ACCTROLE_ACCTID_FK;
alter table CHARGES drop constraint CHARGES_JNL_FK;
alter table CHARGES drop constraint CHARGES_ACCTID_FK;
truncate table charges reuse storage;
truncate table acct_role reuse storage;
truncate table investigator reuse storage;
truncate table accts reuse storage;
truncate table jnls reuse storage;
alter table ACCT_ROLE add constraint ACCTROLE_ACCTID_FK
        foreign key (ACCT_ID)
        references ACCTS;
alter table CHARGES add constraint CHARGES_JNL_FK
        foreign key (JNL_ID)
        references JNLS;
alter table CHARGES add constraint CHARGES_ACCTID_FK
        foreign key (ACCT_ID)
        references ACCTS;

