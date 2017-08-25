create or replace view dv_sr_lspv_pers_v as
  select d.gf_person, 
         d.tax_rate,
         case d.tax_rate when 30 then d.det_charge_type end det_charge_type,
         case d.tax_rate when 30 then d.pen_scheme_code end pen_scheme_code,
         sum(d.revenue)   revenue,
         least(sum(d.revenue), sum(d.benefit)) benefit,
         sum(d.tax_retained)   tax_retained,
         case
           when d.tax_rate = 13 then
             round((sum(d.revenue) - least(sum(d.revenue), nvl(sum(d.benefit), 0))) * .13, 0)
           else
             sum(d.tax_calc)
         end tax_calc
  from   dv_sr_lspv_docs_pers_v d
  group by d.gf_person, 
           d.tax_rate, 
           case d.tax_rate when 30 then d.det_charge_type end,
           case d.tax_rate when 30 then d.pen_scheme_code end
  having sum(d.revenue) > 0
/
