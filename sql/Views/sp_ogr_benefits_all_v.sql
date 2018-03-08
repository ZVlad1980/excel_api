create or replace view sp_ogr_benefits_all_v as
  select op.source_table,
         op.start_year,
         op.nom_vkl,
         op.nom_ips,
         op.ssylka_fl,
         op.shifr_schet,
         coalesce(to_number(pt.benefit_code), -1 * op.shifr_schet) benefit_code,
         pt.amount                  benefit_amount,
         op.start_date,
         op.end_date,
         op.pt_rid,
         op.tdappid,
         pt.start_date              bit_start_date,
         pt.end_date                bit_end_date,
         pt.upper_income,
         op.end_year,
         pt.regdate
  from   sp_ogr_pv_v              op,
         payments_taxdeductions_v pt
  where  1=1
  and    pt.rid(+) = op.pt_rid
  and    nvl(op.pt_rid, 0) > 0
union all
  select 'M' source_table,
         extract(year from m.start_date) start_year,
         m.nom_vkl,
         m.nom_ips,
         m.ssylka_fl,
         m.shifr_schet,
         m.benefit_code,
         m.benefit_amount,
         m.start_date,
         m.end_date,
         m.id pt_rid,
         null tdappid,
         null bit_start_date,
         null bit_end_date,
         m.upper_income,
         extract(year from m.end_date) end_year,
         m.regdate
  from   sp_ogr_pv_man_t m
  where  m.enabled = 'Y'
