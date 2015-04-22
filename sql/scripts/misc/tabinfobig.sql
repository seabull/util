set showmode off echo off
set heading off pagesize 0 timing off feedback off linesize 80
set serveroutput on
rem
rem Script: tabinfobig.sql (large output version of tabinfo.sql)
rem Purpose: Report information about a table, including sizes,
rem   columns, primary key, foreign keys, indexes, constraints,
rem   triggers, and references.
rem Note: This script must now be run from a DBA account or the
rem   user must have access to dba_tables, dba_tab_privs, and
rem   dba_segments.
rem
rem Author: Biju Thomas
rem Updates:
rem Stephen Rea - Added table name and owner prompts, fixed row and
rem   block count calculations and added number of extents and bytes,
rem   added statistics like table's and tablespace name to indexes,
rem   fixed privileges to use dba_tab_privs instead of all_tab_privs,
rem   added table and column comments output, added references to this
rem   table, made foreign key columns output similar to references
rem   columns output, blanked out spacer dots, turned off sql output,
rem   added view and/or print options, made several format changes.
rem Released: 10/22/98 (update)
rem Stephen Rea - Created srea_output routine to get around 1000000-
rem   character limit of dbms_output (uses intermediate table
rem   sreaoutput).  Added file name prompt, if not tabinfobig.lst.
rem Released: 1/28/99 (new version derived from tabinfo.sql)
rem
accept filename char prompt 'Enter output file name, if not tabinfobig.lst: '
accept tablename char prompt 'Enter table name (wildcards like % are allowed): '
set termout off verify off
define tableowner = 'DUMMY'
spool ti_do.sql
select 'define tableowner = ' || owner from dba_tables
where table_name = upper('&tablename') and rownum = 1;
spool off
@ti_do.sql
spool ti_do.sql
select 'define tableowner = ' || username from user_users
where '&tableowner' = 'DUMMY' and rownum = 1;
spool off
@ti_do.sql
set linesize 100
spool ti_do.sql
select 'set termout on verify on' from dual;
select 'accept tableowner2 char prompt ''Enter table owner, if not ' ||
'&tableowner' || ' (wildcards allowed): ''' from dual;
select 'set termout off verify off' from dual;
spool off
set linesize 80
@ti_do.sql
spool ti_do.sql
select 'define filename = ' || decode('&filename','','tabinfobig.lst',
'&filename') from dual;
spool off
@ti_do.sql
spool ti_do.sql
select 'define tableowner = ' || decode('&tableowner2','','&tableowner',
'&tableowner2') from dual;
spool off
@ti_do.sql
spool ti_do.sql
select decode(nvl('&tablename','null'),'null','',
'create table sreaoutput (linenum number(8), linetxt varchar2(240));' || chr(10)
 ||
'truncate table sreaoutput;' || chr(10) ||
'delete from sreaoutput;' || chr(10) ||
'commit;') from dual;
spool off
@ti_do.sql
!rm ti_do.sql
spool &filename
declare
     wuser varchar2 (15) := '&tableowner';
     wtable varchar2 (30) := '&tablename';
     /*  Tables */
     cursor ctabs is select table_name, owner, tablespace_name,
          initial_extent, next_extent, pct_increase, num_rows, blocks
     from all_tables where
     owner like upper(wuser)
     and table_name like upper(wtable)
     and owner not in ('SYS','SYSTEM','SCOTT');
     cursor ccoms (o in varchar2, t in varchar2) is
     select comments from all_tab_comments
     where owner = upper (o) and table_name = upper (t);
     /* Columns */
     cursor ccols (o in varchar2, t in varchar2)
     is select rpad(column_name,49)
          ||rpad(data_type,10)
          ||rpad(
            decode(data_type,'DATE'    ,' '
                            ,'LONG'    ,' '
                            ,'LONG RAW',' '
                            ,'RAW'     ,decode(data_length,null,null
                                                    ,'('||data_length||')')
                            ,'CHAR'    ,decode(data_length,null,null
                                                    ,'('||data_length||')')
                            ,'VARCHAR' ,decode(data_length,null,null
                                                    ,'('||data_length||')')
                            ,'VARCHAR2',decode(data_length,null,null
                                                    ,'('||data_length||')')
                            ,'NUMBER'  ,decode(data_precision,null,'   '
                                                ,'('||data_precision||
     decode(data_scale,null,null,','||data_scale)||')'),'unknown'),8,' ')
          ||decode(nullable,'Y','NULL','NOT NULL') cstr, column_name
     from all_tab_columns
     where table_name = upper(t)
     and   owner = upper(o)
     order by column_id;
     cursor cccoms  (o in varchar2, t in varchar2, c in varchar2) is
     select comments col_comments from all_col_comments
     where table_name = upper(t)
     and owner = upper(o)
     and column_name = upper(c);
     /* Indexes */
     cursor cinds (o in varchar2, t in varchar2) is
     select owner, index_name,uniqueness unq,
     decode(status, 'VALID', ' ', '(INVALID)') status,
     tablespace_name,initial_extent, next_extent, pct_increase
     from all_indexes where
     table_name = upper(t) and
     table_owner = upper(o);
     cursor cind_cols (o in varchar2, t in varchar2, i in varchar2) is
     select  column_name
     from all_ind_columns where table_name = upper(t) and
      index_name = upper(i) and
      index_owner = upper(o)
     order by column_position;
     /* Primary and Unique Constraints */
     cursor cpk (o in varchar2, t in varchar2)  is
     select constraint_name, decode(constraint_type,'U','UNIQUE','PRIMARY') typ,
          status
     from all_constraints
     where table_name = upper(t)
     and   owner = upper(o)
     and   constraint_type in ('U','P');
     cursor cpk_cols (o in varchar2, t in varchar2, c in varchar2) is
     select column_name
     from all_cons_columns
     where table_name = upper(t)
     and   constraint_name = upper(c)
     and owner = upper(o)
     order by position;
     /* Foreign Key */
     cursor cfk (o in varchar2, t in varchar2) is
     select acp.owner,acp.table_name,acp.constraint_name,acp.r_constraint_name,
           acp.status,decode(acp.delete_rule,'CASCADE','ON CASCADE',' ') drule
     from all_constraints acp,all_constraints acc
     where acp.r_constraint_name = acc.constraint_name and
           acp.r_owner = acc.owner and
           acp.owner = upper (o) and
           acp.table_name = upper (t)
     order by 1,2,3;
     cursor cfk_cols (o in varchar2, t in varchar2, c in varchar2) is
     select accp.column_name || ' -> ' || accc.owner || '.' ||
           accc.table_name || '.' || accc.column_name colref
     from all_cons_columns accp,all_cons_columns accc,all_constraints ac
     where ac.constraint_name = upper (c) and
           ac.owner = upper (o) and
           ac.table_name = upper (t) and
           accp.constraint_name = ac.constraint_name and
           accp.owner = ac.owner and
           accc.constraint_name = ac.r_constraint_name and
           accc.owner = ac.r_owner and
           accp.position = accc.position
     order by accp.position;
     /* Other Constraints */
     cursor coc (o in varchar2, t in varchar2)  is
     select constraint_name, search_condition, status
     from all_constraints
     where table_name = upper(t)
     and   owner = upper(o)
     and   constraint_type in ('C');
     /* Trigger */
     cursor ctrig (o in varchar2, t in varchar2) is
     select owner, trigger_name, status, triggering_event event
     from all_triggers
     where table_name = upper(t) and
           table_owner = upper(o);
     /* Privileges on this table (sdr changed all_tab_privs to dba_tab_privs) */
     cursor cpriv (o in varchar2, t in varchar2) is
     select grantee, grantor, privilege, grantable
     from dba_tab_privs
     where table_name = upper(t) and
           owner = upper(o);
     /* Objects Dependency */
     cursor cdep (o in varchar2, t in varchar2) is
     select owner || '.' || name name,  type
     from all_dependencies
     where referenced_owner = upper (o) and
           referenced_name  = upper (t) and
           referenced_type  = 'TABLE'
     order by owner, name;
     /* References to this table */
     cursor cref (o in varchar2, t in varchar2) is
     select acp.owner,acp.table_name,acp.constraint_name,acp.r_constraint_name
     from all_constraints acp,all_constraints acc
     where acp.r_constraint_name = acc.constraint_name and
           acp.r_owner = acc.owner and
           acc.owner = upper (o) and
           acc.table_name = upper (t)
     order by 1,2,3;
     cursor cref_cols (o in varchar2, t in varchar2, c in varchar2) is
     select accp.column_name || ' -> ' || accc.column_name colref
     from all_cons_columns accp,all_cons_columns accc,all_constraints ac
     where ac.constraint_name = upper (c) and
           ac.owner = upper (o) and
           ac.table_name = upper (t) and
           accp.constraint_name = ac.constraint_name and
           accp.owner = ac.owner and
           accc.constraint_name = ac.r_constraint_name and
           accc.owner = ac.r_owner and
           accp.position = accc.position
     order by accp.position;
     wcount number := 0;
     wdate varchar2 (25) := to_char(sysdate,'Mon DD, YYYY  HH:MI AM');
     w5space char(5) := '.    ';
     wdum1 varchar2 (255);
     wdum2 varchar2 (255);
     wdum3 varchar2 (255);
     wdum4 varchar2 (255);
     wdum5 varchar2 (255);
     wdum6 varchar2 (255);
     wdum7 varchar2 (255);
     wdum8 varchar2 (255);
     numextents varchar2 (15) := ' ';
     numbytes varchar2 (15) := ' ';
     numblocks varchar2 (15) := ' ';
     numrows number;
     cursor_handle integer;
     dummy integer;
     i1 integer;
     i2 integer;
     srea_linenum number (8) := 0;
     procedure srea_output (linenum in out number, linetxt in varchar2) is
        begin
           linenum := linenum + 1;
           insert into sreaoutput values(linenum,linetxt);
           if mod(linenum, 1000) = 0 then
              commit;
           end if;
        end;
  begin
    for rtabs in ctabs loop
      -- Put Form Feed between tables for printing (allow for in first put_line)
      if ctabs%ROWCOUNT > 1 then
         srea_output(srea_linenum,chr(12) || '***** ' || rtabs.table_name || ' TABLE INFORMATION *****' || rpad(' ',27-length(rtabs.table_name)) || wdate);
      else
         srea_output(srea_linenum,'***** ' || rtabs.table_name || ' TABLE INFORMATION *****' || rpad(' ',27-length(rtabs.table_name)) || wdate);
      end if;
      srea_output(srea_linenum,'*--------------*------------------------------*--------------------------------*');
      srea_output(srea_linenum,'Table Owner    Table Name                     Tablespace Name');
      srea_output(srea_linenum,'Initial   Next      PctIncrease  Extents   Blocks    Bytes       Rows');
      srea_output(srea_linenum,'*--------------*------------------------------*--------------------------------*');
      wcount := wcount + 1;
      srea_output(srea_linenum,rpad(rtabs.owner,15) || rpad(rtabs.table_name,31) || rpad(rtabs.tablespace_name,30));
      -- The following select only works for DBA users.  Remove it or comment it
      -- out to run tabinfo from non-dba users (those three values won't show).
      select to_char(extents),to_char(blocks),to_char(bytes)
        into numextents,numblocks,numbytes
        from dba_segments where owner = upper(rtabs.owner)
        and segment_name = upper(rtabs.table_name);
      cursor_handle := dbms_sql.open_cursor;
      dbms_sql.parse(cursor_handle,'select count(*) from ' || rtabs.owner || '.' || rtabs.table_name,DBMS_SQL.V7);
      dbms_sql.define_column(cursor_handle,1,numrows);
      dummy := dbms_sql.execute_and_fetch(cursor_handle, true);
      dbms_sql.column_value(cursor_handle, 1, numrows);
      dbms_sql.close_cursor(cursor_handle);
      srea_output(srea_linenum,rpad(rtabs.initial_extent,10) || rpad(rtabs.next_extent,10) || rpad(rtabs.pct_increase,13) || rpad(numextents,10) || rpad(numblocks,10) || rpad(numbytes,12) || rpad(numrows,11));
      for rcoms in ccoms (rtabs.owner, rtabs.table_name) loop
        if length(rcoms.comments) > 0 then
          srea_output(srea_linenum,rcoms.comments);
        end if;
      end loop;
      srea_output(srea_linenum,w5space);
      srea_output(srea_linenum,w5space || '*------------------------------------------------*---------*-------*------*');
      srea_output(srea_linenum,w5space || 'Column Name                                      Datatype          Null?');
      srea_output(srea_linenum,w5space || '*------------------------------------------------*---------*-------*------*');
      for rcols  in ccols (rtabs.owner, rtabs.table_name) loop
         srea_output(srea_linenum,w5space || rcols.cstr);
         for rccoms in cccoms (rtabs.owner, rtabs.table_name, rcols.column_name) loop
            i1 := 1;
            while i1 <= length(rccoms.col_comments) loop
               i2 := greatest(i1 + 69,length(rccoms.col_comments));
               if i2 - i1 + 1 > 70 then
                  i2 := instr(substr(rccoms.col_comments,i1,70),' ',-1) + i1 - 1;
               end if;
               wdum1 := ltrim(rtrim(replace(substr(rccoms.col_comments,i1,i2-i1+1),'  ',' ')));
               while instr(wdum1,'  ') > 1 loop
                  wdum1 := ltrim(rtrim(replace(wdum1,'  ',' ')));
               end loop;
               srea_output(srea_linenum,w5space || '     ' || wdum1);
               i1 := i2 + 1;
            end loop;
         end loop;
      end loop;
      srea_output(srea_linenum,w5space);
      open cinds (rtabs.owner, rtabs.table_name);
      fetch cinds into wdum1, wdum2, wdum3, wdum4, wdum5, wdum6, wdum7, wdum8;
      if cinds%notfound then
         srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - NO INDEXES *********');
         close cinds;
      else
         close cinds;
         srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - INDEXES **********');
         srea_output(srea_linenum,w5space || '*--------------*----------------------------------*-----------*-----------*');
         srea_output(srea_linenum,w5space || 'Index Owner    Index Name                         Unique      Index Columns');
         srea_output(srea_linenum,w5space || 'Initial   Next      PctIncrease  Extents   Blocks    Bytes');
         srea_output(srea_linenum,w5space || '*--------------*----------------------------------*-----------*-----------*');
         for rinds in cinds (rtabs.owner, rtabs.table_name) loop
             srea_output(srea_linenum,w5space || rpad(rinds.owner,15) || rpad(rinds.index_name,35) || rinds.unq || ' ' || rinds.status);
             -- The following select only works for DBA users.  Remove it or
             -- comment it out to run tabinfo from non-dba users (those three
             -- values won't show).
             select to_char(extents),to_char(blocks),to_char(bytes)
                into numextents,numblocks,numbytes
                from dba_segments where owner = upper(rinds.owner)
                and segment_name = upper(rinds.index_name);
             srea_output(srea_linenum,w5space || rpad(rinds.initial_extent,10) || rpad(rinds.next_extent,10) || rpad(rinds.pct_increase,13) || rpad(numextents,10) || rpad(numblocks,10) || rpad(numbytes,12));
             for rind_cols in cind_cols (rinds.owner, rtabs.table_name, rinds.index_name) loop
                 if cind_cols%ROWCOUNT = 1 then
                    wdum1 := 'Tablespace: ' || rinds.tablespace_name;
                 else
                    wdum1 := ' ';
                 end if;
                 srea_output(srea_linenum,w5space || wdum1 || lpad(rind_cols.column_name,75-length(wdum1), '     '));
             end loop;
          end loop;
      end if;
      srea_output(srea_linenum,w5space);
      open cpk (rtabs.owner, rtabs.table_name);
      fetch cpk into wdum1, wdum2, wdum3;
      if cpk%notfound then
         srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - NO PRIMARY/UNIQUE KEY CONSTRAINTS **********');
         close cpk;
      else
         close cpk;
         srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - PRIMARY/UNIQUE KEY CONSTRAINTS **********');
         srea_output(srea_linenum,w5space || '*-----------------------------------------*---------*-----------*---------*');
         srea_output(srea_linenum,w5space || 'Primary/Unique Key                        Type      Status      Key Columns');
         srea_output(srea_linenum,w5space || '*-----------------------------------------*---------*-----------*---------*');
         for rpk in cpk (rtabs.owner, rtabs.table_name) loop
           srea_output(srea_linenum,w5space || Rpad(rpk.constraint_name,42) || rpad(rpk.typ,10) || rpk.status);
           for rpk_cols in cpk_cols (rtabs.owner, rtabs.table_name, rpk.constraint_name) loop
              srea_output(srea_linenum,w5space || lpad(rpk_cols.column_name,75, '     '));
           end loop;
         end loop;
      end if;
      srea_output(srea_linenum,w5space);
      open cfk (rtabs.owner, rtabs.table_name);
      fetch cfk into wdum1, wdum2, wdum3, wdum4, wdum5, wdum6;
      if cfk%notfound then
         srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - NO FOREIGN KEY CONSTRAINTS **********');
         close cfk;
      else
         close cfk;
         srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - FOREIGN KEY CONSTRAINTS **********');
         srea_output(srea_linenum,w5space || '*---------------------------------*--------*----------*-------------------*');
         srea_output(srea_linenum,w5space || 'Foreign Key                       Status   Delete     References Constraint');
         srea_output(srea_linenum,w5space || '*---------------------------------*--------*----------*-------------------*');
         for rfk in cfk (rtabs.owner, rtabs.table_name) loop
           srea_output(srea_linenum,w5space || rpad(rfk.constraint_name,34) || rpad(rfk.status,9) || rpad(rfk.drule,11) || rpad(rfk.r_constraint_name,21));
            for rfk_cols in cfk_cols (rfk.owner, rfk.table_name, rfk.constraint_name) loop
               srea_output(srea_linenum,w5space || rpad(' ',5) || rfk_cols.colref);
            end loop;
         end loop;
      end if;
      srea_output(srea_linenum,w5space);
      open coc (rtabs.owner, rtabs.table_name);
      fetch coc into wdum1, wdum2, wdum3;
      if coc%notfound then
         srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - NO OTHER CONSTRAINTS **********');
         close coc;
      else
         close coc;
         srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - OTHER CONSTRAINTS **********');
         srea_output(srea_linenum,w5space || '*-------------------------*--------*--------------------------------------*');
         srea_output(srea_linenum,w5space || 'Constraint Name           Status   Condition');
         srea_output(srea_linenum,w5space || '*-------------------------*--------*--------------------------------------*');
         for roc in coc (rtabs.owner, rtabs.table_name) loop
           srea_output(srea_linenum,w5space || rpad(roc.constraint_name,26) || rpad(roc.status,9) || roc.search_condition);
         end loop;
      end if;
      srea_output(srea_linenum,w5space);
      open ctrig (rtabs.owner, rtabs.table_name);
      fetch ctrig into wdum1, wdum2, wdum3, wdum4;
      if ctrig%notfound then
          srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - NO TRIGGERS **********');
          close ctrig;
      else
          close ctrig;
          srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - TRIGGERS **********');
          srea_output(srea_linenum,w5space || '*--------------*-------------------------------------------------*--------*');
          srea_output(srea_linenum,w5space || 'Owner          Trigger Name                                      Status');
          srea_output(srea_linenum,w5space || '*--------------*-------------------------------------------------*--------*');
          for rtrig in ctrig (rtabs.owner, rtabs.table_name) loop
             srea_output(srea_linenum,w5space || rpad(rtrig.owner,15) || rpad(rtrig.trigger_name,50) ||  rtrig.status);
          end loop;
      end if;
      srea_output(srea_linenum,w5space);
      open cpriv (rtabs.owner, rtabs.table_name);
      fetch cpriv into wdum1, wdum2, wdum3, wdum4;
      if cpriv%notfound then
          srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - NO PRIVILEGES GRANTED **********');
          close cpriv;
      else
          close cpriv;
          srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - PRIVILEGES GRANTED **********');
          srea_output(srea_linenum,w5space || '*--------------------*--------------*-----------------------------*-------*');
          srea_output(srea_linenum,w5space || 'Granted To           Granted By     Privilege                     Grantable');
          srea_output(srea_linenum,w5space || '*--------------------*--------------*-----------------------------*-------*');
          for rpriv in cpriv (rtabs.owner, rtabs.table_name) loop
             srea_output(srea_linenum,w5space || rpad(rpriv.grantee,21) || rpad(rpriv.grantor,15) || rpad(rpriv.privilege,30) ||  rpriv.grantable);
          end loop;
      end if;
      srea_output(srea_linenum,w5space);
      open cdep (rtabs.owner, rtabs.table_name);
      fetch cdep into wdum1, wdum2;
      if cdep%notfound then
          srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - NO DEPENDENT OBJECTS **********');
          close cdep;
      else
          close cdep;
          srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - DEPENDENT OBJECTS **********');
          srea_output(srea_linenum,w5space || '*-------------------------------------------------------*-----------------*');
          srea_output(srea_linenum,w5space || 'Object Name                                             Type ');
          srea_output(srea_linenum,w5space || '*-------------------------------------------------------*-----------------*');
          for rdep in cdep (rtabs.owner, rtabs.table_name) loop
             srea_output(srea_linenum,w5space || rpad(rdep.name,56) || rdep.type);
          end loop;
      end if;
      srea_output(srea_linenum,w5space);
      open cref (rtabs.owner, rtabs.table_name);
      fetch cref into wdum1, wdum2, wdum3, wdum4;
      if cref%notfound then
         srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - NO REFERENCING OBJECTS **********');
         close cref;
      else
         close cref;
         srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - REFERENCING OBJECTS **********');
         srea_output(srea_linenum,w5space || '*-------------------*---------------------------------*-------------------*');
         srea_output(srea_linenum,w5space || 'Object Name         Constraint Name                   References Constraint');
         srea_output(srea_linenum,w5space || '*-------------------*---------------------------------*-------------------*');
         for rref in cref (rtabs.owner, rtabs.table_name) loop
           srea_output(srea_linenum,w5space || rpad(rref.owner || '.' || rref.table_name,20) || rpad(rref.constraint_name,34) || rpad(rref.r_constraint_name,21));
            for rcols in cref_cols (rref.owner, rref.table_name, rref.constraint_name) loop
               srea_output(srea_linenum,w5space || rpad(' ',25) || rcols.colref);
            end loop;
         end loop;
      end if;
      srea_output(srea_linenum,w5space);
      srea_output(srea_linenum,'********** ' || rtabs.table_name || ' - END INFO **********');
    end loop;
    if wcount =0 then
      srea_output(srea_linenum,'******************************************************');
      srea_output(srea_linenum,'*                                                    *');
      srea_output(srea_linenum,'* Plese Verify Input Parameters... No Matches Found! *');
      srea_output(srea_linenum,'*                                                    *');
      srea_output(srea_linenum,'******************************************************');
    end if;
  end;
/
select linetxt from sreaoutput order by linenum;
spool off
!sed 's/ *$//' &filename >&filename..trim
!rm &filename
!mv &filename..trim &filename
!/home/common/all_rights.shl &filename
!/home/common/view_or_print.shl &filename 'Table Information'
set serveroutput off pagesize 14
set heading on termout on
set timing on feedback 6 verify on echo on showmode both


