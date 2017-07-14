create or replace view ndfl_schet_options_v(
         charge_type, det_charge_type, tax_rate, shifr_schet, sub_shifr_schet, max_nom_vkl
) as
  select 'REVENUE',   'PENSION'    ,   13,       60,          0,               990            from dual union all --пенсия от 3-х лиц
  select 'REVENUE',   'PENSION'    ,   13,       60,          1,               990            from dual union all --пенсия от 3-х лиц
  select 'REVENUE',   'PENSION'    ,   13,       60,          2,               990            from dual union all --пенсия от 3-х лиц
  select 'REVENUE',   'PENSION'    ,   13,       60,          3,               990            from dual union all --пенсия от 3-х лиц
  select 'REVENUE',   'PENSION'    ,   13,       60,          4,               990            from dual union all --пенсия от 3-х лиц
  select 'REVENUE',   'PENSION'    ,   13,       60,          5,               990            from dual union all --пенсия от 3-х лиц
  select 'TAX'    ,   'PENSION'    ,   13,       85,          0,               990            from dual union all --13 налог на пенсию от 3-х лиц
  select 'TAX'    ,   'PENSION'    ,   30,       85,          1,               990            from dual union all --30 налог на пенсию от 3-х лиц
  select 'REVENUE',   'BUYBACK'    ,   13,       55,          0,               null           from dual union all --выкупные суммы
  select 'REVENUE',   'BUYBACK'    ,   13,       55,          1,               null           from dual union all --выкупные суммы
  select 'TAX'    ,   'BUYBACK'    ,   13,       85,          2,               null           from dual union all --13 налог на выкуп
  select 'TAX'    ,   'BUYBACK'    ,   30,       85,          3,               null           from dual union all --30 налог на выкуп
  select 'REVENUE',   'RITUAL'     ,   13,       62,          0,               null           from dual union all --ритуальные выплаты
  select 'TAX'    ,   'RITUAL'     ,   13,       86,          0,               null           from dual union all --13 налог на ритуальные услуги
  select 'TAX'    ,   'RITUAL'     ,   30,       86,          1,               null           from dual union all --30 налог на ритуальные услуги
  -- + вычеты!
  select 'BENEFIT', 
         null, --зависит от операции дохода 
         13,
         t.shifr_schet,
         t.sub_shifr_schet,
         null 
  from   FND.KOD_SHIFR_SCHET t 
  where t.shifr_schet > 1000 --*/
/
