create or replace view ndfl_dv_sr_lspv_v as
with dict as (
  select /*+ MATERIALIZE*/
         nso.charge_type,
         nso.det_charge_type,
         nso.tax_rate,
         nso.shifr_schet,
         nso.sub_shifr_schet,
         nso.max_nom_vkl
  from   ndfl_schet_options_v nso
)
select o.charge_type,
       case 
         when o.det_charge_type is null then
           max(case when o.charge_type not in ('TAX', 'BENEFIT') then o.det_charge_type end) 
             over(partition by d.nom_vkl, d.nom_ips, d.data_op, d.ssylka_doc)
         else 
           o.det_charge_type 
       end           det_charge_type,
       d.ssylka_doc,
       d.service_doc,
       d.nom_vkl,
       d.nom_ips,
       d.data_op,
       d.shifr_schet,
       d.sub_shifr_schet,
       d.summa,
       (select ps.pen_scheme
        from   sp_pen_schemes_v ps
        where  ps.nom_ips = d.nom_ips
        and    ps.nom_vkl = d.nom_vkl
       ) pen_scheme,
       case
         when o.charge_type = 'REVENUE' then
           max(o.tax_rate) over(partition by d.nom_vkl, d.nom_ips, d.data_op, d.ssylka_doc)
         else
           tax_rate
       end  tax_rate,
       case
         when d.service_doc = 0 then
           'N'
         when d.service_doc > 0 and
           not exists(
             select 1
             from   fnd.dv_sr_lspv dd
             where  1=1
             and    dd.shifr_schet     = d.shifr_schet
             and    dd.sub_shifr_schet = d.sub_shifr_schet
             and    dd.service_doc     = d.ssylka_doc  
             and    dd.nom_ips         = d.nom_ips
             and    dd.nom_vkl         = d.nom_vkl
           ) then
           'N'
         else
           'Y'
       end       is_correction
from   ndfl_schet_options_v o,
       fnd.dv_sr_lspv       d
where  1=1
and    d.nom_vkl <= nvl(o.max_nom_vkl, d.nom_vkl)
and    d.sub_shifr_schet = o.sub_shifr_schet
and    d.shifr_schet = o.shifr_schet
and    d.data_op between ndfl_report_api.get_start_date and ndfl_report_api.get_end_date
/
