create or replace view dv_sr_lspv_83_v as
  select d.charge_type, 
         d.det_charge_type,
         d.tax_rate, 
         d.date_op, 
         d.ssylka_doc, 
         d.service_doc, 
         d.nom_vkl, 
         d.nom_ips, 
         d.shifr_schet, 
         d.sub_shifr_schet,
         d.amount, 
         d.kod_oper, 
         d.sub_shifr_grp
  from   dv_sr_lspv_acc_v d
  where  1 = 1
  and    not exists (
           select 1
           from   dv_sr_lspv_acc_v dd--fnd.dv_sr_lspv dd
           where  1=1
           and    dd.service_doc <> 0
           and    dd.charge_type = 'TAX'
           and    dd.ssylka_doc = d.ssylka_doc
           and    dd.nom_ips = d.nom_ips
           and    dd.nom_vkl = d.nom_vkl
         )
  and    d.charge_type = 'TAX_CORR'
  and    d.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date;
/
