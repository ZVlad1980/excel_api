PL/SQL Developer Test script 3.0
33
-- Created on 04.11.2017 by V.ZHURAVOV 
declare
  -- Local variables here
  l_ref_row f2ndfl_arh_spravki%rowtype;
begin
  fxndfl_util.raspredSpravki_poXml(
    pKodNA => 1,
    pGod   => 2017,
    pForma => 2
  );
  /*
  --dbms_session.reset_package; return;
  --
  -- dbms_output.put_line(utl_error_api.get_exception_full); return;
  -- Test statements here
  --
  f2ndfl_arh_spravki_api.create_reference_corr(
    p_code_na       => 1,
    p_year          => 2017,
    p_contragent_id => 100000012,
    p_actual_date   => to_date(20171231, 'yyyymmdd')
  ); --*/
  
--  f2ndfl_arh_spravki_api.delete_reference(p_ref_id => 358577); 
  --FXNDFL_UTIL.calc_benefit_usage(p_spr_id => 358537);
exception
  when others then
    utl_error_api.fix_exception('Test script');
    --dbms_output.put_line(utl_error_api.get_error_msg);
    dbms_output.put_line(utl_error_api.get_exception_full);
    raise;
end;
--358536*/
0
4
gl_SPRID
gl_CAID
l_result.nom_spr
p_src_ref_id
