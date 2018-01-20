create or replace view ndfl6_tax_returns_v as
  with t as (
  select /*+ MATERIALIZE*/
         d.det_charge_type,
         d.pen_scheme_code,
         case when d.year_op = d.year_doc then 'Y' else 'N' end current_year,
         sum(d.tax_return) tax_returned
  from   dv_sr_lspv_docs_v d
  where  1=1
  and    d.is_tax_return = 'Y'
  and    d.type_op = -1
  and    d.year_op <= dv_sr_lspv_docs_api.get_year
  group by d.det_charge_type,
           d.pen_scheme_code, 
           case when d.year_op = d.year_doc then 'Y' else 'N' end
  )
  select dc.short_describe det_charge_describe,
         dc.order_num      det_charge_ord_num,
         t.pen_scheme_code,
         ps.name          pen_scheme,
         t.current_year,
         t.tax_returned
  from   t,
         sp_pen_schemes_v      ps,
         sp_det_charge_types_v dc
  where  1 = 1
  and    dc.det_charge_type(+) = t.det_charge_type
  and    ps.code(+) = t.pen_scheme_code
/
