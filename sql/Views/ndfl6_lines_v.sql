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
         --сумма корректировки (в т.ч. возвращенного) налога за предыдущие периоды
         sum(case
               when d.charge_type = 'TAX'  and
                    d.is_corr_curr_year = 'N' then
                 d.summa
             end
         )                                                           tax_corr_prev,
         --сумма корректировки (в т.ч. возвращенного) налога за текущий период
         sum(case
               when d.charge_type = 'TAX' and 
                    d.is_corr_curr_year = 'Y' then
                 d.summa
             end
         )                                                           tax_corr_curr
  from   ndfl_dv_sr_lspv_v d
  group  by 
    d.tax_rate,
    d.nom_vkl,
    d.nom_ips,
    d.gf_person,
    d.det_charge_type,
    d.pen_scheme
/
