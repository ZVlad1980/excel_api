create or replace trigger dv_sr_lspv_det_aud_trg
  after delete or update of id, 
                            charge_type, 
                            fk_dv_sr_lspv, 
                            fk_dv_sr_lspv_trg, 
                            amount, 
                            addition_code
  on dv_sr_lspv_det_t 
  for each row
declare
  l_os_user log$_dv_sr_lspv_det_t.created_by%type;
  l_action  log$_dv_sr_lspv_det_t.action%type;
begin
  l_os_user := dv_sr_lspv_det_pkg.get_os_user;
  l_action := case when updating then 'U' when deleting then 'D' end;
  --
  insert into log$_dv_sr_lspv_det_t(
    id,
    action,
    action_by,
    fk_dv_sr_lspv,
    fk_dv_sr_lspv_trg,
    amount,
    addition_code,
    addition_id,
    method,
    process_id,
    is_deleted,
    is_disabled
  ) values (
    :old.id,
    l_action,
    l_os_user,
    :old.fk_dv_sr_lspv,
    :old.fk_dv_sr_lspv_trg,
    :old.amount,
    :old.addition_code,
    :old.addition_id,
    :old.method,
    :old.process_id,
    :old.is_deleted,
    :old.is_disabled
  );
  --
end dv_sr_lspv_det_aud_trg;
/
