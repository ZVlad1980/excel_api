create or replace view f2ndfl_benefits_det_v as
  select a.nom_vkl,
         a.nom_ips,
         a.revenue_type,
         a.year_op,
         a.month_op,
         a.date_op,
         a.actual_date,
         a.shifr_schet,
         case 
           when b.ssylka_fl is null then
             (select sp.ssylka_fl
              from   sp_lspv sp
              where  sp.nom_vkl = a.nom_vkl
              and    sp.nom_ips = a.nom_ips
             )
           else b.ssylka_fl
         end                                   ssylka_fl,
         coalesce(
           to_number(b.benefit_code), 
           -1 * a.shifr_schet
         )                                     benefit_code,
         coalesce(
           b.benefit_amount / 
             sum(b.benefit_amount) 
               over(
                 partition by a.nom_vkl, 
                              a.nom_ips, 
                              a.shifr_schet, 
                              a.date_op
             ) * a.amount,
           a.amount
         )                                     benefit_amount,
         a.amount                              amount_op,
         b.benefit_amount                      benefit_amount_spr,
         b.start_date,
         b.end_date,
         b.pt_rid,
         b.tdappid,
         sum(b.benefit_amount) over(partition by a.nom_vkl, a.nom_ips, a.shifr_schet, a.date_op)  benefit_amount_all,
         count(b.benefit_code) over(partition by a.nom_vkl, a.nom_ips, a.shifr_schet, a.date_op)  benefit_codes_cnt
  from   f2ndfl_benefits_v    a,
         sp_ogr_benefits_v        b
  where  1=1
  and    a.date_op between b.start_date(+) and b.end_date(+)
  and    b.shifr_schet(+) = a.shifr_schet
  and    b.nom_ips(+) = a.nom_ips
  and    b.nom_vkl(+) = a.nom_vkl
  and    a.total_amount <> 0
/
