create or replace view vyplach_posob_v as
  select vp.data_vypl,
         vp.ssylka,
         vp.ssylka_doc,
         vp.nom_vipl,
         vp.fio,
         vp.posobie,
         vp.uderg_pn,
         vp.ssylka_poluch,
         nvl(sr.fk_contragent, vp.gf_person) gf_person
  from   fnd.vyplach_posob vp,
         sp_ritual_pos     sr
  where  1=1
  and    sr.ssylka = vp.ssylka
  and    vp.tip_vypl = 1010
/
