create or replace view dv_sr_lspv_docs_v as
with sp_no_residents_w as (
    select /*+ materialize*/ nn.gf_person
    from   sp_no_residents_v  nn
  ),
  dv_sr_lspv_docs_w as (
    select d.id, 
           extract(year from d.date_op)            year_op,
           extract(month from d.date_op)           month_op,
           ceil(extract(month from d.date_op)/3)   quarter_op,
           d.date_op, 
           d.ssylka_doc_op, 
           d.type_op, 
           extract(year from d.date_doc)           year_doc,
           extract(month from d.date_doc)          month_doc,
           ceil(extract(month from d.date_doc)/3)  quarter_doc,
           d.date_doc, 
           d.ssylka_doc, 
           d.nom_vkl, 
           d.nom_ips, 
           d.ssylka_fl, 
           d.gf_person, 
           d.pen_scheme_code,
           d.det_charge_type,
           d.revenue,
           d.benefit, 
           d.tax,
           case when nn.gf_person is not null then 30 else 13 end tax_rate,
           d.tax_rate tax_rate_op,
           d.tax_83, 
           d.source_revenue, 
           d.source_benefit, 
           d.source_tax, 
           d.process_id, 
           d.is_tax_return
    from   dv_sr_lspv_docs_t  d,
           sp_no_residents_w  nn
    where  1=1
    and    nn.gf_person(+) = d.gf_person
    and    d.is_delete is null
    and    d.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date
  )
  select d.id, 
         d.year_op,
         d.month_op,
         d.quarter_op,
         d.date_op, 
         d.ssylka_doc_op, 
         d.type_op, 
         d.year_doc,
         d.month_doc,
         d.quarter_doc,
         d.date_doc, 
         d.ssylka_doc, 
         d.nom_vkl, 
         d.nom_ips, 
         d.ssylka_fl, 
         d.gf_person, 
         d.pen_scheme_code,
         d.det_charge_type,
         d.revenue,
         case when not(d.type_op = -1 and d.year_op <> d.year_doc) then d.revenue end revenue_curr_year,
         d.benefit, 
         d.tax,
         d.tax tax_retained,
         case when not (d.type_op = -1 and coalesce(d.is_tax_return, 'N') = 'Y') then d.tax end tax_retained_old,
         case when (d.type_op = -1 and coalesce(d.is_tax_return, 'N') = 'Y') then d.tax end tax_return,
         d.tax_rate,
         d.tax_rate_op,
         d.tax_83, 
         d.source_revenue, 
         d.source_benefit, 
         d.source_tax, 
         d.process_id, 
         d.is_tax_return
  from   dv_sr_lspv_docs_w d
/
