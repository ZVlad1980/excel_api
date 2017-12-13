create or replace view sp_tax_residents_v as
  select tr.fk_contragent,
         max(tr.resident)   resident,
         min(tr.start_date) start_date,
         max(tr.end_date)   end_date
  from   sp_tax_residents_t tr
  where  1 = 1
  and    nvl(tr.is_disable, 'N') = 'N'
  and    dv_sr_lspv_docs_api.get_resident_date between tr.start_date and tr.end_date
  group by tr.fk_contragent
/
