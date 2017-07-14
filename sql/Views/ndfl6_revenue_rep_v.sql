create or replace view ndfl6_revenue_rep_v as
  select row_number()over(order by d.data_op) block_num,
         trunc(d.data_op)                            operation_date,
         trunc(d.data_op) + 1                        transfer_date,
         sum(case when d.charge_type = 'REVENUE' and d.is_correction = 'N' then d.summa end) revenue,
         sum(case when d.charge_type = 'BENEFIT' and d.is_correction = 'N' then d.summa end) benefit,
         sum(case when d.charge_type = 'TAX'     and d.is_correction = 'N' then d.summa end) tax
  from   ndfl_dv_sr_lspv_v d
  group by d.data_op
/
