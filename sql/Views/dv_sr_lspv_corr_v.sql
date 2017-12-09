create or replace view dv_sr_lspv_corr_v as
  select connect_by_root(d.date_op)    date_op,
         connect_by_root(d.ssylka_doc) ssylka_doc_op,
         date_op                       date_doc,
         d.ssylka_doc                  ssylka_doc,
         d.nom_vkl,
         d.nom_ips,
         d.charge_type, 
         d.det_charge_type,
         d.shifr_schet,
         d.sub_shifr_schet,
         d.sub_shifr_grp,
         d.tax_rate,
         connect_by_root(d.service_doc) service_doc,
         case
           when connect_by_root(d.ssylka_doc) = d.ssylka_doc then
             d.amount
           when d.amount = 0 then
             connect_by_root(d.amount)
           when connect_by_root(d.amount) < 0 then
             least(abs(d.amount), abs(connect_by_root(d.amount))) * sign(connect_by_root(d.amount))
           else
             connect_by_root(d.amount)
         end                                                                    amount,
         case
           when connect_by_root(d.ssylka_doc) <> d.ssylka_doc then
             d.amount
         end                                                                    source_op_amount,
         case
           when connect_by_root(d.ssylka_doc) <> d.ssylka_doc or d.service_doc = -1 then -1
         end type_op,
         connect_by_root(d.amount) corr_op_amount
  from   dv_sr_lspv_acc_v d
  where  1=1
  and    connect_by_isleaf = 1
  start with d.service_doc <> 0 and
             d.date_op > dv_sr_lspv_docs_api.get_start_date
  connect by 
    prior d.ssylka_doc = d.service_doc and
    prior d.nom_vkl = d.nom_vkl        and
    prior d.nom_ips = d.nom_ips        and
    prior d.shifr_schet = d.shifr_schet and
    prior d.sub_shifr_schet = d.sub_shifr_schet
/
