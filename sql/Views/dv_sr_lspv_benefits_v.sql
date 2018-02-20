create or replace view dv_sr_lspv_benefits_v as 
  select d.nom_vkl,
         d.nom_ips,
         d.date_op,
         case
           when d.service_doc <= 0 then
             d.date_op
           else
             (select dd.data_op
              from   dv_sr_lspv_v dd
              where  dd.nom_vkl = d.nom_vkl
              and    dd.nom_ips = d.nom_ips
              and    dd.data_op > d.date_op
              and    dd.sub_shifr_schet = d.sub_shifr_schet
              and    dd.shifr_schet = d.shifr_schet
              and    dd.ssylka_doc = d.service_doc
             )
         end actual_date,
         extract(month from d.date_op) month_op,
         extract(year from d.date_op) year_op,
         d.shifr_schet,
         d.amount,
         case
           when exists(
                  select 1
                  from   dv_sr_lspv_v dd
                  where  dd.nom_vkl = d.nom_vkl
                  and    dd.nom_ips = d.nom_ips
                  and    dd.data_op = d.date_op
                  and    dd.shifr_schet = 55
                  and    dd.ssylka_doc = d.ssylka_doc
                ) then 3
           else 1
         end revenue_type,
         sum(d.amount) over(partition by d.nom_vkl, d.nom_ips, d.shifr_schet, extract(year from d.date_op)) total_amount
  from   dv_sr_lspv_acc_v d
  where  d.charge_type = 'BENEFIT'
  and    d.amount <> 0 --это метки возврата в прошлые периоды!
/
