-- $Id: tables.uninstall.sql,v 1.2 2006/12/06 18:50:23 yangl Exp $

drop sequence pireport.rptmgr_idseq 
/

drop sequence pireport.acctrole_idseq 
/


drop sequence pireport.charges_idseq 
/

-- Tables Section
-- _____________ 

drop table pireport.ACCT_ROLE ;

drop table pireport.CHARGES ;

drop table pireport.ACCTS ;
drop table pireport.INVESTIGATOR ;
drop table pireport.JNLS ;


--alter table pireport.ACCT_ROLE add constraint pireport.ACCTROLE_ACCTID_FK
--	foreign key (ACCT_ID)
--	references ACCTS;
--
--alter table pireport.CHARGES add constraint pireport.CHARGES_JNL_FK
--	foreign key (JNL_ID)
--	references JNLS;
--
--alter table pireport.CHARGES add constraint pireport.CHARGES_ACCTID_FK
--	foreign key (ACCT_ID)
--	references ACCTS;
--
---- Index Section
---- _____________ 
--
--create index pireport.ACCTROLE_EMP_IDX
--	on pireport.ACCT_ROLE (EMP_NUM);
--
--create index pireport.CHARGES_ACCTID_IDX
--	on pireport.CHARGES (ACCT_ID)
--	local 
--/
--
--create index pireport.CHARGES_JNL_IDX
--	on pireport.CHARGES (JNL_ID)
--	local
--/
--
--create index pireport.CHARGES_EID_IDX
--	on pireport.CHARGES (ENTITY_ID)
--	local
--/
--
--create index pireport.charges_type_idx
--	on pireport.charges (type)
--	local
--/
--
--create index pireport.charges_name_idx
--	on pireport.charges (name)
--	local
--/
--
---- this is a candidate to convert to global
--create index pireport.charges_tdate_idx
--	on pireport.charges (trans_date)
--	local
--/
--
--create index pireport.JNLS_PDATE_IDX
--	on pireport.JNLS (POST_DATE)
--	local
--/
--
--create index pireport.investigator_empnum_IDX
--	on pireport.investigator (emp_num);
--
----
--create index pireport.investigator_princ_idx
--	on pireport.investigator (princ)
--/
--
--create index pireport.ACCTROLE_ACCTID_IDX
--	on pireport.ACCT_ROLE (ACCT_ID)
--/
--
