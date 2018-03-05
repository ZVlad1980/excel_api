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
         a.sub_shifr_grp    ,
         d.year_op          ,
         dt.id              fk_dv_sr_lspv#,
         dt.status
  from   dv_sr_lspv_v  d,
         ndfl_accounts_t a,
         lateral(
           select /*+ index dt DV_SR_LSPV_T_UX*/
                  dt.id,
                  dt.status
           from   dv_sr_lspv#_v dt
           where  1=1
           and    dt.ssylka_doc = d.ssylka_doc
           and    dt.sub_shifr_schet = d.sub_shifr_schet
           and    dt.shifr_schet = d.shifr_schet
           and    dt.date_op = d.data_op
           and    dt.nom_ips = d.nom_ips
           and    dt.nom_vkl = d.nom_vkl
         )(+)                                            dt
  where  1 = 1
  and    d.nom_vkl < a.max_nom_vkl
  and    d.sub_shifr_schet = a.sub_shifr_schet
  and    d.shifr_schet = a.shifr_schet
/
