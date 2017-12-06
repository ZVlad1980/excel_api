create or replace view dv_sr_lspv_buf_v as
  with pay_buf_w as (
    select extract(year from max(pb.data_vypl))            year_op,
           extract(month from max(pb.data_vypl))           month_op,
           ceil(extract(month from max(pb.data_vypl))/3)   quarter_op,
           max(pb.data_vypl)                               date_op,
           -1                                         ssylka_doc,
           pb.nom_vkl,
           pb.nom_ips,
           fl.ssylka,
           fl.gf_person,
           fl.pen_scheme_code,
           'PENSION'                                  det_charge_type,
           sum(pb.pens)                                    revenue,
           sum(pb.lpn_sum)                                 benefit,
           sum(pb.udergano)                                tax,
           case fl.resident
             when 1 then 13
             else        30
           end                                             tax_rate/*
           case 
             when nvl(sum(pb.udergano), 0) = 0 then 13 
             when sum(pb.udergano)/sum(pb.pens) < .3 then 13 
             else 30 
           end                                        tax_rate --*/
    from   vyplach_pen_buf    pb,
           sp_fiz_litz_lspv_v fl
    where  1=1
    and    fl.ssylka = pb.ssylka
    and    pb.nom_vkl < 991
    group by pb.nom_vkl,
           pb.nom_ips,
           fl.ssylka,
           fl.gf_person,
           fl.pen_scheme_code,
           fl.resident
    --and    pb.data_vypl between dv_sr_lspv_docs_api.get_start_date_buf and dv_sr_lspv_docs_api.get_end_date_buf
    /*Отключил, т.к. нет пояснений как обрабатывать
    union all
    select extract(year from vs.data_zanes)            year_op,
           extract(month from vs.data_zanes)           month_op,
           ceil(extract(month from vs.data_zanes)/3)   quarter_op,
           trunc(vs.data_zanes)                        date_op,
           vs.ssylka_doc                               ssylka_doc,
           fl.nom_vkl,
           fl.nom_ips,
           fl.ssylka,
           fl.gf_person,
           fl.pen_scheme_code,
           'BUYBACK'                                   det_charge_type,
           vs.posobie                                  revenue,
           0                                           benefit,
           vs.uderg_pn                                 tax,
           case 
             when nvl(vs.uderg_pn, 0) = 0 then 13 
             when vs.uderg_pn/vs.posobie < .3 then 13 
             else 30 
           end                                         tax_rate
    from   vyplach_vykup_summ vs,
           sp_fiz_litz_lspv_v fl
    where  1=1
    and    fl.ssylka = vs.ssylka
    and    vs.data_zanes between dv_sr_lspv_docs_api.get_start_date_buf and dv_sr_lspv_docs_api.get_end_date_buf
    */
  )
  select -rownum                    id, 
         pb.year_op,
         pb.month_op,
         pb.quarter_op,
         pb.date_op, 
         pb.ssylka_doc              ssylka_doc_op, 
         0                          type_op, 
         pb.year_op                 year_doc,
         pb.month_op                month_doc,
         pb.quarter_op              quarter_doc,
         pb.date_op                 date_doc, 
         pb.ssylka_doc              ssylka_doc, 
         pb.nom_vkl, 
         pb.nom_ips, 
         pb.ssylka                   ssylka_fl, 
         pb.gf_person,
         pb.pen_scheme_code,
         pb.det_charge_type,
         pb.revenue,
         pb.revenue                  revenue_curr_year,
         pb.benefit, 
         pb.tax,
         pb.tax                      tax_retained,
         pb.tax                      tax_retained_old,
         0                           tax_return,
         pb.tax_rate,
         pb.tax_rate                 tax_rate_op,
         0                           tax_83, 
         0                           source_revenue, 
         0                           source_benefit, 
         0                           source_tax, 
         null                        process_id, 
         'N'                         is_tax_return
  from   pay_buf_w pb
/
