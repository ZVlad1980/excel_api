create or replace view sp_gf_persons_v as
  with dv_sr_lspv_acc_w as (
    select d.nom_vkl,
           d.nom_ips,
           case d.det_charge_type when 'RITUAL' then 'S' else 'P' end contragent_type
    from   dv_sr_lspv_acc_v d
    where  d.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date
    --    and    d.nom_vkl = 24    and    d.nom_ips = 888    --
    group by d.nom_vkl,
             d.nom_ips,
             case d.det_charge_type when 'RITUAL' then 'S' else 'P' end
  )
  select cast('PENSIONER' as varchar2(40)) contragent_type,
         d.nom_vkl,
         d.nom_ips,
         fl.ssylka,
         nvl(fl.gf_person, -1) gf_person
  from   dv_sr_lspv_acc_w   d,
         sp_fiz_litz_lspv_v fl--,       vyplach_posob_v    vp
  where  1=1
  --
  and    fl.nom_ips = d.nom_ips
  and    fl.nom_vkl = d.nom_vkl
  --
  and    d.contragent_type = 'P'
  union
  select 'SUCCESSOR' contragent_type,
         d.nom_vkl,
         d.nom_ips,
         fl.ssylka,
         nvl(rp.gf_person, -1) gf_person
  from   dv_sr_lspv_acc_w   d,
         sp_fiz_litz_lspv_v fl,
         sp_ritual_pos_v    rp
  where  1=1
  --
  and    rp.ssylka = fl.ssylka
  --
  and    fl.nom_ips = d.nom_ips
  and    fl.nom_vkl = d.nom_vkl
  --
  and    d.contragent_type = 'S'
  union
  select case when dd.det_charge_type = 'RITUAL' then 'SUCCESSOR' else 'PENSIONER' end contragent_type,
         dd.nom_vkl,
         dd.nom_ips,
         dd.ssylka_fl,
         dd.gf_person
  from   dv_sr_lspv_docs_t dd
  where  dd.det_charge_type is not null
  union
  select case
                when n.ssylka_tip = 1 then
                 'SUCCESSOR'
                else
                 'PENSIONER'
              end contragent_type,
         n.nom_vkl,
         n.nom_ips,
         n.ssylka_sips,
         n.gf_person
  from   f_ndfl_load_nalplat n
/
