PL/SQL Developer Test script 3.0
13
declare 
  -- Local variables here
begin
  --dbms_session.reset_package; return;
  f2ndfl_load_empl_api.merge_load_xml(
    p_code_na => 1,
    p_year    => 2017
  );
exception
  when others then
    dbms_output.put_line(utl_error_api.get_exception_full);
    raise;
end;
0
0
