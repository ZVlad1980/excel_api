create or replace view dv_sr_lspv_docs_v as
with dv_sr_lspv_docs_ids_w as (
    select dd.id,
           coalesce(dd.type_op, 0) type_op,
           coalesce(dd.is_tax_return, 'N') is_tax_return
    from   dv_sr_lspv_docs_t dd
    where  1 = 1
    and    date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date
   union all
    select dd.id,
           dd.type_op,
           case 
             when dd.year_op > dv_sr_lspv_docs_api.get_year then
               'N'
             else
               nvl(dd.is_tax_return, 'N')
           end is_tax_return
    from   dv_sr_lspv_docs_t dd
    where  dd.type_op < 0
    and    dd.year_doc = dv_sr_lspv_docs_api.get_year
    and    dd.date_op between trunc(dv_sr_lspv_docs_api.get_end_date) + 1 and dv_sr_lspv_docs_api.get_report_date
  )
  select d.id,
         d.year_op,
         d.month_op,
         d.quarter_op,
         d.date_op,
         d.ssylka_doc_op,
         dd.type_op,
         d.year_doc,
         d.month_doc,
         d.quarter_doc,
         d.date_doc,
         d.ssylka_doc,
         d.nom_vkl,
         d.nom_ips,
         d.ssylka_fl,
         d.gf_person,
         d.pen_scheme_code,
         d.det_charge_type,
         d.revenue revenue,
         case when d.year_doc = dv_sr_lspv_docs_api.get_year then d.revenue else 0 end revenue_curr_year, --доход текущего года (включая исправления последующих периодов)
         case when d.year_doc = dv_sr_lspv_docs_api.get_year then d.benefit else 0 end benefit_curr_year, --вычеты текущего года (включая исправления последующих периодов)
         d.benefit benefit,
         case when not(dd.type_op = -2 and d.year_doc < dv_sr_lspv_docs_api.get_year)  then d.tax else 0 end tax,          --налог, кроме 83
         case when d.year_doc = dv_sr_lspv_docs_api.get_year                           then d.tax else 0 end tax_retained, --налог удержанный, без возврата в прошлые периоды
         case when dd.is_tax_return = 'Y' and d.year_op = dv_sr_lspv_docs_api.get_year then d.tax else 0 end tax_return,   --возвраты в прошлые периоды
         case when dd.type_op = -2 and d.year_doc < dv_sr_lspv_docs_api.get_year then -1 * d.tax  else 0 end tax_83,       --83
         case nn.resident when 'N' then 30 else 13 end tax_rate,
         d.tax_rate                                    tax_rate_op,
         d.source_revenue,
         d.source_benefit,
         d.source_tax,
         d.process_id,
         dd.is_tax_return
  from   dv_sr_lspv_docs_ids_w dd,
         dv_sr_lspv_docs_t     d,
         sp_tax_residents_v    nn
  where  1=1
  and    nn.fk_contragent(+) = d.gf_person
  and    d.is_delete is null
  and    d.id = dd.id
  union all
  select d.id,
         d.year_op,
         d.month_op,
         d.quarter_op,
         d.date_op,
         d.ssylka_doc_op,
         d.type_op,
         d.year_doc,
         d.month_doc,
         d.quarter_doc,
         d.date_doc,
         d.ssylka_doc,
         d.nom_vkl,
         d.nom_ips,
         d.ssylka_fl,
         d.gf_person,
         d.pen_scheme_code,
         d.det_charge_type,
         d.revenue,
         d.revenue_curr_year,
         d.benefit,
         null benefit_corr,
         d.tax,
         d.tax tax_retained,
         d.tax_return,
         null tax_83,
         d.tax_rate,
         d.tax_rate_op,
         d.source_revenue,
         d.source_benefit,
         d.source_tax,
         d.process_id,
         d.is_tax_return
  from   dv_sr_lspv_buf_v d
  where  dv_sr_lspv_docs_api.get_is_buff = 'Y'
/
