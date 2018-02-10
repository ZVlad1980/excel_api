create table f2ndfl_load_vych_man (
  kod_na               number(10,0) default 1, 
  god                  number(4,0), 
  ssylka               number(10,0), 
  tip_dox              number(2,0), 
  nom_korr             number(2,0), 
  mes                  number(2,0), 
  vych_kod_gni         number(4,0), 
  vych_kod_gni_new     number(4,0),
  vych_sum             float(126), 
  kod_stavki           number(4,0) default 13, 
  constraint f2ndfl_load_vych_man_pk primary key (kod_na, god, ssylka, tip_dox, nom_korr, mes, vych_kod_gni)
)
/
/*
begin
  merge into f2ndfl_load_vych_man vm
  using (select v.kod_na,
                v.god,
                v.ssylka,
                v.tip_dox,
                v.nom_korr,
                v.mes,
                v.vych_kod_gni,
                v.vych_sum,
                v.kod_stavki
         from   f2ndfl_load_vych v
         where  v.kod_na = 1
         and    v.god = 2017
         and    v.vych_kod_gni < 0
        ) v
  on    (v.kod_na    = vm.kod_na   and
         v.god       = vm.god      and
         v.ssylka    = vm.ssylka   and
         v.tip_dox   = vm.tip_dox  and
         v.nom_korr  = vm.nom_korr and
         v.mes       = vm.mes     
        )
  when not matched then
    insert (
      kod_na, 
      god, 
      ssylka, 
      tip_dox, 
      nom_korr, 
      mes, 
      vych_kod_gni, 
      vych_sum, 
      kod_stavki
    ) values (
      v.kod_na,
      v.god,
      v.ssylka,
      v.tip_dox,
      v.nom_korr,
      v.mes,
      v.vych_kod_gni,
      v.vych_sum,
      v.kod_stavki
    );
  dbms_output.put_line(sql%rowcount);
  commit;
end;
*/
