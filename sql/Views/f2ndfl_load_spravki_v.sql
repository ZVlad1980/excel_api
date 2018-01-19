create or replace view f2ndfl_load_spravki_v as
  select sp.kod_na,
         sp.god,
         sp.ssylka,
         case sp.tip_dox when 2 then sp.ssylka end ssylka_rp,
         case sp.tip_dox when 2 then null when 9 then null else sp.ssylka end ssylka_fl,
         case sp.tip_dox when 9 then sp.ssylka end employee_id,
         sp.tip_dox,
         sp.nom_spr,
         sp.nom_korr,
         sp.data_dok,
         sp.kvartal,
         sp.priznak,
         sp.inn_fl,
         sp.inn_ino,
         sp.status_np,
         sp.grazhd,
         sp.familiya,
         sp.imya,
         sp.otchestvo,
         sp.data_rozhd,
         sp.kod_ud_lichn,
         sp.ser_nom_doc,
         sp.kor_otmena,
         sp.zam_gra,
         sp.zam_kul,
         sp.zam_snd,
         sp.r_sprid,
         sp.storno_flag,
         sp.storno_doxprav,
         case coalesce(max(sp.nom_korr) over(partition by sp.kod_na, sp.god, sp.ssylka, sp.tip_dox), -1)
           when coalesce(sp.nom_korr, -1) then
             'Y'
           else
             'N'
         end is_last_spr
  from   f2ndfl_load_spravki sp
  where  1 = 1
  and    substr(sp.nom_spr, 1, 4) <> 'ноль' 
  and    sp.god = dv_sr_lspv_docs_api.get_year
  and    sp.kod_na = 1
/
