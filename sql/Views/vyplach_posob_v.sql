create or replace view vyplach_posob_v as
  select vp.data_vypl,
         vp.ssylka,
         vp.ssylka_doc,
         vp.nom_vipl,
         vp.fio,
         vp.posobie,
         vp.uderg_pn,
         vp.ssylka_poluch,
         vp.gf_person
  from   fnd.vyplach_posob vp
  where  vp.tip_vypl = 1010
/
