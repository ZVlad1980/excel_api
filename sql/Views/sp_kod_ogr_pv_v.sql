create or replace view sp_kod_ogr_pv_v as
  select t.rid,
         o.kod_ogr_pv,
         o.soderg_ogr,
         t.code,
         t.name,
         t.amount,
         t.upper_income,
         t.is_double,
         t.double_size,
         t.type,
         t.comments,
         t.regdate,
         t.closedate
  from   kod_ogr_pv             o,
         payments.taxdeductions t
  where  1=1
  and    t.payrestrictionid = o.id
  and    o.kod_ogr_pv > 1000
/
