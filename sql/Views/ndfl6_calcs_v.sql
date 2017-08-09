create or replace view ndfl6_calcs_v as
  select d.header_id,
         d.tax_rate, 
         d.det_charge_type, 
         d.pen_scheme,
         (select count(distinct dd.gf_person) 
          from   (select dd.gf_person, sum(dd.revenue_amount) revenue_amount 
                  from   ndfl6_persons_detail_t dd 
                  group by dd.gf_person
                 ) dd 
          where  nvl(dd.revenue_amount, 0) > 0
         )                           total_persons      ,
         sum(d.revenue_amount)       revenue_amount     ,
         sum(d.benefit)              benefit            ,
         sum(d.tax_retained)         tax_retained       ,
         sum(d.tax_calc)             tax_calc           ,
         sum(d.tax_corr_83)          tax_corr_83        ,
         sum(d.tax_returned_prev)    tax_returned_prev  ,
         sum(d.tax_returned_curr)    tax_returned_curr
  from   ndfl6_persons_v d
  group by d.header_id, d.tax_rate, d.det_charge_type, d.pen_scheme
/
