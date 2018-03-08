with det as (
  select sl.ssylka_fl, to_number(d.addition_code) benefit_code, sum(d.amount) amount
  from   dv_sr_lspv_det_t d,
         dv_sr_lspv#      d#,
         sp_lspv          sl
  where  1=1
  and    sl.nom_vkl = d#.nom_vkl
  and    sl.nom_ips = d#.nom_ips
  and    d.detail_type = 'BENEFIT'
  and    d.addition_id > 0
  and    d.fk_dv_sr_lspv = d#.id
  and    d#.shifr_schet > 1000
  and    extract(year from d#.date_op) = 2018
  group by sl.ssylka_fl, d.addition_code
),
vych as (
  select lv.ssylka ssylka_fl, lv.vych_kod_gni benefit_code, sum(lv.vych_sum) amount
  from   f2ndfl_load_vych lv
  where  lv.kod_na = 1
  and    lv.god = 2018
  and    lv.tip_dox in (1,3)
  group by lv.ssylka, lv.vych_kod_gni
)
select sfl.gf_person,
       d.ssylka_fl      det_ssylka_fl   ,
       d.benefit_code   det_benefit_code,
       d.amount         det_amount      ,
       v.ssylka_fl      vych_ssylka_fl   ,
       v.benefit_code   vych_benefit_code,
       v.amount         vych_amount      
from   det d
       full outer join vych v
        on  d.ssylka_fl = v.ssylka_fl
        and d.benefit_code = v.benefit_code
       outer apply(
         select sfl.gf_person
         from   sp_fiz_lits sfl
         where  sfl.ssylka = nvl(d.ssylka_fl, v.ssylka_fl)
       ) sfl
where  1=1
and    round(coalesce(d.amount, 0), 2) <> round(coalesce(v.amount, 0), 2)
order by det_ssylka_fl
