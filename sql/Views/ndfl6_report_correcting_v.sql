create or replace view ndfl6_report_correcting_v as
  select d.quarter_op,
         d.month_op,
         d.date_op,
         d.ssylka_doc_op,
         d.year_doc,
         d.quarter_doc,
         d.date_doc,
         d.ssylka_doc,
         case ds.charge_type when 'REVENUE' then d.source_revenue when 'BENEFIT' then d.source_benefit when 'TAX' then d.source_tax end source_amount,
         case ds.charge_type when 'REVENUE' then d.revenue when 'BENEFIT' then d.benefit when 'TAX' then d.tax end amount,
         d.gf_person,
         d.nom_vkl,
         d.nom_ips,
         ds.shifr_schet,
         ds.sub_shifr_schet,
         f.ssylka,
         f.last_name,
         f.first_name,
         f.second_name
  from   dv_sr_lspv_docs_v  d,
         dv_sr_lspv_acc_v   ds,       
         sp_fiz_litz_lspv_v f
  where  1=1
  --
  and    f.nom_ips = d.nom_ips
  and    f.nom_vkl = d.nom_vkl
  --
  and    ds.service_doc <> 0
  and    ds.date_op = d.date_op
  and    ds.ssylka_doc = d.ssylka_doc_op
  and    ds.nom_ips = d.nom_ips
  and    ds.nom_vkl = d.nom_vkl
  --
  and    d.type_op = -1
/
