create or replace view ndfl6_persons_v as
  with ndfl_persons as (
    select d.header_id,
           d.tax_rate,
           case when d.tax_rate = 30 then d.det_charge_type end det_charge_type,
           case when d.tax_rate = 30 then d.pen_scheme      end pen_scheme,
           d.gf_person,
           sum(d.revenue_amount)    revenue_amount,
           sum(d.benefit)           benefit, --предоставленные ФЛ вычеты
           sum(d.tax_calc)          tax_calc, 
           sum(d.tax_retained     ) tax_retained     ,
           sum(d.tax_corr_83      ) tax_corr_83      ,
           sum(d.tax_returned_prev) tax_returned_prev,
           sum(d.tax_returned_curr) tax_returned_curr,
           sum(d.tax_corr_prev    ) tax_corr_prev    ,
           sum(d.tax_corr_curr    ) tax_corr_curr
    from   ndfl6_lines_t d
    group  by 
      d.header_id,
      d.tax_rate, 
      case when d.tax_rate = 30 then d.det_charge_type end,
      case when d.tax_rate = 30 then d.pen_scheme      end,
      d.gf_person --*/
  )
  select d.header_id        ,
         d.tax_rate         ,
         d.det_charge_type  ,
         d.pen_scheme       ,
         d.gf_person        ,
         d.revenue_amount   ,
         case 
           when nvl(d.benefit, 0) > 0 then
             least(d.benefit, d.revenue_amount)
         end                                       benefit,
         case d.tax_rate
           when 13 then 
             round((d.revenue_amount - 
                 case 
                   when nvl(d.benefit, 0) > 0 then
                     least(d.benefit, d.revenue_amount)
                   else 0
                 end) * .13, 0)
           else
             d.tax_calc
         end                                       tax_calc,
         d.tax_retained     ,
         d.tax_corr_83      ,
         d.tax_returned_prev,
         d.tax_returned_curr,
         d.tax_corr_prev    ,
         d.tax_corr_curr    
  from   ndfl_persons d
/
