create or replace view ndfl6_report_correcting_v as
  select d.quarter_op,
         d.month_op,
         d.date_op,
         d.ssylka_doc_op,
         d.year_doc,
         d.quarter_doc,
         d.date_doc,
         d.ssylka_doc,
         case ds.charge_type when 'REVENUE' then d.source_revenue when 'BENEFIT' then case when d.benefit = 0 then 0 else d.source_benefit end when 'TAX' then d.source_tax end source_amount,
         case ds.charge_type when 'REVENUE' then d.revenue when 'BENEFIT' then d.benefit_all when 'TAX' then d.tax end amount,
         d.gf_person,
         d.nom_vkl,
         d.nom_ips,
         ds.shifr_schet,
         ds.sub_shifr_schet,
         f.ssylka,
         f.last_name,
         f.first_name,
         f.second_name
  from   dv_sr_lspv_docs_v  d,
         lateral( --для обхода коррекций по вычетам (несколько записей в базе, одна в таблице!)
           select ds.service_doc    ,
                  ds.date_op        ,
                  ds.ssylka_doc     ,
                  ds.nom_ips        ,
                  ds.nom_vkl        ,
                  ds.charge_type    ,
                  listagg(ds.shifr_schet, ', ') within group (order by rownum/*ds.shifr_schet*/) shifr_schet,
                  listagg(ds.sub_shifr_schet, ', ') within group (order by rownum/*ds.shifr_schet*/) sub_shifr_schet
           from   dv_sr_lspv_acc_v   ds
           where  1 = 1
           and    ds.service_doc <> 0
           and    ds.date_op     = d.date_op
           and    ds.ssylka_doc  = d.ssylka_doc_op
           and    ds.nom_ips     = d.nom_ips
           and    ds.nom_vkl     = d.nom_vkl
           group by ds.service_doc,
                    ds.date_op    ,
                    ds.ssylka_doc ,
                    ds.nom_ips    ,
                    ds.nom_vkl    ,
                    ds.charge_type
         )                  ds,      
         sp_fiz_litz_lspv_v f
  where  1=1
  --
  and    f.nom_ips = d.nom_ips
  and    f.nom_vkl = d.nom_vkl
  --
  and    ds.service_doc <> 0
  and    ds.date_op = d.date_op
  and    ds.ssylka_doc = d.ssylka_doc_op
  and    ds.nom_ips = d.nom_ips
  and    ds.nom_vkl = d.nom_vkl
  --
  and    d.type_op = -1
/
