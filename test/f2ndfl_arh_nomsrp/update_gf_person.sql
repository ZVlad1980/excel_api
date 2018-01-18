begin
  dv_sr_lspv_docs_api.set_period(
    p_end_date    => to_date(20161231, 'yyyymmdd'),
    p_report_date => sysdate
  );
end;
/
select ns.*, rowid
from   f2ndfl_arh_nomspr  ns/*,
       lateral (
         select d.gf_person,
                d.det_charge_type,
                row_number()over(partition by )
         from   dv_sr_lspv_docs_v d
         where  d.ssylka_fl = ns.ssylka
         and    d.det_charge_type = 
                  case ns.tip_dox
                    when 1 then 'PENSION'
                    when 2 then 'RITUAL'
                    when 3 then 'BUYBACK'
                    else 'UNKNOWN'
                  end
       )*/
where  1=1
and    (ns.kod_na, ns.god, ns.nom_spr) in (
         select 1, 2016, 075856 from dual union all
         select 1, 2016, 122595 from dual union all
         select 1, 2016, 148012 from dual
       )
/
select d.ssylka_fl, d.gf_person, d.det_charge_type
from   dv_sr_lspv_docs_t d
where  d.ssylka_fl in (
         9173,
233043,
218009,
53351
       )
       group by d.ssylka_fl, d.gf_person, d.det_charge_type
/*
233043	2993443	PENSION
218009	2937366	PENSION
9173	2937366	PENSION
53351	3070477	PENSION
53351	1675349	RITUAL

*/
