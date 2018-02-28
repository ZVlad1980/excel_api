create or replace trigger dv_sr_lspv_det_biud_trg
  before insert or update or delete
  on dv_sr_lspv_det_t 
  referencing old as old new as new
  for each row
declare
  l_os_user       dv_sr_lspv_det_t.created_by%type;
  l_method        dv_sr_lspv_det_t.method%type;
  l_current_date  date;
begin
  if dv_sr_lspv_det_pkg.legacy = 'N' then
    if deleting then
      raise program_error;
    end if;
    --
    l_method := 'M';
    l_os_user := dv_sr_lspv_det_pkg.get_os_user;
    l_current_date := current_date;
  else
    l_method := 'A';
  end if;
  --
  if inserting then
    :new.created_by      := l_os_user;
    :new.created_at      := l_os_user;
    :new.method          := l_method;
  elsif updating then
    :new.last_updated_by := l_os_user;
    :new.last_updated_at := l_current_date;
    if :new.is_deleted = 'Y' then
      :new.is_disabled := 'Y';
    end if;
  end if;
  --
end dv_sr_lspv_det_biud_trg;
/
