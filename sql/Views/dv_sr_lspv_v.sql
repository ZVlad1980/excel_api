create or replace view dv_sr_lspv_v as
  select d.nom_vkl,
         d.nom_ips,
         d.shifr_schet,
         d.data_op,
         /*case
           when sysdate <= to_date(20180331, 'yyyymmdd')
                and d.ssylka_doc = 420328 and d.shifr_schet = 85 then
             case
               when d.nom_vkl = 5 and d.nom_ips = 10223 then -728
               else d.summa
             end
           else d.summa--*/
         d.summa summa,
         d.ssylka_doc,
         d.kod_oper,
         d.sub_shifr_schet,
         d.service_doc
  from   dv_sr_lspv d
/
