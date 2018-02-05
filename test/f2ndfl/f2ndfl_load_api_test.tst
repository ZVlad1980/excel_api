PL/SQL Developer Test script 3.0
23
-- Created on 31.01.2018 by V.ZHURAVOV 
declare 
  -- Local variables here
  i integer;
begin
  --dbms_session.reset_package; return;
  -- Test statements here
/*  f2ndfl_load_api.create_2ndfl_refs(
    p_action_code => 'f2_delete_zero_ref',
    p_code_na     => 1,
    p_year        => 2017
  );*/
  --
  f2ndfl_load_api.purge_loads(
    p_action_code => 'f2_arh_purge_xml',
    p_code_na     => 1,
    p_year        => 2017
  );
exception
  when others then
    dbms_output.put_line(utl_error_api.get_exception_full);
    raise;
end;
0
0
