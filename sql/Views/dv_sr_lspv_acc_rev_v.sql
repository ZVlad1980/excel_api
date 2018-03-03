create or replace view dv_sr_lspv_acc_rev_v as
  select a.year_op,
         a.nom_vkl,
         a.nom_ips,
         extract(month from a.date_op) month_op,
         a.amount                      revenue,
         sum(a.amount)
           over(
             partition by 
               a.nom_vkl, 
               a.nom_ips 
             order by 
               a.date_op 
             rows between unbounded 
             preceding 
             and current row
         )                             revenue_acc
  from   dv_sr_lspv_acc_v a
  where  1=1
  and    a.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date
  and    a.det_charge_type in ('PENSION', 'BUYBACK')
  and    a.charge_type = 'REVENUE'
/
