
set linesize 1000

--column acct_string format a24 truncated
--column account_flag heading FLAG format a4
--column flag heading FLAG format a6 truncated
--column charge_by_type heading charge_src format a10 truncated
--column type heading type format a4
--column dist_src_type heading actual_src format a10 truncated
--column id format a12 truncated
--column name format a24 truncated
--column dist_src format a8 truncated
--column amount format $99,999,999.99
--
--column actual_distribution format a200 trunc
--column default_distribution format a200 trunc

spool who_fallthru.csv
set heading off
set feedback off
select
        'princ'
        ||',"'||'name'||'"'
        ||',"'||'dist_src'||'"'
        ||',"'||'pct'||'"'
        ||',"'||'dist_src_type'||'"'
        ||',"'||'charge_by'||'"'
        ||',"'||'charge_by_type'||'"'
        ||',"'||'sponsor'||'"'
        ||',"'||'dist'||'"'
        ||',"'||'default_dist'||'"'
        ||',"'||'actual_distribution'||'"'
        ||',"'||'actual_flags'||'"'
        ||',"'||'default_distribution'||'"'
        ||',"'||'default_flags'||'"'
  from dual
/

select
        princ
        ||',"'||name||'"'
        ||',"'||dist_src||'"'
        ||',"'||pct||'"'
        ||',"'||dist_src_type||'"'
        ||',"'||charge_by||'"'
        ||',"'||charge_by_type||'"'
        ||',"'||sponsor||'"'
        ||',"'||dist||'"'
        ||',"'||default_dist||'"'
        ||',"'||actual_distribution||'"'
        ||',"'||actual_flags||'"'
        ||',"'||default_distribution||'"'
        ||',"'||default_flags||'"'
  from (
select
        unique
        ID princ
        ,name
        ,pct
        ,dist_src
        ,dist_src_type
        ,charge_by
        ,charge_by_type
        ,sponsor
        ,dist
        ,default_dist
        ,(select unique dist_vec from dist_vector_string_v d where w.dist=d.dist) actual_distribution
        ,(select unique flags from dist_vector_string_v d where w.dist=d.dist) actual_flags
        ,(select unique dist_vec from dist_vector_string_v d where w.default_dist=d.dist) default_distribution
        ,(select unique flags from dist_vector_string_v d where w.default_dist=d.dist) default_flags
  from who_distsrc_v w
 where w.dist is not null
order by princ
)
/

spool off
set linesize 80

-- ID                                        NOT NULL VARCHAR2(8)
-- NAME                                      NOT NULL VARCHAR2(50)
-- PRI                                                NUMBER
-- EMP_NUM                                            NUMBER(7)
-- SPONSOR                                            VARCHAR2(8)
-- PROJECT                                            VARCHAR2(30)
-- SUBPROJECT                                         VARCHAR2(12)
-- DIST_SRC_TYPE                                      VARCHAR2(8)
-- DIST_SRC                                           VARCHAR2(3)
-- CHARGE_BY_TYPE                                     VARCHAR2(7)
-- CHARGE_BY                                          CHAR(1)
-- DIST                                               NUMBER(6)
-- PCT                                                NUMBER(6,3)
-- DEFAULT_DIST                                       NUMBER

