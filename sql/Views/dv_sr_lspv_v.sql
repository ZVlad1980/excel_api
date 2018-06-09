create or replace view dv_sr_lspv_v as
  select d.nom_vkl,
         d.nom_ips,
         d.shifr_schet,
         d.data_op,
         /*case
           when d.nom_vkl = 5 and d.nom_ips = 11250 and d.ssylka_doc = 420397 and d.shifr_schet = 85 and d.data_op = to_date(20180401, 'yyyymmdd') then
             -2184 --был 0 на 20180519
           else round(d.summa, 2)
         end  summa,*/
         round(d.summa, 2) summa,
         d.ssylka_doc,
         d.kod_oper,
         d.sub_shifr_schet sub_shifr_schet,
         d.service_doc,
         extract(year from d.data_op) year_op
  from   dv_sr_lspv d
/
