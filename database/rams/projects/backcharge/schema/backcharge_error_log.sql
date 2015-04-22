
create sequence hostdb.backchg_error_seq maxvalue 999999 cycle;

create table hostdb.backcharge_error_log
(
	ID	NUMBER(6)
	,TBL_NAME	VARCHAR2(12)
	,ROW_ID		ROWID
	,Error_Date	DATE
)
tablespace apps
/

alter table hostdb.backcharge_error_log add constraint backchgerrorlog_pk primary key (ID)
	using index
	tablespace indx
/
