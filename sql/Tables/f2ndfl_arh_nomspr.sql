create index f2ndfl_arh_nomspr_ix on f2ndfl_arh_nomspr(kod_na, god, ui_person)
/
begin
  dbms_stats.gather_index_stats(user, 'f2ndfl_arh_nomspr_ix');
end;
/