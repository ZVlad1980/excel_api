create or replace view dv_sr_lspv_acc_v as
  select a.charge_type      ,
         a.det_charge_type  ,
         a.tax_rate         ,
         d.id               ,
         d.data_op          date_op,
         d.ssylka_doc       ,
         d.service_doc      ,
         d.nom_vkl          ,
         d.nom_ips          ,
         d.shifr_schet      ,
         d.sub_shifr_schet  ,
         d.summa            amount,
         d.kod_oper         ,
         a.sub_shifr_grp    ,
         d.status           ,
         d.year_op
  from   dv_sr_lspv_v  d,
         ndfl_accounts_t a
  where  1 = 1
  and    d.nom_vkl < a.max_nom_vkl
  and    d.sub_shifr_schet = a.sub_shifr_schet
  and    d.shifr_schet = a.shifr_schet
/
