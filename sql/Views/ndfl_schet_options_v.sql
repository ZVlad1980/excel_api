create or replace view ndfl_schet_options_v(
         charge_type, det_charge_type, tax_rate, shifr_schet, sub_shifr_schet, max_nom_vkl
) as
  select 'REVENUE',   'PENSION'    ,   13,       60,          0,               990            from dual union all --������ �� 3-� ���
  select 'REVENUE',   'PENSION'    ,   13,       60,          1,               990            from dual union all --������ �� 3-� ���
  select 'REVENUE',   'PENSION'    ,   13,       60,          2,               990            from dual union all --������ �� 3-� ���
  select 'REVENUE',   'PENSION'    ,   13,       60,          3,               990            from dual union all --������ �� 3-� ���
  select 'REVENUE',   'PENSION'    ,   13,       60,          4,               990            from dual union all --������ �� 3-� ���
  select 'REVENUE',   'PENSION'    ,   13,       60,          5,               990            from dual union all --������ �� 3-� ���
  select 'TAX'    ,   'PENSION'    ,   13,       85,          0,               990            from dual union all --13 ����� �� ������ �� 3-� ���
  select 'TAX'    ,   'PENSION'    ,   30,       85,          1,               990            from dual union all --30 ����� �� ������ �� 3-� ���
  select 'REVENUE',   'BUYBACK'    ,   13,       55,          0,               null           from dual union all --�������� �����
  select 'REVENUE',   'BUYBACK'    ,   13,       55,          1,               null           from dual union all --�������� �����
  select 'TAX'    ,   'BUYBACK'    ,   13,       85,          2,               null           from dual union all --13 ����� �� �����
  select 'TAX'    ,   'BUYBACK'    ,   30,       85,          3,               null           from dual union all --30 ����� �� �����
  select 'REVENUE',   'RITUAL'     ,   13,       62,          0,               null           from dual union all --���������� �������
  select 'TAX'    ,   'RITUAL'     ,   13,       86,          0,               null           from dual union all --13 ����� �� ���������� ������
  select 'TAX'    ,   'RITUAL'     ,   30,       86,          1,               null           from dual union all --30 ����� �� ���������� ������
  -- + ������!
  select 'BENEFIT', 
         null, --������� �� �������� ������ 
         13,
         t.shifr_schet,
         t.sub_shifr_schet,
         null 
  from   FND.KOD_SHIFR_SCHET t 
  where t.shifr_schet > 1000 --*/
/
