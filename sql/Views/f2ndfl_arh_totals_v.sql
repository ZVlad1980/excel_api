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
         sum(ai.sgd_sum) revenue,
         sum(ai.sgd_sum - ai.sum_obl) benefit,
         sum(ai.sum_obl_ni)           tax_calc,
         sum(ai.sum_obl_nu)           tax_retained
  from   f2ndfl_arh_spravki_v s,
         f2ndfl_arh_itogi     ai
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
