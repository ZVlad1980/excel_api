create or replace view dv_sr_lspv_docs_v as
  with dv_sr_lspv_docs_w as (
    select d.id, 
           d.year_op,
           d.month_op,
           d.quarter_op,
           d.date_op, 
           d.ssylka_doc_op, 
           nvl(d.type_op, 0) type_op, 
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
           d.benefit, 
           d.tax,
           case nn.resident when 'N' then 30 else 13 end tax_rate,
           d.tax_rate tax_rate_op,
           d.source_revenue, 
           d.source_benefit, 
           d.source_tax, 
           d.process_id, 
           d.is_tax_return
    from   dv_sr_lspv_docs_t   d,
           sp_tax_residents_v  nn
    where  1=1
    and    nn.fk_contragent(+) = d.gf_person
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
         case when d.type_op in (0, -1) and d.year_doc = dv_sr_lspv_docs_api.get_year then d.benefit end benefit, 
         case when d.type_op in (0, -1) then d.tax end tax,
         case when d.type_op in (0, -1) then d.tax end tax_retained,
         case when not (d.type_op = -2 or (d.type_op = -1 and coalesce(d.is_tax_return, 'N') = 'Y')) then d.tax end tax_retained_old,
         case when (d.type_op = -1 and coalesce(d.is_tax_return, 'N') = 'Y') then d.tax end tax_return,
         case when d.type_op = -2 then d.tax end tax_83,
         d.tax_rate,
         d.tax_rate_op,
         d.source_revenue, 
         case when d.type_op in (0, -1) then d.source_benefit end source_benefit,
         d.source_tax, 
         d.process_id, 
         d.is_tax_return
  from   dv_sr_lspv_docs_w d
  union all
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
         d.revenue_curr_year,
         d.benefit, 
         d.tax,
         d.tax tax_retained,
         d.tax_retained_old,
         d.tax_return,
         null tax_83,
         d.tax_rate,
         d.tax_rate_op,
         d.source_revenue, 
         d.source_benefit, 
         d.source_tax, 
         d.process_id, 
         d.is_tax_return
  from   dv_sr_lspv_buf_v d
  where  dv_sr_lspv_docs_api.get_is_buff = 'Y'
/
