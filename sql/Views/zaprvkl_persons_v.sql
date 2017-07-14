create or replace view zaprvkl_persons_v as
  select p.ssylka           person_id,
         upper(p.familiya)  last_name,
         upper(p.imya)      first_name,
         upper(p.otchestvo) second_name,
         p.data_rogd        birth_date,
         to_char(p.data_rogd, 'dd.mm.yyyy')        birth_date_str,
         p.pen_sxem         pen_scheme,
         p.pol              sex,
         p.tab_nom          employee_id,
         p.nom_vkl          investor_id
  from   fnd.sp_fiz_lits p
/
