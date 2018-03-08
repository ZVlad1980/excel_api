create or replace view sp_ogr_benefits_v as
  select op.source_table,
         op.start_year,
         op.nom_vkl,
         op.nom_ips,
         op.ssylka_fl,
         op.shifr_schet,
         op.benefit_code,
         op.benefit_amount,
         op.start_date,
         op.end_date,
         op.pt_rid,
         op.tdappid,
         op.bit_start_date,
         op.bit_end_date,
         op.upper_income,
         op.end_year,
         op.regdate,
         case 
           when extract(day from op.start_date) > 25
               and not exists (
                 select 1
                 from   dv_sr_lspv_acc_rev_v p
                 where  1=1
                 and    p.date_op between op.start_date and last_day(op.start_date)
                 and    p.nom_vkl = op.nom_vkl
                 and    p.nom_ips = op.nom_ips
                 and    p.year_op = op.start_year
               )
             then 1
           else 0
         end + extract(month from op.start_date) start_month,
         least(
           coalesce(( select min(p.month_op) - 1
             from   dv_sr_lspv_acc_rev_v p
             where  p.nom_vkl = op.nom_vkl
             and    p.nom_ips = op.nom_ips
             and    p.revenue_acc > op.upper_income
             and    p.year_op = op.start_year
           ), 12),
           extract(month from op.end_date) -
             case 
               when extract(day from op.end_date) < 6
                   and not exists (
                     select 1
                     from   dv_sr_lspv_acc_rev_v p
                     where  1=1
                     and    p.date_op between trunc(op.end_date, 'MM') and op.end_date
                     and    p.nom_vkl = op.nom_vkl
                     and    p.nom_ips = op.nom_ips
                     and    p.year_op = op.start_year
                   )
                 then 1
               else 0
             end
         ) end_month
  from   sp_ogr_benefits_all_v op
/
