create or replace view sp_tax_residents_src_v as
  select 3022644 fk_contragent,
         to_date(20170101, 'yyyymmdd') start_date,
         to_date(20171231, 'yyyymmdd') end_date
  from   dual/*
 union all
  select 3022644 fk_contragent,
         to_date(20170401, 'yyyymmdd') start_date,
         to_date(20170731, 'yyyymmdd') end_date
  from   dual
 union all
  select 3022644 fk_contragent,
         to_date(20171001, 'yyyymmdd') start_date,
         to_date(20171130, 'yyyymmdd') end_date
  from   dual
*/
