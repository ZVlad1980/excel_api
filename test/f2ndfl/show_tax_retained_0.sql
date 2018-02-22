select *
from   (
select m.r_sprid, 
       m.vych_kod_gni,
       m.vych_sum_predost,
       sum(m.vych_sum_predost)over(partition by m.r_sprid) total_vych_sum,
       (
         select sum(ai.sgd_sum)
         from   f2ndfl_arh_itogi ai
         where  ai.r_sprid = m.r_sprid
       ) revenue,
       (
         select sum(ai.sum_obl)
         from   f2ndfl_arh_itogi ai
         where  ai.r_sprid = m.r_sprid
       ) revenue_obl,
       (
         select sum(ai.sum_obl_ni)
         from   f2ndfl_arh_itogi ai
         where  ai.r_sprid = m.r_sprid
       ) tax_calc,
       (
         select sum(ai.sum_obl_nu)
         from   f2ndfl_arh_itogi ai
         where  ai.r_sprid = m.r_sprid
       ) tax_retained
from   f2ndfl_arh_vych m
where  m.r_sprid in (
          select s.id
          from   f2ndfl_arh_spravki s
          where  1=1
          and    s.god = 2017
          and    s.kod_na = 1
       )
) t
where  t.total_vych_sum <> t.vych_sum_predost
and    t.total_vych_sum > t.revenue
