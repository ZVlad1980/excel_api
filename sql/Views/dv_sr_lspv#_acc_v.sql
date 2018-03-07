create or replace view dv_sr_lspv#_acc_v as
  select /*+ index(dd AKEY_DLSPV)*/
         d.id,
         a.charge_type,
         a.det_charge_type,
         extract(year from d.date_op) year_op,
         d.gf_person,
         d.nom_vkl, 
         d.nom_ips, 
         d.shifr_schet, 
         d.sub_shifr_schet,
         d.date_op, 
         dd.summa amount, 
         d.ssylka_doc, 
         dd.service_doc, 
         d.is_parent,
         d.process_id,
         d.status,
         a.tax_rate
  from   dv_sr_lspv#_v d,
         dv_sr_lspv_v  dd,
         ndfl_accounts_t   a
  where  1=1
  --
  and    a.max_nom_vkl > d.nom_vkl
  and    a.sub_shifr_schet = d.sub_shifr_schet
  and    a.shifr_schet = d.shifr_schet
  --
  and    dd.ssylka_doc = d.ssylka_doc
  and    dd.sub_shifr_schet = d.sub_shifr_schet
  and    dd.shifr_schet = d.shifr_schet
  and    dd.data_op = d.date_op
  and    dd.nom_ips = d.nom_ips
  and    dd.nom_vkl = d.nom_vkl
/
