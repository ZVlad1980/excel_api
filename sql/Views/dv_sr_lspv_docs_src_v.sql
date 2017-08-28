create or replace view dv_sr_lspv_docs_src_v as
  with dv_sr_lspv_all as (
    select dc.date_op,
           dc.ssylka_doc_op,
           dc.date_doc,
           dc.ssylka_doc,
           dc.nom_vkl,
           dc.nom_ips,
           max(dc.tax_rate)        tax_rate,
           max(dc.det_charge_type) det_charge_type,
           sum(case dc.charge_type when 'REVENUE'  then dc.amount end) revenue,
           sum(case dc.charge_type when 'BENEFIT'  then dc.amount end) benefit,
           sum(case dc.charge_type when 'TAX'      then dc.amount end) tax,
           sum(case dc.charge_type when 'TAX_CORR' then dc.amount end) tax_83,
           sum(case dc.charge_type when 'REVENUE'  then dc.source_op_amount end) source_revenue,
           sum(case dc.charge_type when 'BENEFIT'  then dc.source_op_amount end) source_benefit,
           sum(case dc.charge_type when 'TAX'      then dc.source_op_amount end) source_tax,
           max(dc.is_tax_return) is_tax_return,
           dc.type_op
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
             (select vp.gf_person
              from   fnd.vyplach_posob vp
              where  vp.tip_vypl = 1010
              and    vp.ssylka_doc = dc.ssylka_doc
              and    vp.ssylka = lspv.ssylka)
           else
             lspv.gf_person
         end gf_person,
         lspv.pen_scheme_code, 
         dc.tax_rate, 
         dc.det_charge_type,
         dc.revenue, 
         dc.benefit, 
         dc.tax, 
         dc.tax_83, 
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