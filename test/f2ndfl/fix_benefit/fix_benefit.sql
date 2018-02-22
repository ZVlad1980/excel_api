select *
from   f2ndfl_arh_vych v
where  v.r_sprid = 3270131
/
select *
from   f2ndfl_load_spravki ss
where  ss.ssylka = 1194848
and    ss.god = 2017
/
select *
from   f2ndfl_load_vych v
where  v.god = 2017
and    v.kod_na = 1
and    v.vych_sum <> trunc(v.vych_sum)
--
select *
from   sp_lspv sp
where  sp.ssylka_fl = 1194848
/
select *--a.shifr_schet,       sum(a.amount) amount
from   dv_sr_lspv_acc_v a
where  a.nom_vkl = 330
and    a.nom_ips = 1943
and    a.date_op between to_date(20170101, 'yyyymmdd') and to_date(20171231, 'yyyymmdd')
and    a.charge_type = 'BENEFIT'
order by a.date_op, a.shifr_schet
--group by a.shifr_schet
/
select *
from   payments_taxdeductions_v pt
where  pt.ssylka_fl = 1194848
/
select *
from   sp_ogr_pv_v t
where  t.ssylka_fl = 1194848
/
select *
from   sp_ogr_benefits_v b
where  b.ssylka_fl = 1194848
--!!!!!!!!!!!!!!!!!!!!!!!
-- LOAD по ней кривой!

select v.*, rowid
--delete
from   f2ndfl_load_vych v
where  v.god = 2017
and    v.ssylka = 1195218
/
select v.*, rowid
from   f2ndfl_arh_vych v
where  v.r_sprid in (
select s.id
from   f2ndfl_arh_spravki s
where  s.god = 2017
and    s.kod_na = 1
and    s.nom_spr = '089136'
)
/
select np.*
from   f2ndfl_arh_spravki s,
       f_ndfl_load_nalplat np
where  s.god = 2017
and    s.kod_na = 1
and    s.nom_spr = '089136'
and    np.kod_na = s.kod_na
and    np.god = s.god
and    np.ssylka_tip = 0
and    np.gf_person = s.ui_person
/
select *--a.shifr_schet,       sum(a.amount) amount
from   dv_sr_lspv_acc_v a
where  a.nom_vkl = 172
and    a.nom_ips = 66
and    a.date_op between to_date(20170101, 'yyyymmdd') and to_date(20171231, 'yyyymmdd')
and    a.charge_type = 'BENEFIT'
group by a.shifr_schet
/
select *
from   payments_taxdeductions_v pt
where  pt.ssylka_fl = 1195218
/
select *
from   sp_ogr_pv_v t
where  t.ssylka_fl = 1195218
/
select *
from   sp_ogr_benefits_v b
where  b.ssylka_fl = 1195218
/
select t.*, rowid
from   sp_ogr_pv_arh t
where  t.kod_ogr_pv > 1000 and t.ssylka_fl = 1195218
/
Insert into F2NDFL_LOAD_VYCH 
              ( KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, MES, VYCH_KOD_GNI, VYCH_SUM, KOD_STAVKI) 
select s.kod_na,
             s.god,
             s.ssylka,
             s.tip_dox,
             s.nom_korr,
             a.month_op,
             a.benefit_code,
             sum(a.benefit_amount),
             13
      from   dv_sr_lspv_benefits_det_v a,
             f2ndfl_load_spravki       s
      where  1 = 1
     /* and    case 
               when gl_sprid is null then 1 
               when gl_sprid = nvl(s.r_sprid, -1) then 1 
               else 0 
             end = 1*/
      --
      and    s.tip_dox = a.revenue_type
      and    s.ssylka = a.ssylka_fl
      and    s.god = a.year_op
      and    s.kod_na = 1--gl_KODNA
      --
      and    a.nom_ips = 66--nvl(gl_NOMIPS, a.nom_ips)
      and    a.nom_vkl = 172--nvl(gl_NOMVKL, a.nom_vkl)
      --
--      and    a.actual_date <= gl_ACTUAL_DATE
      and    a.date_op >= to_date(20170101, 'yyyymmdd') --dTermBeg
      and    a.date_op < to_date(20180101, 'yyyymmdd') --dTermEnd;
      group by s.kod_na,
             s.god,
             s.ssylka,
             s.tip_dox,
             s.nom_korr,
             a.month_op,
             a.benefit_code;
