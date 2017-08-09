create or replace view ndfl_report_correcting_v as
with corrected_op as (
    select /*+ MATERIALIZE*/
           c.is_leaf,
           c.root_ssylka_doc,
           c.root_data_op,
           c.data_op,
           c.summa,
           c.charge_type,
           c.det_charge_type,
           c.tax_rate,
           c.nom_vkl,
           c.nom_ips,
           c.shifr_schet,
           c.sub_shifr_schet,
           c.ssylka_doc,
           c.service_doc,
           c.summa_source
           from   ndfl_dv_sr_lspv_corr_v c
  )
  select to_number(to_char(c.root_data_op, 'q'))  corr_quartal,
         to_number(to_char(c.root_data_op, 'mm')) corr_mouth,
         c.root_data_op                           corr_data_op,
         c.root_ssylka_doc                        corr_ssylka_doc,
         to_number(to_char(c.data_op, 'yyyy'))    src_year,
         to_number(to_char(c.data_op, 'q'))       src_quartal,
         to_number(to_char(c.data_op, 'mm'))      src_mouth,
         c.data_op                                src_data_op,
         c.ssylka_doc                             src_ssylka_doc,
         c.summa_source                           src_summa,
         c.summa                                  correction_sum,
         c.nom_vkl                                nom_vkl         ,
         c.nom_ips                                nom_ips         ,
         c.shifr_schet                            shifr_schet     ,
         c.Sub_shifr_schet                        sub_shifr_schet ,
         f.ssylka                                 ssylka_fl,
         f.last_name,
         f.first_name,
         f.second_name,
         f.gf_person
  from   corrected_op       c,
         sp_fiz_litz_lspv_v f
  where  1=1
  and    f.nom_ips = c.nom_ips
  and    f.nom_vkl = c.nom_vkl
  and    c.is_leaf = 1;
/
