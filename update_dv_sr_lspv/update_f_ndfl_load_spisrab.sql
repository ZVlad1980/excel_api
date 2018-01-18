begin
  merge into f_ndfl_load_spisrab sr
  using (
          select ss.god, 
                 ss.kod_na, 
                 ss.employee_id, 
                 ss.familiya      , 
                 ss.imya          , 
                 ss.otchestvo     , 
                 ss.data_rozhd
          from   f2ndfl_load_spravki_v ss
          where  ss.tip_dox = 9
        ) u
  on    (sr.kod_na = u.kod_na and 
         sr.god = u.god and
         sr.familiya   = u.familiya   and
         sr.imya       = u.imya       and
         sr.otchestvo  = u.otchestvo  and
         sr.data_rozhd = u.data_rozhd
        )
  when matched then
    update set
      sr.uid_np = u.employee_id;
  --
  dbms_output.put_line(sql%rowcount);
end;
