create or replace view ndfl_dv_sr_lspv_corr_v as
with flow_cash_hier as (
    select level                         lvl,             --уровень
           connect_by_isleaf             is_leaf,         --признак листа
           connect_by_root(d.data_op)    root_data_op,    --дата коррекции
           connect_by_root(d.summa)      root_summa,
           connect_by_root(d.ssylka_doc) root_ssylka_doc, --корректирующий документ
           case connect_by_isleaf
             when 1 then
               sum(case when connect_by_isleaf = 0 then d.summa end)
                 over(partition by d.nom_vkl, 
                                   d.nom_ips, 
                                   connect_by_root(d.data_op), 
                                   d.shifr_schet, 
                                   d.SUB_SHIFR_SCHET, 
                                   connect_by_root(d.ssylka_doc)
                      )
           end                           summa_corr,      --сумма корректирующих операций
           d.nom_vkl,
           d.nom_ips,
           d.data_op,
           d.shifr_schet,
           d.sub_shifr_schet,
           d.ssylka_doc,
           d.service_doc,
           d.summa
    from   fnd.dv_sr_lspv d
    start with 
           d.service_doc <> 0
      and  d.data_op between ndfl_report_api.get_start_date and ndfl_report_api.get_end_date
    connect by
      prior ssylka_doc = service_doc          and
      prior nom_vkl = nom_vkl                 and
      prior nom_ips = nom_ips                 and
      prior shifr_schet = shifr_schet         and
      prior sub_shifr_schet = sub_shifr_schet
  )
  --
  select f.lvl,
         f.is_leaf,
         f.root_ssylka_doc,
         f.root_data_op,    --дата коррекции
         f.data_op,         --дата корректируемой операции
         case
           when f.is_leaf = 1 then --если это исходная операция
             case                  --по налогу на пенсию
               when a.charge_type = 'TAX' and a.det_charge_type = 'PENSION' and 
                   ( --проверим существование операции по 83 счету с тем же доком и инверсной суммой
                     select sum(dd.summa)
                     from   fnd.dv_sr_lspv dd
                     where  1=1
                     and    dd.ssylka_doc = f.root_ssylka_doc
                     and    dd.shifr_schet = 83
                     and    dd.nom_ips = f.nom_ips
                     and    dd.nom_vkl = f.nom_vkl
                   ) = -1 * f.root_summa
                 then
                   f.root_summa
               else
                 sign(f.root_summa) * 
                   least(
                     abs(f.summa),
                     abs(f.root_summa)
                   )
             end
         end summa,     --реальная сумма корректировки в дату root_data_op
         f.summa_corr,  --общая сумма корректировки на дату root_data_op по длинным цепочкам
         a.charge_type,
         case
           when a.det_charge_type is null then
             max(case when a.charge_type not in ('TAX', 'BENEFIT') then a.det_charge_type end)
               over(partition by f.nom_vkl, f.nom_ips, f.data_op, f.ssylka_doc)
           else
             a.det_charge_type
         end  det_charge_type,
         case
           when a.charge_type = 'REVENUE' then
             max(a.tax_rate) over(partition by f.nom_vkl, f.nom_ips, f.data_op, f.ssylka_doc)
           else
             tax_rate
         end  tax_rate,
         f.NOM_VKL,
         f.NOM_IPS,
         f.SHIFR_SCHET,
         f.SUB_SHIFR_SCHET,
         f.SSYLKA_DOC,
         f.service_doc,
         f.summa summa_source, --исходная сумма операции
         (select ps.pen_scheme
          from   sp_pen_schemes_v ps
          where  ps.nom_ips = f.nom_ips
          and    ps.nom_vkl = f.nom_vkl
         ) pen_scheme
  from   flow_cash_hier  f,
         ndfl_accounts_t a
  where  1=1
  and    a.max_nom_vkl > f.nom_vkl
  and    a.sub_shifr_schet = f.sub_shifr_schet
  and    a.shifr_schet = f.shifr_schet
  and    not(f.is_leaf = 1 and f.root_ssylka_doc = f.ssylka_doc)
/
