create or replace view sp_fiz_lits_non_ident_v as
  with dv_sr as (
    select f.nom_vkl,
           f.nom_ips,
           f.ssylka,
           f.gf_person,
           count(gf_person) cnt
    from   dv_sr_lspv_acc_v   a,
           sp_fiz_litz_lspv_v f
    where  1=1
    and    f.gf_person is null
    and    f.nom_ips = a.nom_ips
    and    f.nom_vkl = a.nom_vkl
    and    nvl(a.det_charge_type, 'PENSION') in ('PENSION', 'BUYBACK')
    and    a.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date
    group by f.nom_vkl,
           f.nom_ips,
           f.ssylka,
           f.gf_person
  )
  select fd.nom_vkl, 
         fd.nom_ips, 
         f.ssylka, 
         f.familiya, 
         f.imya, 
         f.otchestvo, 
         f.data_rogd,
         f.gf_person,
         p.fk_contragent gf_person_new,
         p.lastname,
         p.firstname,
         p.secondname,
         p.birthdate,
         p.birthplace
  from   dv_sr fd,
         fnd.sp_fiz_lits     f,
         gazfond.people      p
  where  1=1
  and    p.lastname(+) = f.familiya
  and    p.firstname(+) = f.imya
  and    p.secondname(+) = f.otchestvo
  and    p.birthdate(+) = f.data_rogd
  --
  and    f.ssylka = fd.ssylka
/
