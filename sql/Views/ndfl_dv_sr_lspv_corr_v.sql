create or replace view ndfl_dv_sr_lspv_corr_v as
with flow_cash_hier as (
    select level                         lvl,
           connect_by_isleaf             is_leaf,
           connect_by_root(d.data_op)    root_data_op,
           connect_by_root(d.ssylka_doc) root_ssylka_doc,
           connect_by_root(d.summa)      root_summa,
           sum(case when connect_by_isleaf = 0 then d.summa end)
             over(partition by d.nom_vkl, d.nom_ips, connect_by_root(d.data_op), d.shifr_schet, d.SUB_SHIFR_SCHET, connect_by_root(d.ssylka_doc)) correcting_summa,
           d.NOM_VKL,
           d.NOM_IPS,
           d.data_op,
           d.SHIFR_SCHET,
           d.SUB_SHIFR_SCHET,
           d.SSYLKA_DOC,
           d.service_doc,
           d.summa
    from   fnd.dv_sr_lspv d
    start with
          (d.NOM_VKL, d.NOM_IPS, d.data_op, d.SHIFR_SCHET, d.SUB_SHIFR_SCHET, d.SSYLKA_DOC) in
            (select cf.NOM_VKL, cf.NOM_IPS, cf.data_op, cf.SHIFR_SCHET, cf.SUB_SHIFR_SCHET, cf.SSYLKA_DOC
             from   ndfl_dv_sr_lspv_v cf
             where  cf.is_correction = 'Y'
             and    cf.service_doc = -1
            )
    connect by
      prior ssylka_doc = service_doc          and
      prior nom_vkl = nom_vkl                 and
      prior nom_ips = nom_ips                 and
      prior SHIFR_SCHET = SHIFR_SCHET         and
      prior SUB_SHIFR_SCHET = SUB_SHIFR_SCHET
  )
  --
  select f.lvl,
         f.is_leaf,
         f.root_ssylka_doc,
         f.root_data_op,
         f.root_summa,
         f.data_op,
         case
           when f.is_leaf = 1 then
             case sign(f.correcting_summa) 
               when 1 then f.correcting_summa
               else -1 * least(abs(f.summa), abs(f.correcting_summa))
           end
         end summa,
         f.correcting_summa,
         o.charge_type,
         case
           when o.det_charge_type is null then
             max(case when o.charge_type not in ('TAX', 'BENEFIT') then o.det_charge_type end)
               over(partition by f.nom_vkl, f.nom_ips, f.data_op, f.ssylka_doc)
           else
             o.det_charge_type
         end           det_charge_type,
         case
           when o.charge_type = 'REVENUE' then
             max(o.tax_rate) over(partition by f.nom_vkl, f.nom_ips, f.data_op, f.ssylka_doc)
           else
             tax_rate
         end  tax_rate,
         f.NOM_VKL,
         f.NOM_IPS,
         f.SHIFR_SCHET,
         f.SUB_SHIFR_SCHET,
         f.SSYLKA_DOC,
         f.service_doc,
         f.summa source_summa,
         (select ps.pen_scheme
          from   sp_pen_schemes_v ps
          where  ps.nom_ips = f.nom_ips
          and    ps.nom_vkl = f.nom_vkl
         ) pen_scheme
  from   flow_cash_hier         f,
         ndfl_schet_options_v   o
  where  1=1
  and    o.sub_shifr_schet = f.SUB_SHIFR_SCHET
  and    o.shifr_schet = f.shifr_schet
/
