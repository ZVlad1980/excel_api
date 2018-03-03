create or replace view dv_sr_lspv#_v as
  select d.id,
         extract(year from d.date_op) year_op,
         d.nom_vkl, 
         d.nom_ips, 
         d.shifr_schet, 
         d.sub_shifr_schet,
         d.date_op, 
         d.amount, 
         d.ssylka_doc, 
         d.service_doc, 
         d.process_id,
         d.status,
         d.is_deleted
  from   dv_sr_lspv# d
/
