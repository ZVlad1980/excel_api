create or replace view dv_sr_lspv_all_v as
  select 1 rn, --корректировки
         d.date_op,
         d.ssylka_doc_op,
         d.date_doc,
         d.ssylka_doc,
         d.nom_vkl,
         d.nom_ips,
         d.charge_type,
         d.det_charge_type,
         d.shifr_schet,
         d.sub_shifr_schet,
         d.tax_rate,
         d.amount,
         d.source_op_amount,
         d.type_op,
         case
           when nvl(d.type_op, 0) = -1 and d.charge_type = 'TAX' 
               and (d.det_charge_type = 'BUYBACK' 
                 or
                    exists(
                      select 1
                      from   dv_sr_lspv_acc_v da
                      where  1=1
                      and    abs(da.amount) - abs(d.amount) < .01
                      and    da.charge_type = 'TAX_CORR'
                      and    da.ssylka_doc = d.ssylka_doc_op
                      and    da.nom_ips = d.nom_ips
                      and    da.nom_vkl = d.nom_vkl
                    )
               ) then
             'Y'
           else
             'N'
         end is_tax_return--*/
  from   dv_sr_lspv_corr_v d
  where  d.date_doc <= dv_sr_lspv_docs_api.get_report_date
 union all --83 (кроме возврата по 231)
  select 1 rn,
         d.date_op,
         d.ssylka_doc ssylka_doc_op,
         coalesce(d.date_doc, trunc(d.date_op, 'Y') - 1) date_doc ,
         d.ssylka_doc,
         d.nom_vkl,
         d.nom_ips,
         d.charge_type,
         d.det_charge_type,
         d.shifr_schet,
         d.sub_shifr_schet,
         d.tax_rate,
         d.amount,
         d.benefit source_op_amount,
         -2,
         'N'
  from   dv_sr_lspv_83_v d
  where  coalesce(d.date_doc, trunc(d.date_op, 'Y') - 1) <= dv_sr_lspv_docs_api.get_report_date
 union all --прямые операции
  select case d.sub_shifr_grp
           when 0 then
             row_number()
             over(
               partition by d.nom_vkl,
                            d.nom_ips,
                            d.date_op,
                            d.shifr_schet,
                            d.ssylka_doc
               order by     d.sub_shifr_schet
             )
           else 1
         end            rn,
         d.date_op,
         d.ssylka_doc   ssylka_doc_op,
         d.date_op      date_doc,
         d.ssylka_doc,
         d.nom_vkl,
         d.nom_ips,
         d.charge_type,
         d.det_charge_type,
         d.shifr_schet,
         d.sub_shifr_schet,
         d.tax_rate,
         d.amount,
         null source_op_amount,
         null type_op,
         null is_tax_return
  from   dv_sr_lspv_acc_v d
  where  1=1
  and    d.charge_type <> 'TAX_CORR'
  and    d.service_doc = 0
  and    d.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date
/
