create or replace view f2ndfl_arh_totals_v as
  select s.gf_person,
         s.kod_na,
         s.status_np,
         s.nom_spr,
         s.nom_korr,
         s.is_last_spr,
         s.god,
         ai.kod_stavki tax_rate,
         s.is_employee,
         s.is_participant,
         sum(ai.sgd_sum - coalesce(ltd.revenue, 0))                   revenue,
         sum(ai.sgd_sum - ai.sum_obl - coalesce(ltd.benefit_used, 0)) benefit,
         sum(ai.sum_obl_ni - coalesce(ltd.tax_calc, 0))               tax_calc,
         sum(ai.sum_obl_nu - coalesce(ltd.tax_retained, 0))           tax_retained
  from   f2ndfl_arh_spravki_v s,
         f2ndfl_arh_itogi     ai,
         lateral(
           select ltd.revenue,
                  ltd.benefit_used,
                  ltd.tax_calc,
                  ltd.tax_retained
           from   f2ndfl_load_totals_det_v ltd
           where  1=1
           and    ltd.tip_dox = 9
           and    ltd.tax_rate = ai.kod_stavki
           and    ltd.nom_korr = s.nom_korr
           and    ltd.nom_spr = s.nom_spr
           and    ltd.kod_na = s.kod_na
           and    s.is_employee = 'Y'
           and    dv_sr_lspv_docs_api.get_employees = 'N' --Только при отключенных сотрудниках!
         ) (+) ltd
  where  1=1
  and    ai.r_sprid = s.id
  and    not(dv_sr_lspv_docs_api.get_employees = 'N' and (s.is_participant = 'N' or ai.kod_stavki = 35))
  group by s.gf_person,
           s.kod_na,
           s.status_np,
           s.nom_spr,
           s.nom_korr,
           s.is_last_spr,
           s.god,
           ai.kod_stavki,
           s.is_employee,
           s.is_participant
/
