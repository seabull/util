-- $Id: asofv_pkg.spb.sql,v 1.9 2006/08/07 18:01:53 yangl Exp $
--
create or replace package body utility.asofv_pkg
as
	/*
	 * NAME:
	 *   exec_force
	 *
	 * DESCRIPTION:
	 *   Wrapper for EXECUTE IMMEDIATE that discards any exceptions.
	 */
	procedure exec_force(pCmd varchar2) IS
	begin
		traceit.log(traceit.constDEBUGLEVEL_C, 'Enter asofv_pkg.exec_force, %s', pCmd);
		EXECUTE IMMEDIATE pCmd;
		traceit.log(traceit.constDEBUGLEVEL_C, 'Exit asofv_pkg.exec_force');
	exception when others then
		traceit.log(traceit.constDEBUGLEVEL_C, 'Exit asofv_pkg.exec_force with ignored exceptions');
	end exec_force;

	procedure show_msg(p_msg IN varchar2)
	is
	begin
		-- Should add prefix here?
		dbms_output.put_line(p_msg);
	end show_msg;

	--function vcreate(
	procedure vcreate(
			pTblSchema	IN	all_tables.owner%TYPE
			,pTblName	IN	all_tables.table_name%TYPE
			,pVSchema	IN	all_tables.owner%TYPE
			,pVName		IN	all_tables.table_name%TYPE
			,pParamTblFlag	IN	varchar2			default ParamTblFlag
			,pParamTblSchema IN	all_tables.owner%TYPE		default PARAMTBLSCHEMA
			,pParamTblName	IN	all_tables.table_name%TYPE	default PARAMTBLNAME
			)
		--return boolean
	is
		l_sql_str		varchar2(4000);
		l_TblSchema		all_tables.owner%TYPE		:= upper(nvl(rtrim(pTblSchema), 'HOSTDB'));
		l_TblName		all_tables.table_name%TYPE	:= upper(rtrim(pTblName));

		l_VSchema		all_tables.owner%TYPE		:= upper(nvl(rtrim(pVSchema), sys_context('USERENV','CURRENT_USER')));
		l_VName			all_tables.table_name%TYPE	:= upper(nvl(rtrim(pVName), l_TblName||ASOFV_POSTFIX));

		l_ParamTblSchema	all_tables.owner%TYPE		:= upper(nvl(rtrim(pParamTblSchema), PARAMTBLSCHEMA));
		l_ParamTblName		all_tables.table_name%TYPE	:= upper(nvl(rtrim(pParamTblName), PARAMTBLNAME));

	begin
		traceit.log(traceit.constDEBUGLEVEL_C, 'Enter asofv_pkg.vcreate(%s, %s, %s, %s, %s, %s, %s)'
						,l_TblSchema
						,l_TblName
						,l_VSchema
						,l_VName
						,l_ParamTblSchema
						,l_ParamTblName
						,pParamTblFlag
			);

		if (l_TblName is null) then
			raise_application_error(-20102
				, 'Base table name can not be null when calling asofv_pkg.vcreate()');
		end if;

		if(not obj_util.is_table(l_TblSchema, l_TblName)) then
			traceit.log(traceit.constDEBUGLEVEL_A
					, '%s.%s does not exist or you do not have access to it'
					,l_TblSchema, l_TblName);
			raise_application_error(-20100
				, l_TblSchema||'.'||l_TblName||'does not exist or you do not have access to it.');
		end if;

		if(upper(l_TblSchema) not like 'AUD_%') then
			traceit.log(traceit.constDEBUGLEVEL_A
					, 'Schema name %s should be audited and named AUD_<Base Schema>'
					,l_TblSchema);
			raise_application_error(-20100
				, 'Schema name should be audited and named AUD_<Base Schema> Got '||l_TblSchema);
		end if;

		if(obj_util.is_view(l_VSchema, l_VName)) then
			traceit.log(traceit.constDEBUGLEVEL_A
					, '%s.%s alread exists in the database.'
					,l_VSchema, l_VName);
			raise_application_error(-20101
				, l_VSchema||'.'||l_VName||'already exists in the database.');
		end if;

		-- Bind variables don't work. Need to make them work.
		--l_sql_str :=
		--	'create or replace view :VName as ' || NEWLINE
		--	||' select '		|| NEWLINE
		--	||'	* '		|| NEWLINE
		--	||'  from ( '		|| NEWLINE
		--	||'		select '	|| NEWLINE
		--	||'			b.* '	|| NEWLINE
		--	||'			,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then '	|| NEWLINE
		--	||'				aud_action '	|| NEWLINE
		--	||'			end rowflag '		|| NEWLINE
		--	||'		  from :TblName b '	|| NEWLINE
		--	||'		 where aud_ts <= ( '		|| NEWLINE
		--		||' select ts from :ParamTblName '
		--		||' where id=(select max(id) from :ParamTblName '
		--					||' where flag='':ParamTblFlag'')) '	|| NEWLINE
		--	||' ) x '	|| NEWLINE
		--	||' where x.rowflag!=''D'' '	|| NEWLINE
		--	||'   and x.rowflag is not null;'
		--	;
		l_sql_str :=
			'create or replace view ' || '"' || l_VSchema || '".' ||l_VName ||' as ' || NEWLINE
			||' select '		|| NEWLINE
			||'	* '		|| NEWLINE
			||'  from ( '		|| NEWLINE
			||'		select '	|| NEWLINE
			||'			b.* '	|| NEWLINE
			||'			,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then '	|| NEWLINE
			||'				aud_action '	|| NEWLINE
			||'			end rowflag '		|| NEWLINE
			||'		  from ' || '"' || l_TblSchema || '".' || l_TblName || ' b '	|| NEWLINE
			||'		 where aud_ts <= ( '		|| NEWLINE
				||' select ts from '|| '"' || l_ParamTblSchema || '".' || l_ParamTblName 
				||' where id=(select max(id) from ' ||'"' || l_ParamTblSchema || '".' || l_ParamTblName
							||' where flag=''' || pParamTblFlag || ''')) '	|| NEWLINE
			||' ) x '	|| NEWLINE
			||' where x.rowflag!=''D'' '	|| NEWLINE
			||'   and x.rowflag is not null'
			;
		traceit.log(traceit.constDEBUGLEVEL_C, 'sql_str=%s', l_sql_str);
		--traceit.log(traceit.constDEBUGLEVEL_C, '%s, %s, %s, %s'
		--					,'"' || l_VSchema || '".' ||l_VName
		--					,'"' || l_TblSchema || '".' || l_TblName
		--					,'"' || l_ParamTblSchema || '".' || l_ParamTblName
		--					,pParamTblFlag
		--					);

		EXECUTE IMMEDIATE l_sql_str;
		--	using '"' || l_VSchema || '".' ||l_VName
		--		,'"' || l_TblSchema || '".' || l_TblName
		--		,'"' || l_ParamTblSchema || '".' || l_ParamTblName
		--		,pParamTblFlag;

		traceit.log(traceit.constDEBUGLEVEL_A, 'view %s.%s created', l_VSchema, l_VName);
		show_msg('Successfully Created View "'||l_VSchema||'".'||l_VName);
		traceit.log(traceit.constDEBUGLEVEL_C, 'Exit asofv_pkg.vcreate');
	exception
		when others then
			show_msg('Failed Create View "'||l_VSchema||'".'||l_VName);
			raise;
	end vcreate;

end asofv_pkg;
/
show error
grant execute on utility.asofv_pkg to public;
create public synonym asofv_pkg for utility.asofv_pkg;
