-- $Id: mach_hist.sql,v 1.1 2005/10/11 14:08:49 yangl Exp $
--

create sequence machhist_idseq
	start with 1
	increment by 1
	nocycle
/

create table mach_hist
(
	NID		number
		constraint machhist_pk primary key
	,assetid	varchar2(8) not null
	,journal	number(5) not null
	,charge_by	char(1) not null
	,dist_src	varchar2(3) not null
	--
	,qual		char(1) not null
	,princ		varchar2(8) not null
	,dist_vec	varchar2(2000) 
	,project	varchar2(30)
	,subproject	varchar2(12)
)
partition by range (journal)
(
        partition c_fy05        values less than (238)
                tablespace costing_lg
        ,partition c_currfy     values less than (MAXVALUE)
                tablespace costing_lg
)
enable row movement
/

create index machhist_jnl_idx on mach_hist (journal)
	tablespace indx
	local;

create index machhist_chgby_idx on mach_hist (charge_by)
	tablespace indx
	local;

create index machhist_distsrc_idx on mach_hist (dist_src)
	tablespace indx
	local;
