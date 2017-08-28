create or replace view dv_sr_lspv_tax_diff_v as
  select d.gf_person,
         d.tax_rate,
         sum(d.accounts_cnt)                   accounts_cnt,
         sum(d.tax_calc)                       tax_calc,
         sum(d.tax_retained)                   tax_retained,
         coalesce(sum(d.tax_calc), 0) - 
           coalesce(sum(d.tax_retained), 0)    tax_diff,
         sum(d.tax_return)                     tax_return,
         sum(d.tax_83)                         tax_83
  from   dv_sr_lspv_pers_v d
  group by d.gf_person, d.tax_rate
  having coalesce(sum(d.tax_calc), 0) <> coalesce(sum(d.tax_retained), 0)
           and --если разошлась сумма исчислено/удержано, проверяем с учетом возвратов
          abs(
            coalesce(sum(d.tax_calc),     0) - 
            coalesce(sum(d.tax_retained), 0) - 
            coalesce(sum(d.tax_return),   0) -
            coalesce(sum(d.tax_83),       0)
          ) > 0
/
