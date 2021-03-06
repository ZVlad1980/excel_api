create or replace view ndfl_report_tax_retained_v as
  with tax_accruve as (
    select d.id                                    id,
           sum(
             case 
               when d.type_op = -1 then coalesce(d.tax, 0) /*+ coalesce(case when d.year_op <> d.year_doc then d.tax_return end, 0)*/
             end
           ) over (
             partition by 
               d.ssylka_doc, 
               d.nom_vkl, 
               d.nom_ips 
             order by 
               d.date_op 
             rows UNBOUNDED preceding
           )                                       tax_accruing
    from   dv_sr_lspv_docs_v d
    where  d.type_op = -1
  ),
  dv_sr_lspv_docs_w as (
    select d.id,
           d.year_op,
           d.year_doc,
           d.det_charge_type,
           d.pen_scheme_code,
           d.tax_rate_op,
           coalesce(d.tax, 0) tax,
           d.source_tax,
           d.type_op,
           d.is_tax_return,
           max(case when d.type_op < 0 and d.year_op = dv_sr_lspv_docs_api.get_year then 1 else 0 end)over(partition by d.ssylka_doc, d.nom_vkl, d.nom_ips) is_corrected
    from   dv_sr_lspv_docs_v d
    where  not (d.type_op = -2 and d.year_doc < dv_sr_lspv_docs_api.get_year)
  )
  select d.det_charge_type,
         d.pen_scheme_code,
         sum(case when d.tax_rate_op = 13 then d.tax end) tax_retained_13,
         sum(case when d.tax_rate_op = 30 then d.tax end) tax_retained_30,
         sum(case when d.tax_rate_op = 13 and d.is_corrected = 0 then
               d.tax 
             end
         )          tax_wo_corr_13,
         sum(case when d.tax_rate_op = 13 and d.is_corrected = 1 and d.is_tax_return = 'Y' then 
               coalesce(t.tax_accruing, coalesce(d.tax, 0)) + coalesce(case when d.year_doc = dv_sr_lspv_docs_api.get_year then d.source_tax end, 0)
             end
         )          tax_corr_13,
         sum(case when d.tax_rate_op = 30 and d.is_corrected = 0 then d.tax end) tax_wo_corr_30,
         sum(case when d.tax_rate_op = 30 and d.is_corrected = 1 and d.is_tax_return = 'Y' then 
               coalesce(t.tax_accruing, coalesce(d.tax, 0)) + coalesce(case when d.year_op = d.year_doc then d.source_tax end, 0)
             end
         )          tax_corr_30
  from   dv_sr_lspv_docs_w d,
         tax_accruve       t
  where  t.id(+) = d.id
  group by d.det_charge_type, d.pen_scheme_code
/
