create or replace view ndfl6_part1_general_v as
  select count(distinct 
           case d.exists_revenue 
             when 'Y' then 
               d.gf_person 
           end
         )                           total_persons,
         sum(d.tax_retained)         tax_retained,
         null                        tax_not_retained,
         abs(sum(d.tax_return))      tax_return,
         abs(sum(d.tax_return_prev)) tax_return_prev,
         sum(d.tax_83)               tax_83
  from   dv_sr_lspv_pers_v d
/
