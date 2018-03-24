update dv_sr_lspv_docs_t d
set    d.revenue = round(d.revenue, 2),
       d.tax = round(d.tax, 2),
       d.benefit = round(d.benefit, 2),
       d.source_revenue = round(d.source_revenue, 2),
       d.source_tax = round(d.source_tax, 2),
       d.source_benefit = round(d.source_benefit, 2)
/
update dv_sr_lspv_docs_t d
set    d.delete_process_id = d.process_id
where  d.is_delete = 'Y'
and    d.delete_process_id is  null
/
commit;
