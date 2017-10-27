create or replace view dv_sr_lspv_docs_pers_v as
  select d.gf_person,
         d.tax_rate,
         det_charge_type,
         pen_scheme_code,
         count(distinct d.nom_vkl || '#' || d.nom_ips) accounts_cnt,
         sum(case when not(d.type_op = -1 and d.year_doc < d.year_op) then d.revenue end) revenue,
         sum(d.benefit) benefit,
         sum(case when not (d.type_op = -1 and nvl(d.is_tax_return, 'N') = 'Y') then d.tax end) tax_retained,
         sum(case when d.tax_rate = 30 and not(d.type_op = -1 and d.year_doc < d.year_op) then round(d.revenue * .3, 0) end) tax_calc,
         sum(case when d.type_op = -1 and nvl(d.is_tax_return, 'N') = 'Y' and d.year_op = d.year_doc then d.tax end) tax_return,
         sum(
           case
             when not exists(
                 select 1
                 from   dv_sr_lspv_docs_t dd
                 where  dd.gf_person = d.gf_person
                 and    dd.ssylka_doc_op = d.ssylka_doc_op
                 and    dd.id <> d.id
                 and    dd.is_tax_return = 'Y'
               ) then
                d.tax_83
           end
         ) tax_83
  from   dv_sr_lspv_docs_v d
  group by d.gf_person,
           d.tax_rate,
           d.det_charge_type,
           d.pen_scheme_code
/
