create or replace package oct2005_je is
	procedure record ;
	function flag_je return pls_integer;
	procedure accept(p_jnl IN number) ;
	procedure re_journal(p_jnl IN number) ;
	procedure purge ;
end oct2005_je;
.
RUN
show errors

create or replace package body oct2005_je is
	g_postdate	date	:= trunc(sysdate);

	procedure purge is
	begin
		delete from "YANGL@CS.CMU.EDU".jnl245_who_charged_adj;
		Util.log('purged '||SQL%ROWCOUNT||' from jnl245_who_charged_adj');
		delete from "YANGL@CS.CMU.EDU".jnl245_journal_adj;
		Util.log('purged '||SQL%ROWCOUNT||' from jnl245_journal_adj');
		update who_charged
		   set account_flag='l'
		 where journal=245
		   and wr_id in (select id 
				   from who_recorded wr
					, "YANGL@CS.CMU.EDU".jnl245_user_adj jua
				  where wr.princ=jua.princ )
		   and account_flag='b';
		Util.log('Updated '||SQL%ROWCOUNT||' who_charged records from b to l');
	end purge;

	procedure re_journal(p_jnl IN number) is
	begin
		if p_jnl < 1 then
			raise_application_error(-20100, 'Invalid Journal number. jnl='||p_jnl);
		end if;

		UPDATE "YANGL@CS.CMU.EDU".jnl245_who_charged_adj wc 
		   SET wc.account_flag=(SELECT a.flag FROM accounts a WHERE a.id=wc.account)
		 WHERE wc.journal=p_jnl 
		   AND account_flag IS NULL
		   AND wc.account IN (select a.id FROM accounts a WHERE a.flag is NOT NULL);

		Util.log('Adjusted '||SQL%ROWCOUNT||' account flags in jnl245_who_charged_adj');

		delete from "YANGL@CS.CMU.EDU".jnl245_journal_adj;
		Util.log('purged '||SQL%ROWCOUNT||' from jnl245_journal_adj');

		--
		-- This part is the same as in record, it should be in a seperate procedure.
		--
	 	insert into "YANGL@CS.CMU.EDU".jnl245_journal_adj
			(journal,objcode,account,amount,trans_date,post_date,description ,creation_date,created_by)
			select 
				p_jnl
				,88200
				,c.account
				,sum(c.amount)
				,c.trans_date
				,g_postdate
				,count(distinct wr.princ)||' users'
	   			,sysdate
				,'oct2005_je'
			  from "YANGL@CS.CMU.EDU".jnl245_who_charged_adj c
				,who_recorded wr
			 where c.journal=p_jnl 
			   and c.account_flag is null
			   AND wr.id=c.wr_id
			 group by c.account, c.trans_date;
		Util.log('Journaled '||SQL%ROWCOUNT||' user records');

		UPDATE "YANGL@CS.CMU.EDU".jnl245_journal_adj
		   SET description='1 user'
		 WHERE journal = p_jnl 
		   AND description='1 users';

		/*
		 *  Augment descriptions with common prefix for the month.
		 */

		UPDATE "YANGL@CS.CMU.EDU".jnl245_journal_adj 
		   SET description='SCS Special Adjust Batch '||g_postdate||': '||description
		 WHERE journal=p_jnl;

		INSERT INTO "YANGL@CS.CMU.EDU".jnl245_journal_adj
			(journal,objcode,account,post_date,amount,description ,creation_date,created_by)
			SELECT p_jnl
				,'68200'
				,11685
				--,trans_date
				,g_postdate
				,0-sum(j.amount),
				'Special Adjust Batch to JNL 245 incident '||g_postdate
				,sysdate
				,'oct2005_je'
			   FROM "YANGL@CS.CMU.EDU".jnl245_journal_adj j
				,accounts a
			  WHERE j.journal=p_jnl 
			    AND j.account=a.id 
			    AND funding IS NOT NULL;
		Util.log('Journaled GL revenue '||SQL%ROWCOUNT||' rows');

	end re_journal;
		
	procedure record is
		l_adj_jnl	pls_integer;
		l_refund_cnt	pls_integer;
		l_notes_upd_cnt	pls_integer;
		--cursor adjust_princ_c is
		--	--
		--	select princ 
		--	  from "YANGL@CS.CMU.EDU".jnl245_user_adj
		--	;
			--
	begin
		l_adj_jnl := flag_je;
		Util.log('journal= '||l_adj_jnl);

		if l_adj_jnl < 1 then
			raise_application_error(-20100, 'Invalid Journal number. jnl='||l_adj_jnl);
		end if;
		-- refund
		insert into "YANGL@CS.CMU.EDU".jnl245_who_charged_adj
		(WR_ID ,PCT ,CHARGE ,AMOUNT ,TRANS_DATE ,SERVICE_ID ,JOURNAL ,ACCOUNT ,ACCOUNT_FLAG ,NOTES, creation_date, created_by)
			select
				wr_id
				,pct
				,0-charge
				,0-amount
				,trans_date
				,service_id
				,l_adj_jnl
				,account
				,account_flag
				,'Special Adj to JNL 245 incident - Refund Part'
				,sysdate
				--,'JNL 245 Special Adjust'
				,'oct2005_je'
			  from who_charged wc
				,who_recorded wr
			 where journal=245
			   and wr.id=wc.wr_id
			   and princ in (select princ from "YANGL@CS.CMU.EDU".jnl245_user_adj)
			   and (account_flag!='l' or account_flag is null)
		;
		l_refund_cnt := SQL%ROWCOUNT;
		Util.log('Inserted '||l_refund_cnt||' jnl245_who_charged_adj refund records');

		update who_charged 
		   set notes = 'JNL 245 Refunded and redistributed.'
		 where journal=245
		   and wr_id in (select id 
				   from who_recorded wr
					, "YANGL@CS.CMU.EDU".jnl245_user_adj jua
				  where wr.princ=jua.princ )
		   and (account_flag!='l' or account_flag is null);
		l_notes_upd_cnt := SQL%ROWCOUNT;
		Util.log('Updated '||l_notes_upd_cnt||' who_charged refund records');

		if l_refund_cnt <> l_notes_upd_cnt then
			--rollback;
			raise_application_error(-20100, 'Refund numbers do not match original number.'||l_refund_cnt||'-'||l_notes_upd_cnt);
		end if;

		-- Mark limbo accounts?
		update who_charged
		   set notes = 'JNL 245 Backcharged and redistributed.'
			,account_flag='b'
		 where journal=245
		   and wr_id in (select id 
				   from who_recorded wr
					, "YANGL@CS.CMU.EDU".jnl245_user_adj jua
				  where wr.princ=jua.princ )
		   and account_flag='l';
		Util.log('Updated '||SQL%ROWCOUNT||' who_charged backcharge records');
	
		-- record charges according to real labor.
		INSERT INTO "YANGL@CS.CMU.EDU".jnl245_who_charged_adj 	
			(wr_id,pct,charge,amount,trans_date,service_id,account,account_flag,journal, notes ,creation_date,created_by)
			SELECT
				ws.wr_id
				,sc.pct
				,sc.charge
				,sc.amount
				--,nvl(ws.trans_date,trunc(sysdate))
				,to_date('OCT-31-2005','MON-DD-YYYY') trans_date
				,ws.service_id
				,sc.account
				,a.flag account_flag
				,l_adj_jnl
				,'Special Adj to JNL 245 incident - Redist Part'
				,sysdate
				,'oct2005_je'
			 FROM	"YANGL@CS.CMU.EDU".oct_who_service_v ws
			 --FROM	oct_who_service_v ws
				,"YANGL@CS.CMU.EDU".jnl254_who_service_charge sc
				,accounts a
				--,journals j
			WHERE  ws.princ=sc.princ 
			  AND ws.service_id=sc.service_id
			  AND sc.account=a.id 
			  and ws.princ in (select princ from "YANGL@CS.CMU.EDU".jnl245_user_adj)
			  --AND j.id=qjournal
			;
		Util.log('Inserted '||SQL%ROWCOUNT||' jnl245_who_charged_adj new records');

	 	insert into "YANGL@CS.CMU.EDU".jnl245_journal_adj
			(journal,objcode,account,amount,trans_date,post_date,description ,creation_date,created_by)
			select 
				l_adj_jnl
				,88200
				,c.account
				,sum(c.amount)
				,c.trans_date
				,g_postdate
				,count(distinct wr.princ)||' users'
	   			,sysdate
				,'oct2005_je'
			  from "YANGL@CS.CMU.EDU".jnl245_who_charged_adj c
				,who_recorded wr
			 where c.journal=l_adj_jnl 
			   and c.account_flag is null
			   AND wr.id=c.wr_id
			 group by c.account, c.trans_date;
		Util.log('Journaled '||SQL%ROWCOUNT||' user records');

		UPDATE "YANGL@CS.CMU.EDU".jnl245_journal_adj
		   SET description='1 user'
		 WHERE journal = l_adj_jnl 
		   AND description='1 users';

		/*
		 *  Augment descriptions with common prefix for the month.
		 */

		UPDATE "YANGL@CS.CMU.EDU".jnl245_journal_adj 
		   SET description='SCS Special Adjust Batch '||g_postdate||': '||description
		 WHERE journal=l_adj_jnl;

		INSERT INTO "YANGL@CS.CMU.EDU".jnl245_journal_adj
			(journal,objcode,account,post_date,amount,description ,creation_date,created_by)
			SELECT l_adj_jnl
				,'68200'
				,11685
				--,c.trans_date
				,g_postdate
				,0-sum(j.amount),
				'Special Adjust Batch to JNL 245 incident '||g_postdate
				,sysdate
				,'oct2005_je'
			   FROM "YANGL@CS.CMU.EDU".jnl245_journal_adj j
				,accounts a
			  WHERE j.journal=l_adj_jnl 
			    AND j.account=a.id 
			    AND funding IS NOT NULL;
		--Util.log('Journaled GL revenue');
		Util.log('Journaled GL revenue '||SQL%ROWCOUNT||' rows');
	end record;

	function flag_je return pls_integer is
		l_adj_jnl	pls_integer;
		l_openid	pls_integer;
	begin
		begin
			select count(*)  
			  into l_openid
			  from journals;
		exception
			when no_data_found then
				raise_application_error(-20100, 'There is open Journal.');
		end;

		select max(id)
		  into l_adj_jnl
		  from journals;
		
		update journals
		   set JOURNAL_TYPE_FLAG='A'
			,JE_IN_PROCESS_FLAG='Y'
		 where id=l_adj_jnl;
		return l_adj_jnl;
	end flag_je;

	procedure accept(p_jnl	IN number)  is
	begin
		insert into who_charged
			( wr_id,pct,charge,amount,trans_date,service_id,account,account_flag,journal ,creation_date,created_by)
			select
				wr_id
				,pct
				,charge
				,amount
				,trans_date
				,service_id
				,account
				,account_flag
				,journal
				,creation_date
				,created_by
			  from "YANGL@CS.CMU.EDU".jnl245_who_charged_adj
			 where journal=p_jnl
		;
		Util.log('Inserted '||SQL%ROWCOUNT||' who_charged records');
		insert into journal
			(journal,objcode,account,post_date,amount,description ,creation_date,created_by)
			select
				journal
				,objcode
				,account
				,post_date
				,amount
				,description 
				,creation_date
				,created_by
			  from "YANGL@CS.CMU.EDU".jnl245_journal_adj
			 where journal=p_jnl
		;
		Util.log('Inserted '||SQL%ROWCOUNT||' Journal records');
		-- increment jnl in journals and param.
		UPDATE JOURNALS
		   SET JOURNAL_TYPE_FLAG = 'M',
			JE_IN_PROCESS_FLAG = NULL,
			post_date=g_postdate
		 WHERE  id = p_jnl;

		UPDATE param
		   SET journal=(select max(id)+1 FROM journals);

		INSERT INTO journals (id, post_date)
			SELECT p.journal,p.charge_last FROM param p;

	end accept;

end oct2005_je;
.
RUN
show errors
