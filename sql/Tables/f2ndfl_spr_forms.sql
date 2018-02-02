create sequence f2ndfl_spr_forms_seq order
/
create table f2ndfl_spr_forms(
  id               int 
    default        f2ndfl_spr_forms_seq.nextval
    constraint     f2ndfl_spr_forms_pk primary key,
  form_code        varchar2(5),
  form_version     varchar2(20),
  from_date        date,
  to_date          date,
  constraint f2ndfl_spr_forms_u unique (form_code, form_version)
)
/
begin
  merge into f2ndfl_spr_forms f
  using      (select '2' form_code, '5.04' form_version, to_date(20150101, 'yyyymmdd') from_date, to_date(20161231, 'yyyymmdd') to_date from dual union all
              select '6' form_code, '5.01' form_version, to_date(20160101, 'yyyymmdd') from_date, null to_date from dual union all
              select '2' form_code, '5.05' form_version, to_date(20170101, 'yyyymmdd') from_date, null to_date from dual
             ) u
  on         (f.form_code = u.form_code and
              f.form_version = u.form_version
             )
  when matched then
    update set
      f.from_date = u.from_date,
      f.to_date   = u.to_date
  when not matched then
    insert (form_code, form_version, from_date, to_date)
      values(u.form_code, u.form_version, u.from_date, u.to_date);
  dbms_output.put_line(sql%rowcount);
  commit;
end;
/
