create or replace view dv_sr_lspv_docs_pers_v as
  select d.gf_person, 
         d.tax_rate,
         det_charge_type,
         pen_scheme_code,
         sum(case when not(d.type_op = -1 and d.year_doc < d.year_op) then d.revenue end) revenue,
         sum(d.benefit) benefit,
         sum(case when not (d.type_op = -1 and nvl(d.is_tax_return, 'N') = 'Y') then d.tax end) tax_retained,
         sum(case when d.tax_rate = 30 and not(d.type_op = -1 and d.year_doc < d.year_op) then round(d.revenue * .3, 0) end) tax_calc
  from   dv_sr_lspv_docs_v d
  group by d.gf_person, 
           d.tax_rate, 
           d.det_charge_type,
           d.pen_scheme_code
/
