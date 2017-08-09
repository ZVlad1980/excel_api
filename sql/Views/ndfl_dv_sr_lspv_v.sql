create or replace view ndfl_dv_sr_lspv_v as
with cash_flow as (
  select d.ssylka_doc,
         d.service_doc,
         d.nom_vkl,
         d.nom_ips,
         d.data_op,
         d.shifr_schet,
         d.sub_shifr_schet,
         d.summa,
         a.charge_type,
         -- Определяем тип выплаты для вычетов (см. ndfl_schet_options_t) !
         coalesce(
           a.det_charge_type,
           max(case when a.charge_type = 'REVENUE' then a.det_charge_type end)
               over(partition by d.nom_vkl, d.nom_ips, d.data_op, d.ssylka_doc)
         ) det_charge_type,
         --
         case
           when a.charge_type = 'REVENUE' then
             max(a.tax_rate) over(partition by d.nom_vkl, d.nom_ips, d.data_op, d.ssylka_doc)
           else
             a.tax_rate
         end  tax_rate_op,
         --
         case
           when d.service_doc <> 0 then
             (select min(case when d.ssylka_doc <> dd.ssylka_doc then dd.data_op end)
              from   fnd.dv_sr_lspv dd
              start with 
                dd.nom_vkl = d.nom_vkl and
                dd.nom_ips = d.nom_ips and
                dd.shifr_schet = d.shifr_schet and
                dd.sub_shifr_schet = d.sub_shifr_schet and
                dd.data_op = d.data_op and
                dd.ssylka_doc = d.ssylka_doc 
              connect by 
                prior dd.ssylka_doc = dd.service_doc and
                prior dd.nom_vkl = dd.nom_vkl and
                prior dd.nom_ips = dd.nom_ips and
                prior dd.shifr_schet = dd.shifr_schet and
                prior dd.sub_shifr_schet = dd.sub_shifr_schet
              )
         end date_op_corrected
  from   fnd.dv_sr_lspv       d,
         ndfl_accounts_t      a
  where  1=1
  and    d.nom_vkl < a.max_nom_vkl
  and    d.sub_shifr_schet = a.sub_shifr_schet
  and    d.shifr_schet = a.shifr_schet
  and    d.data_op between ndfl_report_api.get_start_date and ndfl_report_api.get_end_date
),
cash_flow_person as (
  select d.ssylka_doc,
         d.service_doc,
         d.nom_vkl,
         d.nom_ips,
         d.data_op,
         extract(month from d.data_op) month_op,
         d.shifr_schet,
         d.sub_shifr_schet,
         d.charge_type,
         d.det_charge_type,
         d.summa,
         d.tax_rate_op,
         case when d.date_op_corrected is not null then 'Y' else 'N' end is_correction,
         case 
           when d.charge_type = 'TAX' and d.date_op_corrected is not null then
             case
               when (d.det_charge_type = 'BUYBACK') or
                 (d.summa + 
                   sum(
                     case 
                       when d.charge_type = 'TAX_CORR' then  d.summa
                     end
                   ) over(partition by d.nom_vkl, d.nom_ips, d.ssylka_doc)
                 ) = 0
               then
                 'Y'
               else 
                 'N'
             end
         end is_tax_returned,
         --
         case 
           when  d.date_op_corrected is not null then
             case
               when trunc(d.date_op_corrected, 'Y') = trunc(d.data_op, 'Y') then 'Y'
               else 'N'
             end
         end is_corr_curr_year, --коррекция текущего года
         --
         f.ssylka ssylka_fl,
         f.pen_scheme_code,
         f.pen_scheme,
         --
         case --Для ритуальных выплат и наследований - определяем контрагента, получившего выплату
           when d.det_charge_type = 'RITUAL' then
             (select vp.gf_person
              from   fnd.vyplach_posob vp
              where  vp.tip_vypl = 1010
              and    vp.ssylka_doc = d.ssylka_doc
              and    vp.ssylka = f.ssylka)
           else
             f.gf_person
         end gf_person,
         --
         f.gf_person gf_person_ips,
         d.date_op_corrected,
         extract(month from d.date_op_corrected) month_op_corrected
  from   cash_flow            d,
         sp_fiz_litz_lspv_v   f
  where  1=1
  and    f.nom_ips(+) = d.nom_ips
  and    f.nom_vkl(+) = d.nom_vkl
)
--
select ceil(d.month_op / 3) quarter_op,
       d.month_op,
       d.data_op,
       --дата первой корректируемой операции
       d.date_op_corrected,
       d.month_op_corrected,
       ceil(d.month_op_corrected / 3) quarter_op_corrected,
       --счет
       d.nom_vkl,
       d.nom_ips,
       --реальное физ лицо
       d.gf_person,
       --тип операции: налог/доход/бенефит
       d.charge_type,
       --тип дохода: пенсия/выкуп/ритуал
       d.det_charge_type,
       --пенсионная схема
       d.pen_scheme_code,
       d.pen_scheme,
       --сумма операции
       d.summa,
       --реальная ставка налога на конец периода
       first_value(d.tax_rate_op)
         over(
           partition by d.gf_person
           order     by case when d.charge_type = 'REVENUE' then 0 else 1 end, d.data_op desc
         ) tax_rate,
       --
       d.tax_rate_op,
       d.ssylka_doc,
       d.service_doc,
       d.shifr_schet,
       d.sub_shifr_schet,
       d.ssylka_fl ,
       d.gf_person_ips,
       d.is_correction,
       d.is_tax_returned,
       d.is_corr_curr_year
from   cash_flow_person d
/
