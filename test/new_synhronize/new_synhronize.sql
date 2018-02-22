begin
  dv_sr_lspv_docs_api.set_period(
    p_year => 2017,
    p_report_date => to_date(20171231, 'yyyymmdd')
  );
end;
/
insert into dv_sr_lspv_docs_t(
  date_op, 
  ssylka_doc_op, 
  type_op, 
  date_doc, 
  ssylka_doc, 
  nom_vkl, 
  nom_ips, 
  ssylka_fl, 
  gf_person, 
  pen_scheme_code, 
  tax_rate, 
  det_charge_type, 
  revenue, 
  benefit, 
  tax,
  source_revenue,
  source_benefit,
  source_tax,
  is_tax_return,
  process_id
) select dc.date_op, 
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
         dc.is_tax_return,
         -1
  from   (
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
                 coalesce(abs(dc.tax),     0) >= 0.01
          minus
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
          from   dv_sr_lspv_docs_t dc
          where  1=1
          and    (dc.year_op = dv_sr_lspv_docs_api.get_year or dc.year_doc = dv_sr_lspv_docs_api.get_year)
          and    nvl(dc.is_delete, 'N') <> 'Y'
        ) dc
/
