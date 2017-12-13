PL/SQL Developer Test script 3.0
11
-- Created on 09.12.2017 by V.ZHURAVOV 
declare 
  -- Local variables here
  i integer;
begin
  --dbms_session.reset_package; return;
  -- Test statements here
  dv_sr_lspv_docs_api.update_sp_tax_residents_t(
    p_process_id => 150
  );
end;
0
0
