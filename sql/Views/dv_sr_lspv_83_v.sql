create or replace view dv_sr_lspv_83_v as
select d.nom_vkl,
       d.nom_ips,
       d.ssylka_doc,
       min(case d.charge_type when 'TAX_CORR' then d.service_doc end)     service_doc,
       min(case d.charge_type when 'TAX_CORR' then d.date_op end)         date_op,
       min(case d.charge_type when 'TAX_CORR' then d.shifr_schet end)     shifr_schet,
       min(case d.charge_type when 'TAX_CORR' then d.sub_shifr_schet end) sub_shifr_schet,
       min(case d.charge_type when 'TAX_CORR' then d.charge_type end)     charge_type,
       min(case d.charge_type when 'TAX_CORR' then d.det_charge_type end) det_charge_type,
       min(case when d.charge_type = 'BENEFIT' then d.date_op end)        date_doc,
       sum(case d.charge_type when 'TAX_CORR' then d.amount end)          amount,
       max(d.tax_rate)                                                    tax_rate,
       sum(case when d.charge_type = 'TAX' then 1 else 0 end)             is_link_tax_op,
       sum(case when d.charge_type = 'BENEFIT' then 1 else 0 end)         is_link_benefit_op
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
/
