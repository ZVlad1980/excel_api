PL/SQL Developer Test script 3.0
14
-- Created on 02.03.2018 by V.ZHURAVOV 
declare 
  -- Local variables here
  i integer;
begin
  -- Test statements here
  dv_sr_lspv#_api.update_dv_sr_lspv#(
    p_year_from => 2016,
    p_year_to   => 2018
  );
  --
  dbms_stats.gather_table_stats(user, 'dv_sr_lspv#');
  --
end;
0
0
