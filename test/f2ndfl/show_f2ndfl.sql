/*
(
(t.nom_vkl = 12 and t.nom_ips = 14651) or
(t.nom_vkl = 12 and t.nom_ips = 15355) or
(t.nom_vkl = 37 and t.nom_ips = 921)
)
*/
select s.*, s.rowid
from   f2ndfl_arh_spravki s
where  1=1
and    s.ui_person in (
         select t.gf_person
         from   f_ndfl_load_nalplat t
         where  1=1
         and    (
                 (t.nom_vkl = 12 and t.nom_ips = 14651) or
                 (t.nom_vkl = 12 and t.nom_ips = 15355) or
                 (t.nom_vkl = 37 and t.nom_ips = 921)
                )
         and    t.ssylka_tip = 0
         and    t.god = 2017
         and    t.kod_na = 1
       )
and    s.god = 2017
and    s.kod_na = 1
/
select *
from   f2ndfl_arh_mes m
where  m.r_sprid in (
          select s.id
          from   f2ndfl_arh_spravki s
          where  1=1
          and    s.ui_person in (
                   select t.gf_person
                   from   f_ndfl_load_nalplat t
                   where  1=1
                   and    (
                           (t.nom_vkl = 12 and t.nom_ips = 14651) or
                           (t.nom_vkl = 12 and t.nom_ips = 15355) or
                           (t.nom_vkl = 37 and t.nom_ips = 921)
                          )
                   and    t.ssylka_tip = 0
                   and    t.god = 2017
                   and    t.kod_na = 1
                 )
          and    s.god = 2017
          and    s.kod_na = 1
       )
/
select *
from   f2ndfl_arh_vych m
where  m.r_sprid in (
          select s.id
          from   f2ndfl_arh_spravki s
          where  1=1
          and    s.ui_person in (
                   select t.gf_person
                   from   f_ndfl_load_nalplat t
                   where  1=1
                   and    (
                           (t.nom_vkl = 12 and t.nom_ips = 14651) or
                           (t.nom_vkl = 12 and t.nom_ips = 15355) or
                           (t.nom_vkl = 37 and t.nom_ips = 921)
                          )
                   and    t.ssylka_tip = 0
                   and    t.god = 2017
                   and    t.kod_na = 1
                 )
          and    s.god = 2017
          and    s.kod_na = 1
       )
/
select *
from   f2ndfl_arh_itogi m
where  m.r_sprid in (
          select s.id
          from   f2ndfl_arh_spravki s
          where  1=1
          and    s.ui_person in (
                   select t.gf_person
                   from   f_ndfl_load_nalplat t
                   where  1=1
                   and    (
                           (t.nom_vkl = 12 and t.nom_ips = 14651) or
                           (t.nom_vkl = 12 and t.nom_ips = 15355) or
                           (t.nom_vkl = 37 and t.nom_ips = 921)
                          )
                   and    t.ssylka_tip = 0
                   and    t.god = 2017
                   and    t.kod_na = 1
                 )
          and    s.god = 2017
          and    s.kod_na = 1
       )
/
select *
from   f2ndfl_load_spravki sl
where  1=1
and    sl.ssylka in (
         select t.ssylka_sips
         from   f_ndfl_load_nalplat t
         where  1=1
         and    (
                 (t.nom_vkl = 12 and t.nom_ips = 14651) or
                 (t.nom_vkl = 12 and t.nom_ips = 15355) or
                 (t.nom_vkl = 37 and t.nom_ips = 921)
                )
         and    t.ssylka_tip = 0
         and    t.god = 2017
         and    t.kod_na = 1
       )
and    sl.god = 2017
and    sl.kod_na = 1
/
select *
from   f2ndfl_load_mes ml
where  (ml.kod_na, ml.god, ml.ssylka, ml.tip_dox, ml.nom_korr) in (
         select sl.kod_na, sl.god, sl.ssylka, sl.tip_dox, sl.nom_korr
         from   f2ndfl_load_spravki sl
         where  1=1
         and    sl.ssylka in (
                  select t.ssylka_sips
                  from   f_ndfl_load_nalplat t
                  where  1=1
                  and    (
                          (t.nom_vkl = 12 and t.nom_ips = 14651) or
                          (t.nom_vkl = 12 and t.nom_ips = 15355) or
                          (t.nom_vkl = 37 and t.nom_ips = 921)
                         )
                  and    t.ssylka_tip = 0
                  and    t.god = 2017
                  and    t.kod_na = 1
                )
         and    sl.god = 2017
         and    sl.kod_na = 1
       )
/
select *
from   f2ndfl_load_vych ml
where  (ml.kod_na, ml.god, ml.ssylka, ml.tip_dox, ml.nom_korr) in (
         select sl.kod_na, sl.god, sl.ssylka, sl.tip_dox, sl.nom_korr
         from   f2ndfl_load_spravki sl
         where  1=1
         and    sl.ssylka in (
                  select t.ssylka_sips
                  from   f_ndfl_load_nalplat t
                  where  1=1
                  and    (
                          (t.nom_vkl = 12 and t.nom_ips = 14651) or
                          (t.nom_vkl = 12 and t.nom_ips = 15355) or
                          (t.nom_vkl = 37 and t.nom_ips = 921)
                         )
                  and    t.ssylka_tip = 0
                  and    t.god = 2017
                  and    t.kod_na = 1
                )
         and    sl.god = 2017
         and    sl.kod_na = 1
       )
/
select *
from   f2ndfl_load_itogi ml
where  (ml.kod_na, ml.god, ml.ssylka, ml.tip_dox, ml.nom_korr) in (
         select sl.kod_na, sl.god, sl.ssylka, sl.tip_dox, sl.nom_korr
         from   f2ndfl_load_spravki sl
         where  1=1
         and    sl.ssylka in (
                  select t.ssylka_sips
                  from   f_ndfl_load_nalplat t
                  where  1=1
                  and    (
                          (t.nom_vkl = 12 and t.nom_ips = 14651) or
                          (t.nom_vkl = 12 and t.nom_ips = 15355) or
                          (t.nom_vkl = 37 and t.nom_ips = 921)
                         )
                  and    t.ssylka_tip = 0
                  and    t.god = 2017
                  and    t.kod_na = 1
                )
         and    sl.god = 2017
         and    sl.kod_na = 1
       )
/
