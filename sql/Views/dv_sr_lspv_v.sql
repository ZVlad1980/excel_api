create or replace view dv_sr_lspv_v as
  select d.nom_vkl,
         d.nom_ips,
         d.shifr_schet,
         d.data_op,
         round(d.summa, 2) summa,
         d.ssylka_doc,
         d.kod_oper,
         d.sub_shifr_schet,
         d.service_doc,
         extract(year from d.data_op) year_op
  from   dv_sr_lspv d
/
