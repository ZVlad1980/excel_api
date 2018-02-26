create or replace trigger dv_sr_lspv_aud_trg
  --
  after delete or update of nom_vkl,
                            nom_ips,
                            shifr_schet,
                            data_op,
                            summa,
                            ssylka_doc,
                            sub_shifr_schet,
                            service_doc
  on dv_sr_lspv
  referencing old as old new as new
  for each row
  --
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
  insert into log$_dv_sr_lspv(
    id, 
    action, 
    nom_vkl, 
    nom_ips, 
    shifr_schet, 
    data_op, 
    summa, 
    ssylka_doc, 
    kod_oper, 
    sub_shifr_schet, 
    service_doc, 
    created_by
  ) values (
    :old.id,
    l_action,
    :old.nom_vkl, 
    :old.nom_ips, 
    :old.shifr_schet, 
    :old.data_op, 
    :old.summa, 
    :old.ssylka_doc, 
    :old.kod_oper, 
    :old.sub_shifr_schet,
    :old.service_doc, 
    l_os_user
  );
  --
exception when others then null;
end dv_sr_lspv_aud_trg;
/
