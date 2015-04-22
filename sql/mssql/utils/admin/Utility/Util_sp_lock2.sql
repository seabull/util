BEGIN TRAN

CREATE procedure sp_lock2
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @test cursor
	DECLARE @dbname nvarchar(60)
	DECLARE @strsql varchar(300)
	DECLARE @objid int, @id int, @indid int


	CREATE TABLE #splock2_table (
		[id] INT NOT NULL IDENTITY(1,1),
		[spid] [smallint] NULL ,
		[dbid] smallint not null,
		[dbName] [nvarchar] (30) ,
		[ObjId] [int] NOT NULL ,
		[objname] nvarchar(60) NULL,
		[IndId] [smallint] NOT NULL ,
		[indName] nvarchar(60) NULL,
		[Type] [nvarchar] (4)  NULL ,
		[Resource] [nvarchar] (16)  NULL ,
		[Mode] [nvarchar] (8)  NULL ,
		[Status] [nvarchar] (5) NULL 
	) 

	CREATE INDEX INX_SP_LOCK2_OBJID on #splock2_table ( objid )
	
	INSERT INTO #splock2_table ( spid, dbid, dbname, objid, indid, type, resource, mode, status ) 
	-- the base for the following query is taken from sp_lock
	(SELECT convert (smallint, req_spid) As spid,
		rsc_dbid as dbid,
		left( d.name, 30) as dbName,
		rsc_objid As ObjId,		
		rsc_indid As IndId,
		substring (v.name, 1, 4) As Type,
		substring (rsc_text, 1, 16) as Resource,
		substring (u.name, 1, 8) As Mode,
		substring (x.name, 1, 5) As Status
	from 	
		master.dbo.syslockinfo,
		master.dbo.spt_values v,
		master.dbo.spt_values x,
		master.dbo.spt_values u,
		master.dbo.sysdatabases d

	where   master.dbo.syslockinfo.rsc_type = v.number
			and v.type = 'LR'
			and master.dbo.syslockinfo.req_status = x.number
			and x.type = 'LS'
			and master.dbo.syslockinfo.req_mode + 1 = u.number
			and u.type = 'L'
			and d.dbid = rsc_dbid )


SET @test =  CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT [id],dbname,objid,indid FROM #splock2_table WHERE objid > 0 

OPEN @test
FETCH NEXT FROM @test INTO @id, @dbname, @objid, @indid
WHILE @@fetch_status = 0 BEGIN
	IF ( @objid > 0 ) AND ( @indid > 0 ) BEGIN
		SELECT @strsql = 'update #splock2_table set objname = left(so.name,60), indname = left( si.name, 60 )  from #splock2_table t, '+@dbname+'.dbo.sysobjects so, '+@dbname+'.dbo.sysindexes si' 
		SELECT @strsql = @strsql + ' where t.objid = so.id  and t.indid=si.indid and so.id = si.id and t.id = '+convert(varchar(20),@id)
		EXEC(@strsql)
	END ELSE
	IF ( @objid > 0 ) BEGIN
		SELECT @strsql = 'update #splock2_table set objname = left( so.name,60) from #splock2_table t, '+@dbname+'.dbo.sysobjects so where so.id  = t.objid and t.id = '+convert(varchar(20),@id)
		EXEC(@strsql)
	end
	FETCH NEXT FROM @test INTO @id, @dbname, @objid, @indid
END
CLOSE @test
DEALLOCATE @test

SELECT spid,dbid,dbname,objid,objname,indid,indname,type,resource,mode,status 
	FROM #splock2_table 
	ORDER by spid


DROP TABLE #splock2_table
END
GO



ROLLBACK