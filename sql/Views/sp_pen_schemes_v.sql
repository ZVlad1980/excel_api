create or replace view sp_pen_schemes_v as
  select ps.kod_ps  code,
         ps.kr_nazv name,
         ps.nazv_ps full_name,
         ps.fund_id
  from   fnd.kod_pens_shem ps
/
