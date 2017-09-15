create or replace view ndfl_report_tax_retained_v as
  with tax_accruve as (
    select /*+ MATERIALIZE*/
           o.id,
           o.tax_accruing
    from   dv_sr_lspv_corr_ops_v o
  )
  select d.det_charge_type,
         d.pen_scheme_code,
         sum(case when d.tax_rate_op = 13 then d.tax end) tax_retained_13,
         sum(case when d.tax_rate_op = 30 then d.tax end) tax_retained_30,
         sum(case when d.tax_rate_op = 13 and d.is_corrected = 0 then
               d.tax 
             end
         )          tax_wo_corr_13,
         sum(case when d.tax_rate_op = 13 and 
                    coalesce(d.type_op, 0) = -1 and coalesce(d.is_tax_return, 'N') = 'Y' then 
               coalesce(t.tax_accruing, coalesce(d.tax, 0)) + coalesce(case when d.year_op = d.year_doc then d.source_tax end, 0)
             end
         )          tax_corr_13,
         sum(case when d.tax_rate_op = 30 and d.is_corrected = 0 then d.tax end) tax_wo_corr_30,
         sum(case when d.tax_rate_op = 30 and coalesce(d.type_op, 0) = -1 and coalesce(d.is_tax_return, 'N') = 'Y' then 
               coalesce(t.tax_accruing, coalesce(d.tax, 0)) + coalesce(case when d.year_op = d.year_doc then d.source_tax end, 0)
             end
         )          tax_corr_30
  from   dv_sr_lspv_docs_v d,
         tax_accruve       t
  where  t.id(+) = d.id
  group by d.det_charge_type, d.pen_scheme_code
/
