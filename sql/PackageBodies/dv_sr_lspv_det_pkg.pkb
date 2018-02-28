create or replace package body dv_sr_lspv_det_pkg is

  -- Private type declarations
  GC_PACKAGE_NAME   constant varchar2(32)                       := $$plsql_unit;  
  GС_PRC_UPDATE_DET constant dv_sr_lspv_prc_t.process_name%type := 'UPDATE_DETAIL';
  --
  G_LEGACY       varchar2(1);
  
  /**
   * Обвертки обработки ошибок
   */
  procedure fix_exception(p_line number, p_msg varchar2 default null) is
  begin
    utl_error_api.fix_exception(
      p_err_msg => GC_PACKAGE_NAME || '(' || p_line || '): ' || ' ' || p_msg
    );
  end fix_exception;
  --
  
  function legacy return varchar2 deterministic is begin return nvl(G_LEGACY, 'N'); end legacy;
  --
  
  function get_os_user return varchar2 deterministic is
    l_result log$_dv_sr_lspv.created_by%type;
  begin
    select substrb(sys_context( 'userenv', 'os_user'), 1,32)
    into   l_result
    from dual;
    --
    return l_result;
  exception
    when others then
      return null;
  end get_os_user;

  /**
   * Процедура create_process создает новый процесс в таблице dv_sr_lspv_prc_t
   */
  function create_process(
    p_process_name varchar2 default GС_PRC_UPDATE_DET
  ) return dv_sr_lspv_prc_t.id%type is
    --
    l_process_row dv_sr_lspv_prc_t%rowtype;
  begin
    --
    l_process_row.process_name := p_process_name;
    --
    dv_sr_lspv_prc_api.create_process(
      p_process_row => l_process_row
    );
    --
    return l_process_row.id;
    --
  exception
    when others then
      rollback;
      fix_exception($$plsql_line, 'create_process');
      raise;
  end create_process;
  
  /**
   */
  procedure set_process_state(
    p_process_id      dv_sr_lspv_prc_t.id%type,
    p_state           dv_sr_lspv_prc_t.state%type,
    p_error_msg       dv_sr_lspv_prc_t.error_msg%type    default null,
    p_deleted_rows    dv_sr_lspv_prc_t.deleted_rows%type default null,
    p_error_rows      dv_sr_lspv_prc_t.error_rows%type   default null
  ) is
    l_process_row dv_sr_lspv_prc_t%rowtype;
  begin
    --
    l_process_row.id              := p_process_id  ;
    l_process_row.state           := p_state       ;
    l_process_row.error_msg       := p_error_msg   ;
    l_process_row.deleted_rows    := p_deleted_rows;
    l_process_row.error_rows      := p_error_rows  ;
    --
    dv_sr_lspv_prc_api.set_process_state(
      p_process_row => l_process_row
    );
    --
  exception
    when others then
      rollback;
      fix_exception($$plsql_line, 'set_process_state(' || p_process_id || ',' || p_state || ')');
      raise;
  end set_process_state;
  
  /**
   * 
   */
  procedure update_benefits(
    p_process_id dv_sr_lspv_det_t.process_id%type,
    p_date       date
  ) is
    --
    cursor c_dv_dates as
      select a.date_op
      from   dv_sr_lspv_acc_v a
      where  1=1
      and    a.status = 'N'
      and    a.charge_type = 'BENEFIT'
      and    a.date_op = p_date
      group by a.date_op;
    --
    procedure update_benefits_ is
    begin
      
    end update_benefits_;
  begin
    --
    update_benefits_;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'update_details');
      raise;
  end update_benefits;
  
  /**
   * 
   */
  procedure update_details(
    p_process_id dv_sr_lspv_det_t.process_id%type
  ) is
    --
    cursor c_dv_dates as
      select a.date_op
      from   dv_sr_lspv_acc_v a
      where  a.status = 'N'
      group by a.date_op;
    --
  begin
    --
    for d in c_dv_dates loop
      update_benefits(p_process_id, d.date_op);
    end loop;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'update_details');
      raise;
  end update_details;
  
  /**
   * Процедура update_details обновляет данные таблицы 
   *   dv_sr_lspv_det_t данными из dv_sr_lspv, строки в статусе N или U
   *   и сбрасывает их статус в null
   */
  procedure update_details is
    l_process_id dv_sr_lspv_det_t.process_id%type;
  begin
    --
    l_process_id := create_process;
    --
    update_details(l_process_id);
    --
    set_process_state(
      l_process_id, 
      'SUCCESS'
    );
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'update_details');
      if l_process_id is not null then
        set_process_state(
          l_process_id, 
          'ERROR', 
          p_error_msg => sqlerrm
        );
      end if;
      raise;
  end update_details;
  
end dv_sr_lspv_det_pkg;
/
