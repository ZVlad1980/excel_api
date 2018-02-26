/*
select d.*, rowid
--delete
from   dv_sr_lspv_v d
where  d.status = 'U' --extract(year from d.data_op) = 2018
*/
/*insert into dv_sr_lspv(
  nom_vkl,
  nom_ips,
  shifr_schet,
  data_op,
  summa,
  ssylka_doc,
  kod_oper,
  sub_shifr_schet,
  service_doc,
  id
) select nom_vkl,
  nom_ips,
  shifr_schet,
  data_op,
  summa,
  ssylka_doc,
  kod_oper,
  sub_shifr_schet,
  service_doc,
  id 
  from (*/
with w_log as (
  select ld.id,
         ld.action,
         ld.nom_vkl,
         ld.nom_ips,
         ld.shifr_schet,
         ld.data_op,
         ld.summa,
         ld.ssylka_doc,
         ld.kod_oper,
         ld.sub_shifr_schet,
         ld.service_doc,
         ld.status,
         ld.created_at,
         ld.created_by
  from   log$_dv_sr_lspv ld
),
w_full_log as (
  select ld.action,
         ld.id,
         ld.nom_vkl,
         ld.nom_ips,
         ld.shifr_schet,
         ld.data_op,
         ld.summa,
         ld.ssylka_doc,
         ld.kod_oper,
         ld.sub_shifr_schet,
         ld.service_doc,
         ld.status,
         ld.created_at,
         ld.created_by
  from   w_log        ld
  union all
  select 'A' action,
         d.id,
         d.nom_vkl,
         d.nom_ips,
         d.shifr_schet,
         d.data_op,
         d.summa,
         d.ssylka_doc,
         d.kod_oper,
         d.sub_shifr_schet,
         d.service_doc,
         d.status,
         null,
         null
  from   dv_sr_lspv   d
  where  d.id in (
           select ld.id
           from   w_log        ld
         )
  and    d.status <> 'N'
  union all
  select 'A' action,
         d.id,
         d.nom_vkl,
         d.nom_ips,
         d.shifr_schet,
         d.data_op,
         d.summa,
         d.ssylka_doc,
         d.kod_oper,
         d.sub_shifr_schet,
         d.service_doc,
         d.status,
         null,
         null
  from   dv_sr_lspv   d
  where  d.status = 'N'
)
select *
from   w_full_log wl
where  wl.action <> 'A'
order by id, action, data_op
