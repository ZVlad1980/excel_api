create or replace view ndfl6_revenue_rep_2_v as
  select row_number()over(order by d.operation_date, case d.det_charge_type when 'PENSION' then 1 when 'BUYBACK' then 2 else 3 end, d.pen_scheme) block_num,
         d.operation_date,
         d.transfer_date,
         d.det_charge_type                                         charge_type,
         d.pen_scheme,
         sum(case d.charge_type when 'REVENUE' then amount_13 end) revenue_13,
         sum(case d.charge_type when 'BENEFIT' then amount_13 end) benefit_13,
         sum(case d.charge_type when 'TAX'     then amount_13 end) tax_13,
         sum(case d.charge_type when 'REVENUE' then amount_30 end) revenue_30,
         sum(case d.charge_type when 'TAX'     then amount_30 end) tax_30
  from   (
          select trunc(d.data_op)     operation_date,
                 trunc(d.data_op) + 1 transfer_date,
                 d.charge_type,
                 d.det_charge_type,
                 d.pen_scheme,
                 d.ssylka_doc,
                 d.service_doc,
                 d.nom_vkl,
                 d.nom_ips,
                 d.shifr_schet,
                 d.sub_shifr_schet,
                 case
                   when d.tax_rate_op = 13 and d.is_correction = 'N' then
                     d.summa
                 end                  amount_13,
                 case
                   when d.tax_rate_op = 30 and d.is_correction = 'N' then
                     d.summa
                 end                  amount_30
          from   ndfl_dv_sr_lspv_v d
         ) d
  group by d.operation_date, d.transfer_date, d.det_charge_type, d.pen_scheme
/
