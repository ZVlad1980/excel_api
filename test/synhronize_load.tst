PL/SQL Developer Test script 3.0
10
begin
  f2ndfl_arh_spravki_api.synhonize_load(
    p_code_na => 1,
    p_year    => 2016 --,    p_ref_id  => 358541 --закончил на этой справке. ќшибка в мес€цах лоада
  );
exception
  when others then
    dbms_output.put_line(utl_error_api.get_exception_full);
    raise;
end;
0
0
