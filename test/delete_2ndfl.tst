PL/SQL Developer Test script 3.0
27
-- Created on 04.11.2017 by V.ZHURAVOV 
declare
  -- Local variables here
begin
  --dbms_session.reset_package; return;
  f2ndfl_arh_spravki_api.delete_reference(
    p_ref_id => f2ndfl_arh_spravki_api.get_reference_last_id(
                  p_code_na => 1,
                  p_year    => 2016,
                  p_ref_num => f2ndfl_arh_spravki_api.get_reference_num(
                                 p_code_na       => 1,
                                 p_year          => 2016,
                                 p_contragent_id => 1619074
                               ),
                  p_load_exists => 'N'
                )
  );
  --*/
  --FXNDFL_UTIL.calc_benefit_usage(p_spr_id => 358537);
exception
  when others then
    utl_error_api.fix_exception('Test script');
    --dbms_output.put_line(utl_error_api.get_error_msg);
    dbms_output.put_line(utl_error_api.get_exception_full);
    --raise;
end;
--358536
0
4
gl_SPRID
gl_CAID
l_result.nom_spr
p_src_ref_id
