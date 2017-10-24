create or replace view ndfl6_part1_general_v as
  select (select count(distinct dd.gf_person) 
          from   (select dd.gf_person
                  from   dv_sr_lspv_docs_v dd
                   where  1=1
                  and    not (dd.type_op = -1 and dd.year_doc < dd.year_op)
                  group by dd.gf_person
                  having coalesce(sum(dd.revenue), 0) > 0
                 ) dd
         ) total_persons,
         d.tax_retained,
         null tax_not_retained,
         abs(d.tax_return) tax_return
  from   (select sum(case when d.year_op = d.year_doc then d.tax_retained end) tax_retained,
                 sum(d.tax_return) tax_return
          from   dv_sr_lspv_docs_v d
         ) d
/
