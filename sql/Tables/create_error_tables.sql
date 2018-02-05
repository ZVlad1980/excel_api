declare
  l_list_tbl sys.odcivarchar2list := 
    sys.odcivarchar2list(
      'f2ndfl_load_spravki',
      'dv_sr_lspv_docs_t'
    );

  procedure create_err_table(p_table_name varchar2) is
    e_exists_tbl exception;
    pragma exception_init(e_exists_tbl, -955);
  begin
    dbms_output.put('Create error table for ' || p_table_name || ' ... ');
    DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name => p_table_name); --'');
    dbms_output.put_line('Ok');
  exception
    when e_exists_tbl then
      dbms_output.put_line('Exists');
    when others then
      dbms_output.put_line('Error: ' || sqlerrm);
  end create_err_table;
  
begin
  for i in 1..l_list_tbl.count loop
    create_err_table(p_table_name => l_list_tbl(i));
  end loop;
end;
/
/*
begin
  DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name => 'dv_sr_lspv_docs_t');
end;
/
create index err$_dv_sr_lspv_docs_i1 on err$_dv_sr_lspv_docs_t(process_id)

*/
