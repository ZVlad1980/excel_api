create or replace view ndfl_report_errors_v as 
  select dc.data_op,
         dc.ssylka_doc,
         dc.nom_vkl,
         dc.nom_ips,
         dc.shifr_schet,
         dc.SUB_SHIFR_SCHET,
         dc.source_summa correcting_summa,
         null corrected_summa,
         null corrected_docs,
         1 error_code
  from   ndfl_dv_sr_lspv_corr_v dc
  where  1=1
  and    dc.service_doc = -1
  and    dc.is_leaf = 1
  union all
  select dc.data_op,
         dc.ssylka_doc,
         dc.nom_vkl,
         dc.nom_ips,
         dc.shifr_schet,
         dc.SUB_SHIFR_SCHET,
         dc.correcting_summa,
         dc.corrected_summa,
         dc.corrected_docs,
         2 error_code
  from   (
          select dc.root_data_op data_op, dc.nom_vkl, dc.nom_ips, dc.shifr_schet, dc.SUB_SHIFR_SCHET, dc.root_ssylka_doc ssylka_doc, dc.det_charge_type,
                 listagg(case when is_leaf = 1 then dc.ssylka_doc || ' (' || to_char(dc.source_summa) || ')' end, ' ,') within group(order by dc.ssylka_doc) corrected_docs,
                 sum(case when is_leaf = 1 then dc.source_summa end) corrected_summa,
                 max(dc.correcting_summa) correcting_summa
          from   ndfl_dv_sr_lspv_corr_v dc
          where  dc.det_charge_type in ('PENSION', 'RITUAL')
          group by dc.root_data_op, dc.nom_vkl, dc.nom_ips, dc.shifr_schet, dc.SUB_SHIFR_SCHET, dc.root_ssylka_doc, dc.det_charge_type
          having count(1) > 1
         ) dc
  where  dc.corrected_summa + dc.correcting_summa <> 0
/
