create or replace trigger sp_ogr_pv_aud_trg
  after delete or update of nom_vkl,
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
declare
  l_os_user log$_dv_sr_lspv.created_by%type;
  l_action  log$_dv_sr_lspv.action%type;
begin
  --
  l_action := case when updating then 'U' when deleting then 'D' end;
  --
  begin
    select substrb(sys_context( 'userenv', 'os_user'), 1,32)
    into   l_os_user
    from dual;
  exception when others then null;
  end;
  --
  insert into log$_sp_ogr_pv(
    id,
    action,
    nom_vkl,
    nom_ips,
    kod_ogr_pv,
    nach_deistv,
    okon_deistv,
    ssylka_fl,
    ssylka_td,
    rid_td,
    inserted_at,
    created_by
  ) values (
    :old.id,
    l_action,
    :old.nom_vkl,
    :old.nom_ips,
    :old.kod_ogr_pv,
    :old.nach_deistv,
    :old.okon_deistv,
    :old.ssylka_fl,
    :old.ssylka_td,
    :old.rid_td,
    :old.created_at,
    l_os_user
  );
  --
exception when others then null;
end sp_ogr_pv_aud_trg;
/
