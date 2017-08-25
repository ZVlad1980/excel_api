create or replace view ndfl6_part1_rates_30_persns_v as
  select d.gf_person,
         gp.lastname,
         gp.firstname,
         gp.secondname,
         sum(d.tax_retained)   tax_retained,
         sum(d.tax_calc)       tax_calc,
         sum(d.tax_calc) - 
           sum(d.tax_retained) tax_diff
  from   dv_sr_lspv_docs_pers_v d,
         gf_people_v            gp
  where  1=1
  and    gp.fk_contragent(+) = d.gf_person
  and    d.tax_rate = 30
  group by d.gf_person,
           gp.lastname,
           gp.firstname,
           gp.secondname
  having sum(d.tax_retained) <> sum(d.tax_calc)
/
