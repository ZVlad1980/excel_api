PL/SQL Developer Test script 3.0
20
/*select *
from   dv_sr_lspv_det_t d
where  d.addition_id < 0
*/
-- Created on 28.02.2018 by V.ZHURAVOV 
declare 
  -- Local variables here
  i integer;
begin
  --dbms_session.reset_package; return;
  -- Test statements here
  dv_sr_lspv_det_pkg.update_details;
exception
  when others then
    dbms_output.put_line(
      utl_error_api.get_exception_full
    );
end;

--*/
0
0
