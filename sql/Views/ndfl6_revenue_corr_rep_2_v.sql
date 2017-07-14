create or replace view ndfl6_revenue_corr_rep_2_v as
  select d.operation_date,
         d.corrected_date,
         d.det_charge_type                                         charge_type,
         d.pen_scheme,
         sum(case d.charge_type when 'REVENUE' then amount_13 end) revenue_13,
         sum(case d.charge_type when 'BENEFIT' then amount_13 end) benefit_13,
         sum(case d.charge_type when 'TAX'     then amount_13 end) tax_13,
         sum(case d.charge_type when 'REVENUE' then amount_30 end) revenue_30,
         sum(case d.charge_type when 'TAX'     then amount_30 end) tax_30
  from   (
          select trunc(d.root_data_op)     operation_date,
                 trunc(d.data_op)          corrected_date,
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
                   when d.tax_rate = 13 then
                     d.summa
                 end                  amount_13,
                 case
                   when d.tax_rate = 30 then
                     d.summa
                 end                  amount_30
          from   ndfl_dv_sr_lspv_corr_v d
          where  d.is_leaf = 1
          and    d.service_doc <> -1
         ) d
  group by d.operation_date, d.corrected_date, d.det_charge_type, d.pen_scheme
/
