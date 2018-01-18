create or replace view f2ndfl_load_totals_v as
  select s.gf_person,
         s.kod_na,
         s.status_np,
         s.nom_spr,
         s.nom_korr,
         s.is_last_spr,
         s.god,
         s.tax_rate,
         max(case s.tip_dox when 9 then 'Y' end) is_employee,
         max(case when s.tip_dox in (1, 2, 3) then 'Y' end) is_participant,
         sum(s.revenue     ) revenue     ,
         sum(s.benefit     ) benefit     ,
         round(
           case s.tax_rate
             when 13 then
               (sum(s.revenue) - least(sum(coalesce(s.benefit, 0)), sum(s.revenue))) * s.tax_rate / 100
             else
               sum(s.tax_calc)--s.revenue * s.tax_rate / 100)
           end,
           0
         )                   tax_calc    ,
         sum(s.tax_retained) tax_retained
  from   f2ndfl_load_totals_det_v s
  where  s.tip_dox <> 9
  group by s.gf_person,
         s.kod_na,
         s.status_np,
         s.nom_spr,
         s.nom_korr,
         s.is_last_spr,
         s.god,
         s.tax_rate
/
