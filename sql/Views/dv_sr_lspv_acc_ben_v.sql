--drop view dv_sr_lspv_det_bft_v
--drop view dv_sr_lspv_benefits_v
create or replace view dv_sr_lspv_acc_ben_v as
  select a.fk_dv_sr_lspv#, 
         a.charge_type, 
         a.det_charge_type,
         a.tax_rate, 
         a.date_op, 
         a.ssylka_doc, 
         a.service_doc, 
         a.nom_vkl, 
         a.nom_ips, 
         a.shifr_schet, 
         a.sub_shifr_schet,
         a.amount, 
         a.kod_oper, 
         a.sub_shifr_grp, 
         a.year_op,
         extract(month from a.date_op)    month_op,
         b.start_date,
         extract(month from b.start_date) start_month,
         b.end_date,
         extract(month from b.end_date)   end_month,
         b.benefit_code,
         b.benefit_amount,
         b.upper_income,
         b.pt_rid,
         count(distinct b.pt_rid)over(partition by a.date_op, a.nom_vkl, a.nom_ips, a.shifr_schet) benefit_cnt,
         count(distinct b.pt_rid)over(partition by a.date_op, a.nom_vkl, a.nom_ips, a.shifr_schet) benefit_code_cnt,
         a.status,
         b.regdate,
         --coalesce(
           ( select min(p.month_op) - 1
             from   dv_sr_lspv_acc_rev_v p
             where  p.nom_vkl = a.nom_vkl
             and    p.nom_ips = a.nom_ips
             and    p.revenue_acc > b.upper_income
           ) last_month,
          -- extract(month from b.date_op)
         --)                                                last_month,
         ( select coalesce(sum(d.amount), 0)
           from   dv_sr_lspv_det_v d
           where  d.nom_vkl = a.nom_vkl
           and    d.nom_ips = a.nom_ips
           and    d.shifr_schet = a.shifr_schet
           and    d.year_op = a.year_op
           and    d.date_op < a.date_op
           and    d.addition_id = b.pt_rid
           and    d.detail_type = 'BENEFIT'
         )                                                total_benefits
  from   dv_sr_lspv_acc_v  a
  outer apply (
    select b.start_date,
           b.end_date,
           b.benefit_code,
           b.benefit_amount,
           b.upper_income,
           b.pt_rid,
           b.regdate
    from   sp_ogr_benefits_v b
    where  b.nom_vkl = a.nom_vkl
    and    b.nom_ips = a.nom_ips
    and    b.shifr_schet = a.shifr_schet
    and    a.date_op between b.start_date and b.end_date
    and    b.regdate <= a.date_op
  ) b
  where  1=1
  and    a.status = 'N'
  and    a.charge_type = 'BENEFIT'
  and    a.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date
  and    a.year_op >= dv_sr_lspv_docs_api.get_year
/
