create or replace view sp_fiz_litz_lspv_v as
  select lspv.nom_vkl,
         lspv.nom_ips,
         fz.ssylka,
         fz.familiya             last_name,
         fz.imya                 first_name,
         fz.otchestvo            second_name,
         fz.data_rogd            birth_date,
         case fz.nal_rezident 
           when 1 then 1
           else 0 
         end                     resident,
         s.kod_ps                pen_scheme_code,
         fz.gf_person            gf_person,
         s.kr_nazv               pen_scheme,
         fz.familiya || ' ' || 
           fz.imya   || ' ' ||
           fz.otchestvo          full_name
  from   fnd.sp_lspv        lspv, 
         fnd.sp_pen_dog     dog,
         fnd.sp_fiz_lits    fz,
         fnd.kod_pens_shem  s
  where  1=1
  and    s.kod_ps(+) = nvl(dog.shema_dog, fz.pen_sxem) --fz.pen_sxem
  and    dog.ssylka(+) = fz.ssylka
  and    lspv.ssylka_fl(+) = fz.ssylka
/
