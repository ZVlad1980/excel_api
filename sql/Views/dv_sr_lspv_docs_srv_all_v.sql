create or replace view dv_sr_lspv_docs_srv_all_v as
  with w_dv_sr_lspv as (
    select dc.date_op, 
           dc.ssylka_doc_op, 
           dc.type_op, 
           dc.date_doc, 
           dc.ssylka_doc, 
           dc.nom_vkl, 
           dc.nom_ips, 
           dc.ssylka_fl, 
           dc.gf_person, 
           dc.pen_scheme_code,
           dc.tax_rate, 
           dc.det_charge_type,
           dc.revenue, 
           dc.benefit, 
           dc.tax,
           dc.source_revenue, 
           dc.source_benefit, 
           dc.source_tax,
           dc.is_tax_return
    from   dv_sr_lspv_docs_src_v  dc
    where  coalesce(abs(dc.revenue), 0) + 
           coalesce(abs(dc.benefit), 0) + 
           coalesce(abs(dc.tax),     0)
            >= 0.01
  ),
  w_dv_sr_lspv_docs_t as (
    select dc.id,
           dc.date_op, 
           dc.ssylka_doc_op, 
           dc.type_op, 
           dc.date_doc, 
           dc.ssylka_doc, 
           dc.nom_vkl, 
           dc.nom_ips, 
           dc.ssylka_fl, 
           dc.gf_person, 
           dc.pen_scheme_code,
           dc.tax_rate, 
           dc.det_charge_type,
           dc.revenue, 
           dc.benefit, 
           dc.tax,
           dc.source_revenue, 
           dc.source_benefit, 
           dc.source_tax,
           dc.is_tax_return
    from   dv_sr_lspv_docs_t  dc
    where  dc.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date
    and    dc.is_delete is null
    union all
    select dc.id,
           dc.date_op, 
           dc.ssylka_doc_op, 
           dc.type_op, 
           dc.date_doc, 
           dc.ssylka_doc, 
           dc.nom_vkl, 
           dc.nom_ips, 
           dc.ssylka_fl, 
           dc.gf_person, 
           dc.pen_scheme_code,
           dc.tax_rate, 
           dc.det_charge_type,
           dc.revenue, 
           dc.benefit, 
           dc.tax,
           dc.source_revenue, 
           dc.source_benefit, 
           dc.source_tax,
           dc.is_tax_return
    from   dv_sr_lspv_docs_t  dc
    where  1=1
    and    dc.type_op < 0
    and    dc.date_op > dv_sr_lspv_docs_api.get_end_date
    and    dc.year_doc  = dv_sr_lspv_docs_api.get_year
    and    dc.is_delete is null
  ),
  w_dv_sr_lspv_src as (
    select dd.id,
           dc.date_op, 
           dc.ssylka_doc_op, 
           dc.type_op, 
           dc.date_doc, 
           dc.ssylka_doc, 
           coalesce(dc.nom_vkl,   dd.nom_vkl)   nom_vkl,  
           coalesce(dc.nom_ips,   dd.nom_ips  ) nom_ips  , 
           coalesce(dc.ssylka_fl, dd.ssylka_fl) ssylka_fl,
           coalesce(dc.gf_person, dd.gf_person) gf_person,
           dc.pen_scheme_code,
           dc.tax_rate, 
           dc.det_charge_type,
           dc.revenue, 
           dc.benefit, 
           dc.tax,
           dc.source_revenue, 
           dc.source_benefit, 
           dc.source_tax,
           dc.is_tax_return
    from   w_dv_sr_lspv dc
    full outer join w_dv_sr_lspv_docs_t dd
      on   dd.date_op       = dc.date_op
      and  dd.ssylka_doc_op = dc.ssylka_doc_op
      and  dd.date_doc      = dc.date_doc
      and  dd.ssylka_doc    = dc.ssylka_doc
      and  dd.nom_vkl       = dc.nom_vkl
      and  dd.nom_ips       = dc.nom_ips
      and  dd.gf_person     = dc.gf_person
      and  dd.tax_rate      = dc.tax_rate
      and  to_char(dd.revenue ) || '#' ||
             to_char(dd.benefit ) || '#' ||
             to_char(dd.tax ) || '#' ||
             to_char(dd.source_revenue ) || '#' ||
             to_char(dd.source_benefit ) || '#' ||
             to_char(dd.source_tax  ) || '#' ||
             to_char(dd.is_tax_return )|| '#' ||
             to_char(dd.type_op )
           = 
           to_char(dc.revenue ) || '#' ||
             to_char(dc.benefit ) || '#' ||
             to_char(dc.tax ) || '#' ||
             to_char(dc.source_revenue ) || '#' ||
             to_char(dc.source_benefit ) || '#' ||
             to_char(dc.source_tax  ) || '#' ||
             to_char(dc.is_tax_return )|| '#' ||
             to_char(dc.type_op )
  )
  select d.id,
         d.date_op, 
         d.ssylka_doc_op, 
         d.type_op, 
         d.date_doc, 
         d.ssylka_doc, 
         d.nom_vkl, 
         d.nom_ips, 
         d.ssylka_fl, 
         d.gf_person, 
         d.pen_scheme_code,
         d.tax_rate, 
         d.det_charge_type,
         d.revenue, 
         d.benefit, 
         d.tax,
         d.source_revenue, 
         d.source_benefit, 
         d.source_tax,
         d.is_tax_return
  from   w_dv_sr_lspv_src d
  where  d.date_op is null or d.id is null
/
