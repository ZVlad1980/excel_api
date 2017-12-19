create or replace view dv_sr_lspv_all_v as
  select 1 rn, --корректировки
         dc.date_op,
         dc.ssylka_doc_op,
         dc.date_doc, 
         dc.ssylka_doc,
         dc.nom_vkl, 
         dc.nom_ips, 
         dc.charge_type, 
         dc.det_charge_type, 
         dc.shifr_schet, 
         dc.sub_shifr_schet, 
         dc.tax_rate,
         case
           when type_op = 0 then dc.source_op_amount
           when dc.charge_type = 'TAX' and dc.source_op_amount = 0 then dc.corr_op_amount
           else sign(dc.corr_op_amount) * least(abs(dc.corr_op_amount) - dc.source_op_amount_accum, dc.source_op_amount) 
         end amount, 
         dc.source_op_amount,
         dc.type_op,
         case
           when nvl(dc.type_op, 0) = -1 and dc.charge_type = 'TAX' 
               and (dc.det_charge_type = 'BUYBACK' 
                 or
                    exists(
                      select 1
                      from   dv_sr_lspv_acc_v da
                      where  1=1
                      and    da.charge_type = 'TAX_CORR'
                      and    da.ssylka_doc = dc.ssylka_doc_op
                      and    da.nom_ips = dc.nom_ips
                      and    da.nom_vkl = dc.nom_vkl
                    )
               ) then
             'Y'
           else
             'N'
         end is_tax_return
  from   dv_sr_lspv_corr_v dc
  where  1=1
  and    abs(dc.corr_op_amount) - dc.source_op_amount_accum > 0
  and    dc.is_leaf = 1
  and    not (dc.ssylka_doc_op = dc.ssylka_doc and dc.source_op_amount = 0 and dc.corr_op_amount = 0)
  and    case 
           when dc.charge_type = 'BENEFIT' 
             and dc.type_op = -1 and dc.root_amount <> 0 and exists (
               select 1
               from   dv_sr_lspv_acc_v da
               where  da.nom_vkl = dc.nom_vkl
               and    da.nom_ips = dc.nom_ips
               and    da.ssylka_doc = dc.root_service_doc
               and    da.date_op > dc.date_op
               and    da.amount = 0
             ) then 0
           else 1
         end = 1
  and    (
           (dc.date_op <= dv_sr_lspv_docs_api.get_end_date and dc.date_doc <= dv_sr_lspv_docs_api.get_end_date)
           or --если коррекция следующим годом - должны учитываться только корректируемые документы заданного года
           (extract(year from dc.date_op) > dv_sr_lspv_docs_api.get_year  and dc.date_doc between  dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date)
         )
 union all --83 (только коррекция рубля)
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
         null source_op_amount,
         -2,
         'N'
  from   dv_sr_lspv_83_v d
  where  coalesce(d.date_doc, d.date_op) <= to_date((dv_sr_lspv_docs_api.get_year + 1) || '1231', 'yyyymmdd')
  and    d.is_link_tax_op + d.is_link_benefit_op = 0 --нет связанных операций вычетов и налога
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
