create or replace view sp_ogr_benefits_v as
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
         pt.regdate,
         extract(month from op.start_date) start_month,
         coalesce(
           ( select min(p.month_op) - 1
             from   dv_sr_lspv_acc_rev_v p
             where  p.nom_vkl = op.nom_vkl
             and    p.nom_ips = op.nom_ips
             and    p.revenue_acc > pt.upper_income
           ),
           extract(month from op.end_date) 
         ) end_month
  from   sp_ogr_pv_v              op,
         payments_taxdeductions_v pt
  where  1=1
  and    pt.rid(+) = op.pt_rid
  and    nvl(op.pt_rid, 0) > 0
/
