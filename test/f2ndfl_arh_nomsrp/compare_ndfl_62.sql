begin
  dv_sr_lspv_docs_api.set_period(
    p_end_date    => to_date(20161231, 'yyyymmdd'),
    p_report_date => sysdate
  );
end;
/
select t.*,
       t.tax_calc - t.tax_retained tax_diff,
       p.revenue                   revenue6,
       p.tax_calc                  tax_calc6,
       p.tax_retained + coalesce(p.tax_83, 0)   tax_retained6,
       p.tax_return                tax_return6,
       p.tax_83,
       t.tax_calc - p.tax_calc     tax_calc_diff,
       t.tax_retained - (p.tax_retained + coalesce(p.tax_83, 0)) tax_calc_retained
from   f2ndfl_load_totals_v t,
       dv_sr_lspv_pers_v    p
where  1=1
and    (abs(t.tax_calc - p.tax_calc) > .01
        or
        abs(t.tax_retained - (p.tax_retained + coalesce(p.tax_83, 0))) > .01
       )
and    p.gf_person = t.gf_person
and    t.is_last_spr = 'Y'
--and    t.nom_spr = '122361'
--and    abs(t.tax_calc - t.tax_retained) > .01
order by tax_diff
/
begin
  f2ndfl_arh_spravki_api.synhonize_load(
    p_code_na => 1,
    p_year    => 2016,
    p_ref_id  => 358526
  );
exception
  when others then
    dbms_output.put_line(utl_error_api.get_exception_full);
    raise;
end;
/*
select t.*,
       t.tax_calc - t.tax_retained tax_diff,
       p.revenue                   revenue6,
       p.tax_calc                  tax_calc6,
       p.tax_retained + coalesce(p.tax_83, 0)   tax_retained6,
       p.tax_return                tax_return6,
       p.tax_83,
       t.tax_calc - p.tax_calc     tax_calc_diff,
       t.tax_retained - (p.tax_retained + coalesce(p.tax_83, 0)) tax_calc_retained
from   f2ndfl_load_totals_v t,
       dv_sr_lspv_pers_v    p
where  1=1
and    p.gf_person = t.gf_person
and    t.gf_person = 1290023
and    t.is_last_spr = 'Y'
--and    t.nom_spr = '090613'
--and    abs(t.tax_calc - t.tax_retained) > .01
order by tax_diff
--*/
