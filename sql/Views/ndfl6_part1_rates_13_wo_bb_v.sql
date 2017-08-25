create or replace view ndfl6_part1_rates_13_wo_bb_v as
  with t as (
    select d.det_charge_type,
           d.pen_scheme_code,
           sum(case when not(d.type_op = -1 and nvl(d.is_tax_return, 'N') = 'Y') then d.revenue end)                 revenue,
           sum(case when d.type_op = -1 and nvl(d.is_tax_return, 'N') = 'N' then d.revenue end)                      storno_total,
           sum(case when d.quarter_op = 1 and d.type_op = -1 and nvl(d.is_tax_return, 'N') = 'N' then d.revenue end) storno_q1,
           sum(case when d.quarter_op = 2 and d.type_op = -1 and nvl(d.is_tax_return, 'N') = 'N' then d.revenue end) storno_q2,
           sum(case when d.quarter_op = 3 and d.type_op = -1 and nvl(d.is_tax_return, 'N') = 'N' then d.revenue end) storno_q3,
           sum(case when d.quarter_op = 4 and d.type_op = -1 and nvl(d.is_tax_return, 'N') = 'N' then d.revenue end) storno_q4
    from   dv_sr_lspv_docs_v d
    where  1=1
    and    d.det_charge_type in ('PENSION', 'RITUAL')
    and    d.tax_rate = 13
    and    d.year_doc = d.year_op
    group by d.det_charge_type, d.pen_scheme_code
  )
  select dc.short_describe det_charge_describe,
         dc.order_num      det_charge_ord_num,
         t.pen_scheme_code,
         ps.name           pen_scheme,
         t.revenue,
         t.storno_total,
         t.storno_q1,
         t.storno_q2,
         t.storno_q3,
         t.storno_q4
  from   t,
         sp_pen_schemes_v      ps,
         sp_det_charge_types_v dc
  where  1 = 1
  and    dc.det_charge_type(+) = t.det_charge_type
  and    ps.code(+) = t.pen_scheme_code
/
