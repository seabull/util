select 
        table_name
        ,(num_rows*avg_row_len)/(1024*1024) MB 
  from user_tables 
where table_name='mytable';
