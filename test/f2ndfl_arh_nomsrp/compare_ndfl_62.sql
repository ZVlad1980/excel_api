begin
  dv_sr_lspv_docs_api.set_period(
    p_end_date    => to_date(20161231, 'yyyymmdd'),
    p_report_date => sysdate
  );
end;
/ --2975008
select t.*,
       t.tax_calc - t.tax_retained tax_diff,
       p.revenue                   revenue6,
       p.tax_calc                  tax_calc6,
       p.tax_retained + coalesce(p.tax_83, 0)   tax_retained6,
       p.tax_return                tax_return6,
       p.tax_83,
       t.tax_calc - p.tax_calc     tax_calc_diff,
       t.tax_retained - (p.tax_retained + coalesce(p.tax_83, 0)) tax_retained_diff
from   f2ndfl_load_totals_v t,
       dv_sr_lspv_pers_v    p
where  1=1
and    (abs(t.tax_calc - p.tax_calc) > .01
        or
        abs(t.tax_retained - (p.tax_retained + coalesce(p.tax_83, 0))) > .01
       )
and    p.gf_person = t.gf_person
and    t.is_last_spr = 'Y'
--and    t.nom_spr = '116155'
--and    abs(t.tax_calc - t.tax_retained) > .01
order by tax_diff
/
select t.*,
       t.tax_calc - t.tax_retained tax_diff,
       p.revenue                   revenue6,
       p.tax_calc                  tax_calc6,
       p.tax_retained + coalesce(p.tax_83, 0)   tax_retained6,
       p.tax_return                tax_return6,
       p.tax_83,
       t.tax_calc - p.tax_calc     tax_calc_diff,
       t.tax_retained - (p.tax_retained + coalesce(p.tax_83, 0)) tax_retained_diff
from   f2ndfl_arh_totals_v t,
       dv_sr_lspv_pers_v    p
where  1=1
and    (abs(t.tax_calc - p.tax_calc) > .01
        or
        abs(t.tax_retained - (p.tax_retained + coalesce(p.tax_83, 0))) > .01
       )
and    p.gf_person = t.gf_person
and    t.is_last_spr = 'Y'
--and    t.nom_spr = '116155'
--and    abs(t.tax_calc - t.tax_retained) > .01
order by tax_diff
/
