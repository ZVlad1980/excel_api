create or replace view sp_ogr_benefits_v as
  select op.source_table,
         op.start_year,
         op.nom_vkl,
         op.nom_ips,
         op.ssylka_fl,
         op.shifr_schet,
         coalesce(to_number(pt.benefit_code), op.shifr_schet) benefit_code,
         pt.amount                  benefit_amount,
         op.start_date,
         op.end_date,
         op.pt_rid,
         op.tdappid,
         pt.start_date              bit_start_date,
         pt.end_date                bit_end_date,
         pt.upper_income,
         op.end_year
  from   sp_ogr_pv_v              op,
         payments_taxdeductions_v pt
  where  1=1
  and    pt.tdappid(+) = op.tdappid
  and    pt.rid(+) = op.pt_rid
/
