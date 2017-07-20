create or replace view ndfl6_residents_v as
  select d.gf_person,
         d.ssylka_fl,
         d.revenue_amount,
         d.benefit,
         case
            when nvl(d.benefit, 0) <> 0 then
             least(d.benefit, d.revenue_amount)
          end benefit_used, --использованный вычет
         round((d.revenue_amount - case
                  when nvl(d.benefit, 0) <> 0 then
                   least(d.benefit, d.revenue_amount)
                  else
                   0
                end) * tax_rate_prc,
                0) tax_calc, --исчисленный налог 13%
         d.tax_retained,
         d.tax_corr_83,
         d.tax_corr_prev_year
  from   (select d.gf_person,
                 d.tax_rate_last / 100 tax_rate_prc,
                 max(d.ssylka) ssylka_fl,
                 sum(case
                        when d.charge_type = 'REVENUE' and
                             nvl(d.is_correction_prev_year, 'N') = 'N' then
                         d.summa
                      end) revenue_amount, --сумма дохода по 13%
                 sum(case
                        when d.charge_type = 'BENEFIT' then
                         d.summa
                      end) benefit,
                 sum(case
                        when d.charge_type = 'TAX' then
                         d.summa
                      end) tax_retained,
                 sum(case
                        when d.charge_type = 'TAX_CORR' then
                         d.summa
                      end) tax_corr_83,
                 sum(case
                        when d.charge_type = 'TAX' and
                             d.is_correction_prev_year = 'Y' then
                         d.summa
                      end) tax_corr_prev_year
          from   ndfl_dv_sr_lspv d
          where  1 = 1
          --and    d.det_charge_type = 'PENSION'
          and    d.tax_rate_last = 13
          group  by d.gf_person, d.tax_rate_last
         ) d
/
