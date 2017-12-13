create or replace view vyplach_posob_receivers_v as
  select a.nom_vkl,
         a.nom_ips,
         f.ssylka              ssylka_fl,
         vp.fio,
         vp.gf_person          gf_person_vp,
         vp.ssylka_poluch,
         vp.DATA_VYPL,
         vp.SSYLKA,
         vp.ssylka_doc,
         vp.NOM_VIPL,
         fp.gf_person          gf_person_fp,
         rp.last_name,
         rp.first_name,
         rp.second_name,
         rp.birth_date,
         rp.gf_person          gf_person_rp
  from   dv_sr_lspv_acc_v      a,
         sp_fiz_litz_lspv_v    f,
         fnd.vyplach_posob_v   vp,
         fnd.sp_fiz_lits       fp,
         sp_ritual_pos_v       rp
  where  1=1
  --
  and    rp.fio_vlad(+) = vp.fio
  and    rp.ssylka(+) = vp.ssylka
  --
  and    fp.ssylka(+) = vp.ssylka_poluch
  --
  and    vp.ssylka_doc(+) = a.ssylka_doc
  and    vp.ssylka(+) = f.ssylka
  --
  and    f.nom_ips(+) = a.nom_ips
  and    f.nom_vkl(+) = a.nom_vkl
  --
  and    a.charge_type = 'REVENUE'
  and    a.det_charge_type = 'RITUAL'
  and    a.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date
/
