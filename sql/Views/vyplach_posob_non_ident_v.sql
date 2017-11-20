create or replace view vyplach_posob_non_ident_v as
  select rr.nom_vkl,
         rr.nom_ips,
         rr.ssylka ssylka_fl,
         rr.fio,
         rr.gf_person_vp,
         rr.ssylka_poluch,
         rr.data_vypl,
         rr.ssylka,
         rr.nom_vipl,
         rr.gf_person_fp,
         rr.last_name,
         rr.first_name,
         rr.second_name,
         rr.birth_date,
         rr.gf_person_rp,
         nvl(rr.gf_person_vp, nvl(rr.gf_person_fp, p.fk_contragent)) gf_person_new,
         rr.ssylka_doc
  from   vyplach_posob_receivers_v rr,
         gazfond.people            p
  where  1 = 1
  and    p.fk_contragent(+) =
         nvl(rr.gf_person_vp, nvl(rr.gf_person_fp, p.fk_contragent(+)))
  and    p.lastname(+) = rr.last_name
  and    p.firstname(+) = rr.first_name
  and    p.secondname(+) = rr.second_name
  and    p.birthdate(+) = rr.birth_date
  and    rr.gf_person_vp is null
/
  
