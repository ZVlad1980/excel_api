create or replace trigger dv_sr_lspv_bu_trg
  before update of nom_vkl,
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
  when (new.status is null)
begin
  :new.status := 'U';
exception
  when others then
    null; --отказ триггера - не повод падения транзакции!
end dv_sr_lspv_bu_trg;
/
