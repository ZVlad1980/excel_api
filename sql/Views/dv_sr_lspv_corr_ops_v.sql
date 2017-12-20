create or replace view dv_sr_lspv_corr_ops_v as 
  select d.id                                    id,
         sum(
           case 
             when d.type_op = -1 then d.revenue 
           end
         ) over (
           partition by 
             d.ssylka_doc, 
             d.nom_vkl, 
             d.nom_ips 
           order by 
             d.date_op 
           rows UNBOUNDED preceding
         )                                       revenue_accruing,
         sum(
           case 
             when d.type_op = -1 then d.tax 
           end
         ) over (
           partition by 
             d.ssylka_doc, 
             d.nom_vkl, 
             d.nom_ips 
           order by 
             d.date_op 
           rows UNBOUNDED preceding
         )                                       tax_accruing
  from   dv_sr_lspv_docs_v d
  where  d.type_op < 0
  and    d.year_op <= dv_sr_lspv_docs_api.get_year
/
