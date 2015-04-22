-- Find duplicate indexes.
set nocount on

Declare @tablename varchar(130), @indid int, @loopcnt int, @indexCol varchar(150), @ind int, @indexname varchar(150),
        @table_id int

select @tablename = '', @table_id = 0

If @tablename <> ''  set @ind = 1
Else Set @ind = 0

create table #indexes ( Tablename varchar(130), id int,indexname varchar(150), colname varchar(150), seqno int, groupcnt int )

while ( 1 = 1)
Begin 

    select Top 1 @tablename = name, @table_id = id
    from   sysobjects
    where  type = 'u'
    and    id > @table_id 

   If @@ROWCOUNT = 0  
      BREAK


  Select @indid = 0, @ind = 0

  While ( 1 = 1)
  Begin 
    select TOP 1 @indid = indid, @indexname = name
    from   sysindexes
    Where  id = @table_id --object_id (@tablename)
    and    name not like '[_]%'
    and    indid > @indid
   
    If @@ROWCOUNT = 0
       BREAK

    Select @indexCol = '',@loopcnt = 1
    While ( 1 = 1)
    Begin
      select @indexCol = index_col(@tablename,@indid,@loopcnt)     

      If @indexcol IS NULL
         BREAK
      insert into #indexes (Tablename,id,colname,seqno,indexname) values (@tablename,@indid,@indexCol,@loopcnt,@indexname)
      Set @loopcnt = @loopcnt + 1
    End
  End
End

update a
set    a.groupcnt = ( select count(*) from #indexes b where a.id = b.id and a.tablename = b.tablename)
from   #indexes a


select a.tablename As 'TableName', a.indexname As 'FirstIndex', b.indexname As 'SecondIndex' , a.colname As 'Column name in First Index',
       a.seqno As 'Seq No',
       b.colname As 'Column name in Second Index', a.groupcnt, a.id,a.indexname
into   #indexes2
from   #indexes a, #indexes b 
where  a.colname  = b.colname
and    a.groupcnt = b.groupcnt
and    a.seqno    = b.seqno 
and    a.tablename = b.tablename
and    a.id < b.id
order by 1

select TableName,FirstIndex, SecondIndex, [Column name in First Index],[Seq No],[Column name in Second Index]
From   #indexes2 a
Where  a.groupcnt = ( Select count(*) from #indexes2 b
                      Where a.tablename = b.tablename and a.firstindex = b.firstindex 
                      and a.secondindex = b.secondindex)



drop table #indexes
drop table #indexes2


