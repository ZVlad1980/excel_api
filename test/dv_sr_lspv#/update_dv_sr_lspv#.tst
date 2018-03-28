PL/SQL Developer Test script 3.0
20
-- Created on 02.03.2018 by V.ZHURAVOV 
declare 
  -- Local variables here
  i integer;
begin
--  dbms_session.reset_package; return;
  -- Test statements here
  dv_sr_lspv#_api.update_dv_sr_lspv#(
    p_year_from => 2018,
    p_year_to   => 2018,
    p_actual_date => to_date(20180228, 'yyyymmdd')
  );
  --
  --dbms_stats.gather_table_stats(user, 'dv_sr_lspv#');
  --
exception
  when others then
    dbms_output.put_line(utl_error_api.get_exception_full);
    raise;
end;
0
0
