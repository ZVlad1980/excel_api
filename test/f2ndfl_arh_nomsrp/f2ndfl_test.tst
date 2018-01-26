PL/SQL Developer Test script 3.0
38
-- Created on 26.01.2018 by V.ZHURAVOV 
declare 
  -- Local variables here
  l_err_msg varchar2(32767);
begin
  --dbms_session.reset_package; return;
  -- Test statements here
  /*
  gateway_pkg.f2_ndfl_api(
    x_err_msg     => l_err_msg,
    p_action_code => 'f2_load_spravki',
    p_code_na     => 1,
    p_year        => 2017
  );
  dbms_output.put_line(l_err_msg);
  --*/
  /*
  f2ndfl_load_api.create_2ndfl_refs(
    p_action_code => 'f2_load_spravki',
    p_code_na     => 1,
    p_year        => 2017,
    p_force       => true
  );
  --*/
  f2ndfl_load_api.create_2ndfl_refs(
    p_action_code => 'f2_arh_nomspr',
    p_code_na     => 1,
    p_year        => 2017,
    p_force       => true
  );
  --
exception
  when others then
    dbms_output.put_line(
      utl_error_api.get_exception_full
    );
    raise;
end;
0
0
