PL/SQL Developer Test script 3.0
53
-- Created on 19.02.2018 by V.ZHURAVOV 
declare 
  -- Local variables here
  procedure recreate_2ndfl(
    p_year   int,
    p_ref_id f2ndfl_arh_spravki.id%type
  ) is
    l_ref_row f2ndfl_arh_spravki%rowtype;
  begin
    --
    l_ref_row := f2ndfl_arh_spravki_api.get_reference_row(p_ref_id);
    --
    update f2ndfl_arh_spravki s
    set    s.r_xmlid = null
    where  s.id = p_ref_id;
    --
    f2ndfl_arh_spravki_api.delete_reference(
      p_ref_id => p_ref_id
    );
    --
    f2ndfl_arh_spravki_api.create_reference(
      p_code_na       => 1,
      p_year          => p_year,
      p_contragent_id => l_ref_row.ui_person,
      p_ref_num       => l_ref_row.nom_spr,
      p_report_date   => to_date(20171231, 'yyyymmdd')
    );
    --
    l_ref_row.id := f2ndfl_arh_spravki_api.get_reference_last_id(
                  p_code_na     => 1,
                  p_year        => p_year,
                  p_ref_num     => l_ref_row.nom_spr,
                  p_load_exists => 'N'
                );
    --
    update f2ndfl_arh_spravki s
    set    s.r_xmlid = l_ref_row.r_xmlid
    where  s.id = p_ref_id;
    --
  end recreate_2ndfl;
begin
  -- Test statements here
    /*
    2580301
    2641748
    2641779
    */
  recreate_2ndfl(2017, 2580301);
exception
  when others then
    dbms_output.put_line(utl_error_api.get_exception_full);
    raise;
end;
0
0
