update(
  select ns.fk_contragent ,
         ns.ui_person  ,   
         nvl((select max(m.fk_person_united) keep(dense_rank last order by m.lvl)
             from   contragent_merge_log_v m
             where  1 = 1
             and    m.fk_person_removed_root = ns.fk_contragent),
             nvl((select max(sfl.gf_person)
                 from   sp_fiz_lits sfl
                 where  sfl.ssylka = ns.ssylka_fl),
                 (select max(srp.fk_contragent)
                  from   sp_ritual_pos srp
                  where  srp.ssylka(+) = ns.ssylka))) fk_person_united
        from   f2ndfl_arh_nomspr ns
        where  1=1
        and    ns.fk_contragent not in (
                 select p.fk_contragent
                 from   gf_people_v p
               )
               ) u
set   u.fk_contragent = u.fk_person_united,
      u.ui_person     = u.fk_person_united
where u.fk_person_united is not null
/
select ns.kod_na,
       ns.god,
       ns.ssylka,
       ns.tip_dox,
       ns.flag_otmena,
       ns.fk_contragent,
       ns.ssylka_fl,
       ns.ui_person,
       nvl((select max(m.fk_person_united) keep(dense_rank last order by m.lvl)
           from   contragent_merge_log_v m
           where  1 = 1
           and    m.fk_person_removed_root = ns.fk_contragent),
           nvl((select max(sfl.gf_person)
               from   sp_fiz_lits sfl
               where  sfl.ssylka = ns.ssylka_fl),
               (select max(srp.fk_contragent)
                from   sp_ritual_pos srp
                where  srp.ssylka(+) = ns.ssylka))) fk_person_united
from   f2ndfl_arh_nomspr ns
where  1 = 1
and    ns.fk_contragent not in
       (select p.fk_contragent
         from   gf_people_v p)
