create or replace trigger sp_ogr_pv_bu_trg
  before insert or update of nom_vkl,
                             nom_ips,
                             kod_ogr_pv,
                             nach_deistv,
                             okon_deistv,
                             ssylka_fl,
                             ssylka_td,
                             rid_td
  on sp_ogr_pv 
  referencing old as old new as new
  for each row
  when ((new.kod_ogr_pv > 1000 or old.kod_ogr_pv > 1000))
begin
  :new.status := case when inserting then 'N' else 'U' end;
end sp_ogr_pv_bu_trg;
/
