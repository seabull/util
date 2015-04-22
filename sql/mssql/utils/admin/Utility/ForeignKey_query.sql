/*
Often time, you have trouble delete records or drop table on a table with PK because the table record is referenced by a foreign key constraint you don't know where. You inherit this database and there is no data dictionary passed on to you. The only other way Microsoft has provided is to generate a diagram, but on a laptop and thousands of tables, the diagram is not viewable.

Use this SQLServer2005 script for a quick lookup for all tables, or one table - the primary key table being referenced, and find all foreign keys..

*/
----all tables-------
SELECT b.name as PKTbl, d.name as FKTble, c.name as KeyName, a.*
 FROM [sys].[foreign_keys] a, sys.objects b, sys.objects c, sys.objects d
 where b.object_id = a.referenced_object_id
 and a.object_id = c.object_id 
 and a.parent_object_id = d.object_id 
 order by b.name, d.name

----one table-----
SELECT b.name as PKTbl, d.name as FKTble, c.name as KeyName, a.*
 FROM [sys].[foreign_keys] a, sys.objects b, sys.objects c, sys.objects d
 where b.object_id = a.referenced_object_id
 and a.object_id = c.object_id 
 and a.parent_object_id = d.object_id 
 and b.name = 'Tablename'



