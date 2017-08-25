create or replace view ndfl6_part2_v as
  select d.date_doc,
         sum(case when not(d.type_op = -1 and d.year_op <> d.year_doc) then d.revenue end)     revenue,
         sum(case when not(d.type_op = -1 and nvl(d.is_tax_return, 'N') = 'Y') then d.tax end) tax_retained
  from   dv_sr_lspv_docs_v d
  group by d.date_doc
/
