create or replace view sp_fiz_lits_receivers_v as
  select f.nom_vkl,
         f.nom_ips,
         f.ssylka,
         f.gf_person
  from   dv_sr_lspv_acc_v   a,
         sp_fiz_litz_lspv_v f
  where  1 = 1
  and    f.nom_ips = a.nom_ips
  and    f.nom_vkl = a.nom_vkl
  and    nvl(a.det_charge_type, 'PENSION') in ('PENSION', 'BUYBACK')
  and    a.date_op between dv_sr_lspv_docs_api.get_start_date and
         dv_sr_lspv_docs_api.get_end_date
  group  by f.nom_vkl,
            f.nom_ips,
            f.ssylka,
            f.gf_person
/
