--#####################################################################
--	detect fragmented index and rebuild it
--#####################################################################
CREATE OR REPLACE PROCEDURE RebuildUnbalancedIndexes
	(pMaxHeight integer := 3,
	pMaxLeafsDeleted integer := 20)
is

	cursor csrIndexStats is
		select name,
			height,
			lf_rows as leafRows,
			del_lf_rows as leafRowsDeleted
		  from index_stats;
       
	vIndexStats csrIndexStats%rowtype;

	cursor csrGlobalIndexes is
		select index_name, tablespace_name
		  from user_indexes
		 where partitioned = 'NO';

	cursor csrLocalIndexes is
		select index_name, partition_name, tablespace_name
		  from user_ind_partitions
		 where status = 'USABLE';

	vCount integer := 0;
	vAnalyze varchar2(100);
	vCursor NUMBER;
	vNumRows INTEGER;

begin

   	/* Global indexes */
   	for vIndexRec in csrGlobalIndexes
   	loop

		vAnalyze := 'analyze index ' || vIndexRec.index_name || ' validate structure';
		vCursor := DBMS_SQL.OPEN_CURSOR;
		DBMS_SQL.PARSE(vCursor,vAnalyze,DBMS_SQL.V7);
		vNumRows := DBMS_SQL.EXECUTE(vCursor);
		DBMS_SQL.CLOSE_CURSOR(vCursor);

		open csrIndexStats;
		fetch csrIndexStats into vIndexStats;
		if csrIndexStats%found
		then
			if (vIndexStats.height > pMaxHeight) or
				(vIndexStats.leafRows > 0 and
				vIndexStats.leafRowsDeleted > 0 and
				(vIndexStats.leafRowsDeleted * 100 / vIndexStats.leafRows) >
				pMaxLeafsDeleted)
			then
				vCount := vCount + 1;
				dbms_output.put_line('Rebuilding index ' || vIndexRec.index_name || '...');
         	 
				vAnalyze :=  'alter index ' || vIndexRec.index_name ||
							' rebuild' ||
							' parallel nologging compute statistics' ||
							' tablespace ' || vIndexRec.tablespace_name;
				vCursor := DBMS_SQL.OPEN_CURSOR;
				DBMS_SQL.PARSE(vCursor,vAnalyze,DBMS_SQL.V7);
				vNumRows := DBMS_SQL.EXECUTE(vCursor);
				DBMS_SQL.CLOSE_CURSOR(vCursor);
			end if;
		end if;
		close csrIndexStats;

	end loop;

   	dbms_output.put_line('Global indexes rebuilt: ' || to_char(vCount));
   	vCount := 0;
	
   	/* Local indexes */
/*
   	for vIndexRec in csrLocalIndexes
   	loop
	
		vAnalyze := 'analyze index ' || vIndexRec.index_name ||
                        	' partition (' || vIndexRec.partition_name ||
                        	') validate structure';
      
		open csrIndexStats;
		fetch csrIndexStats into vIndexStats;
		if csrIndexStats%found
		then
			if (vIndexStats.height > pMaxHeight) or
				(vIndexStats.leafRows > 0 and
				vIndexStats.leafRowsDeleted > 0 and
				(vIndexStats.leafRowsDeleted * 100 / vIndexStats.leafRows) > 
				pMaxLeafsDeleted)
			then
				vCount := vCount + 1;
				dbms_output.put_line('Rebuilding index ' || vIndexRec.index_name || '...');
           
				vAnalyze := 'alter index ' || vIndexRec.index_name ||
						' rebuild' ||
						' partition ' || vIndexRec.partition_name ||
						' parallel nologging compute statistics' ||
						' tablespace ' || vIndexRec.tablespace_name;
				execute immediate 'alter index ' || vIndexRec.index_name ||
							' rebuild' ||
							' partition ' || vIndexRec.partition_name ||
							' parallel nologging compute statistics' ||
							' tablespace ' || vIndexRec.tablespace_name;
			end if;
		end if;
		close csrIndexStats;

	end loop;

	dbms_output.put_line('Local indexes rebuilt: ' || to_char(vCount));
*/

end RebuildUnbalancedIndexes;
/

