create or replace view ndfl2_corr_spr_rep_v as 
  select s.year_doc,
         s.gf_person,
         s.last_name || ' ' || s.first_name || ' ' || s.second_name || ' (' || to_char(s.birth_date, 'dd.mm.yyyy') || ')' fio,
         s.spr_nom,
         s.spr_corr_num,
         s.spr_date,
         s.exists_xml,
         coalesce(s.revenue_last, s.revenue) spr_revenue,
         coalesce(s.tax_retained_last, s.tax_retained) spr_tax,
         (s.revenue_last - s.revenue) spr_revenue_corr,
         (s.tax_retained_last - s.tax_retained) spr_tax_corr,
         s.revenue_corr,
         s.tax_corr
  from   ndfl2_corr_spr_v s
/
