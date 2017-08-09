create or replace view ndfl6_lines_v as
  select d.tax_rate,
         d.nom_vkl,
         d.nom_ips,
         d.gf_person,
         d.det_charge_type,
         d.pen_scheme,
         --сумма дохода с учетом корректировок текущего налогового периода
         sum(case
               when d.charge_type = 'REVENUE' and
                    nvl(d.is_corr_curr_year, 'Y') = 'Y' then
                 d.summa
             end
         )                                                           revenue_amount,
         --сумма предоставленного вычета по счету/ФЛ-получателю!
         sum(case d.charge_type when 'BENEFIT' then d.summa end)     benefit,
         --удержанная сумма налога
         sum(case d.charge_type when 'TAX'     then d.summa end)     tax_retained,
         --исчисленная сумма налога (здесь считаем только для нерезидентов!)
         sum(case 
               when d.tax_rate = 30 and 
                    d.charge_type = 'REVENUE' then
                 round(d.summa * .3, 0) 
             end
         )                                                           tax_calc,
         --сумма корректировки налога за прошлые периоды по пенсиям
         sum(case d.charge_type when 'TAX_CORR' then d.summa end)    tax_corr_83,
         --сумма возвращенного налога за предыдущие периоды
         sum(case
               when d.is_tax_returned = 'Y' and 
                    d.is_corr_curr_year = 'N' then
                 d.summa
             end
         )                                                           tax_returned_prev,
         --сумма возвращенного налога за текущий период
         sum(case
               when d.is_tax_returned = 'Y' and 
                    d.is_corr_curr_year = 'Y' then
                 d.summa
             end
         )                                                           tax_returned_curr,
         --сумма дохода: исходная по скорректированным операциям текущего года (лучше по кварталам)
         sum(
           case
             when d.charge_type = 'REVENUE' and
                  d.is_correction = 'N'     and
                  d.service_doc <> 0        and
                  d.quarter_op = 1 then
               d.summa
           end
         )                                                           rev_source_q1,
         sum(
           case
             when d.charge_type = 'REVENUE' and
                  d.is_correction = 'N'     and
                  d.service_doc <> 0        and
                  d.quarter_op = 2 then
               d.summa
           end
         )                                                           rev_source_q2,
         sum(
           case
             when d.charge_type = 'REVENUE' and
                  d.is_correction = 'N'     and
                  d.service_doc <> 0        and
                  d.quarter_op = 3 then
               d.summa
           end
         )                                                           rev_source_q3,
         sum(
           case
             when d.charge_type = 'REVENUE' and
                  d.is_correction = 'N'     and
                  d.service_doc <> 0        and
                  d.quarter_op = 4 then
               d.summa
           end
         )                                                           rev_source_q4,
         sum(
           case
             when d.charge_type = 'REVENUE' and
                  d.is_correction = 'N'     and
                  d.service_doc <> 0    then
               d.summa
           end
         )                                                           rev_source,
         --сумма дохода: коррекция по кварталам текущего периода и предыдущих периодов (налоговых)
         sum(
           case
             when d.charge_type = 'REVENUE' and
                  d.is_corr_curr_year = 'N' then
               d.summa
           end
         )                                                           rev_corr_prev,
         sum(
           case
             when d.charge_type = 'REVENUE' and
                  d.is_corr_curr_year = 'Y' and
                  d.quarter_op = 1 then
               d.summa
           end
         )                                                           rev_corr_q1,
         sum(
           case
             when d.charge_type = 'REVENUE' and
                  d.is_corr_curr_year = 'Y' and
                  d.quarter_op = 2 then
               d.summa
           end
         )                                                           rev_corr_q2,
         sum(
           case
             when d.charge_type = 'REVENUE' and
                  d.is_corr_curr_year = 'Y' and
                  d.quarter_op = 3 then
               d.summa
           end
         )                                                           rev_corr_q3,
         sum(
           case
             when d.charge_type = 'REVENUE' and
                  d.is_corr_curr_year = 'Y' and
                  d.quarter_op = 4 then
               d.summa
           end
         )                                                           rev_corr_q4
  from   ndfl_dv_sr_lspv_v d
  group  by 
    d.tax_rate,
    d.nom_vkl,
    d.nom_ips,
    d.gf_person,
    d.det_charge_type,
    d.pen_scheme
/
