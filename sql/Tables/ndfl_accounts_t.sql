create table ndfl_accounts_t (
  shifr_schet     number,
  sub_shifr_schet number,
  charge_type     varchar2(8) not null,
  det_charge_type varchar2(7),
  tax_rate        number,
  max_nom_vkl     number,
  constraint ndfl_schet_options_pk 
    primary key (shifr_schet, sub_shifr_schet)
) organization index
/
begin
  merge into ndfl_accounts_t a
    using ( with options(charge_type, det_charge_type, tax_rate, shifr_schet, sub_shifr_schet, max_nom_vkl) as(
              select 'REVENUE' ,  'PENSION',   13,  60,  0,  990   from dual union all --пенсия от 3-х лиц
              select 'REVENUE' ,  'PENSION',   13,  60,  1,  990   from dual union all --пенсия от 3-х лиц
              select 'REVENUE' ,  'PENSION',   13,  60,  2,  990   from dual union all --пенсия от 3-х лиц
              select 'REVENUE' ,  'PENSION',   13,  60,  3,  990   from dual union all --пенсия от 3-х лиц
              select 'REVENUE' ,  'PENSION',   13,  60,  4,  990   from dual union all --пенсия от 3-х лиц
              select 'REVENUE' ,  'PENSION',   13,  60,  5,  990   from dual union all --пенсия от 3-х лиц
              select 'TAX'     ,  'PENSION',   13,  85,  0,  990   from dual union all --13 налог на пенсию от 3-х лиц
              select 'TAX'     ,  'PENSION',   30,  85,  1,  990   from dual union all --30 налог на пенсию от 3-х лиц
              select 'REVENUE' ,  'BUYBACK',   13,  55,  0,  null  from dual union all --выкупные суммы
              select 'REVENUE' ,  'BUYBACK',   13,  55,  1,  null  from dual union all --выкупные суммы
              select 'TAX'     ,  'BUYBACK',   13,  85,  2,  null  from dual union all --13 налог на выкуп
              select 'TAX'     ,  'BUYBACK',   30,  85,  3,  null  from dual union all --30 налог на выкуп
              select 'REVENUE' ,  'RITUAL' ,   13,  62,  0,  null  from dual union all --ритуальные выплаты
              select 'TAX'     ,  'RITUAL' ,   13,  86,  0,  null  from dual union all --13 налог на ритуальные услуги
              select 'TAX'     ,  'RITUAL' ,   30,  86,  1,  null  from dual union all --30 налог на ритуальные услуги
              select 'TAX_CORR',  'PENSION',   13,  83,  0,  null  from dual union all --Переплата (задолженность) по ПН с пенсий за прошедший год
              -- + вычеты!
              select 'BENEFIT', 
                     null, --статья дохода (пенсия, выкуп или наследование/ритуалка) зависит от операции дохода 
                     13,
                     t.shifr_schet,
                     t.sub_shifr_schet,
                     null 
              from   FND.KOD_SHIFR_SCHET t 
              where t.shifr_schet > 1000
            )
            select o.*
            from   options o
          ) u
  on (a.shifr_schet = u.shifr_schet and a.sub_shifr_schet = u.sub_shifr_schet)
  when not matched then
    insert (
      shifr_schet    ,
      sub_shifr_schet,
      charge_type    ,
      det_charge_type,
      tax_rate       ,
      max_nom_vkl    
    ) values(
      u.shifr_schet    ,
      u.sub_shifr_schet,
      u.charge_type    ,
      u.det_charge_type,
      u.tax_rate       ,
      u.max_nom_vkl
    );
  commit;
  dbms_stats.gather_table_stats(user, upper('ndfl_accounts_t'));
end;
/
