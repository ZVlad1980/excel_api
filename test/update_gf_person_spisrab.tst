PL/SQL Developer Test script 3.0
9
begin
  f_ndfl_load_spisrab_api.identify_employees(
    p_year => 2016
  );
exception
  when others then
    dbms_output.put_line(utl_error_api.get_exception_full);
    raise;
end;
0
0
