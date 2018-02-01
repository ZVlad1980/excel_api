create or replace view f2ndfl_arh_spravki_src_v as
  with w_persons as (
    select ns.kod_na,
           ns.god,
           ns.ui_person,
           case 
             when min(ns.tip_dox) < 9 then
               'Y'
             else 'N'
           end  is_participant,
           case max(ns.tip_dox) 
             when 9 then
               'Y'
             else 'N'
           end  is_employee
    from   f2ndfl_arh_nomspr ns
    where  1=1
    group by ns.kod_na,
             ns.god,
             ns.ui_person
  )
  select p.kod_na,
         p.god,
         p.ui_person,
         p.is_participant,
         p.is_employee,
         gfp.inn,
         gfp.resident,
         ac.code3d citizenship,
         gfp.lastname,
         gfp.firstname,
         gfp.secondname,
         gfp.birthdate,
         gfi.fk_idcard_type,
         gfi.series || case when gfi.series is not null and gfi.nbr is not null then ' ' end || gfi.nbr ser_nom_doc
  from   w_persons p,
         gf_people_v  gfp,
         gf_idcards_v gfi,
         gazfond.address_countries ac
  where  1=1
  and    ac.id(+) = gfi.citizenship
  and    gfi.id(+) = gfp.fk_idcard
  and    gfp.fk_contragent = p.ui_person
  and    p.is_participant = 'Y'
  union all
  select p.kod_na,
         p.god,
         p.ui_person,
         p.is_participant,
         p.is_employee,
         ls.inn_fl,
         ls.status_np,
         ls.grazhd,
         ls.familiya,
         ls.imya,
         ls.otchestvo,
         ls.data_rozhd,
         ls.kod_ud_lichn,
         ls.ser_nom_doc
  from   w_persons p,
         f2ndfl_load_spravki ls
  where  1=1
  and    ls.tip_dox = 9
  and    ls.ssylka = p.ui_person
  and    ls.god = p.god
  and    ls.kod_na = p.kod_na
  and    p.is_participant = 'N'
/
