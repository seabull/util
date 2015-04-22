create or replace
trigger biu_fer_debugtab_trg
before insert or update on debugtab for each row
begin
  :new.modules := upper( :new.modules );
  :new.show_date := upper( :new.show_date );
  :new.session_id := upper( :new.session_id );
  :new.userid := upper( :new.userid );

  declare
    l_date varchar2(100);
  begin
    l_date := to_char( sysdate, :new.date_format );
  exception
    when others then
      raise_application_error( 
        -20001, 
        'Invalid Date Format In Debug Date Format' );
  end;
end;
/
