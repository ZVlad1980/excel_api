select *
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
from   sp_ogr_pv_arh t
where  t.kod_ogr_pv > 1000 and t.ssylka_fl = 1195218
/
