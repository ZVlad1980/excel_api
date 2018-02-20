PL/SQL Developer Test script 3.0
53
-- Created on 31.01.2018 by V.ZHURAVOV 
declare 
  -- Local variables here
  C_YEAR int := 2017;
begin
  --dbms_session.reset_package; return;
  -- Test statements here
  /*
  f2ndfl_load_api.purge_loads(
    p_action_code => f2ndfl_load_api.C_PRG_ARH_SPRAVKI,
    p_code_na     => 1,
    p_year        => C_YEAR,
    p_force       => true
  );--*/
  --
  /*
  f2ndfl_load_api.create_2ndfl_refs(
    p_action_code => f2ndfl_load_api.C_ACT_ENUMERATION, --C_ACT_ENUMERATION,--
    p_code_na     => 1,
    p_year        => C_YEAR
  );
  --*/
  /*
  f2ndfl_load_api.create_2ndfl_refs(
    p_action_code => f2ndfl_load_api.C_ACT_COPY2ARH, --C_ACT_ENUMERATION,--
    p_code_na     => 1,
    p_year        => C_YEAR
  );
  --*/
  /*
  f2ndfl_arh_spravki_api.fix_cityzenship(
    p_code_na => 1,
    p_year    => C_YEAR
  );
  commit;
  --*/
  /*f2ndfl_load_api.create_2ndfl_refs(
    p_action_code => f2ndfl_load_api.C_ACT_INIT_XML, --C_ACT_ENUMERATION,--
    p_code_na     => 1,
    p_year        => C_YEAR
  );
  --
  commit;*/
  fxndfl_util.raspredSpravki_poXml(
    pKodNA => 1,
    pGod   => 2017,
    pForma => 2
  );
exception
  when others then
    dbms_output.put_line(utl_error_api.get_exception_full);
    raise;
end;
0
0
