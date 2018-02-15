alter table f2ndfl_arh_spravki add (ui_person int, is_participant varchar2(1))
/
create index f2ndfl_arh_spravki_ix on f2ndfl_arh_spravki(kod_na, god, ui_person)
/
begin
  dbms_stats.gather_index_stats(user, 'f2ndfl_arh_spravki_ix');
end;
/
