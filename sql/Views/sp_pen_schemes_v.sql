create or replace view sp_pen_schemes_v as
  select f.nom_vkl,
         f.nom_ips,
         f.ssylka,
         s.kod_ps      pen_scheme_code,
         s.num_pen_pp  pen_scheme
  from   sp_fiz_litz_lspv_v f,
         fnd.kod_pens_shem  s
  where  1=1
  and    s.kod_ps = f.pen_scheme_code
/
