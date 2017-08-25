create or replace view sp_det_charge_types_v as
  select 'PENSION' det_charge_type, 1 order_num, 'Пенсия'             describe, 'пенсии'    short_describe from dual union all
  select 'BUYBACK' det_charge_type, 2 order_num, 'Выкупные суммы'     describe, 'вык.сум.'  short_describe from dual union all
  select 'RITUAL'  det_charge_type, 3 order_num, 'Ритуальные пособия' describe, 'рит.выпл.' short_describe from dual
/
