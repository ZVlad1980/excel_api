create or replace view dv_sr_lspv#_full_v as
select /*+ index(dd AKEY_DLSPV)*/
       d.id,
       d.year_op,
       d.nom_vkl,
       d.nom_ips,
       d.shifr_schet,
       d.sub_shifr_schet,
       d.date_op,
       dd.summa amount,
       d.ssylka_doc,
       dd.service_doc service_doc,
       d.process_id,
       d.status,
       d.is_deleted
from   dv_sr_lspv#_v d,
       dv_sr_lspv_v  dd
where  1=1
and    dd.ssylka_doc = d.ssylka_doc
and    dd.sub_shifr_schet = d.sub_shifr_schet
and    dd.shifr_schet = d.shifr_schet
and    dd.data_op = d.date_op
and    dd.nom_ips = d.nom_ips
and    dd.nom_vkl = d.nom_vkl
/
