create or replace view ndfl6_part1_rates_13_bb_v as
  with buybacks as (
    select d.nom_vkl, d.nom_ips, d.ssylka_doc, d.gf_person, d.pen_scheme_code, d.year_doc, d.year_op,
           min(d.type_op) type_op,
           sum(d.revenue) revenue,
           sum(case when d.type_op is null then d.revenue when d.type_op = -1 then -1 * d.source_revenue end) fix_revenue,
           sum(case d.type_op when -1 then d.revenue end) corr_revenue,
           max(d.source_revenue) source_revenue
    from   dv_sr_lspv_docs_v d
    where  1=1
    and    d.det_charge_type = 'BUYBACK'
    and    d.tax_rate = 13 --year_doc < d.year_op
    group by d.nom_vkl, d.nom_ips, d.ssylka_doc, d.gf_person, d.pen_scheme_code, d.year_doc, d.year_op
  ), 
  buybacks2 as (
    select d.pen_scheme_code,
           sum(case when d.year_doc = d.year_op then d.revenue end) revenue,
           sum(case when d.year_doc = d.year_op then d.fix_revenue end)      fix_revenue,
           sum(case when d.type_op = -1 and d.year_doc = d.year_op then d.source_revenue end) source_revenue,
           sum(case when d.type_op = -1 and d.year_doc = d.year_op then corr_revenue end) corr_revenue,
           sum(case when d.year_doc <> d.year_op then d.revenue end) revenue_prev_year
    from   buybacks d
    group by d.pen_scheme_code
  )
  --
  select dc.short_describe det_charge_describe,
         d.pen_scheme_code,
         ps.name           pen_scheme,
         d.revenue,
         d.fix_revenue,
         d.source_revenue,
         d.corr_revenue,
         d.source_revenue + d.corr_revenue diff_revenue,
         d.revenue_prev_year
  from   buybacks2 d,
         sp_pen_schemes_v      ps,
         sp_det_charge_types_v dc
  where  1 = 1
  and    dc.det_charge_type(+) = 'BUYBACK'
  and    ps.code(+) = d.pen_scheme_code
/
