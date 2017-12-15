create or replace view dv_sr_lspv_acc_v as
  select a.charge_type      ,
         a.det_charge_type  ,
         a.tax_rate         ,
         d.data_op          date_op,
         d.ssylka_doc       ,
         d.service_doc      ,
         d.nom_vkl          ,
         d.nom_ips          ,
         d.shifr_schet      ,
         d.sub_shifr_schet  ,
         d.summa            amount,
         d.kod_oper         ,
         a.sub_shifr_grp
  from   fnd.dv_sr_lspv  d,
         ndfl_accounts_t a
  where  1 = 1
  and    d.nom_vkl < a.max_nom_vkl
  and    d.sub_shifr_schet = a.sub_shifr_schet
  and    d.shifr_schet = a.shifr_schet
  --
  --and    d.nom_ips = 3123 and    d.nom_vkl = 6
  --and    d.nom_ips = 2643 and    d.nom_vkl = 140
  --and    d.nom_ips = 6183  and    d.nom_vkl = 75
  --and    d.nom_ips = 1376  and    d.nom_vkl = 1
  --and    d.nom_ips = 1859 and    d.nom_vkl = 37 --Мингазова
  --and    d.nom_ips = 5098  and    d.nom_vkl = 77  --3443820 - benefit + 83   (77 5098)
  --and    d.nom_ips = 3123  and    d.nom_vkl = 6   --3052332 - benefit + -1 0 (6 3123)
/
