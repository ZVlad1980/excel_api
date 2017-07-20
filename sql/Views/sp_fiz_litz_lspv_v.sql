create or replace view sp_fiz_litz_lspv_v as
  select lspv.nom_vkl,
         lspv.nom_ips,
         fz.ssylka,
         fz.familiya    last_name,
         fz.imya        first_name,
         fz.otchestvo   second_name,
         fz.data_rogd   birth_date,
         --fz.pen_sxem    pen_scheme_code,
         s.kod_ps       pen_scheme_code,
         fz.gf_person   gf_person,
         s.kr_nazv      pen_scheme
  from   fnd.sp_lspv        lspv, 
         fnd.sp_pen_dog     dog,
         fnd.sp_fiz_lits    fz,
         fnd.kod_pens_shem  s
  where  1=1
  and    s.kod_ps = nvl(dog.shema_dog, fz.pen_sxem) --fz.pen_sxem
  and    dog.ssylka(+) = lspv.ssylka_fl
  and    fz.ssylka = lspv.ssylka_fl
/
