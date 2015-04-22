--##########################################################################
--#	This script uses package parent_tree to show dependency of a table
--#
--#	Author: Longjiang Yang
--#	Related scripts: 
--#	usage:	show_tree 'table_name'
--##########################################################################

execute parent_tree.show("&&1");

set head off
prompt  Level Child Entity                     Parent Entity
select
tree_level||'   '||
rpad(child_table_name||'.'||child_column_name,30,' ')||'  <-  '||
rpad(parent_table_name||'.'||parent_column_name,30,' ')
from dependency_tree
order by tree_level desc;
set head on
