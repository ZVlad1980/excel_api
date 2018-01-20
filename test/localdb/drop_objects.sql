declare
  cursor l_obj_cur is
    select 'view' obj_type, v.view_name obj_name
    from   user_views v
    where  v.view_name like 'DV_SR_LSPV_%'
    or     v.view_name like 'NDFL6_%'
    or     v.view_name like 'NDFL2_%'
    or     v.view_name like 'ZAPRVKL_%'
    or     v.view_name like upper('vyplach_%')
    or     v.view_name like upper('ndfl_report_tax_retained_v')
    or     v.view_name in (
                            upper('sp_quarters_v'),
                            upper('sp_det_charge_types_v'),
                            upper('sp_ritual_pos_v'),
                            upper('gf_people_v'),
                            upper('sp_gf_persons_v'),
                            upper('sp_pen_schemes_v'),
                            upper('sp_fiz_litz_lspv_v'),
                            upper('sp_fiz_lits_receivers_v'),
                            upper('sp_fiz_lits_diff_v'),
                            upper('sp_fiz_lits_non_ident_v'),
                            upper('sp_no_residents_v'),
                            upper('taxdeductions_v'),
                            upper('contragent_merge_log_v')
                          )
    union all
    select 'package' obj_type, p.object_name obj_name
    from   user_objects p
    where  p.object_type = 'PACKAGE'
    and    p.object_name in (
              'dv_sr_lspv_docs_api',
              'f_ndfl_load_spisrab_api',
              'f2ndfl_arh_spravki_api',
              --'FXNDFL_UTIL',
              'gateway_pkg',
              'gateway_user_pkg',
              'ndfl_report_api',
              'utl_error_api',
              'zaprvkl_api',
              'zaprvkl_headers_tapi',
              'zaprvkl_lines_tmp_api'
           )
    ;
begin
  for o in l_obj_cur loop
    begin
      execute immediate 'drop ' || o.obj_type || ' ' || o.obj_name;
    exception
      when others then
        dbms_output.put_line('drop ' || o.obj_type || ' ' || o.obj_name || ' error: ' || sqlerrm);
    end;
  end loop;
  --
end;
/
