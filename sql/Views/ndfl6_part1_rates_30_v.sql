create or replace view ndfl6_part1_rates_30_v as
  with t as (
    select d.det_charge_type,
           d.pen_scheme_code, 
           sum(d.revenue)            revenue,
           sum(d.tax_calc)           tax_calc,
           sum(
             nvl(d.tax_retained, 0) 
               - nvl(d.tax_calc, 0)
           )                         tax_diff
    from   dv_sr_lspv_docs_pers_v d
    where  d.tax_rate = 30
    group by d.det_charge_type,
             d.pen_scheme_code
  )
  select dc.short_describe det_charge_describe,
         dc.order_num      det_charge_ord_num,
         t.pen_scheme_code,
         ps.name           pen_scheme,
         t.revenue,
         t.tax_calc,
         t.tax_diff
  from   t,
         sp_pen_schemes_v      ps,
         sp_det_charge_types_v dc
  where  1 = 1
  and    dc.det_charge_type(+) = t.det_charge_type
  and    ps.code(+) = t.pen_scheme_code
/
