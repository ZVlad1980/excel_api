create or replace view dv_sr_lspv_corr_v as
  with d83 as (
    select d83.date_op,
           d83.ssylka_doc,
           d83.service_doc,
           d83.date_doc,
           d83.nom_vkl,
           d83.nom_ips,
           d83.charge_type,
           d83.det_charge_type,
           d83.shifr_schet,
           d83.sub_shifr_schet,
           d83.amount
    from   dv_sr_lspv_83_v d83
    where  1=1
    and    d83.is_link_benefit_op = 1
    and    d83.is_link_tax_op = 0
  )
  select max(connect_by_root(d.date_op)) over(partition by connect_by_root(d.ssylka_doc), d.nom_vkl, d.nom_ips) date_op, 
         connect_by_root(d.ssylka_doc)               ssylka_doc_op,
         case 
           when d.charge_type = 'TAX_CORR' then
             (select d83.date_doc
              from   d83
              where  d83.nom_vkl = d.nom_vkl
              and    d83.nom_ips = d.nom_ips
              and    d83.ssylka_doc = d.ssylka_doc
             )
           else date_op
         end                                         date_doc,
         d.ssylka_doc,
         d.nom_vkl,
         d.nom_ips,
         d.charge_type,
         d.det_charge_type,
         d.shifr_schet,
         d.sub_shifr_schet,
         d.tax_rate,
         d.amount                                    source_op_amount,
         sum(d.amount) 
           over(
             partition by d.nom_vkl, 
                          d.nom_ips, 
                          connect_by_root(d.ssylka_doc), 
                          d.shifr_schet, 
                          d.sub_shifr_schet,
                          connect_by_isleaf 
             order by     d.date_op desc 
             rows unbounded preceding 
           ) - d.amount                              source_op_amount_accum,
         case connect_by_root(d.amount)
           when 0 then
            sum(case level
                  when 2 then
                   d.amount
                  else 0
                end
            ) over(
              partition by 
                connect_by_root(d.ssylka_doc),
                connect_by_root(d.date_op),
                d.nom_vkl,
                d.nom_ips,
                d.shifr_schet,
                d.sub_shifr_schet
           )
           else
            connect_by_root(d.amount)
         end                                         corr_op_amount,
         level                                       lvl,
         connect_by_isleaf                           is_leaf,
         connect_by_root(d.service_doc)              root_service_doc,
         connect_by_root(d.amount)                   root_amount,
         case when d.charge_type = 'TAX_CORR' then -2 when connect_by_root(d.ssylka_doc) = d.ssylka_doc then null else -1 end type_op
         --lead(connect_by_root(d.amount))over(partition by d.nom_vkl, d.nom_ips, d.ssylka_doc, d.charge_type order by level) base_root_amount
  from   dv_sr_lspv_acc_v d
  start with (d.nom_vkl, d.nom_ips, d.date_op, d.shifr_schet, d.sub_shifr_schet, d.ssylka_doc) in (
    select dd.nom_vkl, dd.nom_ips, dd.date_op, dd.shifr_schet, dd.sub_shifr_schet, dd.ssylka_doc
    from   dv_sr_lspv_acc_v dd
    where  dd.service_doc <> 0
    and    dd.date_op >= dv_sr_lspv_docs_api.get_start_date
    union
    select dd.nom_vkl, dd.nom_ips, dd.date_op, dd.shifr_schet, dd.sub_shifr_schet, dd.ssylka_doc
    from   dv_sr_lspv_acc_v dd
    where  (dd.nom_vkl, dd.nom_ips, dd.ssylka_doc) in (
             select d83.nom_vkl, d83.nom_ips, d83.ssylka_doc
             from   d83 d83
             where  d83.service_doc = 0
           )
    and    dd.charge_type = 'BENEFIT'
    and    dd.date_op < dv_sr_lspv_docs_api.get_start_date
    union
    select dd.nom_vkl, dd.nom_ips, dd.date_op, dd.shifr_schet, dd.sub_shifr_schet, dd.ssylka_doc
    from   d83 dd
  )
  connect by prior d.ssylka_doc = d.service_doc
      and    prior d.nom_vkl = d.nom_vkl
      and    prior d.nom_ips = d.nom_ips
      and    prior d.shifr_schet = d.shifr_schet
      and    prior d.sub_shifr_schet = d.sub_shifr_schet
/
