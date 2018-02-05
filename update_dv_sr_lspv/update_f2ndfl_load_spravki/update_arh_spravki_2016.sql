merge into f2ndfl_arh_spravki s
using      (select ns.kod_na,
                   ns.god,
                   ns.nom_spr,
                   ns.ui_person,
                   case when min(ns.tip_dox) in (1,2,3) then 'Y' else 'N' end is_participant
            from   f2ndfl_arh_nomspr ns
            where  1=1
            and    ns.kod_na = 1
            and    ns.god = 2016
            group by ns.kod_na,
                   ns.god,
                   ns.nom_spr,
                   ns.ui_person
           ) u
on         (s.kod_na = u.kod_na and s.god = u.god and s.nom_spr = u.nom_spr)
when matched then
  update set
    s.ui_person = u.ui_person,
    s.is_participant = u.is_participant
/
select ns.nom_spr, count(1)
from   f2ndfl_arh_spravki ns
            where  1=1
            and    ns.kod_na = 1
            and    ns.god = 2016
            group by ns.kod_na,
                   ns.god,
                   ns.nom_spr
                   having count(1) > 1
