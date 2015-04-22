rem####################################################
rem#	This is sql to create package body in Oracle
rem#	in ylj's schema
rem#	
rem#	Author: Longjiang Yang
rem#	Related scripts: show_tree.sql
rem#	usage:	execute parent_tree.show('table_name')
rem####################################################


CREATE OR REPLACE  PACKAGE "YLJ"."PARENT_TREE"  as
--  : Identify all parent level dependency for a given table.
--  : Longjiang Yang 02/08/2002
procedure show_depnd(tab_name in varchar,call_level in number);
procedure show(tab_name in varchar);
end ;
/

CREATE OR REPLACE  PACKAGE BODY "YLJ"."PARENT_TREE"    as
-- Identify all parent level dependency for a given table.
-- Longjiang Yang 02/08/2002
procedure show_depnd(tab_name in varchar,call_level in number) is
  y_tab varchar(100);
  y_col varchar(100);
cursor c1 is
  select table_name,column_name,constraint_name  from sys.dba_cons_columns
  where constraint_name in
      (select constraint_name from
        sys.dba_constraints where constraint_type='R' and
        table_name=upper(tab_name)
        );
begin
  if call_level = 0 then
    delete from dependency_tree;
    commit;
  end if;

  for i in c1
  loop
    select table_name,column_name into y_tab,y_col from sys.dba_cons_columns
    where constraint_name =
                          (select r_constraint_name from
                                  sys.dba_constraints
                            where table_name=i.table_name and constraint_name=i.constraint_name
                            );
    dbms_output.put_line(i.table_name||' '||i.column_name||' '||y_tab||' '||y_col);

    insert into dependency_tree values
       (call_level,i.table_name,i.column_name,y_tab,y_col);
  end loop;
  commit;
end;


procedure show(tab_name in varchar) is
temp_level  number;
more_parent number;
cursor c1 is
   select parent_table_name
   from dependency_tree
   where tree_level=temp_level;
begin
   show_depnd(tab_name,0);
   temp_level :=  -1;
   loop
     temp_level := temp_level + 1;
     for i in c1
     loop
        show_depnd(i.parent_table_name,temp_level+1);
     end loop;
     select count(*) into more_parent
     from   dependency_tree
     where  tree_level=temp_level+1;
     if  more_parent = 0 then
       exit;
     end if;
  end loop;
  insert into dependency_tree
  select temp_level+1,parent_table_name,parent_column_name,null,null
  from   dependency_tree where tree_level=temp_level;
  commit;
end;
end;

/

