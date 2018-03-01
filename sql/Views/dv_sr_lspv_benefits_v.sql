create or replace view dv_sr_lspv_benefits_v as
  select a.charge_type, 
         a.det_charge_type,
         a.tax_rate, 
         a.id, 
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
         a.status, 
         a.year_op,
         b.start_date,
         b.end_date,
         b.benefit_code,
         b.benefit_amount,
         b.upper_income,
         b.pt_rid,
         count(distinct b.pt_rid)over(partition by a.date_op, a.nom_vkl, a.nom_ips, a.shifr_schet) benefit_cnt,
         count(distinct b.benefit_code)over(partition by a.date_op, a.nom_vkl, a.nom_ips, a.shifr_schet) benefit_code_cnt
  from   dv_sr_lspv_acc_v  a
  outer apply (
    select b.start_date,
           b.end_date,
           b.benefit_code,
           b.benefit_amount,
           b.upper_income,
           b.pt_rid
    from   sp_ogr_benefits_v b
    where  b.nom_vkl = a.nom_vkl
    and    b.nom_ips = a.nom_ips
    and    b.shifr_schet = a.shifr_schet
    and    a.date_op between b.start_date and b.end_date
  ) b
  where  1=1
  and    a.status is not null
  and    a.charge_type = 'BENEFIT'
/
