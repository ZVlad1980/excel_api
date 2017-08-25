create or replace view dv_sr_lspv_acc_v as
  select a.charge_type      ,
         a.det_charge_type  ,
         a.tax_rate         ,
         d.data_op          date_op,
         d.ssylka_doc       ,
         d.service_doc      ,
         d.nom_vkl          ,
         d.nom_ips          ,
         d.shifr_schet      ,
         d.sub_shifr_schet  ,
         d.summa            amount,
         d.kod_oper         ,
         a.sub_shifr_grp
  from   fnd.dv_sr_lspv  d,
         ndfl_accounts_t a
  where  1 = 1
  and    d.nom_vkl < a.max_nom_vkl
  and    d.sub_shifr_schet = a.sub_shifr_schet
  and    d.shifr_schet = a.shifr_schet
  --
  --and    d.nom_vkl = 7
  --and    d.nom_ips = 1471
/
/*

  and    (d.nom_vkl, d.nom_ips) in (
        select 12, 4932 from dual union all
        select 12, 10047 from dual union all
        select 14, 105 from dual union all
        select 17, 3645 from dual union all
        select 164, 189 from dual union all
        select 17, 262 from dual union all
        select 21, 4855 from dual union all
        select 10, 152 from dual union all
        select 77, 1852 from dual union all
        select 71, 2281 from dual union all
        select 71, 2670 from dual union all
        select 4, 339 from dual union all
        select 71, 6591 from dual
       )*/
  --
 /* and    (d.nom_vkl, d.nom_ips) in (
          /*select 12, 4932 from dual union all
          select 12, 10047 from dual union all
          select 14, 105 from dual union all
          select 17, 3645 from dual union all
          select 164, 189 from dual union all
          select 17, 262 from dual union all
          select 21, 4855 from dual union all
          select 10, 152 from dual union all
          select 77, 1852 from dual union all
          select 71, 2281 from dual union all
          select 71, 2670 from dual union all
          select 4, 339 from dual union all
          select 71, 6591 from dual*/
          /*--групповые коррекции
          select 161, 28 from dual union all
          select 12, 4067 from dual union all
          --длинные цепочки (2016 год!)
          select 991, 34637 from dual union all
          select 991, 34637 from dual union all
          select 991, 35353 from dual union all
          select 991, 35353 from dual union all
          select 991, 39846 from dual union all
          select 991, 39846 from dual union all
          select 991, 33428 from dual union all
          select 991, 33428 from dual /*
          select 39, 45 from dual union all
          select 63, 6 from dual union all
          select 6, 2557 from dual union all
          select 65, 990 from dual union all
          select 335, 76 from dual union all
          select 37, 2120 from dual union all
          select 22, 1106 from dual union all
          select 6, 2489 from dual
         )
*/
