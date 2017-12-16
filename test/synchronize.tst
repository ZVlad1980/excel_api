PL/SQL Developer Test script 3.0
11
-- Created on 16.12.2017 by V.ZHURAVOV 
declare 
  -- Local variables here
  i integer;
begin
  -- Test statements here
  dv_sr_lspv_docs_api.synchronize(p_year => 2016);
  commit;
  dv_sr_lspv_docs_api.synchronize(p_year => 2017);
  commit;
end;
0
0
