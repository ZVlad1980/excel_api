create or replace view sp_fiz_lits_diff_v as
  with receivers_w as (
    select /*+ materialize*/
           r.ssylka,
           r.gf_person,
           r.nom_vkl,
           r.nom_ips,
           sfl.familiya || ' ' || 
            sfl.imya    || ' ' || 
            sfl.otchestvo             fio,
           sfl.data_rogd              birth_date,
           sifl.inn                   inn,
           sfl.nal_rezident           resident
    from   (
            select r.ssylka,
                   r.gf_person,
                   r.nom_vkl,
                   r.nom_ips,
                   count(r.gf_person)over(partition by r.gf_person) cnt
            from   sp_fiz_lits_receivers_v r
            where  r.gf_person is not null
           ) r,
           sp_fiz_lits     sfl,
           sp_inn_fiz_lits sifl
    where  1=1
    and    sifl.ssylka = sfl.ssylka
    and    sfl.ssylka = r.ssylka
    and    r.cnt > 1
  ),
  double_receivers_w as (
    select r.gf_person,
           r.ssylka,
           r2.ssylka                                                 ssylka2         ,
           case when r.fio        <> r2.fio        then 1 else 0 end diff_fio        ,
           case when r.birth_date <> r2.birth_date then 2 else 0 end diff_birth_date ,
           case when r.inn        <> r2.inn        then 4 else 0 end diff_inn        ,
           case when r.resident   <> r2.resident   then 8 else 0 end diff_resident
    from   receivers_w r,
           receivers_w r2
    where  1=1
    and    r.ssylka < r2.ssylka
    and    r.gf_person = r2.gf_person
  )
  select r.gf_person,
         r.nom_vkl,
         r.nom_ips,
         r.ssylka ssylka_fl,
         r.fio,
         r.birth_date,
         r.inn,
         r.resident,
         (dr.diff_fio + dr.diff_birth_date + dr.diff_inn + dr.diff_resident) diff_sum
  from   double_receivers_w dr,
         receivers_w        r
  where  1=1
  and    r.gf_person = dr.gf_person
  and    (dr.diff_fio + dr.diff_birth_date + dr.diff_inn + dr.diff_resident) > 0
  order by r.gf_person, r.ssylka
/
