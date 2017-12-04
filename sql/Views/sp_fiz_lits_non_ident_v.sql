create or replace view sp_fiz_lits_non_ident_v as
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
  from   sp_fiz_lits_receivers_v fd,
         fnd.sp_fiz_lits         f,
         gazfond.people          p
  where  1=1
  and    p.lastname(+) = f.familiya
  and    p.firstname(+) = f.imya
  and    p.secondname(+) = f.otchestvo
  and    p.birthdate(+) = f.data_rogd
  --
  and    f.ssylka = fd.ssylka
  and    fd.gf_person is null
/
