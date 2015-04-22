----- create Subordinates function using CTE
if object_id( 'subordinates', 'IF' ) is not null 
drop function subordinates
GO

create function subordinates( @year int, @node_id int ) 
    returns table as 
return 
    with subnodes( distance, year, node_id, node_name, node_seq )
        as ( 
        select 0, @year, h.node_id, h.node_name, 
                convert( varchar(80), ltrim(str(h.node_id))) as node_seq 
          from hierarchy h 
         where h.node_id = @node_id 
           and h.year = @year 
        union all 
        select distance+1, @year, h.node_id, h.node_name, 
                convert( varchar(80), sn.node_seq+'.'+ltrim(str(h.node_id))) 
          from hierarchy h 
        inner join subnodes sn 
            on h.year = @year 
            and h.parent_node = sn.node_id
        )
    select distance, year, node_id, node_name, node_seq 
      from subnodes
GO

----- create the Superiors function using CTE
if object_id( 'superiors', 'IF' ) is not null 
drop function superiors
GO

create function superiors( @year int, @node_id int ) 
    returns table 
as 
    return
        with supnodes( distance, year, node_id, node_name, parent_node )
        as ( 
            select 0, @year, h.node_id, h.node_name, h.parent_node 
              from hierarchy h 
             where h.node_id = @node_id 
               and h.year = @year 
            union all 
            select distance-1, @year, h.node_id, h.node_name, h.parent_node 
              from hierarchy h 
            inner join supnodes sn 
                on h.year = @year 
                and h.node_id = sn.parent_node
        )
        select distance, year, node_id, node_name 
          from supnodes
GO
