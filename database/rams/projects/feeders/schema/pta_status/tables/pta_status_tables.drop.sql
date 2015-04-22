--$Header: c:\\Repository/database/rams/projects/feeders/schema/pta_status/tables/pta_status_tables.drop.sql,v 1.1 2006/04/26 19:29:13 yangl Exp $
--drop sequence hostdb.ptarecorded_id_seq;
--drop index ptarecorded_pta_idx;

drop index hostdb.ptarecorded_flag_idx;
drop index hostdb.ptarecorded_adate_idx;
drop table hostdb.pta_recorded;
drop view hostdb.pta_status_v;

drop table hostdb.history_flags;
