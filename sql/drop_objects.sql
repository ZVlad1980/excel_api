/*
drop PACKAGE SYNC_CA_PERSONS;
drop PACKAGE TEST_TBL_API;
drop PACKAGE BODY SET_PERIOD;
drop PROCEDURE F6NDFL_XML_PARSE;
drop PROCEDURE PARSE_XML_IZBUH;
drop VIEW NDFL6_PART2;
drop VIEW NDFL6_RESIDENTS_V;
drop VIEW NDFL6_PERSONS_DETAIL_V;
drop VIEW NDFL_DV_SR_LSPV_NEW_V;
drop VIEW SP_LSPV_FZ_PEN_SCHEMES_V;

*/
declare
  C_MODE_DROP    constant boolean := false;
  C_MAX_REPEATED constant number := 3;
  --
  l_drop_exc boolean := true;
  l_loop     number := 0;
begin
  while l_drop_exc loop
    l_loop := l_loop + 1;
    if l_loop > C_MAX_REPEATED then
      dbms_output.put_line('Max repeated: ' || C_MAX_REPEATED);
      exit;
    end if;
    dbms_output.put_line('Repeat: ' || l_loop);
    l_drop_exc := false;
    for o in (select 'drop ' || o.object_type || ' ' || o.object_name cmd_drop,
                     o.*
              from   user_objects o
              where  object_type not in
                     ('INDEX', 'PACKAGE BODY', 'LOB')
              and    object_name not like 'ISEQ$$%'
              and    object_name not in
                     ('CASH_FLOW_CORRECTS_T',
                       'DV_SR_LSPV_CORRECTION_T',
                       'DV_SR_LSPV_CORR_T',
                       'F6NDFL_LOAD_SPRAVKI',
                       'F6NDFL_LOAD_SUMGOD',
                       'F6NDFL_LOAD_SUMPOSTAVKE',
                       'F6NDFL_LOAD_SVED',
                       'FIZ_LITS_LSPV_ALL',
                       'F_NDFL_LOAD_SPISRAB')
              order  by object_type, object_name) loop
      begin
        dbms_output.put(o.cmd_drop || ' ... ');
        if C_MODE_DROP then
          execute immediate o.cmd_drop;
          dbms_output.put_line('Ok');
        else
          dbms_output.put_line('Mode drop false');
        end if;
      exception
        when others then
          l_drop_exc := true;
          dbms_output.put_line('Fail: ' || sqlerrm);
      end;
    end loop;
    exit when not C_MODE_DROP;
  end loop;
end;
