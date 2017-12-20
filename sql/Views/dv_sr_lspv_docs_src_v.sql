create or replace view dv_sr_lspv_docs_src_v as
  with dv_sr_lspv_all as (
    select dc.type_op,
           dc.date_op,
           dc.ssylka_doc_op,
           dc.date_doc,
           dc.ssylka_doc,
           dc.nom_vkl,
           dc.nom_ips,
           max(dc.tax_rate)        tax_rate,
           max(dc.det_charge_type) det_charge_type,
           sum(case dc.charge_type when 'REVENUE'  then dc.amount end) revenue,
           sum(case dc.charge_type 
                 when 'BENEFIT'  then case when (dc.type_op = -1 and dc.amount = 0) then dc.source_op_amount else dc.amount end
               end
           )                                                           benefit,
           sum(case dc.charge_type when 'TAX'      then dc.amount end) tax,
           sum(case dc.charge_type when 'TAX_CORR' then dc.amount end) tax_83,
           sum(case dc.charge_type when 'REVENUE'  then dc.source_op_amount end) source_revenue,
           sum(case dc.charge_type when 'BENEFIT'  then dc.source_op_amount end) source_benefit,
           sum(case dc.charge_type when 'TAX' then dc.source_op_amount end) source_tax,
           max(dc.is_tax_return) is_tax_return
    from   dv_sr_lspv_all_v dc
    where  1=1
    group by dc.date_op,
           dc.ssylka_doc_op,
           dc.date_doc,
           dc.ssylka_doc,
           dc.nom_vkl,
           dc.nom_ips,
           dc.type_op,
           dc.rn
    having sum(dc.amount) is not null
  )
  select dc.date_op,
         dc.ssylka_doc_op, 
         dc.type_op,
         dc.date_doc, 
         dc.ssylka_doc, 
         dc.nom_vkl, 
         dc.nom_ips, 
         lspv.ssylka ssylka_fl,
         case dc.det_charge_type
           when 'RITUAL' then
             (select rp.fk_contragent
              from   sp_ritual_pos rp
              where  1=1
              and    rp.ssylka = lspv.ssylka)
           else
             lspv.gf_person
         end gf_person,
         lspv.pen_scheme_code, 
         dc.tax_rate, 
         case
           when dc.det_charge_type is null then min(dc.det_charge_type) over(partition by dc.ssylka_doc_op, dc.nom_vkl, dc.nom_ips)
           else dc.det_charge_type
         end det_charge_type,
         dc.revenue, 
         dc.benefit, 
         nvl(dc.tax, dc.tax_83) tax, 
         dc.source_revenue, 
         dc.source_benefit, 
         dc.source_tax,
         dc.is_tax_return
  from   dv_sr_lspv_all     dc,
         sp_fiz_litz_lspv_v lspv
  where  1 = 1
  and    lspv.nom_ips = dc.nom_ips
  and    lspv.nom_vkl = dc.nom_vkl
/
