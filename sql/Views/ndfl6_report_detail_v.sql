create or replace view ndfl6_report_detail_v as 
  select case row_number() over(
                partition by 
                  nvl(d.date_op, dc.date_op)
                order by dc.date_corr
              ) 
           when 1 then 'Y' 
           else 'N' 
         end                  first_row,
         nvl(d.date_op, dc.date_op)                 date_op,
         d.revenue,
         d.benefit,
         d.tax,
         dc.date_corr,
         dc.revenue                               revenue_corr,
         dc.benefit                               benefit_corr,
         dc.tax                                   tax_corr
  from (
  select d.date_op,
         sum(d.revenue) revenue,
         sum(d.benefit) benefit,
         sum(d.tax)     tax
  from   dv_sr_lspv_det_v d
  where  d.type_op is null
  group by d.date_op
  ) d
  full outer join (
  select d.date_op,
         d.date_corr,
         sum(d.revenue) revenue,
         sum(d.benefit) benefit,
         sum(d.tax)     tax
  from   dv_sr_lspv_det_v d
  where  d.type_op  = -1
  group by d.date_op, d.date_corr
  ) dc
  on  d.date_op = dc.date_op
/
