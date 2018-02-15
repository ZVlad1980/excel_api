create sequence f2ndfl_arh_spravki_err_seq cache 1000
/
create table f2ndfl_arh_spravki_err(
  id                 int 
    default          f2ndfl_arh_spravki_err_seq.nextval
    constraint       f2ndfl_arh_spravki_err_pk primary key,
  code_na            int,
  year               int,
  r_sprid            int,
  r_spr_id_prev      int,
  error_id           number,
  status             varchar2(10) default 'New',
  constraint       f2ndfl_arh_srp_err_fk
      foreign key (r_sprid)
      references f2ndfl_arh_spravki(id),
  constraint       f2ndfl_arh_srp_err_fk2
      foreign key (r_spr_id_prev)
      references f2ndfl_arh_spravki(id),
  constraint f2ndfl_arhsrp_sts_chk
      check (status in ('New', 'Fix', 'FixGF', 'Pass'))
)
/
begin
  merge into f2ndfl_arh_spravki_err ase
  using (with w_errors as (
           select  e.kod_na, 
                   e.god,
                   e.r_sprid,
                   e.ui_person,
                   f2ndfl_arh_spravki_api.validate_pers_info(
                     e.kod_na          ,
                     e.god             ,
                     e.nom_spr         ,
                     e.ui_person       ,
                     e.kod_ud_lichn    ,
                     e.ser_nom_doc     ,
                     e.inn_fl          ,
                     e.grazhd          ,
                     e.status_np       ,
                     e.inn_dbl         ,
                     e.fiod_dbl        ,
                     e.doc_dbl         ,
                     e.is_invalid_doc
                   )                            error_list
           from   f2ndfl_arh_spravki_errors_v e
           where  1=1
           and    e.god = 2017
           and    e.kod_na = 1
         )
         select e.kod_na code_na,
                e.god year,
                e.r_sprid,
                s_prev.id r_sprid_prev,
                p.error_id
         from   w_errors e,
                lateral(
                  select level lvl,
                         to_number(regexp_substr(e.error_list, '[^ ]+', 1, level)) error_id
                  from   dual
                  connect by level <= regexp_count(e.error_list, ' +?') + 1
                ) p,
                lateral(
                  select 1
                  from   sp_ndfl_errors     se
                  where  se.error_type <> 'Warning'
                  and    se.error_id = p.error_id
                ) se,
                lateral(
                  select max(s_prev.id) keep(dense_rank last order by s_prev.nom_korr) id
                  from   f2ndfl_arh_spravki s_prev
                  where  s_prev.ui_person(+) = e.ui_person
                  and    s_prev.god(+) = e.god - 1
                  and    s_prev.kod_na(+) = e.kod_na
                ) s_prev
         where  1=1
         and    e.error_list is not null
        ) u
  on    (ase.code_na = u.code_na and ase.year = u.year and ase.r_sprid = u.r_sprid)
  when not matched then
    insert (code_na, year, r_sprid, r_sprid_prev, error_id)
      values (u.code_na, u.year, u.r_sprid, u.r_sprid_prev, u.error_id);
dbms_output.put_line(sql%rowcount);
end;
/
