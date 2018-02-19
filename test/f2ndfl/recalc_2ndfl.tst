PL/SQL Developer Test script 3.0
14
-- Created on 19.02.2018 by V.ZHURAVOV 
declare 
  -- Local variables here
  i integer;
begin
  -- Test statements here
  f2ndfl_arh_spravki_api.recalc_reference(
    p_ref_id => 1030190
  );
exception
  when others then
    dbms_output.put_line(utl_error_api.get_exception_full);
    raise;
end;
0
0
