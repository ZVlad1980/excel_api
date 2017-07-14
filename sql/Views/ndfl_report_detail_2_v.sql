create or replace view ndfl_report_detail_2_v as
  select r.block_num,
         row_number()over(partition by block_num order by r.operation_date, rc.corrected_date) block_row_num,
         r.operation_date,
         r.transfer_date,
         case r.charge_type
           when 'PENSION' then 'Пенсия'
           when 'BUYBACK' then 'Выкупные суммы'
           when 'RITUAL'  then 'Ритуальные пособия'
         end charge_type,
         --r.charge_code,
         r.revenue_13,
         r.benefit_13,
         r.tax_13,
         r.revenue_30,
         r.tax_30,
         r.pen_scheme,
         rc.operation_date correction_date,
         rc.corrected_date,
         rc.revenue_13 corr_revenue_13,
         rc.benefit_13 corr_benefit_13,
         rc.tax_13     corr_tax_13,
         rc.revenue_30 corr_revenue_30,
         rc.tax_30     corr_tax_30
  from   ndfl6_revenue_rep_2_v      r,
         ndfl6_revenue_corr_rep_2_v rc
  where  1=1
  and    rc.pen_scheme(+) = r.pen_scheme
  and    rc.charge_type(+) = r.charge_type
  and    rc.operation_date(+) = r.operation_date 
/
