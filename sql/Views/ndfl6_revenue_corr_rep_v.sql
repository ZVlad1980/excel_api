create or replace view ndfl6_revenue_corr_rep_v as
  select trunc(d.root_data_op)     operation_date,
         trunc(d.data_op)          corrected_date,
         sum(case d.charge_type when 'REVENUE' then d.summa end) revenue,
         sum(case d.charge_type when 'BENEFIT' then d.summa end) benefit,
         sum(case d.charge_type when 'TAX'     then d.summa end) tax
  from   ndfl_dv_sr_lspv_corr_v d
  where  d.is_leaf = 1
  and    d.service_doc <> -1
  group by d.root_data_op, d.data_op
/
