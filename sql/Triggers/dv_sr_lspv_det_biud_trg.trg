create or replace trigger dv_sr_lspv_det_biud_trg
  before insert or update or delete
  on dv_sr_lspv_det_t 
  referencing old as old new as new
  for each row
declare
  l_os_user dv_sr_lspv_det_t.created_by%type;
  l_method  dv_sr_lspv_det_t.method%type;
begin
  if dv_sr_lspv_det_pkg.legacy = 'N' then
    if deleting then
      raise program_error;
    end if;
    l_os_user := dv_sr_lspv_det_pkg.get_os_user;
    l_method := 'M';
  else
    l_method := 'A';
  end if;
  --
  if inserting then
    :new.created_by      := l_os_user;
    :new.method          := l_method;
  elsif updating then
    :new.last_updated_by := dv_sr_lspv_det_pkg.get_os_user;
    :new.last_updated_at := current_date;
  end if;
  --
end dv_sr_lspv_det_biud_trg;
/
