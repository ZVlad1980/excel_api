create or replace view sp_fiz_litz_lspv_v as
  select lspv.nom_vkl,
         lspv.nom_ips,
         fz.ssylka,
         fz.familiya    last_name,
         fz.imya        first_name,
         fz.otchestvo   second_name,
         fz.data_rogd   birth_date,
         fz.pen_sxem    pen_scheme_code,
         fz.gf_person
  from   fnd.sp_lspv       lspv, 
         fnd.sp_fiz_lits   fz
  where  1=1
  and    fz.ssylka = lspv.ssylka_fl
/
