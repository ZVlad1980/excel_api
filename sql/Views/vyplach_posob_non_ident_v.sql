create or replace view vyplach_posob_non_ident_v as
  with ritual_receivers as (
    select a.nom_vkl,
           a.nom_ips,
           f.ssylka ssylka_fl,
           vp.fio,
           vp.gf_person gf_person_vp,
           vp.ssylka_poluch,
           vp.DATA_VYPL,
           vp.TIP_VYPL,
           vp.SSYLKA,
           vp.ssylka_doc,
           vp.NOM_VIPL,
           fp.gf_person gf_person_fp,
           regexp_substr(rp.fio_vlad, '[^ ]+', 1, 1) last_name,
           regexp_substr(rp.fio_vlad, '[^ ]+', 1, 2) first_name,
           regexp_substr(rp.fio_vlad, '[^ ]+', 1, 3) second_name,
           rp.rogd_vlad birth_date,
           rp.fk_contragent gf_person_rp
    from   dv_sr_lspv_acc_v   a,
           sp_fiz_litz_lspv_v f,
           fnd.vyplach_posob  vp,
           fnd.sp_fiz_lits    fp,
           fnd.sp_ritual_pos  rp
    where  1=1
    --
    and    rp.fio_vlad(+) = vp.fio
    and    rp.ssylka(+) = vp.ssylka
    --
    and    fp.ssylka(+) = vp.ssylka_poluch
    --
    and    vp.gf_person is null --!!!
    and    vp.tip_vypl(+) = 1010
    and    vp.ssylka_doc(+) = a.ssylka_doc
    and    vp.ssylka(+) = f.ssylka
    --
    and    f.nom_ips(+) = a.nom_ips
    and    f.nom_vkl(+) = a.nom_vkl
    --
    and    a.charge_type = 'REVENUE'
    and    a.det_charge_type = 'RITUAL'
    and    a.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_start_date
  )
  select rr.nom_vkl,
         rr.nom_ips,
         rr.ssylka ssylka_fl,
         rr.fio,
         rr.gf_person_vp,
         rr.ssylka_poluch,
         rr.DATA_VYPL,
         rr.TIP_VYPL,
         rr.SSYLKA,
         rr.NOM_VIPL,
         rr.gf_person_fp,
         rr.last_name,
         rr.first_name,
         rr.second_name,
         rr.birth_date,
         rr.gf_person_rp,
         nvl(rr.gf_person_vp, nvl(rr.gf_person_fp, p.fk_contragent)) gf_person_new,
         rr.ssylka_doc
  from   ritual_receivers rr,
         gazfond.people   p
  where  1=1
  and    p.fk_contragent(+) = nvl(rr.gf_person_vp, nvl(rr.gf_person_fp, p.fk_contragent(+)))
  and    p.lastname(+) = rr.last_name
  and    p.firstname(+) = rr.first_name
  and    p.secondname(+) = rr.second_name
  and    p.birthdate(+) = rr.birth_date
/
  
