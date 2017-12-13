create or replace view dv_sr_lspv_83_v as
select d.nom_vkl,
       d.nom_ips,
       d.ssylka_doc ssylka_doc,
       min(case d.charge_type when 'TAX_CORR' then d.date_op end) date_op,
       min(case d.charge_type when 'TAX_CORR' then d.shifr_schet end) shifr_schet,
       min(case d.charge_type when 'TAX_CORR' then d.sub_shifr_schet end) sub_shifr_schet,
       min(case d.charge_type when 'TAX_CORR' then d.charge_type end) charge_type,
       min(case d.charge_type when 'TAX_CORR' then d.det_charge_type end) det_charge_type,
       min(case when d.charge_type = 'BENEFIT' then d.date_op end) date_doc,
       sum(case when d.charge_type = 'BENEFIT' then d.amount end) benefit,
       sum(case d.charge_type when 'TAX_CORR' then d.amount end) amount,
       max(d.tax_rate) tax_rate
from   dv_sr_lspv_acc_v d
where  1=1
and    (d.nom_vkl, d.nom_ips, d.ssylka_doc) in (
          select dd.nom_vkl,
                 dd.nom_ips,
                 dd.ssylka_doc
          from   dv_sr_lspv_acc_v dd
          where  1=1
          and    dd.charge_type = 'TAX_CORR'
          and    dd.date_op >= dv_sr_lspv_docs_api.get_start_date
       )
group by d.nom_vkl,
       d.nom_ips,
       d.ssylka_doc
having sum(case when d.charge_type = 'TAX' then 1 end) is null   
/
/*  with tax_corr as (
    select d.charge_type, 
           d.det_charge_type,
           d.tax_rate, 
           d.date_op, 
           d.ssylka_doc, 
           d.service_doc, 
           d.nom_vkl, 
           d.nom_ips, 
           d.shifr_schet, 
           d.sub_shifr_schet,
           d.amount, 
           d.kod_oper, 
           d.sub_shifr_grp,
           (select 1
            from   dv_sr_lspv_acc_v dd--fnd.dv_sr_lspv dd
            where  1=1
            and    dd.service_doc <> 0
            and    dd.charge_type = 'TAX'
            and    dd.ssylka_doc = d.ssylka_doc
            and    dd.nom_ips = d.nom_ips
            and    dd.nom_vkl = d.nom_vkl
           ) is_tax_return
    from   dv_sr_lspv_acc_v d
    where  1 = 1
    and    d.charge_type = 'TAX_CORR'
    and    d.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date
  )
  select d.charge_type, 
         d.det_charge_type,
         d.tax_rate, 
         d.date_op, 
         d.ssylka_doc, 
         d.service_doc, 
         d.nom_vkl, 
         d.nom_ips, 
         d.shifr_schet, 
         d.sub_shifr_schet,
         d.amount, 
         d.kod_oper, 
         d.sub_shifr_grp
  from   tax_corr d
  where  1 = 1
  and    d.is_tax_return is null
  and    d.charge_type = 'TAX_CORR'
  and    d.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date;
*/
