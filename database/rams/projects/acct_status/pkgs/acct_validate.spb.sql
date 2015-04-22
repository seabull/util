-- $Id: acct_validate.spb.sql,v 1.3 2008/07/15 15:47:12 yangl Exp $
--
--	$Author: yangl $
--	$Date: 2008/07/15 15:47:12 $
--
create or replace package body acct_validate
as
    -- for debugging only
    procedure show(msg varchar2)
    is
    begin
        dbms_output.put_line(msg);
    end show;

	--
	-- private methods
	--
	function is_valid_gl(p_acct_string	in varchar2
				,p_trans_date	in date default trunc(sysdate)
				,p_post_date	in date default trunc(sysdate)
			)
		return varchar2;

	function is_valid_gm(p_acct_string	in varchar2
				,p_trans_date	in date default trunc(sysdate)
				,p_post_date	in date default trunc(sysdate)
                ,p_message      out varchar2
			)
		return varchar2;

	--
	-- Public methods
	--
    function account_status(p_acct_string   in varchar2
                            ,p_trans_date   in date default trunc(sysdate))
        return varchar2
    is
        l_result    varchar2(1) := null;
        l_valid     varchar2(20):= null;
        l_trans_date    date;
        l_msg       varchar2(32765);
    begin
        traceit.log(traceit.constDEBUGLEVEL_B, 'Entering account_status(%s, %s)', p_acct_string, p_trans_date);
        if(p_trans_date is null) then
            l_trans_date := trunc(sysdate);
        else
            l_trans_date := trunc(p_trans_date);
        end if;

        if(p_acct_string is not null) then
            l_valid := is_valid(p_acct_string, l_trans_date, trunc(sysdate), l_msg);
            traceit.log(traceit.constDEBUGLEVEL_B
                    , '%s - account_status message:', l_valid, l_msg);

            if (l_valid = eValidOracleString) then
                l_result := cFlagValid;
            else if (l_valid = eInvalidOracleString) then
                    l_result := cFlagLimbo;
                 else
                    l_result := cFlagUnknown;
                 end if;
            end if;
        end if;

        traceit.log(traceit.constDEBUGLEVEL_B, 'Exitting account_status=%s', l_result);
        return l_result;
    end account_status;

	function checkAcctType(p_acct_string	in varchar2)
		return varchar2
	is
		TYPE account_segs_t IS VARRAY(5) OF VARCHAR2(8);

		l_acct_segs account_segs_t;
		j pls_integer	:= 1;
		i pls_integer	:= 1;
		n pls_integer	:= 1;
		l_rtn varchar2(20);
	begin
		l_acct_segs := account_segs_t(null,null,null,null,null);
		LOOP
			i := INSTR(p_acct_string,'-',j);
			EXIT WHEN (i <= 0 OR i IS NULL);

			IF (n > 4) THEN
				raise_application_error(
					-20101,'too many segments in account string (max 5)'
				);
			END IF;
			l_acct_segs(n) := SUBSTR(p_acct_string,j,i-j);
			n := n+1;
			j := i+1;
		END LOOP;

		l_acct_segs(n) := SUBSTR(p_acct_string,j);
		IF (n = 5) THEN
			-- GL
			return eOracleStringGL;
		ELSE	
			IF (n = 3) THEN
				-- GM
				return eOracleStringGM;
			ELSE
				--Unknown
				return eOracleStringUnknown;
			END IF;
		END IF; 

	end checkAcctType;

	function is_valid(p_acct_id in number
				,p_trans_date	in date default trunc(sysdate)
				,p_post_date	in date default trunc(sysdate)
                ,p_message      out varchar2
			)
		return varchar2
	is
		cursor l_pta_csr(p_pta varchar2) is
			select
				*
			  from hostdb.pta_status
			 where pta=p_pta;

		l_acct_str	varchar2(24);
		l_acct_type	varchar2(2);
        l_acct_flag hostdb.accounts.flag%TYPE;

		l_trans_date	date	:= trunc(p_trans_date);
		l_post_date	    date	:= trunc(p_post_date);
	begin
		begin
			select 
				decode(project, null, 'GL','GM')
				,decode(project
					, null
					,funding||'-'||function||'-'||activity||'-'||org||'-'||entity
					,project||'-'||task||'-'||award
					)
                ,flag
			  into l_acct_type, l_acct_str, l_acct_flag
			  from hostdb.accounts
			 where id=p_acct_id;
		exception
			when no_data_found then
				return eInvalidOracleString;
		end;

		if (l_acct_type = 'GL') then
            if(l_acct_flag is null or l_acct_flag = 'i') then
                return eValidOracleString;
            else
			    return eInvalidOracleString;
            end if;
			--return decode(l_acct_flag, null, eValidOracleString, eInvalidOracleString);
			--return is_valid_gl(l_acct_str);
		else
			return is_valid_gm(l_acct_str, l_trans_date, l_post_date, p_message);
		end if;

	end is_valid;

	function is_valid(p_acct_string		in varchar2
				,p_trans_date	in date default trunc(sysdate)
				,p_post_date	in date default trunc(sysdate)
                ,p_message      out varchar2
			)
		return varchar2
	is
		l_acct_type	varchar2(10);
        --l_msg       varchar2(32765);
	begin
		l_acct_type := checkAcctType(p_acct_string);
        show('acct type='||l_acct_type);

        p_message := null;
		if (l_acct_type = eOracleStringGM) then
			return is_valid_gm(p_acct_string, p_trans_date, p_post_date, p_message);
		else
			if (l_acct_type = eOracleStringGL) then
				return is_valid_gl(p_acct_string, p_trans_date, p_post_date);
			else
                show('neither GM nor GL');
				return eInvalidOracleString;
			end if;
		end if;

	end is_valid;

	function is_valid_gl(p_acct_string		in varchar2
				,p_trans_date	in date default trunc(sysdate)
				,p_post_date	in date default trunc(sysdate)
			)
		return varchar2
	is
		l_id	        pls_integer;
		l_acct_type	    varchar2(10);
		l_acct_str	    varchar2(24)	:= p_acct_string;
        l_acct_flag     hostdb.accounts.flag%TYPE;
	begin
		l_acct_type := checkAcctType(l_acct_str);
	
		if (l_acct_type != eOracleStringGL) then
			dbms_output.put_line('Unexpected Oracle String Type - '||l_acct_str);
			traceit.log(traceit.constDEBUGLEVEL_A, 'Unexpected Oracle String Type - %s', l_acct_str);
			raise_application_error(-20100, l_acct_str||' does not appear to be GM');
		end if;

		begin
			select id, flag
			  into l_id, l_acct_flag
			  from hostdb.accounts
			 where p_acct_string=funding||'-'||function||'-'||activity||'-'||org||'-'||entity;
			
		exception
			when no_data_found then
				l_id := null;
			when others then
				raise_application_error(-20101, l_acct_str||' cannot be found as a GL');
		end;

		if (l_id is null or l_acct_flag = 'l') then
			return eInvalidOracleString;
		else
			return eValidOracleString;
		end if;

	end is_valid_gl;

	function is_valid_gm(p_acct_string		in varchar2
				,p_trans_date	in date default trunc(sysdate)
				,p_post_date	in date default trunc(sysdate)
                ,p_message      out varchar2
			)
		return varchar2
	is
		cursor l_pta_csr(p_pta varchar2) is
			select
				*
				--pta
				--,proj_name
				--,award_name
				--,proj_status_code
				--,award_status
				--,task_charge_flag
				--,proj_start_date
				--,award_start_date_active
				--,proj_completion_date
				--,proj_closed_date
				--,award_end_date_active
				--,award_closed_date
				--,task_completion_date
			  from hostdb.pta_status
			 where pta=p_pta;

		l_acct_str	varchar2(24)	:= p_acct_string;
		l_acct_type	varchar2(2);
		l_pta_row	hostdb.pta_status%rowtype;
		l_valid		boolean := true;
		l_msg		varchar2(32765) := '';
		l_msg_sep	varchar2(1) := ':';

		l_trans_date	date	:= trunc(p_trans_date);
		l_post_date	date	:= trunc(p_post_date);
	begin
		-- we probably do not need to check here since it is a private method.
		-- But check it for now anyway since this function could be made public.
		l_acct_type := checkAcctType(l_acct_str);
	
		if (l_acct_type != eOracleStringGM) then
			dbms_output.put_line('Unexpected Oracle String Type - '||l_acct_str);
			raise_application_error(-20100, l_acct_str||' does not appear to be GM');
		end if;

		open l_pta_csr(l_acct_str);
		fetch l_pta_csr into l_pta_row;
		if (l_pta_csr%NOTFOUND) then
			return eUnknownStatus;
		end if;

		-- check pta flags
		--    (pta.TASK_CHARGE_FLAG='Y'
		--   AND pta.Award_Status not in ('CLOSED','ON_HOLD')
		--   AND pta.proj_status_code not IN
                -- 	('CLOSED','PENDING_CLOSE','SUBMITTED','UNAPPROVED')

		if(nvl(l_pta_row.task_charge_flag, 'Y') = 'N') then
			l_valid := false;
			l_msg := 'Task-Charge-Flag';
		end if;

		if (l_pta_row.proj_status_code not in ('APPROVED', 'ACTIVE')) then
			--
			-- invalid or unknown status
			--
			l_valid := false;
			if (l_pta_row.proj_status_code not in 
				('CLOSED','PENDING_CLOSE','SUBMITTED','UNAPPROVED')
			) then
				-- unknown status
				l_msg := l_msg || l_msg_sep || 'PrjStatus-Unknown';
			else
				l_msg := l_msg || l_msg_sep || 'PrjStatus-' ||l_pta_row.proj_status_code;
			end if;
		end if;

		if (l_pta_row.award_status not in ('ACTIVE','AT_RISK')) then
			--
			-- invalid or unknown status
			--
			l_valid := false;
			if (l_pta_row.award_status not in ('CLOSED','ON_HOLD')) then
				-- unknown status
				l_msg := l_msg || l_msg_sep || 'AwardStatus-Unknown';
			else
				l_msg := l_msg || l_msg_sep || 'AwardStatus-' ||l_pta_row.award_status;
			end if;
		end if;

		--
		-- Check dates
		--
		--
		--    AND NVL(PTA.PROJ_CLOSED_DATE, to_date('31-DEC-2057','DD-MON-YYYY')) >= SYSDATE
		--    AND NVL(PTA.AWARD_CLOSED_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) >= SYSDATE
		-- --
		-- -- transdate check TO_DATE($maxDate,'YYYYMMDD')
		--    AND NVL(PTA.TASK_COMPLETION_DATE,to_date('31-DEC-2057','DD-MON-YYYY')) >=  TO_DATE($maxDate,'YYYYMMDD')
		--    AND NVL(PTA.AWARD_END_DATE_ACTIVE".",to_date('31-DEC-2057','DD-MON-YYYY')) >= TO_DATE($maxDate, 'YYYYMMDD')
		--    AND NVL(PTA.proj_completion_date,to_date('31-DEC-2057','DD-MON-YYYY')) >= TO_DATE($maxDate,'YYYYMMDD')--
		--    AND NVL(PTA.PROJ_START_DATE,to_date('31-DEC-1900','DD-MON-YYYY')) <= TO_DATE($minDate,'YYYYMMDD'))
		-- ;

		if (nvl(l_pta_row.proj_start_date, gMINDATE) > l_trans_date) then
			l_valid := false;
			l_msg := l_msg || l_msg_sep || 'PrjStart>Transdate';
		end if;

		if (nvl(l_pta_row.award_start_date_active, gMINDATE) > l_trans_date) then
			l_valid := false;
			l_msg := l_msg || l_msg_sep || 'AwardStart>Transdate';
		end if;

		if (nvl(l_pta_row.proj_completion_date, gMAXDATE) < l_trans_date) then
			l_valid := false;
			l_msg := l_msg || l_msg_sep || 'PrjComplete<Transdate';
		end if;

		if (nvl(l_pta_row.award_end_date_active, gMAXDATE) < l_trans_date) then
			l_valid := false;
			l_msg := l_msg || l_msg_sep || 'AwardEnd<Transdate';
		end if;

		if (nvl(l_pta_row.task_completion_date, gMAXDATE) < l_trans_date) then
			l_valid := false;
			l_msg := l_msg || l_msg_sep || 'TaskComplete<Transdate';
		end if;

		--
		-- Close Dates
		--
		if (nvl(l_pta_row.proj_closed_date, gMAXDATE) < l_post_date) then
			l_valid := false;
			l_msg := l_msg || l_msg_sep || 'PrjClosed<Postdate';
		end if;

		if (nvl(l_pta_row.award_closed_date, gMAXDATE) < l_post_date) then
			l_valid := false;
			l_msg := l_msg || l_msg_sep || 'AwardClosed<Postdate';
		end if;

        show('l_valid=' || hostdb.yn.bc(l_valid));
        show('l_msg=' || l_msg);

		--
		--
		if (l_valid) then
			return eValidOracleString;
		else
            p_message := l_msg || ':';
			return eInvalidOracleString;
		end if;
		
	end is_valid_gm;

begin
	null;
end acct_validate;
/
show error;

