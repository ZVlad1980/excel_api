create or replace view ndfl6_part2_v as
  select d.date_doc,
         sum(d.revenue_curr_year) revenue,
         sum(d.tax_retained)      tax_retained
  from   dv_sr_lspv_docs_v d
  where  d.date_doc >= dv_sr_lspv_docs_api.get_start_date
  group by d.date_doc
/
