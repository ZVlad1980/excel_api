create table ndfl_accounts_t (
  shifr_schet     number,
  sub_shifr_schet number,
  charge_type     varchar2(8) not null,
  det_charge_type varchar2(7),
  tax_rate        number,
  max_nom_vkl     number,
  sub_shifr_grp   number,
  constraint ndfl_schet_options_pk 
    primary key (shifr_schet, sub_shifr_schet)
) organization index
/
--truncate table ndfl_accounts_t
begin
  merge into ndfl_accounts_t a
    using ( with options(charge_type, det_charge_type, tax_rate, shifr_schet, sub_shifr_schet, max_nom_vkl, sub_shifr_grp) as(
              select 'REVENUE' ,  'PENSION',   13,  60,  0,  991       , 1 from dual union all --пенсия от 3-х лиц
              select 'REVENUE' ,  'PENSION',   13,  60,  1,  991       , 1 from dual union all --пенсия от 3-х лиц
              select 'REVENUE' ,  'PENSION',   13,  60,  2,  991       , 1 from dual union all --пенсия от 3-х лиц
              select 'REVENUE' ,  'PENSION',   13,  60,  3,  991       , 1 from dual union all --пенсия от 3-х лиц
              select 'REVENUE' ,  'PENSION',   13,  60,  4,  991       , 1 from dual union all --пенсия от 3-х лиц
              select 'REVENUE' ,  'PENSION',   13,  60,  5,  991       , 1 from dual union all --пенсия от 3-х лиц
              select 'TAX'     ,  'PENSION',   13,  85,  0,  991       , 0 from dual union all --13 налог на пенсию от 3-х лиц
              select 'TAX'     ,  'PENSION',   30,  85,  1,  991       , 0 from dual union all --30 налог на пенсию от 3-х лиц
              select 'REVENUE' ,  'BUYBACK',   13,  55,  0,  9999999999, 1 from dual union all --выкупные суммы
              select 'REVENUE' ,  'BUYBACK',   13,  55,  1,  9999999999, 1 from dual union all --выкупные суммы
              select 'TAX'     ,  'BUYBACK',   13,  85,  2,  9999999999, 0 from dual union all --13 налог на выкуп
              select 'TAX'     ,  'BUYBACK',   30,  85,  3,  9999999999, 0 from dual union all --30 налог на выкуп
              select 'REVENUE' ,  'RITUAL' ,   13,  62,  0,  9999999999, 1 from dual union all --ритуальные выплаты
              select 'TAX'     ,  'RITUAL' ,   13,  86,  0,  9999999999, 0 from dual union all --13 налог на ритуальные услуги
              select 'TAX'     ,  'RITUAL' ,   30,  86,  1,  9999999999, 0 from dual union all --30 налог на ритуальные услуги
              select 'TAX_CORR',  'PENSION',   13,  83,  0,  9999999999, 1 from dual union all --Переплата (задолженность) по ПН с пенсий за прошедший год
              -- + вычеты!
              select 'BENEFIT', 
                     null, --статья дохода (пенсия, выкуп или наследование/ритуалка) зависит от операции дохода 
                     13,
                     t.shifr_schet,
                     t.sub_shifr_schet,
                     9999999999,
                     1
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
      max_nom_vkl    ,
      sub_shifr_grp
    ) values(
      u.shifr_schet    ,
      u.sub_shifr_schet,
      u.charge_type    ,
      u.det_charge_type,
      u.tax_rate       ,
      u.max_nom_vkl    ,
      u.sub_shifr_grp
    )
  when matched then
    update set
      sub_shifr_grp = u.sub_shifr_grp;
  commit;
end;
/
create index ndfl_accounts_idx1 on ndfl_accounts_t(charge_type, det_charge_type, shifr_schet, sub_shifr_schet)
/
begin
  dbms_stats.gather_table_stats(user, upper('ndfl_accounts_t'));
  dbms_stats.gather_index_stats(user, upper('ndfl_accounts_idx1'));
end;
/
