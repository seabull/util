-- $Id: measure_usage.sql,v 1.1 2005/09/15 13:36:35 yangl Exp $
--
-- Expert One-on-one
--

set echo on
--drop table t;

--create table t ( x int, y char(1000) default 'x' );

create or replace procedure measure_usage
as
	l_free_blks                 number;
	l_total_blocks              number;
	l_total_bytes               number;
	l_unused_blocks             number;
	l_unused_bytes              number;
	l_LastUsedExtFileId         number;
	l_LastUsedExtBlockId        number;
	l_LAST_USED_BLOCK           number;
	
	procedure get_data
	is
	begin
		dbms_space.free_blocks
		(
			segment_owner     =>  USER,
			segment_name      => 'T',
			segment_type      => 'TABLE',
			FREELIST_group_id => 0,
			free_blks         => l_free_blks 
		);
		
		dbms_space.unused_space
		(
			segment_owner     => USER,
			segment_name      => 'T',
			segment_type      => 'TABLE',
			total_blocks      => l_total_blocks,
			total_bytes       => l_total_bytes,
			unused_blocks     => l_unused_blocks,
			unused_bytes      => l_unused_bytes,
			LAST_USED_EXTENT_FILE_ID => l_LastUsedExtFileId,
			LAST_USED_EXTENT_BLOCK_ID => l_LastUsedExtBlockId,
			LAST_USED_BLOCK => l_last_used_block 
		) ;
		
		
		dbms_output.put_line(
					L_free_blks || ' on FREELIST, ' ||
					to_number(l_total_blocks-l_unused_blocks-1 ) ||
					' used by table'
				);
	end;
begin
	for i in 0 .. 10
	loop
		dbms_output.put( 'insert ' || to_char(i,'00') || ' ' );
		get_data;
		insert into t (x) values ( i );
		commit ;
	end loop;
	
	
	for i in 0 .. 10
	loop
		dbms_output.put( 'update ' || to_char(i,'00') || ' ' );
		get_data;
		update t set y = null where x = i;
		commit;
	end loop;
end;
/

-- exec measure_usage
