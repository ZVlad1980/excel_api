create or replace view dv_sr_lspv_errors_v as
  with corrections as (
    select c.date_op, 
           c.ssylka_doc_op, 
           c.date_doc, 
           c.ssylka_doc, 
           c.nom_vkl, 
           c.nom_ips, 
           c.charge_type, 
           c.det_charge_type, 
           c.shifr_schet, 
           c.sub_shifr_schet, 
           c.sub_shifr_grp, 
           c.tax_rate, 
           c.service_doc, 
           c.amount, 
           c.source_op_amount,
           c.type_op, 
           c.corr_op_amount
    from   dv_sr_lspv_corr_v c
    where  c.type_op = -1
  )
  --нет ссылок на корректирующую операцию
  select dc.date_op,
         dc.ssylka_doc_op ssylka_doc,
         dc.nom_vkl,
         dc.nom_ips,
         dc.shifr_schet,
         dc.SUB_SHIFR_SCHET,
         dc.amount,
         null source_amount,
         null ssylka_fl,
         null fio,
         1 error_code
  from   corrections dc
  where  dc.type_op = -1
  and    dc.ssylka_doc_op = dc.ssylka_doc
  union all
  --сумма коррекции не соответствует сумме исходных операций (для двойных цепочек)
  select dc.date_op,
         dc.ssylka_doc_op ssylka_doc,
         dc.nom_vkl,
         dc.nom_ips,
         dc.shifr_schet,
         dc.SUB_SHIFR_SCHET,
         max(dc.corr_op_amount) amount,
         sum(dc.amount)         source_amount,
         null ssylka_fl,
         null fio,
         2 error_code
  from   corrections dc
  where  dc.type_op = -1
  group by dc.date_op, dc.ssylka_doc_op, dc.nom_vkl, dc.nom_ips, dc.shifr_schet, dc.sub_shifr_schet
  having count(1) > 1 and sum(dc.amount) <> max(dc.corr_op_amount)
  union all
  -- не идентифицированные участники
  select null date_op,
         null ssylka_doc,
         fl.nom_vkl,
         fl.nom_ips,
         null,
         null,
         null,
         null,
         fl.ssylka ssylka_fl,
         fl.familiya || ' ' || fl.imya || ' ' || fl.otchestvo fio,
         3 error_code
  from   sp_fiz_lits_non_ident_v fl
  union all
  -- не идентифицированные получатели пособий
  select null date_op,
         vp.ssylka_doc,
         vp.nom_vkl,
         vp.nom_ips,
         null,
         null,
         null,
         null,
         vp.ssylka ssylka_fl,
         vp.fio,
         4 error_code
  from   vyplach_posob_non_ident_v vp
/
