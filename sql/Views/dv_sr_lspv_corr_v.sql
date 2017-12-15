create or replace view dv_sr_lspv_corr_v as
  select d.date_op,
         d.ssylka_doc_op,
         d.date_doc,
         d.ssylka_doc,
         d.nom_vkl,
         d.nom_ips,
         d.charge_type, 
         d.det_charge_type,
         d.shifr_schet,
         d.sub_shifr_schet,
         d.sub_shifr_grp,
         d.tax_rate,
         d.service_doc,
         case
           when d.root_amount = 0 then
             0
           when d.source_op_amount = 0 then
             abs(root_amount)
           when (abs(d.corr_op_amount) - abs(d.source_op_amount_accum)) > abs(d.source_op_amount) then
             abs(d.source_op_amount)
           else abs(d.corr_op_amount) - abs(d.source_op_amount_accum)
         end * sign(d.corr_op_amount) amount,
         d.source_op_amount,
         d.source_op_amount_accum,
         d.corr_op_amount,
         d.root_amount,
         d.type_op,
         d.is_leaf,
         case 
           when d.charge_type = 'BENEFIT' then
             case 
               when d.type_op = -1 and
                 exists(
                   select 1
                   from   dv_sr_lspv_acc_v dd
                   where  1=1
                   and    dd.charge_type = 'TAX_CORR'
                           --(dd.charge_type = 'BENEFIT' and dd.amount = 0)
                   and    dd.ssylka_doc = d.ssylka_doc_op
                   and    dd.date_op > d.date_op
                   and    dd.nom_vkl = d.nom_vkl
                   and    dd.nom_ips = d.nom_ips
                 ) then 1
               when d.type_op is null and exists (
                   select 1
                   from   dv_sr_lspv_acc_v dd
                   where  1=1
                   and    dd.charge_type = 'BENEFIT'
                   and    dd.amount = 0
                   and    dd.ssylka_doc = d.service_doc
                   and    dd.date_op > d.date_op
                   and    dd.nom_vkl = d.nom_vkl
                   and    dd.nom_ips = d.nom_ips
                 )
                 then 1
               else 0
             end
           else
             0
         end exists_83
  from   (
          select connect_by_root(d.date_op)    date_op,
                 connect_by_root(d.ssylka_doc) ssylka_doc_op,
                 date_op                       date_doc,
                 d.ssylka_doc,
                 d.nom_vkl,
                 d.nom_ips,
                 d.charge_type, 
                 d.det_charge_type,
                 d.shifr_schet,
                 d.sub_shifr_schet,
                 d.sub_shifr_grp,
                 d.tax_rate,
                 connect_by_root(d.service_doc) service_doc,
                 d.amount                       source_op_amount,
                 sum(d.amount)over(
                   partition by connect_by_isleaf, connect_by_root(d.ssylka_doc), connect_by_root(d.date_op), d.nom_vkl, d.nom_ips, d.shifr_schet, d.sub_shifr_schet 
                   order by d.date_op desc
                 ) - d.amount                   source_op_amount_accum,
                 case connect_by_root(d.amount) 
                   when 0 then
                     sum(case level when 2 then d.amount end) over(partition by connect_by_root(d.ssylka_doc), connect_by_root(d.date_op), d.nom_vkl, d.nom_ips, d.shifr_schet, d.sub_shifr_schet)
                   else connect_by_root(d.amount)
                 end                            corr_op_amount,
                 connect_by_root(d.amount)      root_amount,
                 case
                   when connect_by_root(d.ssylka_doc) <> d.ssylka_doc or d.service_doc = -1 then -1
                 end                            type_op,
                 level                          lvl,
                 connect_by_isleaf              is_leaf
          from   dv_sr_lspv_acc_v d
          where  1=1
          start with d.service_doc <> 0 and
                     d.date_op > dv_sr_lspv_docs_api.get_start_date
          connect by 
            prior d.ssylka_doc = d.service_doc   and
            prior d.nom_vkl = d.nom_vkl          and
            prior d.nom_ips = d.nom_ips          and
            prior d.shifr_schet = d.shifr_schet  and
            prior d.sub_shifr_schet = d.sub_shifr_schet
         ) d
  where  1=1
  and   (d.root_amount <> 0 and (trim((abs(d.corr_op_amount) - abs(d.source_op_amount_accum))) > 0 and d.is_leaf = 1) or (d.root_amount = 0 and lvl = 2))
/
