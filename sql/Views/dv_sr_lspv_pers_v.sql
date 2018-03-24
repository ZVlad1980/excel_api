create or replace view dv_sr_lspv_pers_v as
  select d.gf_person, 
         d.tax_rate,
         sum(d.accounts_cnt)                                accounts_cnt,
         sum(d.revenue)                                     revenue,
         least(sum(d.revenue), sum(d.benefit))              benefit,
         sum(d.tax_retained)                                tax_retained,
         case
           when d.tax_rate = 13 then
             round((sum(d.revenue) - least(sum(d.revenue), nvl(sum(d.benefit), 0))) * .13, 0)
           else
             sum(d.tax_calc)
         end                                                tax_calc,
         sum(d.tax_return)                                  tax_return,
         sum(d.tax_return_prev)                             tax_return_prev,
         sum(d.tax_83)                                      tax_83,
         sum(d.tax_retained + coalesce(d.tax_83, 0))        tax_retained_83,
         case when coalesce(sum(d.revenue), 0) = 0 then 'N' else 'Y' end exists_revenue
  from   dv_sr_lspv_docs_pers_v d
  group by d.gf_person, 
           d.tax_rate
/
