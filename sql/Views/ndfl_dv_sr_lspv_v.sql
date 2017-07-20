create or replace view ndfl_dv_sr_lspv_v as
with schet_options as (
  select /*+ MATERIALIZE*/
         nso.charge_type,
         nso.det_charge_type,
         nso.tax_rate,
         nso.shifr_schet,
         nso.sub_shifr_schet,
         nso.max_nom_vkl
  from   ndfl_schet_options_v nso
),
cash_flow as (
  select d.ssylka_doc,
         d.service_doc,
         d.nom_vkl,
         d.nom_ips,
         d.data_op,
         d.shifr_schet,
         d.sub_shifr_schet,
         d.summa,
         o.charge_type,
         -- Определяем тип выплаты для вычетов (см. ndfl_schet_options_v) !
         --  !!! Аналогичная логиа используется при вычислении поля gf_person (см. ниже)
         coalesce(
           o.det_charge_type,
           max(case when o.charge_type = 'REVENUE' then o.det_charge_type end)
               over(partition by d.nom_vkl, d.nom_ips, d.data_op, d.ssylka_doc)
         ) det_charge_type,
         --
         case
           when o.charge_type = 'REVENUE' then
             max(o.tax_rate) over(partition by d.nom_vkl, d.nom_ips, d.data_op, d.ssylka_doc)
           else
             o.tax_rate
         end  tax_rate_op,
         --
         case
           when d.service_doc <> 0 then
             (select trunc(min(case when d.ssylka_doc <> dd.ssylka_doc then dd.data_op end), 'Y')
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
         end year_op_corrected
  from   fnd.dv_sr_lspv       d,
         schet_options        o,--ndfl_schet_options_v o,
         sp_fiz_litz_lspv_v   f
  where  1=1
  and    f.nom_ips(+) = d.nom_ips
  and    f.nom_vkl(+) = d.nom_vkl
  and    d.nom_vkl <= nvl(o.max_nom_vkl, d.nom_vkl)
  and    d.sub_shifr_schet = o.sub_shifr_schet
  and    d.shifr_schet = o.shifr_schet
  and    d.data_op between ndfl_report_api.get_start_date and ndfl_report_api.get_end_date
),
cash_flow_person as (
  select d.ssylka_doc,
         d.service_doc,
         d.nom_vkl,
         d.nom_ips,
         d.data_op,
         d.shifr_schet,
         d.sub_shifr_schet,
         d.charge_type,
         d.det_charge_type,
         d.summa,
         d.tax_rate_op,
         case when d.year_op_corrected is not null then 'Y' else 'N' end is_correction,
         case 
           when d.charge_type = 'TAX' and d.year_op_corrected is not null then
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
           when  d.year_op_corrected is not null then
             case
               when d.year_op_corrected = trunc(d.data_op, 'Y') then 'Y'
               else 'N'
             end
         end is_corr_curr_year, --коррекция текущего года
         --
         f.ssylka,
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
         f.gf_person gf_person_ips
  from   cash_flow            d,
         sp_fiz_litz_lspv_v   f
  where  1=1
  and    f.nom_ips(+) = d.nom_ips
  and    f.nom_vkl(+) = d.nom_vkl
)
--
select d.nom_vkl,
       d.nom_ips,
       d.gf_person,
       d.charge_type,
       d.det_charge_type,
       d.pen_scheme,
       d.data_op,
       d.summa,
       first_value(d.tax_rate_op)
         over(
           partition by d.gf_person
           order     by case when d.charge_type = 'REVENUE' then 0 else 1 end, d.data_op desc
         ) tax_rate,
       d.tax_rate_op,
       d.ssylka_doc,
       d.service_doc,
       d.shifr_schet,
       d.sub_shifr_schet,
       d.ssylka ssylka_fl,
       d.gf_person_ips,
       d.is_correction,
       d.is_tax_returned,
       d.is_corr_curr_year --коррекция текущего года
from   cash_flow_person d
/
