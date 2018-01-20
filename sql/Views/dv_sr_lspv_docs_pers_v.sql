create or replace view dv_sr_lspv_docs_pers_v as
  select d.gf_person,
         d.tax_rate,
         det_charge_type,
         pen_scheme_code,
         count(distinct d.nom_vkl || '#' || d.nom_ips) accounts_cnt,
         sum(d.revenue_curr_year)                      revenue,
         sum(d.benefit_curr_year)                      benefit,
         sum(d.tax_retained)                           tax_retained,
         sum(case when d.tax_rate = 30 then round(d.revenue_curr_year * .3, 0) end) tax_calc,
         sum(d.tax_return)                             tax_return,
         sum(d.tax_83)                                 tax_83
  from   dv_sr_lspv_docs_v d
  group by d.gf_person,
           d.tax_rate,
           d.det_charge_type,
           d.pen_scheme_code
/
