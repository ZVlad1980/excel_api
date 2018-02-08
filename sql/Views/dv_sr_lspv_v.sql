create or replace view dv_sr_lspv_v as
  select d.nom_vkl,
         d.nom_ips,
         d.shifr_schet,
         d.data_op,
         case
           when sysdate <= to_date(20180210, 'yyyymmdd')
             and d.ssylka_doc = 420315 and d.shifr_schet = 85 then
               case
                 when d.nom_vkl = 37 and d.nom_ips = 921   then -2184
                 when d.nom_vkl = 12 and d.nom_ips = 14651 then -728
                 when d.nom_vkl = 12 and d.nom_ips = 15355 then -728
                 else d.summa
               end
           else d.summa
         end summa,
         d.ssylka_doc,
         d.kod_oper,
         d.sub_shifr_schet,
         d.service_doc
  from   dv_sr_lspv d
/
