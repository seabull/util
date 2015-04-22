CREATE proc sp_check_job_running
	@job_name 		char(50),
	@minutes_allowed	int,
	@person_to_notify	varchar(50)
AS  

DECLARE @var1 			char(1),
	@process_id		char(8),
	@job_id_char		char(8),
	@minutes_running 	int,
	@message_text		varchar(255)

select @job_id_char = substring(CAST(job_id AS char(50)),1,8) 
from  msdb..sysjobs
where name = @job_name

select @process_id = 	substring(@job_id_char,7,2) + 
			substring(@job_id_char,5,2) +
			substring(@job_id_char,3,2) +
			substring(@job_id_char,1,2)


select @minutes_running = DATEDIFF(minute,last_batch, getdate())
from master..sysprocesses
where program_name LIKE ('%0x' + @process_id +'%')

if @minutes_running > @minutes_allowed
  BEGIN
    select @message_text = ('Job ' 
	+ UPPER(SUBSTRING(@job_name,1,LEN(@job_name)))
	+ ' has been running for '
	+ SUBSTRING(CAST(@minutes_running AS char(5)),1,LEN(CAST(@minutes_running AS char(5))))
	+ ' minutes, which is over the allowed run time of '
	+ SUBSTRING(CAST(@minutes_allowed AS char(5)),1,LEN(CAST(@minutes_allowed AS char(5)))) 
	+ ' minutes.')
    EXEC master..xp_sendmail 
	@recipients = @person_to_notify, 
	@message = @message_text,
        @subject = 'Long-Running Job to Check'
  END

--  Typical job step syntax for job to do the checking

--execute sp_check_job_running
--      'JobThatSHouldBeDoneIn5Minutes', 
--       5, 
--       'DBAdmin@mycompany.com'



