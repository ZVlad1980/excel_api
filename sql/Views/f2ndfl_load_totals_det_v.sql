create or replace view f2ndfl_load_totals_det_v as
  with benefits_all as (
    select lv.kod_na  ,
           lv.god     ,
           lv.ssylka  ,
           lv.nom_korr,
           lv.tip_dox ,
           lv.vych_sum
    from   f2ndfl_load_vych lv
    union all
    select lm.kod_na  ,
           lm.god     ,
           lm.ssylka  ,
           lm.nom_korr,
           lm.tip_dox ,
           lm.vych_sum
    from   f2ndfl_load_mes lm
  )
  select s.kod_na,
         coalesce(sfl.gf_person, rp.fk_contragent, e.gf_person) gf_person,
         s.ssylka,
         s.status_np,
         s.tip_dox,
         s.nom_spr,
         s.nom_korr,
         s.is_last_spr,
         s.god,
         li.kod_stavki tax_rate,
         li.sgd_sum revenue,
         lv.benefit    benefit,
         li.sgd_sum - li.sum_obl benefit_used,
         li.sum_obl_ni tax_calc,
         li.sum_obl_nu tax_retained
  from   f2ndfl_load_spravki_v s,
         sp_fiz_lits           sfl,
         sp_ritual_pos         rp,
         f_ndfl_load_spisrab   e,
         f2ndfL_load_itogi     li,
         lateral (
           select lv.kod_na  ,
                  lv.god     ,
                  lv.ssylka  ,
                  lv.nom_korr,
                  lv.tip_dox ,
                  sum(lv.vych_sum) benefit
           from   benefits_all lv
           where  lv.nom_korr       = s.nom_korr
           and    lv.tip_dox        = s.tip_dox
           and    lv.ssylka         = s.ssylka
           and    lv.god            = s.god
           and    lv.kod_na         = s.kod_na
           group by lv.kod_na  ,
                  lv.god     ,
                  lv.ssylka  ,
                  lv.nom_korr,
                  lv.tip_dox
         ) (+)        lv
  where  1=1
  --
  and    li.nom_korr = s.nom_korr
  and    li.tip_dox = s.tip_dox
  and    li.ssylka = s.ssylka
  and    li.god = s.god
  and    li.kod_na = s.kod_na
  --
  and    e.uid_np(+) = s.employee_id
  and    e.kod_na(+) = s.kod_na
  and    e.god(+) = s.god
  and    sfl.ssylka(+) = s.ssylka_fl
  and    rp.ssylka(+) = s.ssylka_rp
/
