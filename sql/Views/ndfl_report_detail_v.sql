create or replace view ndfl_report_detail_v as
  select r.block_num,
         row_number()over(partition by block_num order by r.operation_date, rc.corrected_date) block_row_num,
         r.operation_date,
         r.transfer_date,
         r.revenue,
         r.benefit,
         r.tax,
         rc.operation_date correction_date,
         rc.corrected_date,
         rc.revenue corr_revenue,
         rc.benefit corr_benefit,
         rc.tax     corr_tax
  from   ndfl6_revenue_rep_v      r,
         ndfl6_revenue_corr_rep_v rc
  where  1=1
  and    rc.operation_date(+) = r.operation_date 
/
