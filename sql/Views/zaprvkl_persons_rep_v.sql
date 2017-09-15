create or replace view zaprvkl_persons_rep_v as
  select p.ssylka                           person_id,
         p.ssylka                           ips_num,
         p.familiya                         last_name,
         p.imya                             first_name,
         p.otchestvo                        second_name,
         p.data_rogd                        birth_date,
         p.tab_nom                          employee_id,
         p.insurance_number                 snils,
         p.data_vstup                       accession_date,
         ps.num_pen_pp                      pen_schem_num,
         u.poln_nazv                        investor,
         dog.data_nach_vypl                 pay_start_date,
         add_months(
           p.data_rogd, 
           case
             when upper(p.pol) in ('М', 'M') then
               60
             else
               55
           end * 12
         )                                  supposed_pay_start_date,
         lspv.rasch_pen,
         lspv.delta_lv,
         case p.pen_sxem 
           when 1 then 
             p.dop_pen 
         end                                dop_pen,
         case
           when exists(
                  select 1 
                  from   fnd.sp_invalid inv
                  where  inv.ssylka_fl = p.ssylka
                ) then
             'Y'
         end                                is_disabled
  from   fnd.sp_fiz_lits   p,
         fnd.kod_pens_shem ps,
         fnd.sp_ur_lits    u,
         fnd.sp_pen_dog    dog,
         fnd.sp_lspv       lspv
  where  1=1
  and    dog.ssylka(+) = p.ssylka
  and    u.ssylka = p.nom_vkl
  and    ps.kod_ps = p.pen_sxem
  and    lspv.ssylka_fl(+) = p.ssylka
/
