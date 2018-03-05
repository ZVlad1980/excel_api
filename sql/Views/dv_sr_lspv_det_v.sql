create or replace view dv_sr_lspv_det_v as
  select d.id, 
         d.fk_dv_sr_lspv_det,
         d.fk_dv_sr_lspv,
         a.charge_type,
         a.det_charge_type,
         d.amount,
         d.addition_code, 
         d.addition_id, 
         dd.date_op                      date_op            ,
         dd.year_op                      year_op            ,
         dd.nom_vkl                      nom_vkl            ,
         dd.nom_ips                      nom_ips            ,
         dd.shifr_schet                  shifr_schet        ,
         dd.sub_shifr_schet              sub_shifr_schet    ,
         dd.amount                       src_amount         ,
         dd.ssylka_doc                   src_ssylka_doc     ,
         dd.service_doc                  src_service_doc    ,
         dd.status                       src_status         ,
         d.fk_dv_sr_lspv_trg             fk_dv_sr_lspv_trg  ,
         dt.date_op                      trg_date_op        ,
         dt.year_op                      trg_year_op        ,
         dt.amount                       trg_amount         ,
         dt.ssylka_doc                   trg_ssylka_doc     ,
         dt.service_doc                  trg_service_doc    ,
         dt.status                       trg_status         ,
         d.process_id, 
         d.method, 
         d.created_by, 
         d.created_at, 
         d.is_deleted, 
         d.is_disabled, 
         d.last_updated_by, 
         d.last_updated_at
  from   dv_sr_lspv_det_t    d,
         dv_sr_lspv#_full_v  dd,
         dv_sr_lspv#_full_v  dt,
         ndfl_accounts_t   a
  where  1=1
  and    a.sub_shifr_schet = dd.sub_shifr_schet
  and    a.shifr_schet = dd.shifr_schet
  and    dt.id(+) = d.fk_dv_sr_lspv_trg
  and    dd.id = d.fk_dv_sr_lspv
/
