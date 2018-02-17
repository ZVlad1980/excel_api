create or replace view dv_sr_lspv_v as
  select d.nom_vkl,
         d.nom_ips,
         d.shifr_schet,
         d.data_op,
         d.summa summa,
         d.ssylka_doc,
         d.kod_oper,
         d.sub_shifr_schet,
         d.service_doc
  from   dv_sr_lspv d
/
