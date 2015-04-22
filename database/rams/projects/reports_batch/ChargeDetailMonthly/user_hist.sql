-- $Id: user_hist.sql,v 1.1 2005/10/11 14:08:49 yangl Exp $
--

create sequence userhist_idseq
	start with 1
	increment by 1
	nocycle
/

create table user_hist
(
	NID		number
		constraint whohist_pk primary key
	,princ		varchar2(8) not null
	,journal	number(5) not null
	,charge_by	char(1) not null
	,dist_src	varchar2(3) not null
	--
	,pct		number(6, 3) not null
	,dist_vec	varchar2(2000) not null
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

create index userhist_jnl_idx on user_hist (journal)
	tablespace indx;
create index userhist_chgby_idx on user_hist (charge_by)
	tablespace indx;
create index userhist_distsrc_idx on user_hist (dist_src)
	tablespace indx;
