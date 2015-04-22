-- $Id: sort_string.sql,v 1.1 2005/06/10 16:29:09 yangl Exp $
--
create or replace function sort_string 
  (p_string in varchar2, p_delim in varchar2, 
  p_dup in varchar2 default 'I') return varchar2 is
  type t_sort_tab is table of number(4) index by varchar2(4000);
  t_sort t_sort_tab;
  v_start number := 1;
  v_end number := 0;
  v_ext varchar2(4000);
  v_out varchar2(4000);
begin
  while v_end < length(p_string) loop
    v_end := instr(p_string,p_delim,v_start);
    if v_end = 0 then
      v_end := length(p_string)+1;
    end if;
    v_ext := substr(p_string,v_start,v_end-v_start);
    if t_sort.exists(v_ext) THEN
      t_sort(v_ext) := t_sort(v_ext) + 1;
    else
      t_sort(v_ext) := 1;
    end if;
    v_start := v_end + length(p_delim);
  end loop;
  v_ext := t_sort.first;
  WHILE v_ext is not null loop
    IF p_dup = 'I' THEN
      -- Option A - Ignore duplicates (treat as single occurrence)
      v_out := v_out||v_ext||p_delim;
    ELSIF p_dup = 'N' THEN
      -- Option B - Add number of entries after value in brackates
      v_end := t_sort(v_ext);
      v_out := v_out||v_ext||'('||to_char(v_end)||')'||p_delim;
    ELSIF p_dup = 'D' THEN
      -- Option C - Repeat duplicated entries
      v_end := t_sort(v_ext);
      FOR i in 1..v_end loop
        v_out := v_out||v_ext||p_delim;
      END LOOP;
    END IF;
    v_ext := t_sort.next(v_ext);
  END LOOP;
  v_out := substr(v_out,1,instr(v_out,p_delim,-1)-1);
  return v_out;
end;
 
