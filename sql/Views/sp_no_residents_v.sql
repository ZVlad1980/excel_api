create or replace view sp_no_residents_v as
  select d.gf_person
  from   dv_sr_lspv_docs_t d
  where  1=1
  and    d.tax_rate = 30
  and    d.is_delete is null
  and    d.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date
  group by gf_person
  having sum(d.tax) <> 0
/
