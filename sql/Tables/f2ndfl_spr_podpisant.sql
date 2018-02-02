alter table f2ndfl_spr_podpisant add (from_date date, to_date date)
/
begin
  merge into f2ndfl_spr_podpisant p
  using (select 2015 god, 1 dflt, to_date(20150101, 'yyyymmdd') from_date, to_date(20151231, 'yyyymmdd') to_date from dual union all
         select 2016 god, 1 dflt, to_date(20160101, 'yyyymmdd') from_date, to_date(20161231, 'yyyymmdd') to_date from dual union all
         select 2017 god, 1 dflt, to_date(20170101, 'yyyymmdd') from_date, null to_date from dual
        ) u
  on    (p.god = u.god and p.pkg_dflt = u.dflt)
  when matched then
    update set
      p.from_date = u.from_date,
      p.to_date   = u.to_date;
  dbms_output.put_line(sql%rowcount);
  commit;
end;
/
